/**
* @Author            : payo03@solomontech.net
* @Description 		 :
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-26      payo03@solomontech.net           Created
*/
@IsTest
private class User_tr_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createAccountBundle();
        TestObjectBuilder2.createObjects();
    }

    @IsTest
    static void testBehavior() {
        Test.startTest();

        List<User> userList = [
                SELECT Id, AccountId
                FROM User
        ];
        new User_tr().test(userList);

        Test.stopTest();
    }
}