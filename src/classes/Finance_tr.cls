/*************************************************************
 * @author : San.Kang
 * @date : 2025-01-23
 * @description : 파이낸스 정보 갱신알림
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-01-23        San.Kang           Created
**************************************************************/

public without sharing class Finance_tr extends TriggerHandler {
//    private static final List<String> ProfileName = new List<String>{'MTBK Agent','MTBK Internal'};
//    private static final Set<String> userIdList = new Set<String>();
    private static final Map<String,Map<String,Object>> updateFieldInfo = new Map<String,Map<String,Object>>();
//    private static final List<String> updateFieldInfoForName = new List<String>();

    /** TriggerHandler **/
    private List<Finance__c>    newList { get; set; }
    private List<Finance__c>    oldList { get; set; }
    private Map<Id, Finance__c> newMap  { get; set; }
    private Map<Id, Finance__c> oldMap  { get; set; }

    public Finance_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap  = (Map<Id, Finance__c>) Trigger.newMap;
        oldMap  = (Map<Id, Finance__c>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        updatedFinanceName();
    }

    public override void beforeUpdate() {
//        updatedFinaceInfo();
        updatedFinanceName();
    }

    private void updatedFinanceName() {
        System.debug('updatedFinanceName start');
//        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(Finance__c.getSObjectType().getDescribe().getName()).getDescribe().fields.getMap();
//        List<String> updateFieldInfoForName;
//        Finance__c finance;

        System.debug('newList ::: ' + newList);

        for(Finance__c finance :newList){

            String year = '';
            String month = '';
            Date startDate = finance.StartDate__c;

            if(finance.StartDate__c != null) {
                year = String.valueOf(startDate.year()).substring(2, 4); // 연도의 마지막 두 자리 (예: "24")
                month = startDate.month() < 10 ? '0' + String.valueOf(startDate.month()) : String.valueOf(startDate.month()); // 두 자리 월
            }

            if(finance.AllSegment2__c)          { finance.Segment2__c = null; }
            if(finance.Segment2__c != null)     { finance.AllSegment2__c = false; }
            if(finance.Segment2__c == null)     { finance.AllSegment2__c = true; }

            String updateName = '';
            String financeName = CommonUtilController.getPicklistLabelForLabel('Finance__c', 'FScompany__c', finance.FScompany__c);

            if(finance.FScompany__c != null) { updateName += financeName + ' '; }
            if(finance.MinimumInterestRate__c != null) { updateName += finance.MinimumInterestRate__c  + ' '; }
            if(finance.MinimumInterestRate__c != null && finance.MaximumInterestRate__c != null) { updateName += '~ '; }
            if(finance.MaximumInterestRate__c != null) { updateName += finance.MaximumInterestRate__c  + ' '; }
            if(finance.AllSegment2__c ) {
                updateName += 'All ';
            } else if (finance.Segment2__c != null) {
                updateName += finance.Segment2__c  + ' ';
            }
            if(finance.MaximumDuration__c != null) { updateName += finance.MaximumDuration__c; }
//            updateName += year + month;

            finance.Name = updateName;
            System.debug(finance.Name);
        }
    }

    //파이낸스 정보 갱신알림
//    private void updatedFinaceInfo() {
//        try{
//            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(Finance__c.getSObjectType().getDescribe().getName()).getDescribe().fields.getMap();
//            for(Id financeId :newMap.keySet()){
//                for(String field :fieldMap.keySet()){
//                    Object newValue = newMap.get(financeId).get(field);
//                    Object oldValue = oldMap.get(financeId).get(field);
//
//                    if(oldValue != newValue) updateFieldInfo.put(financeId, new Map<String,Object>{field => oldValue + '에서 ' + newValue});
//                }
//            }
//            System.debug('test');
//            if(!updateFieldInfo.keySet().isEmpty()){
//                List<User> userList = [SELECT Id
//                                        FROM User
//                                        WHERE Profile.Name IN: ProfileName];
//                for(User userObj : userList){
//                    userIdList.add(userObj.Id);
//                }
//                sendNotiUpdatedFinace();
//            }
//        }catch(Exception e){
//            System.debug('e msg=> ' + e.getMessage() + 'e stack' + e.getStackTraceString());
//        }
//    }
//
//    private void sendNotiUpdatedFinace() {
//        try {
//            // Custom Notification 객체 생성
//            CustomNotificationType notificationType = [SELECT Id, DeveloperName
//                                                        FROM CustomNotificationType
//                                                        WHERE DeveloperName =:'Custom'];
//
//            Messaging.CustomNotification notification = new Messaging.CustomNotification();
//
//            for(String financeId : updateFieldInfo.keySet()){
//                String field = String.valueOf(updateFieldInfo.get(financeId).keySet()).replace('{', '').replace('}', '');
//                // 알림 메시지 설정
//                notification.setTitle('파이낸셜 정보 갱신'); // 제목
//                notification.setBody(newMap.get(financeId).Name +' 파이낸셜의 ' + field + '필드의 정보가 ' + updateFieldInfo.get(financeId).get(field) + '로 갱신 되었습니다.'); // 내용
//                notification.setNotificationTypeId(notificationType.Id);
//                notification.setTargetId(financeId);
//                notification.send(userIdList);
//            }
//            System.debug('Custom Notification sent successfully.');
//        } catch (Exception e) {
//            System.debug('Error sending Custom Notification: ' + e.getMessage());
//        }
//    }
}