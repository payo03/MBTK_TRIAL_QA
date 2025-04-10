/*************************************************************
 * @author : th.kim
 * @date : 2025-01-06
 * @description : 견적 트리거 핸들러
 * @target : Quote
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-06      th.kim          Created
**************************************************************/
public with sharing class Quote_tr extends TriggerHandler {

    private final List<Quote> newList { get; set; }
    private final List<Quote> oldList { get; set; }
    private final Map<Id, Quote> newMap { get; set; }
    private final Map<Id, Quote> oldMap { get; set; }

    public Quote_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap = (Map<Id, Quote>) Trigger.newMap;
        oldMap = (Map<Id, Quote>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        setName();
    }

    public override void afterUpdate() {
        sendNoti();
        updatedOpportunityName();
    }

    /**
     * @author jh.jung
     * @description 승인시 노티 발송
     */
    private void sendNoti() {
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Custom' LIMIT 1];

        for(Quote quoteNew : newList) {
            if(Trigger.isUpdate) {
                Quote quoteOld = oldMap.get(quoteNew.Id);
                // 데이터 변경 없거나 승인된 경우가 아니라면 패스
                if (
                    quoteOld.AdditionalDiscountRateStatus__c == quoteNew.AdditionalDiscountRateStatus__c ||
                    !quoteNew.AdditionalDiscountRateStatus__c.equals('승인됨')
                ) {
                    continue;
                }
            }

            CommonUtilController.sendNotification(new CommonUtilController.NotificationWrap(
                    '추가 손실 승인됨',
                    quoteNew.AdditionalLossPrice__c + '의 추가 손실이 승인되었습니다. \n 클릭시 해당 견적으로 이동합니다.',
                    notificationType.Id,
                    UserInfo.getUserId(),
                    quoteNew.Id,
                    new Set<String> { quoteNew.OwnerId }
            ));
        }
    }

    /**
     * @author th.kim
     * @description Quote Naming Rule
     *              {SA 이름}-{기회 Id 마지막 6자리}-{견적 Q 버전}-{견적 V 버전}
     */
    private void setName() {

        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> ownerIdSet = new Set<Id>();
        for (Quote newQuote : newList) {
            oppIdSet.add(newQuote.OpportunityId);
            ownerIdSet.add(newQuote.OwnerId);
        }

        List<Quote> quoteList = [
            SELECT OpportunityId, Product__c, ConfigurationNo__c, VersionNo__c, (SELECT Product2Id FROM QuoteLineItems)
            FROM Quote
            WHERE OpportunityId IN :oppIdSet
            ORDER BY ConfigurationNo__c DESC NULLS LAST, VersionNo__c DESC NULLS LAST
        ];

        Map<Id, Quote> quoteMap = new Map<Id, Quote>();
        for (Quote quote : quoteList) {
            if (!quoteMap.containsKey(quote.OpportunityId)) {
                quoteMap.put(quote.OpportunityId, quote);
            }
        }

        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :ownerIdSet]);

        for (Quote newQuote : newList) {

            Quote lastQuote = quoteMap.get(newQuote.OpportunityId);
            if (lastQuote == null || String.isBlank(newQuote.Product__c)) {
                newQuote.ConfigurationNo__c = 1;
                newQuote.VersionNo__c = 1;
            } else if (newQuote.Product__c != lastQuote.Product__c) {
                newQuote.ConfigurationNo__c = lastQuote.ConfigurationNo__c + 1;
                newQuote.VersionNo__c = 1;
            } else {
                newQuote.ConfigurationNo__c = lastQuote.ConfigurationNo__c;
                newQuote.VersionNo__c = lastQuote.VersionNo__c + 1;
            }
            String oppId = newQuote.OpportunityId.toString();
            String lastSixDigits = oppId.substring(oppId.length() - 6);
            String configurationNo = 'Q' + newQuote.ConfigurationNo__c;
            String versionNo = 'V' + newQuote.VersionNo__c;
            newQuote.Name = String.join(new List<String>{
                userMap.get(newQuote.OwnerId).Name,
                lastSixDigits,
                configurationNo,
                versionNo
            }, '-');
        }
    }

    /**
     * @author san,kang
     * @description Opportunity Nameing rule
     *              {Owner Agency}-{Account Name}-{Product Name}
     */
    private void updatedOpportunityName() {
        System.debug('Opportunity Start');
        Set<Id> quoteIdSet = new Set<Id>();
        for(Id quoteId : newMap.keySet()){
            if(oldMap.get(quoteId).Status == 'SentOut' && newMap.get(quoteId).Status == 'Published'){
                quoteIdSet.add(quoteId);
            }
        }
        if(!quoteIdSet.isEmpty()){
            List<Opportunity> opportunityList = new List<Opportunity>();
            List<Quote> quoteList = [SELECT Account.Name, OpportunityId, Opportunity.Owner.Agency__c, Product__r.Name FROM Quote WHERE Id IN: quoteIdSet];
            for(Quote quote : quoteList){
                Opportunity opportunity = new Opportunity(
                        Id = quote.OpportunityId,
                        Name = quote.Opportunity.Owner.Agency__c + '-' + quote.Account.Name + '-' + quote.Product__r.Name
                );
                opportunityList.add(opportunity);
            }
            System.debug('opportunityList'+opportunityList);
            if(!opportunityList.isEmpty()) update opportunityList;
        }
    }
}