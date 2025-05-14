/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-05-14      payo03@solomontech.net           Created
*/
@IsTest
private class OpportunityPDFController_test {

    @TestSetup
    static void setup() {
        TestObjectBuilder2.createQuoteBundle();
    }

    @IsTest
    static void testBehavior() {

        Opportunity oppty = [SELECT Id FROM Opportunity LIMIT 1];
        ApexPages.StandardController pageController = new ApexPages.StandardController(oppty);
        OpportunityPDFController controller = new OpportunityPDFController(pageController);

        controller.getVFInfo();
    }
}