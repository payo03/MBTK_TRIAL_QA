/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-31
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-31        San.Kang           Created
**************************************************************/
@IsTest
private class SNSAgreementController_test {

    static {
        Quote quote  = TestObjectBuilder.createQuote();
        Opportunity opportunity  = TestObjectBuilder.createOpportunity();
        VehicleStock__c vehicleStock  = TestObjectBuilder.createVehicleStock();

        if(quote == null ) insert quote;
        if(opportunity == null )  insert opportunity;
    }

    @IsTest
    static void testBehavior() {
        Opportunity opportunity = [SELECT Id, VehicleStock__c,ContractId, Contract.Quote__c FROM Opportunity LIMIT 1];
        Test.setCurrentPage(Page.SNSAgreement);
        ApexPages.currentPage().getParameters().put('id', opportunity.VehicleStock__c);
        Test.startTest();
        SNSAgreementController snsAgreementController = new SNSAgreementController();
        snsAgreementController.init();
        Test.stopTest();
    }
}