/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-03-27      jh.jung           Created
*/
@IsTest
private class MarginCalculatorController_test {

    static AvgLocalCost__c avgLocalCost;
    static VehicleCategory__c vehicleCategory;
    static Product2 product2;

    static {
        TestObjectBuilder.createObjects();
        avgLocalCost = TestObjectBuilder.createAvgLocalCost();
        product2 = TestObjectBuilder.createProduct();
        vehicleCategory = TestObjectBuilder.createVehicleCategory();

//        System.debug('test' + [SELECT Id, VehicleCategory__r.Report_Spec__c FROM Product2 LIMIT 1]);
    }

    @IsTest
    static void testBehavior1() {
        Test.startTest();
        MarginCalculatorController.getInit();
        Test.stopTest();
    }
}