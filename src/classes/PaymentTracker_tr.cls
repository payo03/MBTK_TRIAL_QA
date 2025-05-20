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
 * 1.4          2025-04-25      chaebeom.do             linkPaymentLog() 실행 타이밍 수정
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
        // linkPaymentLog();
    }

    public override void afterUpdate() {
        linkPaymentLog();
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
     * @description PaymentTracker가 생성되고 PaymentType 생성이 완료되면 기존 입금 로그를 연결하기 위한 메서드
     */
    private void linkPaymentLog() {
        // PaymentTractker__c의 PaymentTypeCreation__c 필드가 true로 변경되었을 때
        // 같은 영업기회를 부모로 가지는 IsValid__c 필드가 false인 PaymentTractker가 있다면
        // 그 중에서 가장 최근 PaymentTractker를 가지고 오고
        // 가져온 PaymentTractker 아래에 연결된 PaymentLog를 가져와
        // 새롭게 생성한 PaymentTractker__c에 연결하기

        final String OVER_PAID_KEY = '90_OVER_PAID';
        Map<String, String> curOpptyMap = new Map<String, String>();
        for (PaymentTracker__c newPT : newList) {
            PaymentTracker__c oldPT = oldMap.get(newPT.Id);
            if(oldPT.PaymentTypeCreation__c == false && newPT.PaymentTypeCreation__c == true) curOpptyMap.put(newPT.Id, newPT.Opportunity__c); // ver 1.4
        }

        // 만료 TrackerMap
        Map<String, PaymentTracker__c> expiredPaymentTrackerMap = new Map<String, PaymentTracker__c>();
        for (PaymentTracker__c tracker : [
                SELECT Id, Name, Opportunity__c, Status__c, StatusBeforeCancel__c, 
                (
                    SELECT Id, Amount__c, PaymentTracker__c
                    FROM PaymentLogs__r
                )
                FROM PaymentTracker__c
                WHERE Opportunity__c IN :curOpptyMap.values()
                AND IsValid__c = FALSE
                ORDER BY CreatedDate
        ]) {
            expiredPaymentTrackerMap.put(tracker.Opportunity__c, tracker);
        }

        // 신규 TrackerMap
        Map<String, List<PaymentType__c>> curTypeMap = new Map<String, List<PaymentType__c>>();
        for (PaymentType__c type : [
                SELECT Id, Type__c, RequestAmount__c, DepositAmount__c, PaymentTracker__c, fm_LeftAmount__c
                FROM PaymentType__c
                WHERE PaymentTracker__c IN :curOpptyMap.keySet()
        ]) {
            if (!curTypeMap.containsKey(type.PaymentTracker__c)) {
                curTypeMap.put(type.PaymentTracker__c, new List<PaymentType__c>());
            }
            curTypeMap.get(type.PaymentTracker__c).add(type);
        }

        List<PaymentLog__c> updatePaymentLogList = new List<PaymentLog__c>();
        Map<String, Decimal> sumPaymentLogMap = new Map<String, Decimal>(); // ver 1.3 이전 입금 로그의 합

        // 새 PaymentTracker__c에 기존 PaymentLog 연결
        for (PaymentTracker__c newPT : newList) {
            PaymentTracker__c expiredPT = expiredPaymentTrackerMap.get(newPT.Opportunity__c);

            if (expiredPT != null) {
                Decimal sumPaymentLog = 0;
                for (PaymentLog__c oldLog : expiredPT.PaymentLogs__r) {
                    oldLog.PaymentTracker__c = newPT.Id;
                    updatePaymentLogList.add(oldLog);
                    sumPaymentLog += oldLog.Amount__c;
                }
                sumPaymentLogMap.put(newPT.Id, sumPaymentLog);
            }
        }
        if (!updatePaymentLogList.isEmpty()) update updatePaymentLogList;

        // ver 1.3 이전 입금 로그 연결 후 로그 금액에 따라 입금현황 종류 금액, 입금현황관리 상태 업데이트
        List<PaymentTracker__c> updateTrackerList = new List<PaymentTracker__c>();
        List<PaymentType__c> updateTypeList = new List<PaymentType__c>();

        // 기존금액 분배 Start
        for (PaymentTracker__c newPT : newList) {
            PaymentTracker__c oldTracker = expiredPaymentTrackerMap.get(newPT.Opportunity__c);
            if(oldTracker != null) {
                Decimal remainingAmount = sumPaymentLogMap.get(newPT.Id);
                for (PaymentType__c type : curTypeMap.get(newPT.Id)) {
                    if (remainingAmount <= 0) break;

                    Decimal requestAmt = type.RequestAmount__c != null ? type.RequestAmount__c : 0;
                    Decimal assignAmount = Math.min(remainingAmount, requestAmt);
                    type.DepositAmount__c = assignAmount;
                    remainingAmount -= assignAmount;

                    updateTypeList.add(type);
                }
            }
        }
        if (!updateTypeList.isEmpty()) update updateTypeList;

        for (PaymentTracker__c newPT : newList) {
            PaymentTracker__c oldTracker = expiredPaymentTrackerMap.get(newPT.Opportunity__c);
            if(oldTracker != null) {
                String adjustStatus;
                for (PaymentType__c type : curTypeMap.get(newPT.Id)) {
                    if (type.fm_LeftAmount__c == 0) {
                        adjustStatus = type.UpdateStage__c;                                     // 가장 마지막 UpdateStage 조회
                    } else {
                        if (OVER_PAID_KEY.equals(type.Type__c) && type.DepositAmount__c > 0) adjustStatus = 'OVER_PAID'; // 초과금 납부 Case
                        break;                                                                  // Update 대상 OUT
                    }
                }
                PaymentTracker__c curPT = new PaymentTracker__c(
                    Id = newPT.Id,
                    Status__c = adjustStatus
                );
                updateTrackerList.add(curPT);
            }
        }
        if (!updateTrackerList.isEmpty()) update updateTrackerList;
    }
}