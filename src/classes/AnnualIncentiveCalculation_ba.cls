/*************************************************************
 * @author : th.kim
 * @description : 연간 영업사원별 인센티브 계산 배치
 * @target : AnnualIncentiveCalculation_sc
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-13      th.kim          Created
**************************************************************/
public with sharing class AnnualIncentiveCalculation_ba implements Database.Batchable<SObject>, Database.Stateful {

    // 연간 인센티브 계산할 연도
    private final Integer targetYear;

    // OwnerId별 Opportunity 개수 저장
//    private final Map<Id, Integer> ownerOpportunityCountMap = new Map<Id, Integer>();

    private Map<Id, Set<Id>> ownerOpportunityIdCountMap = new Map<Id, Set<Id>>();

    /**
     * @param targetDate 계산할 연도의 Date
     */
    public AnnualIncentiveCalculation_ba(Date targetDate) {

        targetYear = targetDate.year();

//        for (AggregateResult ar : [
//            SELECT COUNT(Id) cnt, OwnerId
//            FROM Opportunity
//            WHERE CALENDAR_YEAR(TaxInvoiceDate__c) = :targetYear
//            AND StageName = 'Closed Won'
//            GROUP BY OwnerId
//        ]) {
//            ownerOpportunityCountMap.put((Id) ar.get('OwnerId'), (Integer) ar.get('cnt'));
//        }

        // TODO
        for (Opportunity opportunity : [
            SELECT Id, OwnerId
            FROM Opportunity
            WHERE CALENDAR_YEAR(TaxInvoiceDate__c) = :targetYear
            AND StageName = 'Closed Won'
        ]) {
            ownerOpportunityIdCountMap = IncentiveCalculationController.setOwnerOpportunityIdCountMap(ownerOpportunityIdCountMap, opportunity);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id, Year__c, TargetType__c, Quarter__c, MinSalesTarget__c, TargetAmount__c
            FROM IncentiveTargetMaster__c
            WHERE TargetType__c = 'Annual'
            AND Year__c = :String.valueOf(targetYear)
            ORDER BY MinSalesTarget__c DESC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<IncentiveTargetMaster__c> recordList) {

//        IncentiveCalculationController.execute(ownerOpportunityCountMap, recordList);
        IncentiveCalculationController.execute(ownerOpportunityIdCountMap, recordList);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('AnnualIncentiveCalculation_ba is finished');
    }

}