/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-01-21      jh.jung           Created
*/
public with sharing class FinanceCloneAndArchive_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    private static final Integer BATCH_SIZE = 200;
    private static final Date THIS_MONTH = Date.today().toStartOfMonth();
    private static final Date LAST_MONTH = Date.today().toStartOfMonth().addMonths(-1);


    public Database.QueryLocator start(Database.BatchableContext context) {
        // 이전달 1일 ~ 이번달 1일 사이에 활성화된 Finance만 clone 대상
        String selectFields =       getFields();
        String fromObject =         'Finance__c';
        String whereCondition =     'StartDate__c < ' + THIS_MONTH.toString().split(' ')[0];
        whereCondition +=           ' AND StartDate__c >= ' + LAST_MONTH.toString().split(' ')[0];
        whereCondition +=           ' AND IsActive__c = true';

        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, whereCondition);
        return Database.getQueryLocator(buildQuery);
    }

    public void execute(SchedulableContext context) {
        Database.executeBatch(new FinanceCloneAndArchive_ba(), BATCH_SIZE);
    }

    public void execute(Database.BatchableContext context, List<SObject> records) {

        List<Finance__c> updateList = new List<Finance__c>();
        List<Finance__c> insertList = new List<Finance__c>();
        Finance__c cloneObj;
        for(SObject record : records) {
            Finance__c finance = (Finance__c) record;

            // 기존 Record 기반으로 clone, 시작일은 업데이트
            cloneObj = finance.clone();
            cloneObj.Id = null;
            cloneObj.StartDate__c = Date.today();
            cloneObj.IsActive__c = true;
            insertList.add(cloneObj);

            // 기존 Record Inactive
            finance.IsActive__c = false;
            updateList.add(finance);
        }

        System.debug('insertList ::: ' + insertList);
        System.debug('updateList ::: ' + updateList);

        if(!insertList.isEmpty())   insert insertList;
        if(!updateList.isEmpty())   update updateList;

    }

    public void finish(Database.BatchableContext context) {
        System.debug('########## FinanceCloneAndArchive_ba Finish ##########');
    }

    public static String getFields() {
        return 'Id, Name, FScompany__c, IsActive__c, MaximumInterestRate__c, VATFree__c, Extras__c, SACommission__c, SubventionRate__c, StartDate__c, MaximumDuration__c, MinimumDuration__c, MinimumInterestRate__c, Segment2__c, AllSegment2__c ';
    }
}