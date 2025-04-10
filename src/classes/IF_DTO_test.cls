/**
* @Author            : payo03@solomontech.net
* @Description 		 : IF_DTO Test Class
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-13      payo03@solomontech.net           Created
*/
@IsTest
public class IF_DTO_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createStockBundle();
    }

    @IsTest
    static void testOne() {

        Test.startTest();

        new IF_DTO().test();

        Test.stopTest();
    }
}