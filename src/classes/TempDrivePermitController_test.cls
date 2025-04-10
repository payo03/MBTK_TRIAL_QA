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
public with sharing class TempDrivePermitController_test {

    static {
        Quote quote  = TestObjectBuilder.createQuote();
        Opportunity opportunity  = TestObjectBuilder.createOpportunity();
        VehicleStock__c vehicleStock  = TestObjectBuilder.createVehicleStock();
        List<Document> documents  = TestObjectBuilder.createDocument();

        if(quote == null ) insert quote; System.debug('contract'+quote);
        if(opportunity == null )  insert opportunity; System.debug('opportunity'+opportunity);
        if(vehicleStock == null )  insert vehicleStock; System.debug('vehicleStock'+vehicleStock);

        Product2 product2 = [SELECT Id, Segment2__c FROM Product2 LIMIT 1];
        if(product2 != null){
            product2.Segment2__c = 'HDC';
            update product2;
        }

    }
    @IsTest
    static void testBehavior() {

        Opportunity opportunity = [SELECT Id, VehicleStock__c,ContractId, Contract.Quote__c FROM Opportunity LIMIT 1];
//        Quote quote = [SELECT Id, OpportunityId, Contract.Opportunity__c, ContractId FROM Quote LIMIT 1];
//        Contract contract = [SELECT Id, Opportunity__c, Quote__c, VehicleStock__c FROM Contract LIMIT 1];

        List<Document> documentList = [SELECT Id, Url FROM Document];
        Test.setCurrentPage(Page.VehiceManufactCert);
        ApexPages.currentPage().getParameters().put('id', opportunity.VehicleStock__c);
        ApexPages.currentPage().getParameters().put('tempReqDate', String.valueOf(System.today()));
        ApexPages.currentPage().getParameters().put('driveDays', '10');
        Test.startTest();
        TempDrivePermitController tempDrivePermitController = new TempDrivePermitController();
        tempDrivePermitController.init();
        Test.stopTest();
    }
}