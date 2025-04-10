/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-04-01      payo03@solomontech.net           Created
*/
@IsTest
private class TestObjectBuilder2_test {

    @IsTest
    static void createLeadBundle() {
        Test.startTest();

        TestObjectBuilder2.createLeadBundle();

        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        System.debug(lead);

        Test.stopTest();
    }

    @IsTest
    static void createOrderBundle() {
        Test.startTest();

        TestObjectBuilder2.createOrderBundle();

        AvisOrderInfo__c info = [SELECT Id FROM AvisOrderInfo__c LIMIT 1];
        System.debug(info);

        Test.stopTest();
    }

    @IsTest
    static void createConfigBundle() {
        Test.startTest();

        TestObjectBuilder2.createConfigBundle();

        Test.stopTest();
    }

    @IsTest
    static void createIfBundle() {
        Test.startTest();

        TestObjectBuilder2.createIfBundle();

        Test.stopTest();
    }

    @IsTest
    static void createStockBundle() {
        Test.startTest();

        TestObjectBuilder2.createStockBundle();

        Test.stopTest();
    }

    @IsTest
    static void createVirtualAccountBundle() {
        Test.startTest();

        TestObjectBuilder2.createVirtualAccountBundle();

        Test.stopTest();
    }

    @IsTest
    static void createQuoteBundle() {
        Test.startTest();

        TestObjectBuilder2.createQuoteBundle();

        Test.stopTest();
    }

    @IsTest
    static void createContractBundle() {
        Test.startTest();

        TestObjectBuilder2.createContractBundle();

        Test.stopTest();
    }

    @IsTest
    static void createCampaignBundle() {
        Test.startTest();

        TestObjectBuilder2.createCampaignBundle();

        Test.stopTest();
    }

    @IsTest
    static void createPaymentBundle() {
        Test.startTest();

        TestObjectBuilder2.createPaymentBundle();

        Test.stopTest();
    }

    @IsTest
    static void createHandoverBundle() {
        Test.startTest();

        TestObjectBuilder2.createHandoverBundle();

        Test.stopTest();
    }

    @IsTest
    static void createGoodWillBundle() {
        Test.startTest();

        TestObjectBuilder2.createGoodWillBundle();

        Test.stopTest();
    }

    @IsTest
    static void createCommissionBundle() {
        Test.startTest();

        TestObjectBuilder2.createCommissionBundle();

        Test.stopTest();
    }

    @IsTest
    static void createConsentBundle() {
        Test.startTest();

        TestObjectBuilder2.createConsentBundle();

        Test.stopTest();
    }

    @IsTest
    static void createObjects() {
        Test.startTest();

        TestObjectBuilder2.createObjects();

        Test.stopTest();
    }
}