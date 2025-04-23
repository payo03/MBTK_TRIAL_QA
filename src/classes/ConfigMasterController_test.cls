/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-13      payo03@solomontech.net           Created
*/
@IsTest
private class ConfigMasterController_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createConfigBundle();
    }

    @IsTest
    static void testBehavior() {
        String RECORDTYPE_SALES = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('SALES_CONDITION').getRecordTypeId();
        String RECORDTYPE_PL_CALC = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('PL_CAL_INFO').getRecordTypeId();

        ConfigMaster__c master = [
                SELECT Id, Name, Value__c, Description__c, Parent__r.Name
                FROM ConfigMaster__c
                WHERE RecordTypeId = :RECORDTYPE_SALES
        ];
        ConfigDetail__c detail = [
                SELECT Id, ConfigMaster__c
                FROM ConfigDetail__c
                WHERE fm_MaterRecordTypeId__c != :RECORDTYPE_PL_CALC
                LIMIT 1
        ];
        ConfigDetail__c detailCalc = [
                SELECT Id, Name, Attribute1__c, Attribute2__c, Attribute3__c, Attribute4__c, ConfigMaster__c
                FROM ConfigDetail__c
                WHERE ConfigMaster__r.RecordTypeId = :RECORDTYPE_PL_CALC
                LIMIT 1
        ];

        ConfigMasterController.selectConfigMaster('MAN1000');
        ConfigMasterController.selectConfigDetailById(detail.Id);

        List<Map<String, Object>> paramMList = new List<Map<String, Object>>();
        Map<String, Object> paramM = new Map<String, Object>();
        paramM.put('Id', master.Id);
        paramM.put('Name', master.Name);
        paramM.put('Value__c', master.Value__c);
        paramM.put('Description__c', 'Test');
        paramM.put('parentName', master.Parent__r.Name);
        paramMList.add(paramM);

        ConfigMasterController.upsertConfigMaster(paramMList);
        ConfigMasterController.upsertConfigDetail(new List<ConfigDetail__c>{detail});
        ConfigMasterController.upsertConfigDetail(new List<ConfigDetail__c>{detailCalc});
        ConfigMasterController.deleteConfigDetail(new List<Id>{detail.Id});
    }
}