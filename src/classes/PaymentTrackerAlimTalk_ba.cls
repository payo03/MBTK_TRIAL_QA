public with sharing class PaymentTrackerAlimTalk_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    private final static String DUEDATE = String.valueOf(System.today().addDays(+3));

    public Database.QueryLocator start(Database.BatchableContext context) {

        String SelectQuery =  getField();
        String WhereQuery = '  fm_ExpiredDate__c = ' + DUEDATE
                + ' AND Status__c = \'COMPLETED\''
                + ' AND Type__c = \'VATDeferred\''
                + ' AND Opportunity__r.VirtualAccount__c != null ';
        String query = CommonUtilController.buildQuery(SelectQuery, 'DefermentRequest__c' , WhereQuery);
        System.debug('query :: ' + query);
        System.debug('Database.getQueryLocator(query) :: ' + Database.getQueryLocator(query));

        List<DefermentRequest__c> listdeferment = Database.query(query);
        System.debug('listdeferment :::: ' + listdeferment);
        return Database.getQueryLocator(query);

    }

    public String getField(){
        String Field = 'Id, name, fm_ExpiredDate__c, Opportunity__r.Account.Owner.Name, DeferredAmount__c, fm_DeferredAmount__c, Opportunity__r.Account.PersonMobilePhone, toLabel(Status__c), Opportunity__c, Opportunity__r.AccountId, Opportunity__r.VirtualAccount__c, Opportunity__r.VirtualAccount__r.fm_VirtualAccount__c ';

        return Field;
    }

    public void execute(Database.BatchableContext context, List<DefermentRequest__c> records) {

        System.debug('execute 실행');

        try {

            for(DefermentRequest__c objDr : records) {

                List<Map<Object, Object>> infoMapList = new List<Map<Object, Object>>{
                    new Map<Object, Object>{
                        'objectName' => 'Account',
                        'recordId' => objDr.Opportunity__r.AccountId
                    }
                };

                Map<String, Object> InfoMap = new Map<String, Object> {
                    'templateTitle' => '부가세유예 납입 안내',
                    'object' => 'DefermentRequest__c',
                    'recordId' => objDr.Id,
                    'infoMapList' => infoMapList
                };

                if(!test.isRunningTest()){
                    InterfaceKakao.doCallOutKakaoAlimTalk(InfoMap);
                }
            }

        } catch(Exception e) {
            System.debug('Error ::: ' + e.getStackTraceString() + ' msg ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext BC){
        System.debug('Finish');
    }

    public void execute(SchedulableContext context) {
        Database.executeBatch(new PaymentTrackerAlimTalk_ba(), 200);
    }
}