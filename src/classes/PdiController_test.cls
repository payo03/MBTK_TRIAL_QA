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
    static final Handover__c newHandover;
    static final Handover__c handover;
    
    static {
        TestObjectBuilder2.createIfBundle();
        TestObjectBuilder2.createContractBundle2();
        insert TestObjectBuilder2.createPaymentTracker();
        insert TestObjectBuilder2.createPaymentTypeList();
        insert TestObjectBuilder2.createPaymentLog();
        insert TestObjectBuilder2.createPDIStep();
        insert TestObjectBuilder2.createHandover();
        handover = TestObjectBuilder2.createHandover();
        newHandover = [
            SELECT Id, Opportunity__c, fm_VehicleStock__c, Opportunity__r.Name, Opportunity__r.OwnerId,
                Opportunity__r.ContractId, Opportunity__r.VehicleStock__r.Name
            FROM Handover__c
            WHERE Id = :handover.Id
        ];
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
                SpecialDiscountAmt__c = 0,
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
        PdiController.updateVehicleStock('STEP5', vinInfoList, false);
        Test.stopTest();
    }

    @isTest
    static void testStep3() {
        VehicleStock__c vehicle = [SELECT Id FROM VehicleStock__c LIMIT 1];
        Test.startTest();
        PdiController.step3Init(vehicle.Id);
        PdiController.step3CheckSpoiler(vehicle.Id);

        SchedulerMainController.HandoverWrap handoverWrap = HandoverSchedulerController.getFilteredHandoverList(null).get(0);
        VehicleStock__c vehicleStock = new VehicleStock__c(
            Name = 'Test',
            Product__c = handoverWrap.vehicleStock.Product__c,
            Status__c = '재고 노출'
        );
        insert vehicleStock;
        List<PDIStep__c> insertList = new List<PDIStep__c>();
        for(Integer i = 1; i <= 5; i++) {
            PDIStep__c step = new PDIStep__c();
            String stage = 'STEP' + i;

            step.VehicleStock__c = vehicleStock.Id;
            step.Stage__c = stage;
            step.Name = vehicleStock.Name + '_' + stage;
            step.IsPass__c = false;

            insertList.add(step);
        }
        insert insertList;
        Map<String, String> completeMap = new Map<String, String>{
            'stockId' => vehicleStock.Id,
            'opportunityId' => newHandover.Opportunity__r.Id,
            'previousStockId' => newHandover.Opportunity__r.VehicleStock__r.Id
        };

        PdiController.doCompleteStep3(completeMap);
        PdiController.doRollbackStep3(completeMap);
        Test.stopTest();
    }

    @isTest
    static void testStep4() {
        VehicleStock__c vehicle = [SELECT Id, SpoilerPart__c FROM VehicleStock__c LIMIT 1];
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('stockId', vehicle.Id);
        inputMap.put('spoilerId', vehicle.SpoilerPart__c);

        Test.startTest();
        PdiController.step4Init(vehicle.Id);
        PdiController.installSpoilerToVehicleStock(inputMap);
        PdiController.updateStep4(vehicle.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetFilteredSpoilerPartsList() {
        Test.startTest();

        Map<String, String> filterMap = new Map<String, String>{
            'spoilerCode' => 'SpoilerPart__c.SpoilerCode__c'
        };

        PdiController.getFilteredSpoilerPartsList(filterMap);
        
        Test.stopTest();

    }

    @IsTest
    static void testGetInit() {

        Test.startTest();

        PdiController.getInitData();

        Test.stopTest();
    }
}