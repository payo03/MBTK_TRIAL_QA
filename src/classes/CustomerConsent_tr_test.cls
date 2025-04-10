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
private class CustomerConsent_tr_test {

    static final List<CustomerConsent__c> customerConsent = TestObjectBuilder.createCustomerConsent();

    static {
        insert customerConsent;
    }

    @IsTest
    static void testBehavior() {

        Test.startTest();
        customerConsent[0].ConsentStatus__c = '거절됨';
        update customerConsent;
        Test.stopTest();
    }

}