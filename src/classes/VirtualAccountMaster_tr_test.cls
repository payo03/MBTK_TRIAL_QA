/**
* @Author            : payo03@solomontech.net
* @Description 		 : Test Class
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-05-20      payo03@solomontech.net           Created
*/
@IsTest
private class VirtualAccountMaster_tr_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createVirtualAccountBundle();
    }

    @IsTest
    static void testBehavior() {
        Test.startTest();

        List<VirtualAccountMaster__c> objList = [
                SELECT Id, Status__c
                FROM VirtualAccountMaster__c
        ];

        new VirtualAccountMaster_tr().test(objList);

        Test.stopTest();
    }
}