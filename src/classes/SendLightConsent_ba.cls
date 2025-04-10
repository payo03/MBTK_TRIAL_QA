/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-20
 * @description : Light Consent 전송
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-20        San.Kang           Created
**************************************************************/
public without sharing class SendLightConsent_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    public String customerConsentId;

    // 생성자에서 customerConsentId를 받음
    public SendLightConsent_ba(String customerConsentId) {
        if(customerConsentId != null) this.customerConsentId = customerConsentId;
    }

    public void execute(SchedulableContext SC) {
        System.debug(' CustomerConsentId: ' + this.customerConsentId);
        Database.executeBatch(new SendLightConsent_ba(this.customerConsentId));
        return;
    }

    // 배치 작업의 시작 부분 (SOQL 쿼리 설정)
    public Database.QueryLocator start(Database.BatchableContext context) {
        String obj_fields = getField(Schema.SObjectType.CustomerConsent__c.fields.getMap());
        String selectFields = obj_fields + ', Lead__r.ConvertedOpportunityId ';
        String whereConditions = 'Id = \'' + customerConsentId + '\'';
        String query = CommonUtilController.buildQuery(selectFields, 'CustomerConsent__c', whereConditions);
        return Database.getQueryLocator(query);
    }

    // 배치 실행 시 처리될 로직
    public void execute(Database.BatchableContext context, List<CustomerConsent__c> customerConsents) {
        try {
            System.debug('execute');

            CustomerConsent__c customerConsent = customerConsents[0];

            List<Map<Object, Object>> infoMapList = new List<Map<Object, Object>>{
                    new Map<Object, Object>{
                            'objectName' =>  'Lead',
                            'recordId' => customerConsent.Lead__c
                    }
            };
            Map<Object, Map<Object, Object>> buttonMap = new Map<Object, Map<Object, Object>>();

            Map<Object, Object> consentMap = new Map<Object, Object>();
            consentMap.put('VFHost', Label.LandingPage.replace('https://', ''));
            consentMap.put('Id', customerConsent.Id);

            buttonMap.put('Consent', consentMap);

            Map<String, Object> InfoMap = new Map<String, Object> {
                    'templateTitle' => 'Light Consent 알림톡1',
                    'object' => 'CustomerConsent__c',
                    'whereField' => 'Lead__c',
                    'recordId' =>  customerConsent.Lead__c,
                    'externalId' => customerConsent.Id,
                    'buttonMap' => buttonMap,
                    'infoMapList' => infoMapList
            };
            System.debug('customerConsent'+customerConsent);
            if(!test.isRunningTest()) {
                InterfaceKakao.doCallOutKakaoAlimTalk(InfoMap);
            }
//            CustomerConsent__c customerConsent = customerConsents[0];
//
//            List<Map<Object, Object>> infoMapList = new List<Map<Object, Object>>{
//                    new Map<Object, Object>{
//                            'objectName' =>  'Lead',
//                            'recordId' => customerConsent.Lead__c
//                    }
//            };
//            Map<Object, Map<Object, Object>> buttonMap = new Map<Object, Map<Object, Object>>();
//
//            Map<Object, Object> consentMap = new Map<Object, Object>();
//            consentMap.put('Id', customerConsent.Id);
//
//            buttonMap.put('Consent', consentMap);
//
//            Map<String, Object> InfoMap = new Map<String, Object> {
//                    'templateTitle' => customerConsent.Opportunity__c != null ? 'Full Consent 알림톡' :  'Light Consent 알림톡',
//                    'object' => 'CustomerConsent__c',
//                    'whereField' => customerConsent.Opportunity__c != null ? 'Opportunity__c ' : 'Lead__c',
//                    'recordId' => customerConsent.Opportunity__c != null ? customerConsent.Opportunity__c :  customerConsent.Lead__c,
//                    'externalId' => customerConsent.Id,
//                    'buttonMap' => buttonMap,
//                    'infoMapList' => infoMapList
//            };
//
//            if(!test.isRunningTest()) {
//                InterfaceKakao.doCallOutKakaoAlimTalk(InfoMap);
//            }

        } catch (Exception e) {
            System.debug('Error => ' + e.getStackTraceString() + ' msg ' + e.getMessage());
        }
    }

    // 배치가 끝난 후 실행될 로직
    public void finish(Database.BatchableContext BC) {
        System.debug('##### Batch Job Finished!! #####');
    }

    // 객체 필드 조회하는 메서드
    public static String getField(Map<String, Schema.SObjectField> ObjMap) {
        List<String> accessibleFields = new List<String>();
        for (String fieldName : ObjMap.keySet()) {
            Schema.DescribeFieldResult fieldDesc = ObjMap.get(fieldName).getDescribe();
            if (fieldDesc.isAccessible()) {
                accessibleFields.add(fieldName);
            }
        }
        return String.join(accessibleFields, ', ');
    }
}