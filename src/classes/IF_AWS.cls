/**
* @Author            : payo03@solomontech.net
* @Description 		 : AWS PrivateLink를 통한 IF Redirect
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-04-23      payo03@solomontech.net           Created
*/
@RestResource(UrlMapping='/v1/aws/*')
global without sharing class IF_AWS {

    global static String status;
    global static Datetime responseTime;
    global static Datetime requestTime;

    global static RestRequest request;
    global static RestResponse response;

    @HttpPost
    global static void doPost() {
        String pathCase = RestContext.request.requestURI.substringAfter('/v1/aws/');
        System.debug(pathCase);

        requestTime = Datetime.now();
        request = RestContext.request;
        response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');

        switch on pathCase {
            // 대출심사 결과
            when 'loan002' { updateLoanResult(); }
        }
    }

    private static void updateLoanResult() {
        String requestBody = request.requestBody.toString();
        System.debug(requestBody);

        IF_DTO.LoanResponseInfo responseInfo = (IF_DTO.LoanResponseInfo) JSON.deserialize(requestBody, IF_DTO.LoanResponseInfo.class);
        Quote quote = [
                SELECT Id, OpportunityId
                FROM Quote
                WHERE Id =: responseInfo.quote_id
        ];

        String responseMessage;
        try {
            status = 'SUCCESS';
            responseTime = Datetime.now();
            responseMessage = JSON.serialize(responseInfo);




            response.statusCode = 200;
            response.responseBody = Blob.valueOf(responseMessage);
        } catch(Exception e) {
            status = 'ERROR';
            responseTime = Datetime.now();
            responseMessage = JSON.serialize(e.getMessage());

            response.responseBody = Blob.valueOf(JSON.serialize(e.getMessage()));
            response.statusCode = 500;
        } finally {
            IF_DTO.LogWrapper objLogWrapper = new IF_DTO.LogWrapper();

            objLogWrapper.requestTime = requestTime;
            objLogWrapper.requestBody = requestBody;
            objLogWrapper.status = status;
            objLogWrapper.responseTime = responseTime;
            objLogWrapper.responseBody = responseMessage;
            objLogWrapper.errorCode = String.valueOf(response.statusCode);
            objLogWrapper.logType = IF_DTO.LOG_TYPE.AWS_IN;

            CommonUtilCustomController.setLog(objLogWrapper);
        }
    }
}