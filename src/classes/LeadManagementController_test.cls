/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2024-12-13      jh.jung           Created
*/
@IsTest
private class LeadManagementController_test {

    static Lead lead;
    static Lead dupLead;
    static Account accountPerson;
    static CampaignMaster__c campaignMaster;
    static Finance__c finance;
    static LeadManagementController.CampaignWrap campaignWrap;
    static Map<String, Object> inputLeadMap;
    static Map<String, Object> inputDupLeadMap;

    static {
//        TestObjectBuilder.createObjects();
//        TestObjectBuilder2.createQuoteBundle();
//        TestObjectBuilder2.createAccountBundle();

        TestObjectBuilder2.createAccountBundle();
        TestObjectBuilder2.createLeadBundle();
        TestObjectBuilder2.createCampaignBundle();
        TestObjectBuilder2.createPricebook();
        TestObjectBuilder2.createPricebookEntry();

        lead = TestObjectBuilder2.createLead();
        dupLead = TestObjectBuilder2.createDupLead();
        accountPerson = TestObjectBuilder2.createAccountPerson();
        campaignMaster = TestObjectBuilder2.createPercentCampaign();
        finance = TestObjectBuilder2.createFinance();

        System.debug('lead ::: ' + lead);

//        insert lead;
//        insert dupLead;
//        insert accountPerson;
//        insert campaignMaster;
//        insert finance;
//        update TestObjectBuilder.createPricebook();
//        insert TestObjectBuilder.createPricebookEntry();

        campaignWrap = new LeadManagementController.CampaignWrap();
        campaignWrap.id = campaignMaster.Id;
        campaignWrap.name = campaignMaster.Name;
        campaignWrap.expireDate = campaignMaster.ExpireDate__c;
        campaignWrap.discountPrice = campaignMaster.DiscountPrice__c;
        campaignWrap.discountRate = campaignMaster.DiscountRate__c;

        inputLeadMap = new Map<String, Object> {
                'leadId' => lead.Id
                , 'productId' => lead.ProductId__c
                , 'campaignIdList' => JSON.serialize(new List<String> { campaignMaster.Id })
                , 'firstAmt' => 0
                , 'interestRate' => 0
                , 'duration' => 0
                , 'totalLoan' => 0
                , 'advancePayment' => 0
                , 'financeId' => finance.Id
        };

        inputDupLeadMap = new Map<String, Object> {
                'leadId' => dupLead.Id
                , 'productId' => dupLead.ProductId__c
                , 'campaignIdList' => JSON.serialize(new List<String> { campaignMaster.Id })
                , 'firstAmt' => 0
                , 'interestRate' => 0
                , 'duration' => 0
                , 'totalLoan' => 0
                , 'advancePayment' => 0
                , 'financeId' => finance.Id
        };
    }

//    @TestSetup
//    static void setup() {
//        TestObjectBuilder2.createQuoteBundle();
//        TestObjectBuilder2.createAccountBundle();
//        TestObjectBuilder2.createLeadBundle();
//    }

    @IsTest
    static void testBehavior1() {
        LeadManagementController.getLeadListByFilter(999);
        LeadManagementController.getLeadListByFilter(15);
        LeadManagementController.getLeadListByFilter(30);
        LeadManagementController.getLeadListByFilter(60);
        LeadManagementController.getTaskListByLeadId(lead.Id);
        LeadManagementController.saveTask(lead.Id, 'subject', 'description');
        LeadManagementController.getDashboardData();
    }

    @IsTest
    static void testBehavior2() {
        LeadManagementController.createPreQuote(inputLeadMap);
    }

    @IsTest
    static void testBehavior3() {
        LeadManagementController.createPreQuote(inputDupLeadMap);
    }

    @IsTest
    static void testBehavior4() {
        LeadManagementController.callApprovalProcess(new Map<String, String> {
                'accountId' => accountPerson.Id
                , 'leadId' => lead.Id
        });
        LeadManagementController.callApprovalProcess(new Map<String, String> {
                'accountId' => accountPerson.Id
                , 'leadId' => dupLead.Id
        });
    }

    @IsTest
    static void testBehavior5() {
        LeadManagementController.accOwnerCheckByLeadInfo(lead.Id);
    }
}