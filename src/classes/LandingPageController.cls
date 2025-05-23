/*************************************************************
 * @author : chaebeom.do
 * @date : 2024-12-30
 * @description : 1. 계정(변경 가능)에서 버튼 클릭시 고객에게 랜딩페이지 링크 전송
 *                2. 고객 동의 object 생성
 *                3. Consent 타입에 따라 알림톡 발송
 * @target : CustomerConsentLanding.page
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-12-30      chaebeom.do     Created
 * 1.1          2025-01-03      San.Kang        Updated
**************************************************************/
public without sharing class LandingPageController {
    @AuraEnabled public static String Id { get; set; }

    //ConsentType 픽리스트 가져오기
    @AuraEnabled
    public static Map<String, Object> getConsentType() {

        return new Map<String, Object>{
                'type' => CommonUtilController.getPickList('CustomerConsent__c', 'Type__c')
        };
    }

    @AuraEnabled
    public static void getCustomerConsent() {

        try {
            Id = ApexPages.currentPage().getParameters().get('Id');

        } catch (Exception e) {
            System.debug('err :: ' + e.getMessage() + ' || ' + e.getLineNumber());
        }
    }

    @RemoteAction
    public static String updateCustomerConsent(String ccId, List<Boolean> ccList) {

        try {

            CustomerConsent__c cc = [
                    SELECT Id, Account__c, Lead__r.MobilePhone, Lead__r.ConvertedAccountId, Lead__r.LastName, Opportunity__c, ConsentStatus__c, Type__c
                    FROM CustomerConsent__c
                    WHERE Id = :ccId
            ];
            String accountId = cc.Account__c;

            if(accountId == null){
                List<Account> accountList = [SELECT Id
                                    FROM Account
                                    WHERE PersonMobilePhone =: cc.Lead__r.MobilePhone AND LastName =: cc.Lead__r.LastName];
                accountId = !accountList.isEmpty() ? accountList[0].Id : accountId;
            }

            System.debug('accountId:::'+accountId);
            if (ccList.size() <= 4) {
                cc.ConsentRequire1__c = ccList[0];
                cc.ConsentRequire5__c = ccList[1];
                cc.ConsentOptional1__c = ccList[2];
                cc.ConsentOptional4__c = ccList[3];
                cc.Account__c = accountId;
                cc.ConsentStatus__c = !ccList[0] || !ccList[1] ? '거절됨' : '작성완료됨';
                cc.ConsentDate__c = System.today();
                update cc;
            } else {
                cc.ConsentRequire1__c = ccList[0];
                cc.ConsentRequire2__c = ccList[1];
                cc.ConsentRequire3__c = ccList[2];
                cc.ConsentRequire4__c = ccList[3];
                cc.ConsentRequire5__c = ccList[4];
                cc.ConsentOptional1__c = ccList[5];
                cc.ConsentOptional2__c = ccList[6];
                cc.ConsentOptional3__c = ccList[7];
                cc.ConsentStatus__c = !ccList[0] || !ccList[1] || !ccList[2] || !ccList[3] || !ccList[4] ? '거절됨' : '작성완료됨';
                cc.ConsentDate__c = System.today();
                update cc;

                if (ccList[0] && ccList[1] && ccList[2] && ccList[3] && ccList[4]) {
                    Opportunity opportunity = new Opportunity(
                            Id = cc.Opportunity__c,
                            IsLockConsent__c = false
                    );

                    update opportunity;
                }
            }
            return cc.Id;
        } catch (Exception e) {
            System.debug('err :: ' + e.getMessage() + ' || ' + e.getLineNumber());
            return null;
        }
    }

    @AuraEnabled
    public static void getSubCustomerConsent(Id recordId) {

        String objName = recordId.getSobjectType().getDescribe().getName();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType sobjectType = globalDescribe.get(objName);
        String obj_fields = getField(sobjectType.getDescribe().fields.getMap());

        String selectFields = obj_fields + ', ( SELECT Id FROM CustomerConsent__r ) ';
        String whereConditions = 'Id = \'' + recordId + '\'';
        String query = CommonUtilController.buildQuery(selectFields, objName, whereConditions);

        SObject result = Database.query(query);
        CustomerConsent__c customerConsent = new CustomerConsent__c();
        if (result != null) customerConsent = (CustomerConsent__c) result.getSObjects('CustomerConsent__r').get(0);

        if (objName == 'Lead') {
            customerConsent.Lead__c = (Id) result.get('Id');
            customerConsent.ConsentStatus__c = '링크 전송됨';
            customerConsent.SendAlimTalkDate__c = System.today();
            customerConsent.ConsentDate__c = null;
        } else {
            customerConsent.Opportunity__c = (Id) result.get('Id');
            customerConsent.ConsentStatus__c = '링크 전송됨';
            customerConsent.SendAlimTalkDate__c = System.today();
            customerConsent.ConsentDate__c = null;
        }
        if (customerConsent != null) upsert customerConsent;
        sendConsentKakaoAlimtalk(customerConsent.Id);
    }

    @Future(Callout=true)
    public static void sendConsentKakaoAlimtalk(Id customerConsentId) {

        try {
            String obj_fields = getField(Schema.SObjectType.CustomerConsent__c.fields.getMap());
            String selectFields = obj_fields;
            String whereConditions = 'Id = \'' + customerConsentId + '\'';
            String query = CommonUtilController.buildQuery(selectFields, 'CustomerConsent__c', whereConditions);
            CustomerConsent__c customerConsent = Database.query(query);

            List<Map<Object, Object>> infoMapList = new List<Map<Object, Object>>{
                    new Map<Object, Object>{
                            'objectName' => 'Lead',
                            'recordId' => customerConsent.Lead__c
                    }
            };
            Map<Object, Map<Object, Object>> buttonMap = new Map<Object, Map<Object, Object>>();

            Map<Object, Object> consentMap = new Map<Object, Object>();
            consentMap.put('VFHost', Label.LandingPage.replace('https://', ''));
            consentMap.put('Id', customerConsent.Id);

            buttonMap.put('동의서 열기', consentMap);

            Map<String, Object> InfoMap = new Map<String, Object>{
                    'templateTitle' => customerConsent.Opportunity__c != null ? 'Full Consent 알림톡2' : 'Light Consent 알림톡2',
                    'object' => 'CustomerConsent__c',
                    'whereField' => customerConsent.Opportunity__c != null ? 'Opportunity__c ' : 'Lead__c',
                    'recordId' => customerConsent.Opportunity__c != null ? customerConsent.Opportunity__c : customerConsent.Lead__c,
                    'externalId' => customerConsent.Id,
                    'buttonMap' => buttonMap,
                    'infoMapList' => infoMapList
            };
            if (!test.isRunningTest()) {
                InterfaceKakao.doCallOutKakaoAlimTalk(InfoMap);
            }
            if (customerConsent.Opportunity__c == null) SendLightConsent_sc.scheduleBatchWithParam(customerConsentId);
        } catch (Exception e) {
            System.debug('err ::: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    public static void declinedConsent(List<CustomerConsent__c> customerConsents) {
        try {
            Set<Id> leadIdsToUpdate = new Set<Id>();
            Set<Id> opportunityIdsToUpdate = new Set<Id>();
            Map<Id, CustomerConsent__c> oppConsentMap = new Map<Id, CustomerConsent__c>();
            Map<Id, CustomerConsent__c> leadConsentMap = new Map<Id, CustomerConsent__c>();
            // 1. 분기 로직 정리 및 DML 대상 수집
            Set<Id> opportunityIdSet = new Set<Id>();
            for (CustomerConsent__c customerConsent : customerConsents) {
                if (customerConsent.Opportunity__c != null) opportunityIdSet.add(customerConsent.Opportunity__c);
            }
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityIdSet]);

            for (CustomerConsent__c customerConsent : customerConsents) {
                if (customerConsent.ConsentStatus__c == '링크 전송됨' || customerConsent.ConsentStatus__c == '작성완료됨') {
                    customerConsent.ConsentStatus__c = '만료됨';
                }

                if (customerConsent.Opportunity__c != null && opportunityMap.get(customerConsent.Opportunity__c).StageName == 'Negotiation') {
                    opportunityIdsToUpdate.add(customerConsent.Opportunity__c);
                    oppConsentMap.put(customerConsent.Opportunity__c, customerConsent);
                } else if (customerConsent.Lead__c != null &&
                        (customerConsent.ConsentStatus__c == '만료됨' || customerConsent.ConsentStatus__c == '거절됨')) {
                    leadIdsToUpdate.add(customerConsent.Lead__c);
                    leadConsentMap.put(customerConsent.Lead__c, customerConsent);
                }
            }

            // 2. customerConsent 자체 업데이트
            update customerConsents;

            if (!leadIdsToUpdate.isEmpty()) {
                Map<Id, Lead> leadMap = new Map<Id, Lead>();
                Account account = new Account();
                Opportunity opportunity = new Opportunity();
                Contact contact = new Contact();
                for (SObject sObj : getSObjects(leadIdsToUpdate)) {
                    Lead lead = (Lead) sObj;
                    if (lead.ConvertedAccountId != null) account.Id = lead.ConvertedAccountId;
                    if (lead.ConvertedOpportunityId != null) opportunity.Id = lead.ConvertedOpportunityId;
                    leadMap.put(lead.Id, lead);
                }

                for (Lead lead : leadMap.values()) {
                    resetLeadFields(lead);
                }
                update leadMap.values();
                if (opportunity != null) delete opportunity;
                if (account != null) delete account;
            }

            if (!opportunityIdsToUpdate.isEmpty()) {
                Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
                [
                        SELECT Id, AccountId, ContactId, (SELECT Id, ContractId FROM Quotes)
                        FROM Opportunity
                        WHERE Id IN :opportunityIdsToUpdate
                ]
                );

                List<Opportunity> toUpdateOpportunities = new List<Opportunity>();
                List<SObject> recordsToDelete = new List<SObject>();
                for (Opportunity opportunity : oppMap.values()) {
                    CustomerConsent__c consent = oppConsentMap.get(opportunity.Id);

                    if (consent.ConsentStatus__c == '거절됨') {
                        if (opportunity.AccountId != null) {
                            Account acc = [SELECT Id, IsPersonAccount FROM Account WHERE Id = :opportunity.AccountId];
                            recordsToDelete.add(acc);

                            if (!acc.IsPersonAccount && opportunity.ContactId != null) {
                                recordsToDelete.add(new Contact(Id = opportunity.ContactId));
                            }
                        }
                        resetOpportunityFields(opportunity);
                        toUpdateOpportunities.add(opportunity);
                    } else if (consent.ConsentStatus__c == '만료됨') {
                        opportunity.IsLockConsent__c = true;
                        toUpdateOpportunities.add(opportunity);
                    }
                }
                if (!toUpdateOpportunities.isEmpty()) update toUpdateOpportunities;
                if (!recordsToDelete.isEmpty()) delete recordsToDelete;
            }

        } catch (Exception e) {
            System.debug('exception :: ' + e);
        }
    }

    public static List<SObject> getSObjects(Set<Id> recordIds) {

        if (recordIds == null || recordIds.isEmpty()) return new List<SObject>();

        Id firstId = recordIds.iterator().next();
        Schema.SObjectType sObjType = firstId.getSObjectType();
        String objectName = sObjType.getDescribe().getName();
        Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();
        String fieldNames = getField(fieldMap);
        if (objectName == 'Lead') fieldNames = ' Id, BusinessNumber__c, MobilePhone, ConvertedAccountId, ConvertedOpportunityId, ConvertedContactId ';
        String query = 'SELECT ' + fieldNames + ' FROM ' + objectName + ' WHERE Id IN :recordIds';

        return Database.query(query);
    }
    public static void resetOpportunityFields(Opportunity opp) {

        List<String> nullFields = new List<String>{
                'AccountId', 'ContractId'
        };

        for (String fieldName : nullFields) {
            opp.put(fieldName, null);
        }
    }

    public static void resetLeadFields(Lead lead) {

        List<String> fieldsToClear = new List<String>{
                'MobilePhone',
                'BusinessNumber__c',
                'ProductId__c',
                'ApprovalUser__c',
                'RoadAddress__c',
                'DetailAddress__c',
                'Latitude__c',
                'Longitude__c',
                'PostalCode__c'
        };
        for (String fieldName : fieldsToClear) {
            lead.put(fieldName, null);
        }

    }

    public static String getField(Map<String, Schema.SObjectField> ObjMap) {
        List<String> accessibleFields = new List<String>();

        for (String fieldName : ObjMap.keySet()) {
            Schema.DescribeFieldResult fieldDesc = ObjMap.get(fieldName).getDescribe();
            // 접근 가능한 필드만 추가
            if (fieldDesc.isAccessible()) {
                accessibleFields.add(fieldName);
            }
        }
        return String.join(accessibleFields, ', ');
    }
}