/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-27
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-27        San.Kang           Created
**************************************************************/
@IsTest
private class DumpAutoCoverController_test {
    static final Opportunity opportunity  = TestObjectBuilder.createOpportunity();
    static final VehicleStock__c vehicleStock  = TestObjectBuilder.createVehicleStock();
    static final List<Document> documents  = TestObjectBuilder.createDocument();


    static {
        insert opportunity;
        insert documents;
    }

    @IsTest
    static void testBehavior() {
        Test.setCurrentPage(Page.DumpAutoCover);
        ApexPages.currentPage().getParameters().put('id', opportunity.VehicleStock__c);

        Test.startTest();
        DumpAutoCoverController dumpAutoCoverController = new DumpAutoCoverController();
        dumpAutoCoverController.init();
        Test.stopTest();
    }

}