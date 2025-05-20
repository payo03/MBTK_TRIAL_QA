/*************************************************************
 * @author : chaebeom.do
 * @description : 매 반기별 이전 반기의 영업사원별 굿윌 계산
 * @target : HalfYearlyGoodWillCalculation_sc
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-14      chaebeom.do     Created
**************************************************************/
public with sharing class HalfYearlyGoodWillCalculation_ba implements Database.Batchable<SObject>, Database.Stateful {
    // 적립 기준 년도와 월
    private final Integer targetYear;
    private final Integer targetMonth;

    // 적립 기준 반기
    private final Integer targetQuarter1;
    private final Integer targetQuarter2;
    
    // OwnerId별 Opportunity 개수 저장
    private final Map<Id, Integer> ownerOpportunityCountMap = new Map<Id, Integer>();
    
    public HalfYearlyGoodWillCalculation_ba(Date targetDate) {
        // targetYear = targetDate.month() > 6 ? targetDate.year() : targetDate.year() - 1;
        targetYear = targetDate.year();
        targetMonth = targetDate.month();
        targetQuarter1 = targetDate.month() < 7 ? 1 : 3;
        targetQuarter2 = targetDate.month() < 7 ? 2 : 4;

        for (AggregateResult ar : [
            SELECT COUNT(Id) cnt, OwnerId
            FROM Opportunity
            WHERE StageName = 'Closed Won'
            AND CALENDAR_YEAR(TaxInvoiceDate__c) = :targetYear
            AND (CALENDAR_QUARTER(TaxInvoiceDate__c) = :targetQuarter1
            OR CALENDAR_QUARTER(TaxInvoiceDate__c) = :targetQuarter2)
            GROUP BY OwnerId
        ]) {
            ownerOpportunityCountMap.put((Id) ar.get('OwnerId'), (Integer) ar.get('cnt'));
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id
            FROM User
            WHERE Profile.Name = 'MTBK Agent'
            AND IsActive = true 
        ]);
    }

    public void execute(Database.BatchableContext bc, List<User> recordList) {

        GoodWillSavingController.execute(ownerOpportunityCountMap, recordList);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('HalfYearlyGoodWillCalculation_ba is finished');
    }
}