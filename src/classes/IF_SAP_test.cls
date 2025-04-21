/**
* @Author            : payo03@solomontech.net
* @Description 		 :
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-15      payo03@solomontech.net           Created
*/
@IsTest
public class IF_SAP_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createIfBundle();
        TestObjectBuilder2.createVirtualAccountBundle();
        TestObjectBuilder2.createStockBundle();
        TestObjectBuilder2.createPaymentBundle();
    }

    @IsTest
    static void testOne(){
        Test.startTest();

        VirtualAccount__c va = [SELECT Id, fm_VirtualAccount__c, Account__r.BPCode__c FROM VirtualAccount__c LIMIT 1];
        RestRequest req = new RestRequest();
        String requestBody = '';


        requestBody =
            '{' +
            '    "doc_num": "100",' +
            '    "card_cd": "' + va.Account__r.BPCode__c + '",' +
            '    "acc_no": "' + va.fm_VirtualAccount__c + '",' +
            '    "crncy": "KRW",' +
            '    "doc_total": "16000000"' +
            '}';
        req = new RestRequest();
        req.requestURI = '/api/sap/sms019';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        IF_SAP.doPost();


        requestBody = IF_Util.makeSampleBody2();
        req = new RestRequest();
        req.requestURI = '/api/sap/async/sms010';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        IF_SAP.doPost();


        req = new RestRequest();
        req.requestURI = '/api/sap/async/sms011';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        IF_SAP.doPost();


        req = new RestRequest();
        req.requestURI = '/api/sap/async/sms012';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        IF_SAP.doPost();

        Test.stopTest();
    }
}