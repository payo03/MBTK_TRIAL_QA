/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-05-12      jh.jung           Created
*/
public without sharing class PrevSalesConditionCancel {

    @AuraEnabled
    public static Map<String, Object> init() {

        List<Quote> publishQuoteList = new List<Quote>();
        List<Quote> otherQuoteList = new List<Quote>();
        Set<Id> opptyIdSet = new Set<Id>();
        Set<Id> quoteIdSet = new Set<Id>();
        Set<Id> contractIdSet = new Set<Id>();

        List<Quote> quoteList = [
            SELECT Id, Status, Opportunity.TaxInvoiceDate__c, OpportunityId, AccountId, Opportunity.ContractId
            FROM Quote
            WHERE Opportunity.TaxInvoiceDate__c = null
            AND Opportunity.StageName != 'Closed Won'
            AND Status != 'Canceled'
            ORDER BY CreatedDate ASC
        ];

        for(Quote quoteObj : quoteList) {
            if(quoteObj.OpportunityId != null)              opptyIdSet.add(quoteObj.OpportunityId);
            if(quoteObj.Id != null)                         quoteIdSet.add(quoteObj.Id);
            if(quoteObj.Opportunity?.ContractId != null)    contractIdSet.add(quoteObj.Opportunity.ContractId);

            if(quoteObj.Status == 'Published') {
                publishQuoteList.add(quoteObj);
            } else {
                otherQuoteList.add(quoteObj);
            }

        }

        return new Map<String, Object> {
            'opptyNum' => opptyIdSet.size()
            , 'quoteNum' => quoteIdSet.size()
            , 'contractNum' => contractIdSet.size()
        };
    }

    @AuraEnabled
    public static void process() {

        Set<String> userIdSet = new Set<String>();
        for (Id userId : new Map<Id, User>(
            [SELECT Id FROM User WHERE Profile.Name = 'MTBK Agent' AND IsActive = true]
        ).keySet()) {
            userIdSet.add(String.valueOf(userId));
        }

        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Custom' LIMIT 1];

        CommonUtilController.NotificationWrap notiWrap = new CommonUtilController.NotificationWrap(
            '진행중인 견적/계약 자동 취소',
            '신규 판매조건이 업데이트되어 기존 견적/계약이 모두 자동 취소처리됐습니다. (세금계산서 발행완료 계약은 제외)',
            String.valueOf(notificationType.Id),
            UserInfo.getUserId(),
            '000000000000000',  // 아무 곳도 안가도록 더미 값 (필수값이라 ''은 안됨)
            userIdSet
        );
        CommonUtilController.sendNotification(notiWrap);

        try {
            Database.executeBatch(new PrevSalesConditionCancel_ba(), 50);
        } catch (Exception e) {
            System.debug('msg >> '+e.getMessage() + '\n getStackTraceString >>' + e.getStackTraceString());
            throw new AuraHandledException('취소 중 오류가 발생했습니다. :: ' + e.getStackTraceString());
        }
    }
}