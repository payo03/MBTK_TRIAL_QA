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
public with sharing class VehiclePackageCoverController_test {

    @TestSetup
    static void setup() {
        TestObjectBuilder.createObjects();
    }

    @IsTest
    static void testBehavior() {
        Opportunity opportunity = [SELECT Id, VehicleStock__c FROM Opportunity LIMIT 1];
        Test.setCurrentPage(Page.VehiclePackageCover);
        ApexPages.currentPage().getParameters().put('id', opportunity.VehicleStock__c);

        Test.startTest();
        VehiclePackageCoverController vehiclePackageCoverController = new VehiclePackageCoverController();
        vehiclePackageCoverController.init();
        Test.stopTest();
    }
}