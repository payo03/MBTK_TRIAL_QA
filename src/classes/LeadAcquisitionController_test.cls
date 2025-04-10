/**
* @Author            : chaebeom.do@solomontech.net
* @Description 		 : LeadAcquisitionController의 테스트 클래스
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-13      chaebeom.do@solomontech.net           Created
*/

@isTest
public class LeadAcquisitionController_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder.createObjects();
    }

    @isTest
    static void testGetInitData() {
        Test.startTest();
        LeadAcquisitionController.getInitData();
        Test.stopTest();
    }

    @isTest
    static void testGetFilteredProduct() {
        Map<String, String> filterMap = new Map<String, String>{
            'Segment2__c' => 'LDC',
            'Name' => 'new'
        };

        Test.startTest();
        LeadAcquisitionController.getFilteredProduct(filterMap);
        Test.stopTest();
    }

    @isTest
    static void testGetLead() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        LeadAcquisitionController.getLead(testLead.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetProduct() {
        Test.startTest();
        LeadAcquisitionController.getProduct('');
        Test.stopTest();
    }

    @isTest
    static void testDoCheckBizNum() {
        Test.startTest();
        LeadAcquisitionController.doCheckBizNum('8788703231');
        Test.stopTest();
    }

    @isTest
    static void testGetFinancialList() {
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        Test.startTest();
        LeadAcquisitionController.getFinancialList(testProduct.Id);
        Test.stopTest();
    }

    // //완전신규리드 테스트
    // @isTest
    // static void testCreatePreQuote1() {
    //     Lead testLead = [SELECT Id FROM Lead LIMIT 1];
    //     Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
    //     Map<String, String> quoteData = new Map<String, String>{
    //         'leadId' => testLead.Id,
    //         'productId' => testProduct.Id,
    //         'realSellPrice' => '97000000',
    //         'discountPrice' => '3000000',
    //         'firstAmt' => '2000000',
    //         'interestRate' => '5',
    //         'duration' => '12'
    //     };

    //     Test.startTest();
    //     LeadAcquisitionController.createPreQuote(quoteData);
    //     Test.stopTest();
    // }

    // //본인소유 중복리드
    // @isTest
    // static void testCreatePreQuote2() {
    //     Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
    //     Lead dupLead = new Lead();
    //     dupLead.LastName = '테스트 개인 계정';
    //     dupLead.MobilePhone = '090-9999-1919';
    //     dupLead.BusinessNumber__c = '878-87-03231';
    //     dupLead.RoadAddress__c = '서울 금천구 디지털로 178';
    //     dupLead.DetailAddress__c = '가산퍼블릭 719';
    //     dupLead.Description = 'Test Description';
    //     dupLead.ProductId__c = testProduct.Id;
    //     insert dupLead;

    //     Map<String, String> quoteData = new Map<String, String>{
    //         'leadId' => dupLead.Id,
    //         'productId' => testProduct.Id,
    //         'realSellPrice' => '97000000',
    //         'discountPrice' => '3000000',
    //         'firstAmt' => '2000000',
    //         'interestRate' => '5',
    //         'duration' => '12'
    //     };

    //     Test.startTest();
    //     LeadAcquisitionController.createPreQuote(quoteData);
    //     Test.stopTest();
    // }

    @isTest
    static void testGetCampaign() {
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        Test.startTest();
        LeadAcquisitionController.getCampaign(testProduct.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetCampaignDup() {
        CampaignMaster__c testCamp = [SELECT Id FROM CampaignMaster__c LIMIT 1];

        Test.startTest();
        LeadAcquisitionController.getCampaignPreventDuplicate(testCamp.Id);
        Test.stopTest();
    }

    @isTest
    static void testDoCheckDuplicate1() {
        Map<String, String> inputMap = new Map<String, String>{
            'name' => '김길동',
            'phone' => '010-1234-4321'
        };

        Test.startTest();
        LeadAcquisitionController.doCheckDuplicate(inputMap);
        Test.stopTest();
    }

    @isTest
    static void testDoCheckDuplicate2() {
        Map<String, String> inputMap = new Map<String, String>{
            'name' => '테스트 개인 계정',
            'phone' => '090-9999-1919'
        };

        Test.startTest();
        LeadAcquisitionController.doCheckDuplicate(inputMap);
        Test.stopTest();
    }
}