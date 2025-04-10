/**
* @Author            : payo03@solomontech.net
* @Description 		 : API Health Check
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-11      payo03@solomontech.net           Created
*/
@IsTest
public class IF_HealthCheck_test {

    @IsTest
    static void testOne(){
        Test.startTest();
        IF_HealthCheck.doGet();
        Test.stopTest();
    }
}