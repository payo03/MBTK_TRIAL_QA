/*************************************************************
 * @author : th.kim
 * @date : 2025-04-07
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-04-07      th.kim          Created
**************************************************************/
public without sharing class IncentiveHistory_tr extends TriggerHandler {

    private final List<IncentiveHistory__c> newList { get; set; }
    private final List<IncentiveHistory__c> oldList { get; set; }
    private final Map<Id, IncentiveHistory__c> newMap { get; set; }
    private final Map<Id, IncentiveHistory__c> oldMap { get; set; }

    public IncentiveHistory_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap = (Map<Id, IncentiveHistory__c>) Trigger.newMap;
        oldMap = (Map<Id, IncentiveHistory__c>) Trigger.oldMap;
    }

    public override void afterInsert() {
        createCommissionIncentiveMaster();
    }

    /**
     * @author th.kim
     * @description 인센티브 내역 생성 시 (커미션 & 인센티브) 마스터 생성
     */
    private void createCommissionIncentiveMaster() {

        List<CommissionIncentiveMaster__c> commissionIncentiveMasterList = new List<CommissionIncentiveMaster__c>();
        for (IncentiveHistory__c newHistory : newList) {
            commissionIncentiveMasterList.add(new CommissionIncentiveMaster__c(
                    Type__c = 'Incentive',
                    IncentiveHistory__c = newHistory.Id,
                    OwnerId = newHistory.OwnerId
            ));
        }
        insert commissionIncentiveMasterList;
    }
}