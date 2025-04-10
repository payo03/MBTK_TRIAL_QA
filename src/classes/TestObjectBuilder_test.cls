/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2024-12-13      jh.jung           Created
*/
@IsTest
private class TestObjectBuilder_test {

    @IsTest
    static void testBehavior() {
        Account accountPerson = TestObjectBuilder.accountPerson;
        Account accountCompany = TestObjectBuilder.accountCompany;

        Test.startTest();

        TestObjectBuilder.createObjects();

        Test.stopTest();
    }

}