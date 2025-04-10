/**
* @Author            : chaebeom.do@solomontech.net
* @Description 		 : LeadAcquisitionController_test.cls를 위한 HttpCalloutMock
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-16      chaebeom.do@solomontech.net           Created
*/
@isTest
global class HttpCalloutTest implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"request_cnt":1,"match_cnt":1,"status_code":"OK","data":[{"b_no":"5058603049","b_stt":"계속사업자","b_stt_cd":"01","tax_type":"부가가치세 일반과세자","tax_type_cd":"01","end_dt":"","utcc_yn":"N","tax_type_change_dt":"","invoice_apply_dt":"","rbf_tax_type":""}]}');
        return response;
    }
}