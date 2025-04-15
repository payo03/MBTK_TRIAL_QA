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
public with sharing class TransCertController_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder.createObjects();
    }

    @IsTest
    static void testBehavior() {

        Opportunity opportunity = [SELECT Id, VehicleStock__c,ContractId, Contract.Quote__c FROM Opportunity LIMIT 1];

        List<Document> documentList = [SELECT Id, Url FROM Document];
        Test.setCurrentPage(Page.VehiceManufactCert);
        ApexPages.currentPage().getParameters().put('id', opportunity.VehicleStock__c);
        Test.startTest();
        TransCertController transCertController = new TransCertController();
        transCertController.init();
        Test.stopTest();
    }
}