/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-03-28
 * @description : PdiController의 test class
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-28      chaebeom.do     Created
**************************************************************/
@isTest
private class PdiController_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder.createObjects();
    }

    @isTest
    static void testScreenInit() {
        Test.startTest();
        PdiController.screenInit();
        Test.stopTest();
    }

    @isTest
    static void testFetchStatus() {
        List<String> workNoList = new List<String>();
        // workNoList.add('39SH118');
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        List<SpoilerPart__c> spoilerList = [SELECT Id FROM SpoilerPart__c];
        VehicleStock__c vehicleStock = new VehicleStock__c(
                Product__c = product.Id,
                Status__c = '재고 노출',
                LongTermStock__c = true,
                IsSpecial__c = false,
                IsOptionDiscount__c = false,
                LongtermDiscountRate__c = 0.2,
                SpecialDiscountRate__c = 0,
                OptionDiscountRate__c = 0,
                SpecShort__c = 'TGL 10.220 4x2 BL CH',
                SpoilerPart__c = spoilerList.get(0).Id,
                VehicleNo__c = '39SH119',
                Name = 'A001'
            );
        insert vehicleStock;
        workNoList.add('39SH119');
        Test.startTest();
        PdiController.fetchStatus(workNoList);
        Test.stopTest();
    }

    @isTest
    static void testSearch() {
        Test.startTest();
        PdiController.searchVINbyKey('39SH118');
        Test.stopTest();
    }

    @isTest
    static void testCompleteAndRollback() {
        List<Map<String, String>> vinInfoList = new List<Map<String, String>>();
        Map<String, String> vinInfoMap = new Map<String, String>();
        vinInfoMap.put('WorkNo', '39SH118');
        vininfoList.add(vinInfoMap);
        Test.startTest();
        PdiController.rollbackVehicleStock('STEP5', vinInfoList);
        PdiController.updateVehicleStock('STEP5', vinInfoList);
        Test.stopTest();
    }

    @isTest
    static void testStep3() {
        VehicleStock__c vehicle = [SELECT Id FROM VehicleStock__c LIMIT 1];
        Test.startTest();
        PdiController.step3Init(vehicle.Id);
        PdiController.step3CheckSpoiler(vehicle.Id);
        Test.stopTest();
    }

    @isTest
    static void testStep4() {
        VehicleStock__c vehicle = [SELECT Id, SpoilerPart__c FROM VehicleStock__c LIMIT 1];
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('stockId', vehicle.Id);
        inputMap.put('spoilerId', vehicle.SpoilerPart__c);

        Test.startTest();
        PdiController.step4Init(vehicle.Id, vehicle.SpoilerPart__c);
        PdiController.installSpoilerToVehicleStock(inputMap);
        PdiController.updateStep4(vehicle.Id);
        // PdiController.spoilerDropoffSAP(vehicle.Id);
        Test.stopTest();
    }
}