/*************************************************************
 * @author : th.kim
 * @date : 2025-01-06
 * @description : 견적 트리거 핸들러
 * @target : Quote
==============================================================
 * Ver          Date            Author                  Modification
 * 1.0          2025-01-06      th.kim                  Created
 * 1.1          2025-04-23      payo03@solomontech.net  대출승인여부 Update Validation
**************************************************************/
public with sharing class Quote_tr extends TriggerHandler {

    private final static Map<Id, Profile> PROFILE_MAP = new Map<Id, Profile>([
            SELECT Id
            FROM Profile
            WHERE Name IN ('System Administrator', '시스템 관리자', 'Salesforce Custom API')
    ]);

    private final List<Quote> newList { get; set; }
    private final List<Quote> oldList { get; set; }
    private final Map<Id, Quote> newMap { get; set; }
    private final Map<Id, Quote> oldMap { get; set; }
    private final User curUser { get; set; }

    public Quote_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap = (Map<Id, Quote>) Trigger.newMap;
        oldMap = (Map<Id, Quote>) Trigger.oldMap;
        curUser = [
                SELECT Id, ProfileId
                FROM User
                WHERE Id = :UserInfo.getUserId()
        ];
    }

    public override void beforeInsert() {
        setName();
    }

    public override void beforeUpdate() {
        doSetDefaultValues();   // ver1.1 대출승인여부 Update Validation
    }

    public override void afterUpdate() {
        sendNoti();
//        updatedOpportunityName();
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
     *              변경 : {고객 이름}-{견적 Q 버전}-{견적 V 버전}
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

        List<Opportunity> opptyList = [
            SELECT Id, Account.Name
            FROM Opportunity
            WHERE Id IN :oppIdSet
        ];

        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity>();
        for (Opportunity oppty : opptyList) {
            opptyMap.put(oppty.Id, oppty);
        }

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

            String accountName = opptyMap.get(newQuote.OpportunityId).Account.Name;
            String oppId = newQuote.OpportunityId.toString();
//            String lastSixDigits = oppId.substring(oppId.length() - 6);
            String configurationNo = 'Q' + newQuote.ConfigurationNo__c;
            String versionNo = 'V' + newQuote.VersionNo__c;

            newQuote.Name = String.join(new List<String>{
                accountName,
//                userMap.get(newQuote.OwnerId).Name,
//                lastSixDigits,
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
//    private void updatedOpportunityName() {
//        System.debug('Opportunity Start');
//        Set<Id> quoteIdSet = new Set<Id>();
//        for(Id quoteId : newMap.keySet()){
//            if(oldMap.get(quoteId).Status == 'SentOut' && newMap.get(quoteId).Status == 'Published'){
//                quoteIdSet.add(quoteId);
//            }
//        }
//        if(!quoteIdSet.isEmpty()){
//            List<Opportunity> opportunityList = new List<Opportunity>();
//            List<Quote> quoteList = [SELECT Account.Name, OpportunityId, Opportunity.Owner.Agency__c, Product__r.Name FROM Quote WHERE Id IN: quoteIdSet];
//            for(Quote quote : quoteList){
//                Opportunity opportunity = new Opportunity(
//                        Id = quote.OpportunityId,
//                        Name = quote.Opportunity.Owner.Agency__c + '-' + quote.Account.Name + '-' + quote.Product__r.Name
//                );
//                opportunityList.add(opportunity);
//            }
//            System.debug('opportunityList'+opportunityList);
//            if(!opportunityList.isEmpty()) update opportunityList;
//        }
//    }

    // ver1.1 대출승인여부 Update Validation
    private void doSetDefaultValues() {
        Map<Id, Quote> financeMap = new Map<Id, Quote>([
                SELECT Id, Finance__r.FScompany__c
                FROM Quote
                WHERE Id IN :newMap.keySet()
        ]);

        for(Quote newQuote : newList) {
            Quote oldQuote = oldMap.get(newQuote.Id);
            Finance__c finance = financeMap.get(newQuote.Id).Finance__r;
            /*
                대출승인여부 승인 Update조건
                1. 대출승인여부 Update했을때
                2. 대출사 MFS일경우
                3. Update진행자 Validation (Admin, IF계정)
            */
            if (
                finance != null &&
                newQuote.IsApproveLoan__c != oldQuote.IsApproveLoan__c &&
                'MFS'.equals(finance.FScompany__c) &&
                !PROFILE_MAP.keySet().contains(curUser.ProfileId)
            ) {
//                newQuote.addError('(MFS) 대출승인여부는 임의변경이 불가능합니다');  // 05-16. 전도형 책임 요청. MFS 대출 Validation임시 해제
            }
        }
    }
}