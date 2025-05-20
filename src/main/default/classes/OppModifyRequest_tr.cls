/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-05-07      jh.jung           Created
*/
public with sharing class OppModifyRequest_tr extends TriggerHandler {

    private final List<OppModifyRequest__c> newList { get; set; }
    private final List<OppModifyRequest__c> oldList { get; set; }
    private final Map<Id, OppModifyRequest__c> newMap { get; set; }
    private final Map<Id, OppModifyRequest__c> oldMap { get; set; }
    
    private final List<OppModifyRequest__c> approveOppModifyRequests { get; set;}

    CustomNotificationType notificationType;
    ApprovalHierarchy__c approvalHierarchy;

    public OppModifyRequest_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap = (Map<Id, OppModifyRequest__c>) Trigger.newMap;
        oldMap = (Map<Id, OppModifyRequest__c>) Trigger.oldMap;

        notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Custom' LIMIT 1];
        approvalHierarchy = [SELECT Approver1__c FROM ApprovalHierarchy__c WHERE Stage__c = 'OppModifyRequest Approver'];

        if (Trigger.isUpdate && Trigger.isAfter) {
            approveOppModifyRequests = getApproveOpptyRequestList();
        }
    }


    protected override void afterInsert() {
        notiByManager();

    }

    protected override void afterUpdate() {
        notiBySales();
    }

    /**
     * @return 승인됨 필드가 False -> True로 바뀐 레코드
     */
    private List<OppModifyRequest__c> getApproveOpptyRequestList() {

        List<OppModifyRequest__c> ApproveOpptyRequestList = new List<OppModifyRequest__c>();

        for(OppModifyRequest__c newObj : newList) {
            OppModifyRequest__c oldObj = oldMap.get(newObj.Id);
            if(!oldObj.Approved__c && newObj.Approved__c) {
                ApproveOpptyRequestList.add(newObj);
            }
        }
        return ApproveOpptyRequestList;
    }

    private void notiByManager() {

        Map<Id, OppModifyRequest__c> oppModifyRequestMap = new Map<Id, OppModifyRequest__c>(
            [SELECT Id, CreatedBy.Name, Opportunity__r.Name FROM OppModifyRequest__c WHERE Id IN :newMap.keySet()]
        );

        for(OppModifyRequest__c oppModifyRequest : newList) {
            String bodyText = '';
            bodyText += '신청한 SA: ' + oppModifyRequestMap.get(oppModifyRequest.Id).CreatedBy.Name;
            bodyText += ' / 기회명: ' + oppModifyRequestMap.get(oppModifyRequest.Id).Opportunity__r.Name;
            bodyText += ' / 해당 요청사항으로 이동합니다.';
            CommonUtilController.NotificationWrap notiWrap = new CommonUtilController.NotificationWrap(
                '기회정보 변경요청',
                bodyText,
                String.valueOf(notificationType.Id),
                UserInfo.getUserId(),
                String.valueOf(oppModifyRequest.Id),
                new Set<String> {approvalHierarchy.Approver1__c}
            );
            CommonUtilController.sendNotification(notiWrap);
        }
    }

    private void notiBySales() {

        for(OppModifyRequest__c oppModifyRequest : approveOppModifyRequests) {
            CommonUtilController.NotificationWrap notiWrap = new CommonUtilController.NotificationWrap(
                '기회정보 변경완료',
                '요청하신 수정건이 변경되었습니다. 해당 기회로 이동합니다.',
                String.valueOf(notificationType.Id),
                UserInfo.getUserId(),
                String.valueOf(oppModifyRequest.Opportunity__c),
                new Set<String> {oppModifyRequest.CreatedById}
            );
            CommonUtilController.sendNotification(notiWrap);
        }
    }
}