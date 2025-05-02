/**
* @Author            : payo03@solomontech.net
* @Description 		 :
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-26      payo03@solomontech.net           Created
*/
@IsTest
private class PaymentType_tr_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createPaymentBundle();
    }

    @IsTest
    static void testBehavior() {
        Test.startTest();

        PaymentTracker__c tracker = [SELECT Id FROM PaymentTracker__c LIMIT 1];
        List<PaymentType__c> typeList = [
                SELECT Id, RefundCompletedDate__c
                FROM PaymentType__c
                ORDER BY Type__c
        ];

        for(PaymentType__c type : typeList) {
            type.RefundCompletedDate__c = Date.today();
        }
        update typeList;


        // 1. 기본 Insert
        Map<String, String> typeMap = CommonUtilController.getPickListMap('PaymentType__c', 'Type__c');
        PaymentTracker__c tempTracker = new PaymentTracker__c();
        insert tempTracker;

        Map<String, Decimal> amountMap = new Map<String, Decimal>{
                '계약금' => 100,
                '인도금' => 100,
                '부가세 후취(출고전)' => 100,
                '대출금' => 100,
                '대출금 할인금액' => 100,
                'MFS 캠페인 할인금액' => 100,
                '초과금' => 100
        };

        List<PaymentType__c> paymentTypeList = new List<PaymentType__c>();
        for(String key : amountMap.keySet()) {
            PaymentType__c type = new PaymentType__c();

            type.PaymentTracker__c = tempTracker.Id;
            type.Type__c = typeMap.get(key);
            type.RequestAmount__c = amountMap.get(key);
            type.DepositAmount__c = 0;
            type.DiscountAmount__c = 10;

            paymentTypeList.add(type);
        }
        insert paymentTypeList;

        for(PaymentType__c type : [
                SELECT Id, Type__c, UpdateStage__c
                FROM PaymentType__c
                WHERE PaymentTracker__c = :tempTracker.Id
                ORDER BY Type__c
        ]) {
            System.debug(type.Type__c + '-' + type.UpdateStage__c);
        }

        // 2. 인도금 유예 Insert
        PaymentType__c newType = new PaymentType__c();
        newType.PaymentTracker__c = tempTracker.Id;
        newType.Type__c = typeMap.get('인도금 유예');
        newType.RequestAmount__c = 100;
        newType.DepositAmount__c = 0;
        newType.DiscountAmount__c = 10;
        insert newType;

        for(PaymentType__c type : [
                SELECT Id, Type__c, UpdateStage__c
                FROM PaymentType__c
                WHERE PaymentTracker__c = :tempTracker.Id
                ORDER BY Type__c
        ]) {
            System.debug(type.Type__c + '-' + type.UpdateStage__c);
        }

        Test.stopTest();
    }
}