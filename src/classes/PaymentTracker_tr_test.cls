/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-03-28
 * @description : PaymentTracker_tr의 test class
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-28      chaebeom.do     Created
**************************************************************/
@isTest
private class PaymentTracker_tr_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder.createObjects();
    }

    @IsTest
    static void testBehavior() {
        Test.startTest();
        Opportunity opportunityObj = [SELECT Id FROM Opportunity LIMIT 1];
        Account accountObj = [SELECT Id FROM Account LIMIT 1];
        PaymentTracker__c oldPaymentTracker = [SELECT Id FROM PaymentTracker__c LIMIT 1];
        oldPaymentTracker.IsValid__c = false;
        update oldPaymentTracker;

        PaymentLog__c testPaymentLog = new PaymentLog__c();
        testPaymentLog.Amount__c = 1000000;
        testPaymentLog.PaymentTracker__c = oldPaymentTracker.Id;
        testPaymentLog.InternalDocumentId__c = '900001';
        insert testPaymentLog;

        PaymentTracker__c newPaymentTracker = new PaymentTracker__c();
        newPaymentTracker.Opportunity__c = opportunityObj.Id;
        newPaymentTracker.Account__c = accountObj.Id;
        newPaymentTracker.Status__c = 'NEW';
        newPaymentTracker.TotalAmount__c = 100000000;
        newPaymentTracker.IsValid__c = true;
        insert newPaymentTracker;

        newPaymentTracker.Status__c = 'COMPLETE';
        update newPaymentTracker;

        Test.stopTest();
    }
}