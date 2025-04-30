/**
* @Author            : payo03@solomontech.net
* @Description 		 :
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-04-23      payo03@solomontech.net           Created
*/
@IsTest
public class IF_AWS_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createContractBundle();
        TestObjectBuilder2.createIfBundle();
    }

    @IsTest
    static void testOne(){
        Test.startTest();

        RestRequest req = new RestRequest();
        String requestBody = '';

        Quote quote = [SELECT Id FROM Quote LIMIT 1];

        IF_DTO.LoanResponseInfo info = new IF_DTO.LoanResponseInfo();
        info.quote_id = quote.Id;

        requestBody = 'test';
        req.requestURI = '/v1/aws/healthcheck';
        req.httpMethod = 'GET';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        IF_AWS.doGet();

        requestBody = 'test';
        req.requestURI = '/v1/aws/healthcheck';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        IF_AWS.doPost();

        requestBody = JSON.serialize(info);
        req.requestURI = '/v1/aws/loan/response';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        IF_AWS.doPost();

        Test.stopTest();
    }
}