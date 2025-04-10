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
private class SalesCondition_ba_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createConfigBundle();

        TestObjectBuilder2.createStockBundle();

    }

    @IsTest
    static void testBehavior() {
        String RECORDTYPE_SALES_CONDITION = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('SALES_CONDITION').getRecordTypeId();

        String fields = SalesCondition_ba.getFields();
        String fromObject = 'ConfigDetail__c';
        String whereConditions =    'ConfigMaster__r.RecordTypeId = \'' + RECORDTYPE_SALES_CONDITION + '\'';

        String buildQuery = CommonUtilController.buildQuery(fields, fromObject, whereConditions);

        List<ConfigDetail__c> details = Database.query(buildQuery);
        SalesCondition_ba ba = new SalesCondition_ba(String.valueOf(Date.today()));

        Test.startTest();

        Database.QueryLocator queryLocator = ba.start(null);
        ba.execute(null, details);
        ba.finish(null);

        Test.stopTest();
    }
}