/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-28
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-28        San.Kang           Created
**************************************************************/
@IsTest
public with sharing class VehiceManufactCertController_test {
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
        Quote quote = [SELECT Id, OpportunityId, Contract.Opportunity__c, ContractId FROM Quote LIMIT 1];
        Contract contract = [SELECT Id, Opportunity__c, Quote__c, VehicleStock__c FROM Contract LIMIT 1];

        opportunity.ContractId = contract.Id;
        update opportunity;
        List<Document> documentList = [SELECT Id, Url FROM Document];
        System.debug('opportunity::'+ opportunity);
        System.debug('contract::'+ contract);
        System.debug('quote::'+ quote);
        Test.setCurrentPage(Page.VehiceManufactCert);
        ApexPages.currentPage().getParameters().put('id', opportunity.Id);
        Test.startTest();
        VehiceManufactCertController vehiceManufactCertController = new VehiceManufactCertController();
        vehiceManufactCertController.init();
        Test.stopTest();
    }
}