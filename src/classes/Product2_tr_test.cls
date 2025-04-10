/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-04-02      payo03@solomontech.net           Created
*/
@IsTest
private class Product2_tr_test {

    @TestSetup
    static void setup() {
        TestObjectBuilder2.createStockBundle();
    }

    @IsTest
    static void testBehavior() {

        Test.startTest();

        Test.stopTest();
    }
}