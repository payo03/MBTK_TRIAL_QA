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
private class PdfTakeTruckController_test {

    @TestSetup
    static void setup() {
        TestObjectBuilder.createObjects();
    }

    @IsTest
    static void testBehavior() {
        Contract contract = [SELECT Id, Quote__c, Opportunity__r.VehicleStock__c FROM Contract LIMIT 1];
        Test.setCurrentPage(Page.PdfTakeTruck);
        ApexPages.currentPage().getParameters().put('id', contract.Opportunity__r.VehicleStock__c);
        Test.startTest();
        PdfTakeTruckController.getQuoteDetail(contract.Quote__c);
        PdfTakeTruckController pdfTakeTruckController = new PdfTakeTruckController();
        pdfTakeTruckController.init();

        Test.stopTest();
    }
}