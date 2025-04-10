/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-01-20      jh.jung           Created
*/
@IsTest
private class Lead_tr_test {

    static List<IF_Master__c> ifMasterList;
    static Lead lead;
    static Lead dupLead;

    static {
        TestObjectBuilder.createObjects();
        ifMasterList = TestObjectBuilder.createIfMasterList();
        lead = TestObjectBuilder.createLead();
        dupLead = TestObjectBuilder.createDupLead();
    }
    @IsTest
    static void testBehavior() {
        Test.startTest();
        lead.RoadAddress__c = '부산';
        update lead;
        lead.ApprovalStatus__c = '반려됨';
        update lead;
        lead.ApprovalStatus__c = '승인됨';
        update lead;
        dupLead.ApprovalStatus__c = '반려됨';
        update dupLead;
        dupLead.ApprovalStatus__c = '승인됨';
        update dupLead;
        Test.stopTest();
    }

//    public class MyHttpCalloutMock implements HttpCalloutMock {
//        public HTTPResponse respond(HTTPRequest req) {
//            // Mock HTTP 응답을 생성
//            HttpResponse res = new HttpResponse();
//            res.setStatusCode(200);
//
//            Lead_tr.KakaoApiResponse response = new Lead_tr.KakaoApiResponse();
//            response.documents = new List<Lead_tr.Document>();
//            Lead_tr.Document document1 = new Lead_tr.Document();
//            document1.x = 123;
//            document1.y = 123;
//            response.documents.add(document1);
//
//            res.setBody(JSON.serialize(response));
//            return res;
//        }
//    }

}