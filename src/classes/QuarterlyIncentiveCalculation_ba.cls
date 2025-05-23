/*************************************************************
 * @author : th.kim
 * @description : 분기별 영업사원 인센티브 계산
 * @target : QuarterlyIncentiveCalculation_sc
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-12      th.kim          Created
**************************************************************/
public with sharing class QuarterlyIncentiveCalculation_ba implements Database.Batchable<SObject>, Database.Stateful {

    // 계산할 년도와 월
    private final Integer targetYear;
    private final Integer targetMonth;

    // 현재 분기 계산
    private final Integer targetQuarter;

    private Map<Id, Set<Id>> ownerOpportunityIdCountMap = new Map<Id, Set<Id>>();

    /**
     * @param targetDate 분기 계산할 날짜
     */
    public QuarterlyIncentiveCalculation_ba(Date targetDate) {

        targetYear = targetDate.year();
        targetMonth = targetDate.month();
        targetQuarter = (targetMonth - 1) / 3 + 1;

        // 계산 전 초기화
        IncentiveCalculationController.initData([
            SELECT Id, IncentiveHistoryQuarterly__c, IncentiveHistoryAnnual__c
            FROM Opportunity
            WHERE CALENDAR_YEAR(TaxInvoiceDate__c) = :targetYear
            AND CALENDAR_QUARTER(TaxInvoiceDate__c) = :targetQuarter
        ]);

        // 완료된 건
        for (Opportunity opportunity : [
            SELECT Id, OwnerId
            FROM Opportunity
            WHERE CALENDAR_YEAR(TaxInvoiceDate__c) = :targetYear
            AND CALENDAR_QUARTER(TaxInvoiceDate__c) = :targetQuarter
            AND StageName = 'Closed Won'
        ]) {
            // 소유자별 기회 개수 맵
            ownerOpportunityIdCountMap = IncentiveCalculationController.setOwnerOpportunityIdCountMap(ownerOpportunityIdCountMap, opportunity);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id, Year__c, TargetType__c, Quarter__c, MinSalesTarget__c, TargetAmount__c
            FROM IncentiveTargetMaster__c
            WHERE TargetType__c = 'Quarterly'
            AND Year__c = :String.valueOf(targetYear)
            AND Quarter__c = :'Q' + targetQuarter
            ORDER BY MinSalesTarget__c DESC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<IncentiveTargetMaster__c> recordList) {

        IncentiveCalculationController.execute(ownerOpportunityIdCountMap, recordList);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('QuarterlyIncentiveCalculation_ba is finished');
    }
}