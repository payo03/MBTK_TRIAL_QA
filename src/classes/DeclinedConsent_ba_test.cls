/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-27
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-27        San.Kang           Created
**************************************************************/
@IsTest
private class DeclinedConsent_ba_test {
    static final List<CustomerConsent__c> customerConsents = TestObjectBuilder.createCustomerConsent();

    static {
        insert customerConsents;
    }


    @IsTest
    static void testBehavior() {
        DeclinedConsent_ba declinedConsentBa = new DeclinedConsent_ba();
        Test.startTest();

        Database.QueryLocator queryLocator = declinedConsentBa.start(null);
        declinedConsentBa.execute(null, customerConsents);
        declinedConsentBa.finish(null);

        Test.stopTest();
    }
}