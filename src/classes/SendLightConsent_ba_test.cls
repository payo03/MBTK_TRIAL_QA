/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-28
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-28        San.Kang           Created
**************************************************************/
@IsTest
public with sharing class SendLightConsent_ba_test {

    @TestSetup
    static void setup() {
        TestObjectBuilder.createObjects();
    }

    @IsTest
    static void testBehavior() {
        CustomerConsent__c customerConsent = [SELECT Id FROM CustomerConsent__c LIMIT 1];
        SendLightConsent_ba batch = new SendLightConsent_ba(customerConsent.Id);

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
    }
}