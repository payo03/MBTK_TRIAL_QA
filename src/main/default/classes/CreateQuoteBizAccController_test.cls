/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-05-16      jh.jung           Created
*/

@IsTest
private class CreateQuoteBizAccController_test {

    static Account accountPerson;
    static CampaignMaster__c campaignMaster;
    static Finance__c finance;
    static Product2 product;
    static LeadManagementController.CampaignWrap campaignWrap;
    static Map<String, Object> inputAccountMap;

    static {
        TestObjectBuilder2.createAccountBundle();
        TestObjectBuilder2.createLeadBundle();
        TestObjectBuilder2.createCampaignBundle();
        TestObjectBuilder2.createPricebook();
        TestObjectBuilder2.createPricebookEntry();

        accountPerson = TestObjectBuilder2.createAccountPerson();
        campaignMaster = TestObjectBuilder2.createPercentCampaign();
        finance = TestObjectBuilder2.createFinance();
        product = TestObjectBuilder2.createProduct();

        inputAccountMap = new Map<String, Object> {
            'accountId' => accountPerson.Id
            , 'productId' => product.Id
            , 'campaignIdList' => JSON.serialize(new List<String> { campaignMaster.Id })
            , 'firstAmt' => 0
            , 'interestRate' => 0
            , 'duration' => 0
            , 'totalLoan' => 0
            , 'advancePayment' => 0
        };
    }

    @IsTest
    static void testBehavior() {
        CreateQuoteBizAccController.createQuoteByBizAcc(inputAccountMap);
    }
}