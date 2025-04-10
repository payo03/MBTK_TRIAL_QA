/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-25      payo03@solomontech.net           Created
*/
@IsTest
private class CustomCalendar_ba_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createIfBundle();

    }

    @IsTest
    static void testBehavior() {
        String selectFields =       'Id';
        String fromObject =         'Account LIMIT 1';

        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, '', '');

        List<Account> dummyObjects = Database.query(buildQuery);
        CustomCalendar_ba ba = new CustomCalendar_ba(-1);
        CustomCalendar_ba ba2 = new CustomCalendar_ba(0);
        ExchangeRate_ba ba3 = new ExchangeRate_ba(null, null);

        Test.startTest();

        Database.QueryLocator queryLocator = ba.start(null);
        ba.execute(null, dummyObjects);
        ba.execute(null);
        ba.finish(null);

        Database.QueryLocator queryLocator2 = ba2.start(null);
        ba2.execute(null, dummyObjects);
        ba2.execute(null);
        ba2.finish(null);

        Database.QueryLocator queryLocator3 = ba3.start(null);
        ba3.execute(null, dummyObjects);
        ba3.execute(null);
        ba3.finish(null);

        Test.stopTest();
    }
}