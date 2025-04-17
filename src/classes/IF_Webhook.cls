/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-19      payo03@solomontech.net           Created
  1.1      2024-12-26      payo03@solomontech.net           Webhook 분기처리
  1.2      2025-02-05      payo03@solomontech.net           모두싸인. 모든고객 서명완료시 상태값 분기 추가
  1.3      2025-02-26      payo03@solomontech.net           모두싸인. 후처리 Process 비동기로 실행
  1.4      2025-04-17      payo03@solomontech.net           모두싸인 후처리 Process 상속Class 구현
*/
@RestResource(UrlMapping='/api/webhook/*')
global without sharing class IF_Webhook {

    global final static String LABEL_AUTHCODE = Label.ModuSignAuthcode;
    global final static String DOC_IF_ID = 'MDSIGN_006';

    @HttpPost
    global static void doPost() {
        // ver1.1 Webhook 분기처리
        String pathCase = RestContext.request.requestURI.substringAfter('/api/webhook/');
        System.debug(pathCase);
        switch on pathCase {
            // 모두싸인 WebHook
            when 'modusign' { moduSignWebhook(); }
            // 카카오톡 WebHook
            when 'kakao' { kakaoWebhook(); }
        }
    }

    private static void moduSignWebhook() {
        String status;
        Datetime responseTime;
        Datetime requestTime = Datetime.now();

        String authcode;
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        String requestBody = request.requestBody.toString();
        System.debug(requestBody);
        response.addHeader('Content-Type', 'application/json');
        try {
            /*
                https://developers.modusign.co.kr/docs/webhook-event
                📘 아래와 같은 상황에서 Webhook은 호출 실패로 판단하고 최대 5회 재시도 합니다.

                    Webhook event 수신 시 200번대 응답이 아닐 경우 재시도합니다.
                    응답을(200번대 응답) 먼저 회신 후 내부 작업을 진행해주시는 것을 권장 드립니다.

                    📌 다음의 경우 Webhook 요청 실패로 간주합니다.
                        - 2xx 응답이 아닌경우
                        - 응답에 10초 이상 소요되는 경우(timeout)
                    📌 요청 실패로 간주된 경우, 실패 처리 정책에 따라, Webhook 최대 5회 요청이 될 수 있습니다.

                    ❗️정상 처리가 되었음에도 2xx로 응답하지 않는 경우, Webhook이 재전송되며 중복으로 처리 될 수 있습니다.
                    ❗️️이점 양지하셔서 올바른 응답을 회신한 후 다음 작업을 수행하도록 구현하시는 것을 권장해 드립니다.

                    📌 아래의 경우는 재시도 했을 때 성공 전활율이 낮거나, 의도하지 않은 중복 작업을 발생시킬 가능성 있으므로 재시도 하지 않습니다.
                        - 401, 404 응답을 반환환 경우
                        - 응답에 10초 이상이 소요되는 경우(timeout)
             */
            for(String key : request.headers.keySet()) {
                if('AUTHCODE'.equals(key.toUpperCase())) authcode = request.headers.get(key);
            }
            if(authcode == null || !('Bearer ' + LABEL_AUTHCODE).equals(authcode)) throw new IllegalArgumentException('Invalid Authcode: ' + authcode);

            IF_DTO.ModuSign moduSign = (IF_DTO.ModuSign) JSON.deserialize(requestBody, IF_DTO.ModuSign.class);
            String eventType = moduSign.event.type;
            String documentId = moduSign.document.id;
            String responseMessage = 'Webhook Receive Success. Event Type: ' + eventType;

            response.responseBody = Blob.valueOf(JSON.serialize(responseMessage));
            response.statusCode = 200;
            status = 'SUCCESS';
            responseTime = Datetime.now();

            // ver1.3 모두싸인. 후처리 Process 비동기로 실행
            asyncAfterProcess(eventType, documentId);
        } catch(IllegalArgumentException e) {
            status = 'ERROR';
            responseTime = Datetime.now();

            response.responseBody = Blob.valueOf(JSON.serialize(e.getMessage()));
            response.statusCode = 401;
        } catch(Exception e) {
            status = 'ERROR';
            responseTime = Datetime.now();

            response.responseBody = Blob.valueOf(JSON.serialize(e.getMessage()));
            response.statusCode = 500;
        } finally {
            IF_DTO.LogWrapper objLogWrapper = new IF_DTO.LogWrapper();

            objLogWrapper.requestTime = requestTime;
            objLogWrapper.requestBody = requestBody;
            objLogWrapper.status = status;
            objLogWrapper.responseTime = responseTime;
            objLogWrapper.responseBody = response.responseBody.toString();
            objLogWrapper.errorCode = String.valueOf(response.statusCode);
            objLogWrapper.logType = IF_DTO.LOG_TYPE.MODUSIGN_IN;

            CommonUtilCustomController.setLog(objLogWrapper);
        }
    }

    private static void kakaoWebhook() {
        String status;
        Datetime responseTime;
        Datetime requestTime = Datetime.now();

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        response.addHeader('Content-Type', 'application/json');
        String requestBody = request.requestBody.toString();
        try {
            String responseMessage = 'Webhook Receive Success, requestBody : ' + requestBody;

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(JSON.serialize(responseMessage));

            status = 'SUCCESS';
            responseTime = Datetime.now();

            // JSON Key값에 currency가 존재하여 DTO Wrapper -> Map Type사용
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            List<Object> results = (List<Object>) jsonData.get('results');
            for(Object result : results) {
                Map<String, Object> resultMap = (Map<String, Object>) result;
                Map<String, Object> statusMap = (Map<String, Object>) resultMap.get('status');

                String bulkId = String.valueOf(resultMap.get('bulkId'));
                String docStatus = String.valueOf(statusMap.get('groupName'));

                APIDocument__c doc = [SELECT Id, FileName__c, Status__c FROM APIDocument__c WHERE Name =: bulkId];
                doc.Status__c = docStatus;

                update doc;
            }
        } catch(Exception e) {
            status = 'ERROR';
            responseTime = Datetime.now();

            response.responseBody = Blob.valueOf(JSON.serialize(e.getMessage()));
            response.statusCode = 500;
        } finally {
            IF_DTO.LogWrapper objLogWrapper = new IF_DTO.LogWrapper();

            objLogWrapper.requestTime = requestTime;
            objLogWrapper.requestBody = requestBody;
            objLogWrapper.status = status;
            objLogWrapper.responseTime = responseTime;
            objLogWrapper.responseBody = response.responseBody.toString();
            objLogWrapper.errorCode = String.valueOf(response.statusCode);
            objLogWrapper.logType = IF_DTO.LOG_TYPE.KAKAO_IN;

            CommonUtilCustomController.setLog(objLogWrapper);
        }
    }

    // ver1.2 모두싸인. 모든고객 서명완료시 상태값 분기 추가
    private static String doCheckSignCustomer(String docId) {
        String status = 'ON_GOING';

        // 문서조회 HTTP CallOut
        IF_Util ifUtil = new IF_Util(DOC_IF_ID);
        HttpResponse docResponse = ifUtil.webCallout(null, new List<String>{ docId });
        if (HttpCallOutConsts.SUCCESS_CODES.contains(docResponse.getStatusCode())) {
            String responseBody = docResponse.getBody();
            if(Test.isRunningTest()) responseBody = testJSONBody();

            Map<String, Object> docResponseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            List<Object> participants = (List<Object>) docResponseMap.get('participants');
            Integer currentSigningOrder = Integer.valueOf(docResponseMap.get('currentSigningOrder'));

            Integer maxSigningOrder = 1;
            for(Object participantObj : participants) {
                Map<String, Object> participant = (Map<String, Object>) participantObj;
                Integer signingOrder = Integer.valueOf(participant.get('signingOrder'));

                maxSigningOrder = Math.max(signingOrder, maxSigningOrder);
            }
            if(maxSigningOrder == currentSigningOrder) status = 'COMPLETED(CUSTOMER)';
        }
        return status;
    }

    @Future(Callout = true)
    private static void asyncAfterProcess(String eventType, String docId) {
        CommonUtilController.delayTime(Datetime.now(), 5);  // 5초 Delay
        APIDocument__c doc = [SELECT Id, Contract__c, FileName__c, Status__c, AfterProcessClass__c FROM APIDocument__c WHERE Name =: docId];
        String docStatus;
        switch on eventType {
            when 'document_started' { docStatus = 'ON_GOING'; }
            // ver1.2 모두싸인. 모든고객 서명완료시 상태값 분기 추가
            when 'document_signed' { docStatus = doCheckSignCustomer(docId); }
            when 'document_all_signed' { docStatus = 'COMPLETED'; }
            when 'document_rejected' { docStatus = 'ABORTED'; }
            when 'document_request_canceled' { docStatus = 'ABORTED'; }
            when 'document_signing_canceled' { docStatus = 'ABORTED'; }
        }
        if('COMPLETED(CUSTOMER)'.equals(docStatus) || 'COMPLETED'.equals(docStatus)) InterfaceModuSign.doCallOutURLtoPDF(doc.Id, docStatus, true);

        // API 호출이후 DML
        doc.Description__c = eventType;
        doc.Status__c = docStatus;
        update doc;

        if(doc.AfterProcessClass__c != null) {
            Type type = Type.forName(doc.AfterProcessClass__c);
            // 계약 및 입금완료 확인
            if('COMPLETED(CUSTOMER)'.equals(docStatus)) ((CommonAfterProcess) type.newInstance()).doAfterProcess(doc.Contract__c);
        }
    }

    private static String testJSONBody() {
        return '{' +
               '   "participants": [' +
               '    {' +
               '      "id": "c48d67a1-05e0-11f0-bd5a-77b36dabcb09",' +
               '      "type": "SIGNER",' +
               '      "name": "송찬영",' +
               '      "signingOrder": 1,' +
               '      "signingDue": {' +
               '        "valid": true,' +
               '        "datetime": "2025-04-03T23:12:18.794Z"' +
               '      },' +
               '      "signingMethod": {' +
               '        "type": "EMAIL",' +
               '        "value": "payo03@solomontech.net"' +
               '      },' +
               '      "locale": "ko",' +
               '      "verification": null' +
               '    }' +
               '  ],' +
               '  "currentSigningOrder": 1' +
               '}';
    }
}