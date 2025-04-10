/*************************************************************
 * @author          : th.kim
 * @date            : 2024-11-08
 * @description     :
 * @TestClass       : InterfaceSAP_test
 * @target : 
==============================================================
 * Ver          Date            Author                  Modification
 * 1.0          2024-11-08      th.kim                  Created
 * 1.1          2024-11-11      payo03@solomontech.net  기능 추가
 * 1.2          2024-12-17      payo03@solomontech.net  Get방식의 단일조회 URL을 위한 기능 추가
 * 1.3          2025-01-17      payo03@solomontech.net  IF_Log. LogType 추가
 * 1.4          2025-03-12      payo03@solomontech.net  API Call 함수 모듈화작업
**************************************************************/
public without sharing class IF_Util {

    private static final Boolean IS_TEST = Test.isRunningTest();

    private final IF_Master__c objIfMaster;
    private final List<IF_Header__c> objIfHeaders;

    private final static String CONTENT_TYPE = 'Content-Type';
    private final static Integer MAX_LENGTH = 130000;
    private final static List<Integer> SUCCESS_CODE = new List<Integer>{
            200, 201, 202
    };

    // ver1.3 IF_Log. LogType 추가
    private final static Map<String, IF_DTO.LOG_TYPE> logTypeMap = new Map<String, IF_DTO.LOG_TYPE>{
            'MDSIGN'       => IF_DTO.LOG_TYPE.MODUSIGN_OUT,
            'API'          => IF_DTO.LOG_TYPE.PUBLIC_API,
            'HEROKU_SFDC'  => IF_DTO.LOG_TYPE.HEROKU_SFDC,
            'HEROKU_WSMOKA'=> IF_DTO.LOG_TYPE.HEROKU_WSMOKA,
            'HEROKU_KAKAO' => IF_DTO.LOG_TYPE.HEROKU_KAKAO_OUT,
            'HEROKU_SMS'   => IF_DTO.LOG_TYPE.HEROKU_SAP_OUT
    };

    public class LogWrapper {
        public String status;
        public String errorCode;
        public String errorMessage;
        public Datetime requestTime;
        public String requestBody;
        public Datetime responseTime;
        public String responseBody;
        public IF_DTO.LOG_TYPE logType;
    }

    public IF_Util(String ifId) {
        IF_Master__c objIfMaster = [
            SELECT Id, Name, Type__c, Endpoint__c, Method__c, ContentType__c, IF_Id__c,
                IsSendParameter__c, IsLogInsert__c,
                (
                    SELECT Id, Name, Value__c
                    FROM IF_Headers__r
                )
            FROM IF_Master__c
            WHERE IF_Id__c = :ifId
        ];
        this.objIfMaster = objIfMaster;
        this.objIfHeaders = objIfMaster.IF_Headers__r;
    }

    // ver1.2 Get방식의 단일조회 URL을 위한 기능 추가
    public HttpResponse webCallout(String body) {
        return webCallout(body, new List<String>());
    }

    /**
     * @author th.kim
     * @description 각 인터페이스에 맞게 데이터 Request
     * @param body Request Body
     * @param addURLList Dynamic URL
     * @return response
     */
    public HttpResponse webCallout(String body, List<String> addURLList) {
        // Http 변수
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();

        // 로그 데이터 변수
        String status;
        String responseBody;
        String errorCode = '';

        // Request 데이터 생성
        String contentType = this.objIfMaster.ContentType__c;
        String httpMethod = this.objIfMaster.Method__c;
        String endPoint = this.objIfMaster.Endpoint__c;
        String ifId = this.objIfMaster.IF_Id__c;
        Boolean isSendParameter = this.objIfMaster.IsSendParameter__c;
        Boolean isLogInsert = this.objIfMaster.IsLogInsert__c;
        List<IF_Header__c> headers = this.objIfHeaders;

        // Log Request 데이터
        LogWrapper objLogWrapper = new LogWrapper();
        objLogWrapper.requestTime = Datetime.now();
        objLogWrapper.requestBody = body;

        if(contentType != null) request.setHeader(CONTENT_TYPE, contentType);
        for(IF_Header__c header : headers) {
            request.setHeader(header.Name, header.Value__c);
        }
        request.setMethod(httpMethod);

        // ver1.2 Get방식의 단일조회 URL을 위한 기능 추가
        if(!addURLList.isEmpty()) {
            for(String addURL : addURLList) {
                endPoint += '/' + addURL;
            }
        }
        // request.setBody를 할 경우 Method GET으로 설정을 해도 실제로는 POST로 전송되기 때문에 분기처리
        if(isSendParameter) {
            if (httpMethod.toUpperCase() == 'GET') {
                endPoint += '?' + body;
            } else {
                request.setBody(body);
            }
        }
        request.setEndpoint(endPoint);

        try {
            // Request 보내기
            if(!IS_TEST) {
                response = http.send(request);
            } else {
                // TestClass에 맞는 responseBody 추가하시오
                responseBody = makeSampleBody();
                response.setStatusCode(200);
                response.setBody(responseBody);
            }

            if (SUCCESS_CODE.contains(response.getStatusCode())) {
                status = 'SUCCESS';
            } else {
                status = 'ERROR';
                errorCode = String.valueOf(response.getStatusCode());
            }
            responseBody = response.getBody();
            System.debug('requestBody :: ' + request.getBody());
            System.debug('responseBody :: ' + responseBody);
        } catch (Exception e) {
            System.debug('err :: ' + e.getMessage() + ' || ' + e.getLineNumber());
            status = 'ERROR';
            errorCode = '-1';
            responseBody = e.getMessage() + ' || ' + e.getLineNumber();
        }

        // Log Response 데이터
        objLogWrapper.status = status;
        objLogWrapper.responseTime = Datetime.now();
        objLogWrapper.responseBody = responseBody;
        objLogWrapper.errorCode = errorCode;
        for (String key : logTypeMap.keySet()) {
            if (ifId.startsWith(key)) objLogWrapper.logType = logTypeMap.get(key);
        }

        // 로그 생성
        if(isLogInsert) setLog(objLogWrapper);

        return response;
    }

    public static Blob callURLtoPDF(String url) {
        Http http = new Http();

        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');

        // URL to PDF 변환
        HttpResponse response;
        if(!IS_TEST) {
            response = http.send(request);
        } else {
            response = new HttpResponse();
            response.setBodyAsBlob(Blob.valueOf('{"id":"123456789"}'));
        }
        return response.getBodyAsBlob();
    }

    /**
     * @author th.kim
     * @description Log 데이터 생성
     * @param logWrapper Log 데이터
     */
    public void setLog(LogWrapper logWrapper) {

        IF_Log__c objLog = new IF_Log__c();
        objLog.IF_Master__c = this.objIfMaster.Id;
        objLog.Status__c = logWrapper.status;
        objLog.RequestTime__c = logWrapper.requestTime;
        objLog.RequestBody__c = logWrapper.requestBody != null ? logWrapper.requestBody.abbreviate(MAX_LENGTH) : null;
        objLog.ResponseTime__c = logWrapper.responseTime;
        objLog.ResponseBody__c = logWrapper.responseBody != null ? logWrapper.responseBody.abbreviate(MAX_LENGTH) : null;
        objLog.ErrorCode__c = logWrapper.errorCode;
        objLog.LogType__c = String.valueOf(logWrapper.logType);

        insert objLog;
    }

    // ver1.4 API Call 함수 모듈화작업
    public HttpResponse webCallout2(String body)                                    { return webCallout2(body, new List<String>(), new Map<String, String>()); }
    public HttpResponse webCallout2(String body, List<String> addURLList)           { return webCallout2(body, addURLList, new Map<String, String>()); }
    public HttpResponse webCallout2(String body, Map<String, String> cHeaderMap)    { return webCallout2(body, new List<String>(), cHeaderMap); }
    public HttpResponse webCallout2(String body, List<String> addURLList, Map<String, String> cHeaderMap) {
        HttpRequest request = makeRequest(body, addURLList, cHeaderMap);    // Http
        LogWrapper logWrapper = makeLogWrapper(body);                       // Log Request
        
        return doCallOutAPI(request, logWrapper);                           // Response
    }

    // ver1.4 API Call 함수 모듈화작업
    public HttpRequest makeRequest(String body)                                     { return makeRequest(body, new List<String>(), new Map<String, String>()); }
    public HttpRequest makeRequest(String body, List<String> addURLList)            { return makeRequest(body, addURLList, new Map<String, String>()); }
    public HttpRequest makeRequest(String body, Map<String, String> cHeaderMap)     { return makeRequest(body, new List<String>(), cHeaderMap); }
    public HttpRequest makeRequest(String body, List<String> addURLList, Map<String, String> cHeaderMap) {
        // Http 변수
        HttpRequest request = new HttpRequest();
        request = makeHeaders(request, cHeaderMap);
        request = makeBody(request, body, addURLList);

        return request;
    }

    // ver1.4 API Call 함수 모듈화작업
    public HttpRequest makeHeaders(HttpRequest request)                             { return makeHeaders(request, new Map<String, String>()); }
    public HttpRequest makeHeaders(HttpRequest request, Map<String, String> cHeaderMap) {
        String contentType = this.objIfMaster.ContentType__c;
        List<IF_Header__c> headers = this.objIfHeaders;

        if (contentType != null) request.setHeader(CONTENT_TYPE, contentType);
        for (IF_Header__c header : headers) {
            request.setHeader(header.Name, header.Value__c);
        }
        // Custom Header 추가필요시
        for(String key : cHeaderMap.keySet()) {
            request.setHeader(key, cHeaderMap.get(key));
        }

        return request;
    }

    // ver1.4 API Call 함수 모듈화작업
    public HttpRequest makeBody(HttpRequest request, String body)                   { return makeBody(request, body, new List<String>()); }
    public HttpRequest makeBody(HttpRequest request, String body, List<String> addURLList) {
        String httpMethod = this.objIfMaster.Method__c;
        String endPoint = this.objIfMaster.Endpoint__c;
        Boolean isSendParameter = this.objIfMaster.IsSendParameter__c;

        request.setMethod(httpMethod);
        for (String addURL : addURLList) {
            endPoint += '/' + addURL;
        }
        // request.setBody를 할 경우 Method GET으로 설정을 해도 실제로는 POST로 전송되기 때문에 분기처리
        if (isSendParameter) {
            if (httpMethod.toUpperCase() == 'GET') {
                endPoint += '?' + body;
            } else {
                request.setBody(body);
            }
        }
        request.setEndpoint(endPoint);

        return request;
    }

    // ver1.4 API Call 함수 모듈화작업
    public LogWrapper makeLogWrapper(String body) {
        Boolean isLogInsert = this.objIfMaster.IsLogInsert__c;

        LogWrapper logWrapper = new LogWrapper();
        logWrapper.requestTime = Datetime.now();
        logWrapper.requestBody = body;

        return isLogInsert ? logWrapper : null;
    }

    // ver1.4 API Call 함수 모듈화작업
    public HttpResponse doCallOutAPI(HttpRequest request)                           { return this.doCallOutAPI(request, null); }
    public HttpResponse doCallOutAPI(HttpRequest request, LogWrapper logWrapper) {
        HttpResponse response = new HttpResponse();
        Http http = new Http();

        // 로그 데이터 변수
        String status;
        String responseBody;
        String errorCode = '';
        try {
            // Request 보내기
            if(!IS_TEST) {
                response = http.send(request);
            } else {
                // TestClass에 맞는 responseBody 추가하시오
                responseBody = makeSampleBody();
                response.setStatusCode(200);
                response.setBody(responseBody);
            }

            if (SUCCESS_CODE.contains(response.getStatusCode())) {
                status = 'SUCCESS';
            } else {
                status = 'ERROR';
                errorCode = String.valueOf(response.getStatusCode());
            }
            responseBody = response.getBody();
            System.debug('requestBody :: ' + request.getBody());
            System.debug('responseBody :: ' + responseBody);
        } catch (Exception e) {
            System.debug('err :: ' + e.getMessage() + ' || ' + e.getLineNumber());
            status = 'ERROR';
            errorCode = '-1';
            responseBody = e.getMessage() + ' || ' + e.getLineNumber();
        }

        if(logWrapper != null) {
            // Log Response 데이터
            logWrapper.status = status;
            logWrapper.responseTime = Datetime.now();
            logWrapper.responseBody = responseBody;
            logWrapper.errorCode = errorCode;

            String ifId = this.objIfMaster.IF_Id__c;
            for (String key : logTypeMap.keySet()) {
                if (ifId.startsWith(key)) logWrapper.logType = logTypeMap.get(key);
            }
            setLog(logWrapper);
        }

        return response;
    }

    // TestClass용 SampleBody
    public static String makeSampleBody() {
        return '{' +
                '  "id": "123456789",' +
                '  "title": "계약서",' +
                '  "status": "ON_PROCESSING",' +
                '  "file": {' +
                '    "downloadUrl": "Test"' +
                '  },' +
                '  "message": {' +
                '    "bulkId": "123456789",' +
                '    "messages": [{' +
                '      "status": {' +
                '        "groupName": "DELIVERED"' +
                '      },' +
                '        "destination": "821099991919"' +
                '    }],' +
                '    "data": {' +
                '      "list": [{' +
                '        "templateCode": "KAKAO_000",' +
                '        "templateName": "template_name",' +
                '        "templateTitle": "template_title",' +
                '        "templateContent": "template_content",' +
                '        "buttons": [{' +
                '          "name": "namne",' +
                '          "linkType": "type",' +
                '          "linkMo": "link_mo",' +
                '          "linkPc": "link_pc"' +
                '        }]' +
                '      }]' +
                '    },' +
                // SAP I/F
                '    "Code": "0",' +
                '    "Message": "성공",' +
                '    "ResultData": ["test"]' +
                '  },' +
                '  "code":true,' +
                '  "request_cnt":1,' +
                '  "match_cnt":1,' +
                '  "status_code":"OK",' +
                '  "data":[{' +
                '    "b_no":"5058603049",' +
                '    "b_stt":"계속사업자",' +
                '    "b_stt_cd":"01",' +
                '    "tax_type":"부가가치세 일반과세자",' +
                '    "tax_type_cd":"01",' +
                '    "end_dt":"",' +
                '    "utcc_yn":"N",' +
                '    "tax_type_change_dt":"",' +
                '    "invoice_apply_dt":"",' +
                '    "rbf_tax_type":""' +
                '  }],' +
                '  "templates":[{' +
                '    "id":"123",' +
                '    "title":"text"' +
                '  }],' +
                // CustomCalendar
                '  "response": {' +
                '    "header": {' +
                '      "resultCode": "00",' +
                '      "resultMsg": "NORMAL SERVICE."' +
                '    },' +
                '    "body": {' +
                '      "items": {' +
                '        "item": {' +
                '          "dateKind": "01",' +
                '          "dateName": "현충일",' +
                '          "isHoliday": "Y",' +
                '          "locdate": 20250606,' +
                '          "seq": 1' +
                '        }' +
                '      },' +
                '      "numOfRows": 50,' +
                '      "pageNo": 1,' +
                '      "totalCount": 1' +
                '    }' +
                '  }' +
                '}';
    }

    public static String makeSampleBody2() {
        return '{' +
                '  "message": {' +
                '    "Code": "0",' +
                '    "Message": "성공",' +
                '    "ResultData": []' +
                '  },' +
                '  "code":true,' +
                '  "LOG_ID":"123"' +
                '}';
    }
}