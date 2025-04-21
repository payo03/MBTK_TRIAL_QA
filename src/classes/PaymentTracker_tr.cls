/*************************************************************
 * @author : th.kim
 * @date : 2025-02-10
 * @description :
 * @target :
==============================================================
 * Ver          Date            Author                  Modification
 * 1.0          2025-02-10      th.kim                  Created
 * 1.1          2025-04-01      payo03@solomontech.net  Opportunity PaymentStatus Update
 * 1.2          2025-04-08      chaebeom.do             이전 입금내역 연결 기능 linkPaymentLog() 추가
 * 1.3          2025-04-21      chaebeom.do             linkPaymentLog() 실행시 PaymentType 업데이트 로직 추가
**************************************************************/
public without sharing class PaymentTracker_tr extends TriggerHandler {

    private final List<PaymentTracker__c> newList { get; set; }
    private final List<PaymentTracker__c> oldList { get; set; }
    private final Map<Id, PaymentTracker__c> newMap { get; set; }
    private final Map<Id, PaymentTracker__c> oldMap { get; set; }

    public PaymentTracker_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap = (Map<Id, PaymentTracker__c>) Trigger.newMap;
        oldMap = (Map<Id, PaymentTracker__c>) Trigger.oldMap;
    }

    public override void afterInsert() {
        linkPaymentLog();
    }

    public override void afterUpdate() {
        // linkPaymentLog();
        updateHandover();
        createCommission();
        updateOpportunity();
    }

    /**
     * @author th.kim
     * @description Payment 데이터 업데이트 시 핸드오버도 트리거 태워주기 위한 메서드
     */
    private void updateHandover() {

        List<Handover__c> handoverList = [SELECT Id FROM Handover__c WHERE PaymentTracker__c IN :newMap.keySet()];
        update handoverList;
    }

    // ver1.1 Opportunity PaymentStatus Update
    private void updateOpportunity() {

        List<Opportunity> opptyList = new List<Opportunity>();
        for(PaymentTracker__c newTracker : newList) {
            if(newTracker.Status__c != oldMap.get(newTracker.Id).Status__c) {
                // Opportunity Status Update
                Opportunity oppty = new Opportunity(Id = newTracker.Opportunity__c);
                oppty.PaymentStatus__c = newTracker.Status__c;

                opptyList.add(oppty);
            }
        }

        if(!opptyList.isEmpty()) update opptyList;
    }

    /**
     * @author th.kim
     * @description 부가세 후취 입금 완료 시 커미션 생성
     *              부가세 후취 입금 취소 시 커미션 삭제
     */
    private void createCommission() {

        Set<Id> createOpportunityIdSet = new Set<Id>();
        Set<Id> deleteOpportunityIdSet = new Set<Id>();
        for (PaymentTracker__c newTracker : newList) {
            PaymentTracker__c oldTracker = oldMap.get(newTracker.Id);
            // 부가세 후취 입금 완료
            if (
                (oldTracker.Status__c != 'COMPLETE' && oldTracker.Status__c != 'OVER_PAID')
                && (newTracker.Status__c == 'COMPLETE' || newTracker.Status__c == 'OVER_PAID')
                && newTracker.fm_IsVATDeferred__c
            ) {
                createOpportunityIdSet.add(newTracker.Opportunity__c);
            }
            // 부가세 후취 입금 취소
            else if (
                (oldTracker.Status__c == 'COMPLETE' || oldTracker.Status__c == 'OVER_PAID')
                && (newTracker.Status__c != 'COMPLETE' && newTracker.Status__c != 'OVER_PAID')
                && oldTracker.fm_IsVATDeferred__c
            ) {
                deleteOpportunityIdSet.add(newTracker.Opportunity__c);
            }
        }

        if (!createOpportunityIdSet.isEmpty()) {
            List<Opportunity> opportunityList = [
                SELECT Id, OwnerId
                FROM Opportunity
                WHERE Id IN :createOpportunityIdSet
            ];

            CommissionManagementController.createCommissionHistory(createOpportunityIdSet, true);
        }
        if (!deleteOpportunityIdSet.isEmpty()) {
            CommissionManagementController.deleteCommissionHistory(deleteOpportunityIdSet);
        }
    }

    /**
     * @author chaebeom.do
     * @description PaymentTracker가 생성되면 기존 입금 로그를 연결하기 위한 메서드
     */
    private void linkPaymentLog() {
        // PaymentTractker__c이 생성되었을 때
        // 같은 영업기회를 부모로 가지는 IsValid__c 필드가 false인 PaymentTractker가 있다면
        // 그 중에서 가장 최근 PaymentTractker를 가지고 오고
        // 가져온 PaymentTractker 아래에 연결된 PaymentLog를 가져와
        // 새롭게 생성한 PaymentTractker__c에 연결하기

        Map<String, String> curOpptyMap = new Map<String, String>();
        for (PaymentTracker__c newPT : newList) {
            curOpptyMap.put(newPT.Id, newPT.Opportunity__c);
        }

        List<PaymentTracker__c> expiredPaymentTrackerList = new List<PaymentTracker__c>([
            SELECT Id, Name, Opportunity__c, Status__c
            FROM PaymentTracker__c
            WHERE Opportunity__c IN :curOpptyMap.values()
            AND IsValid__c = false
            ORDER BY CreatedDate DESC
        ]);

        Map<Id, List<PaymentTracker__c>> expiredPaymentTrackerMap = new Map<Id, List<PaymentTracker__c>>();
        for (PaymentTracker__c tracker : expiredPaymentTrackerList) {
            if (!expiredPaymentTrackerMap.containsKey(tracker.Opportunity__c)) {
                expiredPaymentTrackerMap.put(tracker.Opportunity__c, new List<PaymentTracker__c>());
            }
            expiredPaymentTrackerMap.get(tracker.Opportunity__c).add(tracker);
        }

        List<PaymentLog__c> expiredPaymentLogList = [
            SELECT Id, Amount__c, PaymentTracker__c
            FROM PaymentLog__c
            WHERE PaymentTracker__r.Opportunity__c IN :expiredPaymentTrackerMap.keySet()
        ];

        Map<Id, List<PaymentLog__c>> expiredPaymentLogMap = new Map<Id, List<PaymentLog__c>>();
        for (PaymentLog__c log : expiredPaymentLogList) {
            if (!expiredPaymentLogMap.containsKey(log.PaymentTracker__c)) {
                expiredPaymentLogMap.put(log.PaymentTracker__c, new List<PaymentLog__c>());
            }
            expiredPaymentLogMap.get(log.PaymentTracker__c).add(log);
        }

        List<PaymentLog__c> updatePaymentLogList = new List<PaymentLog__c>();
        Map<String, String> sumPaymentLogMap = new Map<String, String>(); // ver 1.3 이전 입금 로그의 합

        // 새 PaymentTracker__c에 기존 PaymentLog 연결
        for (PaymentTracker__c newPT : newList) {
            if (expiredPaymentTrackerMap.size() > 0) {
                PaymentTracker__c expiredPT = expiredPaymentTrackerMap.get(newPT.Opportunity__c)[0];
                if (expiredPT != null && expiredPaymentLogMap.containsKey(expiredPT.Id)) {
                    let sumPaymentLog = 0;
                    for (PaymentLog__c oldLog : expiredPaymentLogMap.get(expiredPT.Id)) {
                        oldLog.PaymentTracker__c = newPT.Id;
                        updatePaymentLogList.add(oldLog);
                        sumPaymentLog += oldLog.Amount__c;
                    }
                    sumPaymentLogMap.put(newPT.Id, sumPaymentLog);
                }
            }
        }

        if (!updatePaymentLogList.isEmpty()) update updatePaymentLogList;

        // ver 1.3 이전 입금 로그 연결 후 로그 금액에 따라 입금현황 종류 금액, 입금현황관리 상태 업데이트

        List<SObject> updateList = new List<SObject>();

        // 새로 생성된 계약의 입금현황 종류 가져오기
        Map<Id, List<PaymentType__c>> curTypeMap = new Map<Id, List<PaymentType__c>>();
        for (PaymentType__c type : [SELECT Id, Type__c, RequestAmount__c, DepositAmount__c
            FROM PaymentType__c
            WHERE PaymentTracker__c IN :curOpptyMap.keySet()
        ]) {
            if (!curTypeMap.containsKey(type.PaymentTracker__c)) {
                curTypeMap.put(type.PaymentTracker__c, new List<PaymentType__c>());
            }
            curTypeMap.get(type.PaymentTracker__c).add(type);
        }
        for (PaymentTracker__c newPT : newList) {
            updateList.add(new PaymentTracker__c(
                Id = newPT.Id,
                Status__c = expiredPaymentTrackerMap.get(newPT.Opportunity__c)[0].Status__c
            ));
            Decimal remainingAmount = sumPaymentLogMap.get(newPT.Id);
            for (PaymentType__c type : curTypeMap.get(newPT.Id)) {
                Decimal requestAmt = type.RequestAmount__c != null ? type.RequestAmount__c : 0;

                if (remainingAmount > 0) {
                    if (remainingAmount >= requestAmt) {
                        remainingAmount -= requestAmt;
                        type.DepositAmount__c = requestAmt;
                    } else {
                        type.DepositAmount__c = remainingAmount;
                        remainingAmount = 0;
                    }
                    updateList.add(type);
                }
            }
        }

        if (!updateList.isEmpty()) update updateList;
    }
}