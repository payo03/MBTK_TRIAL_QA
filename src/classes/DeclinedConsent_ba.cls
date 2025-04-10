/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-21
 * @description : 개인정보 고객 동의 Declined 로직
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-21        San.Kang           Created
**************************************************************/
public without sharing class DeclinedConsent_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    public Date expiredLightConsent = Date.today().addDays(-84); // Light Consent 만료일
    public Date expiredFullConsent = Date.today().addYears(-2); // Full Consent 만료일

    public void execute(SchedulableContext context) {
        Database.executeBatch(new DeclinedConsent_ba(), 100);
    }

    // 배치 작업의 시작 부분 (SOQL 쿼리 설정)
    public Database.QueryLocator start(Database.BatchableContext context) {
        String expiredLightConsentStr = String.valueOf(expiredLightConsent);
        String expiredFullConsentStr = String.valueOf(expiredFullConsent);
        String obj_fields = getField(Schema.SObjectType.CustomerConsent__c.fields.getMap());
        String selectFields = obj_fields;
        String whereConditions =
                        ' (ConsentStatus__c = \'작성완료됨\' AND Opportunity__c = null AND ConsentDate__c = ' +  expiredLightConsentStr + ') ' +
                        'OR (ConsentStatus__c = \'작성완료됨\' AND Opportunity__c != null AND ConsentDate__c = ' +  expiredFullConsentStr + ')';

        String query = CommonUtilController.buildQuery(selectFields, 'CustomerConsent__c', whereConditions);
        System.debug('Light'+expiredLightConsentStr);
        System.debug('Full'+expiredFullConsentStr);
        return Database.getQueryLocator(query);
    }

    // 배치 실행 시 처리될 로직
    public void execute(Database.BatchableContext context, List<CustomerConsent__c> customerConsents) {
        try {
            LandingPageController.declinedConsent(customerConsents);
        } catch (Exception e) {
            System.debug('Error => ' + e.getStackTraceString() + ' msg ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('##### Batch Job Finished!! #####');
    }

    public static String getField(Map<String, Schema.SObjectField> ObjMap){
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