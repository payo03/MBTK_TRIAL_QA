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
private class AccountInterface_test {

    @TestSetup
    static void setup() {
        System.debug('TEST88');
        System.debug('TEST90');
        System.debug('TEST92');
        TestObjectBuilder.createObjects();
    }

    @IsTest
    static void testBehavior() {
        Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];

        AccountInterface.fetchRecord(acc.Id);
        AccountInterface.updateRecord(acc);
        AccountInterface.sendCustomerInfo(acc.Id);

        Test.stopTest();
    }
}
