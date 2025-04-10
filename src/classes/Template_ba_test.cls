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
private class Template_ba_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createIfBundle();

    }

    @IsTest
    static void testBehavior() {
        String selectFields =       'Id';
        String fromObject =         'Template__c';
        String whereCondition =     '';
        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, whereCondition);

        List<Template__c> dummyObjects = Database.query(buildQuery);
        Template_ba ba = new Template_ba('MODUSIGN', null);
        Template_ba ba2 = new Template_ba('KAKAO', null);

        Test.startTest();

        Database.QueryLocator queryLocator = ba.start(null);
        ba.execute(null, dummyObjects);
        ba.execute(null);
        ba.finish(null);

        Database.QueryLocator queryLocator2 = ba2.start(null);
        ba2.execute(null, dummyObjects);
        ba2.execute(null);
        ba2.finish(null);

        IF_Util.callURLtoPDF('test');
        IF_Util.makeSampleBody2();

        Test.stopTest();
    }
}