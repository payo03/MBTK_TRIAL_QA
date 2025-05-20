/*************************************************************
 * @author : San.Kang
 * @date : 25. 4. 29.
 * @description : 세금계산서 1일 후 SA에게 noti 발송 배치
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       25. 4. 29.        San.Kang           Created
**************************************************************/
public with sharing class TaxInvoiceDateNoti_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    private final static String dueDate = String.valueOf(System.today().addDays(+1)); // 세금계산서 발행일 +1일
    private final static String notificationTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Custom' LIMIT 1].Id;

    public Database.QueryLocator start(Database.BatchableContext context) {

        String selectFields = 'Id, TaxInvoiceDate__c ';
        String whereConditions = ' TaxInvoiceDate__c = ' + dueDate ;
        String query = CommonUtilController.buildQuery(selectFields, 'Opportunity', whereConditions);
        System.debug('query ::' + query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<Opportunity> records) {
        System.debug('records ::' + records);
        // SA Permission 쿼리
        List<PermissionSetAssignment> permissionSetAssignments = [SELECT Id, AssigneeId, PermissionSet.Name, PermissionSet.Label FROM PermissionSetAssignment WHERE  PermissionSet.Name = 'SA'];

        Set<String> saUserSet = new Set<String>();

        for(PermissionSetAssignment permissionSetAssignment : permissionSetAssignments){
            saUserSet.add(permissionSetAssignment.AssigneeId);
        }

        // notification util Wrapper Class
        for(Opportunity opportunity : records){
            CommonUtilController.NotificationWrap notiWrap = new CommonUtilController.NotificationWrap(
                    '기회의 세금계산서 1일전 알림',
                    '세금계산서 발행일이 1일 남았습니다.',
                    notificationTypeId,
                    UserInfo.getUserId(),
                    opportunity.Id,
                    saUserSet
            );
            CommonUtilController.sendNotification(notiWrap); // Noti 발송
        }
    }

    public void finish(Database.BatchableContext context) {

        System.debug('######finish######');
    }

    public void execute(SchedulableContext context) {

        Database.executeBatch(new TaxInvoiceDateNoti_ba(), 200);
    }
}