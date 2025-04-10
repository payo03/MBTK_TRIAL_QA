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
private class AdvancedSafetyDeviceController_test {
    static final Opportunity opportunity  = TestObjectBuilder.createOpportunity();
    static final VehicleStock__c vehicleStock  = TestObjectBuilder.createVehicleStock();
    static final List<Document> documents  = TestObjectBuilder.createDocument();


    static {
        insert opportunity;
        insert documents;
    }

    @IsTest
    static void testBehavior() {
        Test.setCurrentPage(Page.AdvancedSafetyDevice);
        ApexPages.currentPage().getParameters().put('id', opportunity.VehicleStock__c);

        Test.startTest();
        AdvancedSafetyDeviceController advancedSafetyDeviceController = new AdvancedSafetyDeviceController();
        advancedSafetyDeviceController.init();
        Test.stopTest();
    }

}