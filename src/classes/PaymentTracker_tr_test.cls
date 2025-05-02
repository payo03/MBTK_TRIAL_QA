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
        TestObjectBuilder2.createIfBundle();
        TestObjectBuilder2.createConsentBundle();
        TestObjectBuilder2.createStockBundle();
        TestObjectBuilder2.createAccountBundle();
        TestObjectBuilder2.createPaymentBundle();
    }

    @IsTest
    static void testBehavior() {

        Test.startTest();
        Opportunity opportunityObj = [SELECT Id FROM Opportunity LIMIT 1];
        Account accountObj = [SELECT Id FROM Account LIMIT 1];
        PaymentTracker__c oldPaymentTracker = [SELECT Id FROM PaymentTracker__c LIMIT 1];
        oldPaymentTracker.IsValid__c = false;
        update oldPaymentTracker;

        PaymentTracker__c newPaymentTracker = new PaymentTracker__c();
        newPaymentTracker.Opportunity__c = opportunityObj.Id;
        newPaymentTracker.Account__c = accountObj.Id;
        newPaymentTracker.Status__c = 'NEW';
        newPaymentTracker.TotalAmount__c = 100000000;
        newPaymentTracker.IsValid__c = true;
        newPaymentTracker.PaymentTypeCreation__c = false;
        insert newPaymentTracker;

        Map<String, Decimal> amountMap = new Map<String, Decimal>{
            '인도금' => 100,
            '인도금 유예' => 100,
            '부가세 후취(출고전)' => 100,
            '대출금' => 100,
            '대출금 할인금액' => 100,
            'MFS 캠페인 할인금액' => 100,
            '초과금' => 100
        };
        Map<String, String> typeMap = CommonUtilController.getPickListMap('PaymentType__c', 'Type__c');

        List<PaymentType__c> paymentTypeList = new List<PaymentType__c>();
        PaymentType__c depositType = new PaymentType__c(
            PaymentTracker__c = newPaymentTracker.Id,
            Type__c = '1_DEPOSIT',
            RequestAmount__c = 1000
        );
        for(String key : amountMap.keySet()) {
            PaymentType__c type = new PaymentType__c();

            type.PaymentTracker__c = newPaymentTracker.Id;
            type.Type__c = typeMap.get(key);
            type.RequestAmount__c = amountMap.get(key);
            type.DepositAmount__c = 0;
            type.DiscountAmount__c = 10;

            paymentTypeList.add(type);
        }
        paymentTypeList.add(depositType);
        insert paymentTypeList;

        newPaymentTracker.PaymentTypeCreation__c = true;
        update newPaymentTracker;

        Test.stopTest();
    }
}