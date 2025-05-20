/*************************************************************
 * @author : th.kim
 * @date : 2025-02-21
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-02-21      th.kim          Created
 * 1.1          2025-02-24      tw.Choi         modified
**************************************************************/
public with sharing class DefermentRequestNoti_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    private final static Date dueDate = System.today().addDays(+3);
    private final static String dueDateStr = String.valueOf(dueDate);
    private final static String notificationTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Custom' LIMIT 1].Id;
    
    public Database.QueryLocator start(Database.BatchableContext context) {

        String selectFields = 'Id, RequestDueDate__c, fm_ExpiredDate__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.OwnerId';
        String whereConditions = 'Status__c = \'COMPLETED\' AND (RequestDueDate__c = ' + dueDateStr + ' OR fm_ExpiredDate__c = ' + dueDateStr + ')';
        String query = CommonUtilController.buildQuery(selectFields, 'DefermentRequest__c', whereConditions);

        // List<DefermentRequest__c> listdeferment = Database.query(query);
        // System.debug('listdeferment :::: ' + listdeferment);

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<DefermentRequest__c> records) {

        System.debug('start 조건이 맞을때만 타는곳');

        String titleMessage;
        String bodyMessage;
        for (DefermentRequest__c request : records) {
            titleMessage = request.fm_ExpiredDate__c == dueDate ? '부가세 후취 만료일자 알림' : '인도금 유예 만료일 알림';
            bodyMessage = request.fm_ExpiredDate__c == dueDate
                ? '[' + request.Opportunity__r.Name + ']' + ' 부가세 후취 만료일이 3일 남았습니다.'
                : '[' + request.Opportunity__r.Name + ']' + ' 인도금 유예 만료일이 3일 남았습니다';
            sendNotification(titleMessage, bodyMessage, notificationTypeId, request.Id, new Set<String>{
                request.Opportunity__r.OwnerId
            });
        }

        // 이 부분은 유예요청 상관없이 기회의 출고일 3일전 알림해야 되니 주석 처리
        // for (Opportunity opportunity : [SELECT Id, Name, OwnerId FROM Opportunity WHERE HandoverDate__c = :dueDate]) {
        //     titleMessage = '기회의 출고일 3일전 알림';
        //     bodyMessage = '[' + opportunity.Name + ']' + ' 기회의 출고일이 3일전입니다.';
        //     sendNotification(titleMessage, bodyMessage, notificationTypeId, opportunity.Id, new Set<String>{
        //         opportunity.OwnerId
        //     });
        // }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('Finish');

        // String titleMessage;
        // String bodyMessage;
        // List<Opportunity> listOpp = [SELECT Id, Name, OwnerId FROM Opportunity WHERE HandoverDate__c = :dueDate];

        // System.debug('listOpp ::: ' + listOpp);

        // for (Opportunity opportunity : listOpp) {
        //     titleMessage = '기회의 출고일 3일전 알림';
        //     bodyMessage = '[' + opportunity.Name + '] 출고일이 3일전입니다.';
        //     sendNotification(titleMessage, bodyMessage, notificationTypeId, opportunity.Id, new Set<String>{
        //         opportunity.OwnerId
        //     });
        // }
        // System.debug('여기는 유예요청 상관없이 기회의 출고일 3일전 알림' );
    }

    public void execute(SchedulableContext context) {
        Database.executeBatch(new DefermentRequestNoti_ba(), 200);
    }

    private static void sendNotification(String titleMessage, String bodyMessage, String notificationTypeId, String targetId, Set<String> sendIdSet) {
        // 알림 생성
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(titleMessage);
        notification.setBody(bodyMessage);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setSenderId(UserInfo.getUserId());
        notification.setTargetId(targetId);
        notification.send(sendIdSet);
        System.debug('notification :: ' + notification);
    }
}