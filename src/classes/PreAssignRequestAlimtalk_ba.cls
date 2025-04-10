/*************************************************************
 * @author : San.Kang
 * @date : 2025-01-07
 * @description : 사전배정요청, 가상계좌 안내 7일 후 미입금시 알림톡 발송
 *             PreAssignRequestAlimtalk_sc sc = new PreAssignRequestAlimtalk_sc();
 *             String Schedulable = '0 0 9 * * ?'; // 9시 스케쥴
 *             System.schedule('PreAssignRequestAlimtalk_ba Scheduled Job', Schedulable, sc);
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-01-07        San.Kang           Created
**************************************************************/
public without sharing class PreAssignRequestAlimtalk_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    //오늘부터 7일 경과된 요청날짜
    private final static Date RequestDate = System.today().addDays(-7);

    //계약금 요청상태 이면서 7일 경과된 사전배정요청 쿼리
    public Database.QueryLocator start(Database.BatchableContext context) {
        String SelectQuery =  getField();
        String WhereQuery = '  RequestDate__c =:RequestDate AND Type__c = \'계약금 요청\'' ;

        String query = CommonUtilController.buildQuery(SelectQuery, 'AssignRequest__c' , WhereQuery);
        return Database.getQueryLocator(query);
    }

    //사전배정요청 OR 가상계좌 안내 시점 7일뒤 Account 계약자에게 다시 알림톡 보내는 로직
    public void execute(Database.BatchableContext context, List<AssignRequest__c> records) {
        try {
            Set<Id> OpptyIdSet = new Set<Id>();
            Map<String,String> AccountMap = new Map<String,String>();
            for(AssignRequest__c pa : records){
                OpptyIdSet.add(pa.Opportunity__c);
            }

            List<Opportunity> OpportunityList = [SELECT id,AccountId, Account.Name
                                            FROM Opportunity
                                            WHERE Id IN: OpptyIdSet];

            for(Opportunity oppty : OpportunityList){
                AccountMap.put(oppty.AccountId, oppty.Account.Name);
            }

            List<Object> infoMapList = new List<Object>();

            Map<Object, Object> buttonMap = new Map<Object, Object>{
                    'Webbutton' => ''
            };

            System.debug('test2');
            Map<String, Object> InfoMap = new Map<String, Object>{
                    'templateTitle' => 'Deposit 미입금 알림톡',
                    'object' => 'Account',
                    'buttonMap' => buttonMap,
                    'infoMapList' => infoMapList
            };
            InterfaceKakao.doCallOutKakaoAlimTalk(InfoMap);

        } catch (Exception e) {
            System.debug('Error => ' + e.getStackTraceString() + ' msg ' + e.getMessage());
        }
    }
    public void finish(Database.BatchableContext BC){
        System.debug('#####Finish!!#####');
    }

    public String getField(){
        String Field = ' Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, ' +
        ' SystemModstamp, LastActivityDate, LastViewedDate, LastReferencedDate, Opportunity__c, VehicleStock__c, Submitter__c, ' +
        ' Status__c, Type__c, VehicleCategory__c, RequestDate__c ';

        return Field;
    }
}