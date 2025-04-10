/**
* @Author            : payo03@solomontech.net
* @Description 		 : Test Class
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-13      payo03@solomontech.net           Created
*/
@IsTest
private class AvisConfig_tr_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createOrderBundle();
    }

    @IsTest
    static void testBehavior() {
        Test.startTest();

        List<AvisConfig__c> configs = [
                SELECT Id, OrderIntakeNo__c, CodeNo__c
                FROM AvisConfig__c
        ];

        new AvisConfig_tr().test(configs);

        Test.stopTest();
    }
}