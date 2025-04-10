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
public class IF_Webhook_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createIfBundle();
        
        TestObjectBuilder2.createPaymentBundle();
    }

    @IsTest
    static void testOne(){
        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        APIDocument__c document = [SELECT Id, Name, Contract__c FROM APIDocument__c LIMIT 1];
        List<Opportunity> opptyList = new List<Opportunity>();
        for(Opportunity oppty : [
                SELECT Id, ContractId
                FROM Opportunity
        ]) {
            oppty.ContractId = document.Contract__c;
            opptyList.add(oppty);
        }
        update opptyList;
        List<PaymentType__c> typeList = [
                SELECT Id, RequestAmount__c, DepositAmount__c
                FROM PaymentType__c
                WHERE PaymentTracker__r.Opportunity__r.ContractId = :document.Contract__c
                AND Type__c = '1_DEPOSIT'
                AND PaymentTracker__r.IsValid__c = TRUE
        ];
        for(PaymentType__c type : typeList) {
            type.DepositAmount__c = type.RequestAmount__c;
        }
        update typeList;



        IF_DTO.Requester requester = new IF_DTO.Requester();
        requester.email = 'Test';
        IF_DTO.DocumentInfo info = new IF_DTO.DocumentInfo();
        info.requester = requester;
        info.id = document.Name;
        IF_DTO.EventType type = new IF_DTO.EventType();
        type.type = 'document_signed';
        IF_DTO.ModuSign sign = new IF_DTO.ModuSign();
        sign.document = info;
        sign.event = type;

        String body =
            '{' +
            '  "results": [{' +
            '      "status": {' +
            '        "groupName": "PENDING"' +
            '      },' +
            '      "bulkId": "' + document.Name + '"' +
            '    }' +
            '  ]' +
            '}';

        req.requestURI = '/api/webhook/modusign';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(sign));
        req.addHeader('AUTHCODE', 'Bearer 6rmA7YOc7Z2s67CU67O0');
        RestContext.request = req;
        RestContext.response = res;
        IF_Webhook.doPost();

        req.requestURI = '/api/webhook/kakao';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        IF_Webhook.doPost();

        Test.stopTest();
    }
}