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
private class ReleaseScheduleController_test {

    static final Contract contract = TestObjectBuilder.createContract();
    static final Opportunity opportunity = TestObjectBuilder.createOpportunity();
    static final VehicleStock__c vehicleStock  = TestObjectBuilder.createVehicleStock();
    static final List<Document> document  = TestObjectBuilder.createDocument();

    static {
        insert contract;
        insert document;

    }

    @IsTest
    static void testBehavior() {
        Test.setCurrentPage(Page.ReleaseSchedule);
        ApexPages.currentPage().getParameters().put('id', opportunity.Id);

        Test.startTest();
        ReleaseScheduleController releaseScheduleController = new ReleaseScheduleController();
        releaseScheduleController.init();
        Test.stopTest();
    }
}