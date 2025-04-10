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
private class CompliancePDFController_test {

    static {
        Quote quote  = TestObjectBuilder.createQuote();
        Opportunity opportunity  = TestObjectBuilder.createOpportunity();
        VehicleStock__c vehicleStock  = TestObjectBuilder.createVehicleStock();
        Product2 product2  = TestObjectBuilder.createProduct();
        SelfCertWeightLabel__c selfCertWeightLabel  = TestObjectBuilder.createSelfCertWeightLabel();
        SelfCertWeightLabelDtl__c selfCertWeightLabelDtl  = TestObjectBuilder.createSelfCertWeightLabelDtl();

        if(quote == null ) insert quote;
        if(opportunity == null )  insert opportunity;
        if(product2 == null )  insert product2;
        if(selfCertWeightLabel == null )  insert selfCertWeightLabel;
        if(selfCertWeightLabelDtl == null )  insert selfCertWeightLabelDtl;
    }

    @IsTest
    static void testBehavior() {
        Opportunity opportunity = [SELECT Id, VehicleStock__c,ContractId, Contract.Quote__c,VehicleStock__r.Product__c, VehicleStock__r.Product__r.VehicleCategory__c FROM Opportunity LIMIT 1];
        Test.setCurrentPage(Page.SNSAgreement);
        ApexPages.currentPage().getParameters().put('id', opportunity.VehicleStock__c);

        Test.startTest();
        CompliancePDFController compliancePDFController = new CompliancePDFController();
        compliancePDFController.getInit();

        VehicleCategory__c vehicleCategory = [SELECT Id, ModelType__c FROM VehicleCategory__c WHERE Id =:opportunity.VehicleStock__r.Product__r.VehicleCategory__c];
        vehicleCategory.ModelType__c = 'TGX';
        update vehicleCategory;
        compliancePDFController.getInit();
        Test.stopTest();
    }
}