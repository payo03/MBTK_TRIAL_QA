/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-03-28      jh.jung           Created
*/

@IsTest
private class FinanceCloneAndArchive_ba_test {

    static {
        TestObjectBuilder.createObjects();
    }

    @IsTest
    static void testBehavior1() {

        FinanceCloneAndArchive_ba ba = new FinanceCloneAndArchive_ba();

        Test.startTest();
        Database.executeBatch(ba, 200);
        Test.stopTest();
    }
}