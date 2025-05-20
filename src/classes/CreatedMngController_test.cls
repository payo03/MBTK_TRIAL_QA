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
public with sharing class CreatedMngController_test {

    static final VehicleStock__c vehicleStock = TestObjectBuilder.createVehicleStock();
    static final SpecTypeNo__c specTypeNo = TestObjectBuilder.createSpecTypeNo();
    static final SpecTypeNoJunction__c specTypeNoJunction = TestObjectBuilder2.createSpecTypeNoJunction();

    static {
        insert vehicleStock;
        insert specTypeNo;
        insert specTypeNoJunction;

        specTypeNoJunction.Product__c = vehicleStock.Product__c;
        specTypeNoJunction.SpecTypeNo__c = specTypeNo.Id;
        update specTypeNoJunction;
    }

    @IsTest
    static void testBehavior() {
        Map<String, String> filterMap = new Map<String, String>{
                'EngineType__c' => null,
                'ModelYear__c' => '2019',
                'Remark2__c'    => null,
                'Remark3__c'    => null,
                'Remark__c'     => null
        };
        Test.startTest();
        CreatedMngController.getInitData(vehicleStock.Id);
        CreatedMngController.searchSpecTypeNo('제원관리번호',vehicleStock.Id,filterMap);
        CreatedMngController.getSpecTypeNoList('제원관리번호','');
        CreatedMngController.getField(Schema.SObjectType.SpecTypeNo__c.fields.getMap());
        CreatedMngController.saveSpecTypeNo(specTypeNo.Id,vehicleStock.Id);

        Test.stopTest();
    }
}