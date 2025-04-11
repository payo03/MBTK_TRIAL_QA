/**
* @Author            : payo03@solomontech.net
* @Description 		 : 반제처리 요청, Opportunity 반제처리 요청시
* @Target            : AsyncInterface_test
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-05      payo03@solomontech.net           Created
  1.1      2025-04-08      payo03@solomontech.net           반제금액 Validation
*/
public without sharing class AsyncOffsetRequest implements Queueable, Database.AllowsCallouts {

    private static final String IF_ID = InterfaceSAP.IF_SMS020;
    private static final String LOG_TYPE = 'OFFSET_REQUEST';
    public List<String> opptyIdList;

    public AsyncOffsetRequest(List<String> opptyIdList) {
        this.opptyIdList = opptyIdList;
    }

    public void execute(QueueableContext context) {
        try {
            Map<String, PaymentTracker__c> opptyTrackerMap = new Map<String, PaymentTracker__c>();
            for(PaymentTracker__c tracker : [
                    SELECT Id, Opportunity__c, ru_OffsetAmount__c,
                        Opportunity__r.SaleNumber__c, Opportunity__r.OffsetAmount__c,
                        (
                            SELECT Id, InternalDocumentId__c, Amount__c, IsOffset__c
                            FROM PaymentLogs__r
                            WHERE IsOffset__c = FALSE   // ver1.1 반제금액 Validation
                        )
                    FROM PaymentTracker__c
                    WHERE Opportunity__c IN :opptyIdList
                    AND IsValid__c = TRUE
            ]) {
                String key = tracker.Opportunity__c;
                opptyTrackerMap.put(key, tracker);
            }

            String logId = CommonUtilCustomController.parseIFIdSAP(InterfaceSAP.DFLT);
            List<IF_DTO.OffsetProcess> processList = new List<IF_DTO.OffsetProcess>();
            Map<String, String> keyMap = new Map<String, String>();
            List<PaymentLog__c> updateList = new List<PaymentLog__c>();
            for(String opptyId : opptyTrackerMap.keySet()) {
                Opportunity oppty = opptyTrackerMap.get(opptyId).Opportunity__r;
                PaymentTracker__c tracker = opptyTrackerMap.get(opptyId);

                // ver1.1 반제금액 Validation
                String trackerId = opptyTrackerMap.get(opptyId).Id;
                Decimal offsetDoneAmount = tracker.ru_OffsetAmount__c;      // 기 완료 금액
                Decimal offsetStdAmount = oppty.OffsetAmount__c;            // 반제 기준 금액
                Decimal offsetRequestAmount = 0;                            // 반제요청 금액
                Decimal offsetTotAmount = offsetDoneAmount;                 // 기 완료 금액 + 반제요청 금액

                List<String> docNoList = new List<String>();
                for(PaymentLog__c log : tracker.PaymentLogs__r) {
                    Decimal amount = log.Amount__c;
                    docNoList.add(log.InternalDocumentId__c);

                    offsetRequestAmount += amount;
                    log.IsOffset__c = true;
                    updateList.add(log);

                    offsetTotAmount += amount;
                }
                // 기 완료금액 + 반제요청금액 > 반제 기준 금액일경우
                if(offsetTotAmount > offsetStdAmount) offsetRequestAmount = offsetStdAmount - offsetDoneAmount;

                IF_DTO.OffsetProcess process = new IF_DTO.OffsetProcess();
                process.OINV_DOCNO = oppty.SaleNumber__c;                       // 매출번호
                process.ORCT_PRICE = String.valueOf(offsetRequestAmount);       // 반제금액
                process.ORCT_LIST = docNoList;
                processList.add(process);

                keyMap.put(trackerId, null);
            }
            if(!updateList.isEmpty()) update updateList;

            if(!processList.isEmpty()) {
                // SAP 입금-송장 반제처리 전송
                Map<String, Object> infoMap = new Map<String, Object>();

                infoMap.put('ifId', IF_ID);
                infoMap.put('logId', logId);
                infoMap.put('logType', LOG_TYPE);
                infoMap.put('items', processList);
                infoMap.put('keyMap', keyMap);
                infoMap.put('isLogDetail', true);

                Map<String, Object> resultMap = InterfaceSAP.doCallOutSAPLog(infoMap);
                resultMap.put('isAll', true);
                SAPCommon.syncLogDetailUpdate(logId, resultMap);   // Heroku 통신 완료시. Sync
            }
        } catch(Exception e) {

            System.debug(e.getMessage());
        }
    }
}