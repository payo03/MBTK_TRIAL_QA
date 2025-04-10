@IsTest
public with sharing class PaymentTrackerController_test {
    static final PaymentTracker__c paymentTracker;
    static final PaymentType__c paymentTypeDeposit;

    static {
        TestObjectBuilder.createObjects();
        paymentTracker = TestObjectBuilder.paymentTracker;
        // paymentType = TestObjectBuilder.paymentTypeDeposit;

    }

    @IsTest
    static void testGetInit() {

        Test.startTest();

        PaymentTrackerController.getInitData();

        Test.stopTest();
    }

    @IsTest
    static void testGetFilteredPaymentTrackerList() {

        Test.startTest();

        Map<String, String> filterMap = new Map<String, String>{
            'Status__c' => 'DEPOSIT'
        };

        PaymentTrackerController.getFilteredPaymentTrackerList(filterMap);
        

        Test.stopTest();
    }

    @IsTest
    static void testGetPaymentType() {

        Test.startTest();
        
        PaymentTrackerController.getPaymentType(paymentTracker.Id);
        
        Test.stopTest();
    }




}