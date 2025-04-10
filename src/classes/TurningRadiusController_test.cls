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
public with sharing class TurningRadiusController_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder.createObjects();
    }
//    static {
//        Quote quote  = TestObjectBuilder.createQuote();
//        Opportunity opportunity  = TestObjectBuilder.createOpportunity();
//        Contract contract  = TestObjectBuilder.createContract();
//        VehicleStock__c vehicleStock  = TestObjectBuilder.createVehicleStock();
//        List<Document> documents  = TestObjectBuilder.createDocument();
//
//        if(quote == null ) insert quote; System.debug('contract'+quote);
//        if(opportunity == null )  insert opportunity; System.debug('opportunity'+opportunity);
//        if(contract == null ) insert contract; System.debug('contract'+contract);
//        if(vehicleStock == null )  insert vehicleStock; System.debug('vehicleStock'+vehicleStock);
//        if(documents == null ) insert documents; System.debug('documents'+documents);
//    }
    @IsTest
    static void testBehavior() {

        Opportunity opportunity = [SELECT Id, VehicleStock__c,ContractId, Contract.Quote__c FROM Opportunity LIMIT 1];
//        Quote quote = [SELECT Id, OpportunityId, Contract.Opportunity__c, ContractId FROM Quote LIMIT 1];
//        Contract contract = [SELECT Id, Opportunity__c, Quote__c, VehicleStock__c FROM Contract LIMIT 1];

        List<Document> documentList = [SELECT Id, Url FROM Document];
        System.debug('opportunity::'+ opportunity);
        Test.setCurrentPage(Page.VehiceManufactCert);
        ApexPages.currentPage().getParameters().put('id', opportunity.VehicleStock__c);
        Test.startTest();
        TurningRadiusController turningRadiusController = new TurningRadiusController();
        turningRadiusController.init();
        Test.stopTest();
    }
}