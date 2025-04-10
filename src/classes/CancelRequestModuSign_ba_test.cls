/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-21      payo03@solomontech.net           Created
*/
@IsTest
private class CancelRequestModuSign_ba_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createConfigBundle();
        TestObjectBuilder2.createIfBundle();
    }

    @IsTest
    static void testBehavior() {
        String selectFields =       CancelRequestModuSign_ba.getFields();
        String fromObject =         'APIDocument__c ';
        String whereConditions =    '';

        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, whereConditions);
        List<APIDocument__c> documents = Database.query(buildQuery);
        CancelRequestModuSign_ba ba = new CancelRequestModuSign_ba(null);

        Test.startTest();

        Database.QueryLocator queryLocator = ba.start(null);
        ba.execute(null);
        ba.execute(null, documents);
        ba.finish(null);

        Test.stopTest();
    }
}