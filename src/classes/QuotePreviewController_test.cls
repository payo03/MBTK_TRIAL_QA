/*************************************************************
 * @author : th.kim
 * @date : 2025-01-20
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-20      th.kim          Created
**************************************************************/
@IsTest
private class QuotePreviewController_test {

    static final Opportunity opportunity;

    static {
        TestObjectBuilder2.createOpportunityBundle();
        TestObjectBuilder2.createStockBundle();
        TestObjectBuilder2.createQuoteBundle();

        opportunity = TestObjectBuilder2.opportunity;
    }

    @IsTest
    static void testGetInit() {

        Test.startTest();

        QuotePreviewController.getInit(opportunity.Id);

        Test.stopTest();
    }
}