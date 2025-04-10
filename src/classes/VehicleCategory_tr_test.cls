/*************************************************************
 * @author : th.kim
 * @description : 
 * @target : 
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-26      th.kim          Created
**************************************************************/
@IsTest
private class VehicleCategory_tr_test {

    @IsTest
    static void doTest() {

        Test.startTest();

        VehicleStock__c stock = TestObjectBuilder.createVehicleStock();
        insert stock;

        VehicleCategory__c category = TestObjectBuilder.createVehicleCategory();

        Map<String, Decimal> quantityMap = new Map<String, Decimal>();
        quantityMap.put('Quantity__c', 1);
        category.AdjustField__c = JSON.serialize(quantityMap);
        update category;

        Test.stopTest();
    }
}