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

    static {
        insert vehicleStock;
        insert specTypeNo;
    }

    @IsTest
    static void testBehavior() {
        Map<String, String> filterMap = new Map<String, String>{
                'EngineType__c' => '',
                'ModelYear__c' => '2019',
                'Remark2__c'    => '',
                'Remark3__c'    => '',
                'Remark__c'     => ''
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