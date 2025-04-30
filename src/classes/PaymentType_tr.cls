/**
* @Author            : payo03@solomontech.net
* @Description 		 : PaymentType_tr
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-02-17      payo03@solomontech.net           Created
  1.1      2025-02-28      payo03@solomontech.net           환불처리시 상태 이전단계로 Update
  1.2      2025-03-31      payo03@solomontech.net           PaymentType 인도금유예 단건추가 Case
*/
public with sharing class PaymentType_tr extends TriggerHandler {

    private List<PaymentType__c> newList { get; set; }
    private List<PaymentType__c> oldList { get; set; }
    private Map<Id, PaymentType__c> newMap { get; set; }
    private Map<Id, PaymentType__c> oldMap { get; set; }

    /*
        1. KEY : 단일 Insert여부 / VALUE : List
        2. Map<String, List<PaymentType__c>> List
        3. Key : PaymentTrackerId / VALUE : List<PaymentType__c>
    */
    private Map<Boolean, List<PaymentType__c>> isBundleMap { get; set; }

    public PaymentType_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap = (Map<Id, PaymentType__c>) Trigger.newMap;
        oldMap = (Map<Id, PaymentType__c>) Trigger.oldMap;

        if (Trigger.isInsert && Trigger.isBefore) {
            isBundleMap = getIsBundleMap();
        }
    }

    public override void beforeInsert() {
        doSetDefaultValues();
    }

    public override void afterUpdate() {
        doUpdateRefund();
    }

    /**
     * @author payo03@solomontech.net
     * @description Update단계 Setup
           참조 : https://manonlineservices.sharepoint.com/:p:/r/sites/MTBK_Salesforce_Implementation/_layouts/15/Doc2.aspx?action=edit&sourcedoc=%7B3ca22b7c-8aea-4338-8e21-632ad7b4fe50%7D&wdOrigin=TEAMS-WEB.teamsSdk_ns.rwc&wdExp=TEAMS-TREATMENT&wdhostclicktime=1739509759090&web=1
           Case 1. 계약금,인도금                         / 인도금 => COMPLETE
           Case 2. 계약금,인도금,부가세 후취               / 인도금 => HAND_OVER_READY, 부가세 후취 => COMPLETE
           Case 3. 계약금,인도금,인도금 유예               / 인도금 => TAX_INVOICE, 인도금 유예 => COMPLETE
           Case 4. 계약금,인도금,인도금 유예,부가세 후취     / 인도금 => TAX_INVOICE, 인도금 유예 => HANDOVER_READY, 부가세 후취 => COMPLETE
    */
    private void doSetDefaultValues() {

        for(Boolean isBundle : isBundleMap.keySet()) {
            // ver1.2 PaymentType 인도금유예 단건추가 Case
            List<PaymentType__c> sortedList = new List<PaymentType__c>(isBundleMap.get(isBundle));
            CommonUtilController.sortSObjectList(sortedList, 'Type__c', false);

            // 1. Tracker Key별로 Map, Type Key별로 2차Map 생성
            Map<String, Map<String, PaymentType__c>> typeMap = new Map<String, Map<String, PaymentType__c>>();
            for(PaymentType__c newType : sortedList) {
                // 대출계정은 PASS
                if(newType.Type__c.startsWith('99')) continue;

                String key = newType.PaymentTracker__c;
                Map<String, PaymentType__c> infoMap = typeMap.containsKey(key) ? typeMap.get(key) : new Map<String, PaymentType__c>();

                infoMap.put(newType.Type__c, newType);
                typeMap.put(key, infoMap);
            }

            // 2. Type별 Update단계 지정
            for(String trackerKey : typeMap.keySet()) {
                Map<String, PaymentType__c> infoMap = typeMap.get(trackerKey);

                List<String> typeOrder = new List<String>();
                for(String typeKey : infoMap.keySet()) {
                    typeOrder.add(typeKey);
                }

                String type = typeOrder.get(1); // OVER_PAID DEFAULT 생성
                switch on type {
                    // 입금계정의 마지막 순번 찾기
                    when '91_VAT' {
                        // 부가세 후취 최종
                        adjustPaymentType(infoMap, '91_VAT', 'COMPLETE');                        // 부가세 후취[4]
                        if (infoMap.containsKey('3_DEFERRED_PAYMENT')) {
                            adjustPaymentType(infoMap, '3_DEFERRED_PAYMENT', 'HANDOVER_READY'); // 인도금 유예[3]
                            adjustPaymentType(infoMap, '2_DOWN_PAYMENT', 'TAX_INVOICE');        // 인도금[2]
                        } else if (infoMap.containsKey('2_DOWN_PAYMENT')) {
                            adjustPaymentType(infoMap, '2_DOWN_PAYMENT', 'HANDOVER_READY');     // 인도금[2]
                        }
                    }
                    when '3_DEFERRED_PAYMENT' {
                        // 인도금 유예 최종
                        adjustPaymentType(infoMap, '3_DEFERRED_PAYMENT', 'COMPLETE');           // 인도금 유예[3]
                        adjustPaymentType(infoMap, '2_DOWN_PAYMENT', 'TAX_INVOICE');            // 인도금[2]
                    }
                    when '2_DOWN_PAYMENT' {
                        // 인도금 최종
                        adjustPaymentType(infoMap, '2_DOWN_PAYMENT', 'COMPLETE');               // 인도금[2]
                    }
                }
                adjustPaymentType(infoMap, '90_OVER_PAID', 'OVER_PAID');
                adjustPaymentType(infoMap, '1_DEPOSIT', 'DEPOSIT');
            }

            // 3. 단건은 기데이터 Update대상
            if(!isBundle) updateRelatedList(sortedList);
        }
    }

    // ver1.1 환불처리시 상태 이전단계로 Update[전도형 책임과 논의 완료]
    private void doUpdateRefund() {
        // 환불처리건 Get
        Map<String, String> refundStatusMap = new Map<String, String>();
        for(PaymentType__c newType : newList) {
            PaymentType__c oldType = oldMap.get(newType.Id);

            // 환불처리 완료 Case.
            if(
                    (oldType.RefundCompletedDate__c == null && newType.RefundCompletedDate__c != null) ||
                    (oldType.RefundCompletedDate__c != null && newType.RefundCompletedDate__c != oldType.RefundCompletedDate__c)
            ) {
                refundStatusMap.put(newType.PaymentTracker__c, null);
            }
        }

        // 초과금 제외의 데이터 Get
        for(PaymentType__c paymentType : [
                SELECT Id, PaymentTracker__c, UpdateStage__c
                FROM PaymentType__c
                WHERE PaymentTracker__c IN :refundStatusMap.keySet()
                AND (NOT UpdateStage__c IN (NULL, 'OVER_PAID', 'NEW'))
                ORDER BY PaymentTracker__c, Type__c DESC
        ]) {
            String key = paymentType.PaymentTracker__c;
            if(refundStatusMap.get(key) != null) continue;  // 초과금 이전의 상태값 Check

            refundStatusMap.put(key, paymentType.UpdateStage__c);
        }

        // Tracker 상태 이전값으로 Update
        List<PaymentTracker__c> updateList = new List<PaymentTracker__c>();
        for(String paymentTrackerId : refundStatusMap.keySet()) {
            PaymentTracker__c tracker = new PaymentTracker__c(Id = paymentTrackerId);
//            tracker.Status__c = refundStatusMap.get(paymentTrackerId);
            tracker.Status__c = 'HANDOVER_READY';

            updateList.add(tracker);
        }
        if(!updateList.isEmpty()) update updateList;
    }

    // ver1.2 PaymentType 인도금유예 단건추가 Case
    private static void updateRelatedList(List<PaymentType__c> typeList) {
        List<PaymentType__c> updateList = new List<PaymentType__c>();
        for(PaymentType__c type : typeList) {
            if(type.Id != null) updateList.add(type);
        }

        if(!updateList.isEmpty()) update updateList;
    }

    // ver1.2 PaymentType 인도금유예 단건추가 Case
    private Map<Boolean, List<PaymentType__c>> getIsBundleMap() {
        Map<Boolean, List<PaymentType__c>> isBundleMap = new Map<Boolean, List<PaymentType__c>>();

        // 1. Tracker별로 Insert 확인
        Map<String, List<PaymentType__c>> trackerMap = new Map<String, List<PaymentType__c>>();
        for(PaymentType__c newType : newList) {
            String key = newType.PaymentTracker__c;

            List<PaymentType__c> typeList = trackerMap.containsKey(key)
                    ? trackerMap.get(key)
                    : new List<PaymentType__c>();
            typeList.add(newType);
            trackerMap.put(key, typeList);
        }

        // 2. Tracker별 기존재 데이터여부 확인 및 GET
        // 신규 Insert데이터는 newMap.keySet().contains로 판별
        List<PaymentType__c> paymentTypeList = [
                SELECT Id, PaymentTracker__c,
                        Type__c, UpdateStage__c
                FROM PaymentType__c
                WHERE PaymentTracker__c IN :trackerMap.keySet()
        ];
        for(PaymentType__c paymentType : paymentTypeList) {
            String key = paymentType.PaymentTracker__c;

            List<PaymentType__c> typeList = trackerMap.containsKey(key)
                    ? trackerMap.get(key)
                    : new List<PaymentType__c>();
            typeList.add(paymentType);
            trackerMap.put(key, typeList);
        }

        // 3. 1_DEPOSIT (DEFAULT) 여부에따라 단건-통합건 여부 확인
        for(String key : trackerMap.keySet()) {
            Boolean isBundle = false;
            List<PaymentType__c> typeObjList = trackerMap.get(key);
            for(PaymentType__c typeObj : typeObjList) {

                // 1. 계약금 Record Id == NULL => 통합건 Insert Case
                if('1_DEPOSIT'.equals(typeObj.Type__c) && typeObj.Id == null) isBundle = true;
                if(isBundle) break;
            }

            List<PaymentType__c> typeList = isBundleMap.containsKey(isBundle)
                    ? isBundleMap.get(isBundle)
                    : new List<PaymentType__c>();

            typeList.addAll(typeObjList);
            isBundleMap.put(isBundle, typeList);
        }

        return isBundleMap;
    }

    private static void adjustPaymentType(Map<String, PaymentType__c> infoMap, String key, String stage) {
        PaymentType__c payment = infoMap.get(key);
        payment.UpdateStage__c = stage;
    }
}