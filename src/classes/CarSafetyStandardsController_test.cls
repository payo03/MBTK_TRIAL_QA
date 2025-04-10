/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-04
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-04        San.Kang           Created
**************************************************************/
@IsTest
private class CarSafetyStandardsController_test {

    static final Opportunity opportunity  = TestObjectBuilder.createOpportunity();
    static final VehicleStock__c vehicleStock  = TestObjectBuilder.createVehicleStock();

    static {
        insert opportunity;
    }

    @IsTest
    static void testBehavior() {
        Test.setCurrentPage(Page.CarSafetyStandards);
        ApexPages.currentPage().getParameters().put('id', opportunity.VehicleStock__c);

        Test.startTest();
        CarSafetyStandardsController carSafetyStandardsController = new CarSafetyStandardsController();
        carSafetyStandardsController.init();
        Test.stopTest();
    }
}