/**
* @Author            : payo03@solomontech.net
* @Description 		 : 모두싸인 Interface
* @Target            : ModuSign 공통모듈. sampleLWC 참조
* @Description       : 모두싸인 A to Z
                        A. 모두싸인의 Template을 등록 (url : https://app.modusign.co.kr/)
                        B. 모두싸인 서명받을 사용자의 역할 지정 (ex, 근로자, 을... etc)
                        C. Template의 Input Box 배치, 원하는 데이터의 필드명을 사용
                            C-1. 데이터의 필드명이 아닐경우, prefix 'Custom'을 사용하여 작성
                            C-2. 'Custom'의 데이터는 CustomConfig화면에서 작성
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-17      payo03@solomontech.net           Created
  1.1      2024-12-23      payo03@solomontech.net           recordId를 통한 APIName Get, Lookup필드 가져오기 & SubQuery 결과 Get
  1.2      2025-01-07      jh.jung                          Webhook을 통한 PDF저장
  1.3      2025-01-09      payo03@solomontech.net           DataLabel Copy 처리
  1.4      2025-01-13      payo03@solomontech.net           Custom Where의 Field조건 추가, ExpiredDate 필드 추가
  1.5      2025-02-07      payo03@solomontech.net           문서취소 API 함수
  1.6      2025-03-17      jh.jung                          영업기회 모두싸인 호출 대응
  1.7      2025-04-17      payo03@solomontech.net           모두싸인 후처리 Process 상속Class 구현
*/
global without sharing class InterfaceModuSign {

//    private static final List<String> MODUSIGN_WHITE_LIST = Label.ModuSignWhiteList.split(',');
    private static final String RECORDTYPE_MODUSIGN = Schema.SObjectType.APIDocument__c.getRecordTypeInfosByDeveloperName().get('MODUSIGN').getRecordTypeId();

    private static final String DRAFT_IF_ID = 'MDSIGN_003';
    private static final String REQUEST_TEMPLATE_IF_ID = 'MDSIGN_004';
    private static final String DOC_IF_ID = 'MDSIGN_006';
    private static final String REQUEST_PDF_IF_ID = 'MDSIGN_007';
    private static final String CANCEL_IF_ID = 'MDSIGN_008';
    private static final String DEFAULT_LOCALE = 'ko';

    private final static List<String> TASK_LIST = new List<String>{
            'Contract', 'Opportunity', 'VirtualAccount__c'
    };

    /**
     * @param paramMap          모두싸인 Draft 호출을 위한 파라미터 정보
     *                          1. [v] templateTitle : 모두싸인 Template의 Title명 (ex, [샘플] 개인정보 수집 이용 동의서)
     *                          2. object : 모두싸인 문서에 들어갈 데이터 Object명 (ex, Account)
     *                          3. [v] recordId : 모두싸인 문서에 들어갈 데이터 Id
     *                          4. whereField : Custom Where의 Field조건 추가. ver1.4
     * @return                  Map<String, Object> Value
     * @description             Return Value Description
     *                          1. key : code, value : Boolean
     *                          2. key : message, value : String
     *                          3. (필수값 x) key : statusCode, value : String
     *                          4. (필수값 x) key : url, value : String
     */
    @AuraEnabled
    public static Map<String, Object> doCallOutDraft(Map<String, String> paramMap) {
        /*
            1. Template Draft에 필요한 Object Record Get
            2. 임베디드 초안 Body 생성
            3. Embeded 초안 URL에 대한 값을 Return
        */
        Map<String, Object> resultMap = new Map<String, Object>();
        resultMap.put('code', true);
        resultMap.put('message', 'Great. you\'ve got ' + Integer.valueOf(Math.random()*10) + ' points');

        String templateTitle = paramMap.get('templateTitle');
        String recordId = paramMap.get('recordId');
        String whereField = paramMap.containsKey('whereField') ? String.valueOf(paramMap.get('whereField')) : 'Id';
        String sObjectType = paramMap.containsKey('object') ? paramMap.get('object') : ((Id) recordId).getSobjectType().getDescribe().getName();

        try {
            // 1. Template에 필요한 Object Record Get
            Template__c template = [SELECT Id, Name, Body__c, TemplateId__c FROM Template__c WHERE Name = :templateTitle];
            List<String> fieldList = getTemplateFields(template.Body__c);

            SObject data = fetchRecordData(fieldList, sObjectType, whereField, recordId);
            System.debug(data);

            // 2. 임베디드 초안 Body 생성
            Map<String, Object> bodyMap = new Map<String, Object>();
            Map<String, Object> documentMap = new Map<String, Object>();

            List<Map<String, Object>> inputMapList = buildInputMapList(data, fieldList);
            inputMapList.addAll(CommonUtilCustomController.getConfigMapList(templateTitle));    // 파라미터로 받은 Title명을 기준으로 ConfigList Get

            documentMap.put('requesterInputMappings', inputMapList);
            bodyMap.put('document', documentMap);
            bodyMap.put('templateId', template.TemplateId__c);
            System.debug(JSON.serializePretty(bodyMap));

            // 3. 임베디드 초안 URL에 대한 값을 Return
            IF_Util ifUtil = new IF_Util(DRAFT_IF_ID);
            HttpResponse response = ifUtil.webCallout(JSON.serialize(bodyMap));
            if (HttpCallOutConsts.SUCCESS_CODES.contains(response.getStatusCode())) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                String url = responseMap.get('embeddedUrl') + '&mode=preview';
                resultMap.put('url', url);
                resultMap.put('statusCode', response.getStatusCode());
                resultMap.put('message', response.getBody());
            } else {
                resultMap.put('code', false);
                resultMap.put('statusCode', response.getStatusCode());
                resultMap.put('message', response.getBody());
            }
        } catch(Exception e) {
            resultMap.put('code', false);
            resultMap.put('message', e.getMessage());
            System.debug(e.getStackTraceString());
        }
        System.debug(resultMap);

        return resultMap;
    }

    /**
     * @param paramMap          모두싸인 Draft 호출을 위한 파라미터 정보
     *                          1. [v] templateTitle : 모두싸인 Template의 Title명 (ex, [샘플] 개인정보 수집 이용 동의서)
     *                          2. [v] object : 모두싸인 문서에 들어갈 데이터 Object명 (ex, Account)
     *                          3. [v] recordId : 모두싸인 문서에 들어갈 데이터 Id
     *                          4. documentTitle : 모두싸인 문서명 (ex, 개인정보 동의서)
     *                          5. documentPW : 모두싸인 문서의 PW (6자리 이상. ex, 123456)
     *                          6. externalId : 업무 Object Id(Lookup)
     *                          7. [v] infoMapList : 모두싸인 서명받을 사용자정보 List
     *                              7-1. objectName : Object명
     *                              7-2. [v] recordId : Object Record Id
     *                              7-3. [v] role :문서 참여자 역할. 모두싸인 Template의 역할중 하나로 지정
     *                              7-4. validDuration : 문서 유효기간 (기준 : 일). Default 14일          // 미사용
     *                              7-5. sendType : 문서 수신타입 (ex, 'email', 'kakao'). Default kakao
     *                              7-6. locale :문서 Locale. Default 'ko'
     *                          8. whereField : Custom Where의 Field조건 추가. ver1.4
     *                          9. apexClass : 모두싸인 후처리 Process 상속Class 구현 ver1.7
     * @return                  Map<String, Object> Value
     * @description             Return Value Description
     *                          1. key : code, value : Boolean
     *                          2. key : message, value : String
     *                          3. (필수값 x) key : statusCode, value : String
     *                          4. (필수값 x) key : url, value : String
     *                          5. (필수값 x) key : documentId, value : String
     */
    // 신규 ObjectType(recordId)추가시 TaskFieldSet 만드시오. CommonUtilCustomController.createTask 참조
    @AuraEnabled
    public static Map<String, Object> doCallOutSignRequestByTemplate(Map<String, Object> paramMap) {
        /*
            1. 문서에 필요한 Object Record Get
            2. Record Data, param을 통한 Body 생성
            3. 서명요청 API호출 및 Response 저장
        */
        Map<String, Object> resultMap = new Map<String, Object>();
        resultMap.put('code', true);
        resultMap.put('message', 'Great. you\'ve got ' + Integer.valueOf(Math.random()*10) + ' points');

        String templateTitle = String.valueOf(paramMap.get('templateTitle'));
        String recordId = String.valueOf(paramMap.get('recordId'));
        String whereField = paramMap.containsKey('whereField')
                ? String.valueOf(paramMap.get('whereField'))
                : 'Id';
        String sObjectType = paramMap.containsKey('object')
                ? String.valueOf(paramMap.get('object'))
                : ((Id) recordId).getSobjectType().getDescribe().getName();

        // Custom 선택값
        String title = String.valueOf(paramMap.get('documentTitle'));
        String documentPW = String.valueOf(paramMap.get('documentPW'));
        String externalId = String.valueOf(paramMap.get('externalId'));
        String apexClass = String.valueOf(paramMap.get('apexClass'));

        // 서명요청 List
        List<Map<String, Object>> infoMapList = new List<Map<String, Object>>();
        List<Object> objectList = (List<Object>) paramMap.get('infoMapList');
        for(Object obj : objectList) {
            Map<String, Object> infoMap = new Map<String, Object>();

            Map<Object, Object> objMap = (Map<Object, Object>) obj;
            for(Object key : objMap.keySet()) {
                if(key instanceof String) infoMap.put(String.valueOf(key), objMap.get(key));
            }

            infoMapList.add(infoMap);
        }

        Map<String, String> infoMap = new Map<String, String>{
                'id' => CommonUtilCustomController.parseIFId(InterfaceSAP.DFLT),
                'title' => templateTitle,
                'status' => 'FAIL'
        };

        APIDocument__c doc = new APIDocument__c();
        try {
            // 1. 문서에 필요한 Object Record Get
            Template__c template = [SELECT Id, Name, Body__c, TemplateId__c FROM Template__c WHERE Name = :templateTitle];
            List<String> fieldList = getTemplateFields(template.Body__c);

            SObject data;
            if(!fieldList.isEmpty()) data = fetchRecordData(fieldList, sObjectType, whereField, recordId);
            System.debug(data);

            // 2. Record Data, param을 통한 Body 생성
            Map<String, Object> bodyMap = new Map<String, Object>();
            Map<String, Object> documentMap = new Map<String, Object>();

            List<Map<String, Object>> inputMapList = buildInputMapList(data, fieldList);
            inputMapList.addAll(CommonUtilCustomController.getConfigMapList(templateTitle));    // 파라미터로 받은 Title명을 기준으로 ConfigList Get
            List<Map<String, Object>> participantMapList = buildParticipantMapList(infoMapList);
            System.debug('\n' + JSON.serializePretty(participantMapList));

            documentMap.put('requesterInputMappings', inputMapList);
            documentMap.put('participantMappings', participantMapList);
            documentMap.put('title', templateTitle);

            if (title != null) documentMap.put('title', title);
            if (documentPW != null) documentMap.put('fileOpenPassword', documentPW);

            bodyMap.put('document', documentMap);
            bodyMap.put('templateId', template.TemplateId__c);
            System.debug(JSON.serializePretty(bodyMap));

            // 3. 서명요청 API호출 및 Response 저장
            IF_Util ifUtil = new IF_Util(REQUEST_TEMPLATE_IF_ID);
            HttpResponse response = ifUtil.webCallout(JSON.serialize(bodyMap));
            if (HttpCallOutConsts.SUCCESS_CODES.contains(response.getStatusCode())) {
                String objectType = Id.valueOf(recordId).getSobjectType().getDescribe().getName();

                // ver1.4 ExpiredDate 필드 추가, Destination 추가
                Integer expiredDuration = 0;
                List<String> destinations = new List<String>();
                for(Map<String, Object> participantMap : participantMapList) {
                    Integer duration = Integer.valueOf(participantMap.get('signingDuration'));
                    expiredDuration = Math.max(expiredDuration, duration);

                    Map<String, Object> signingMap = (Map<String, Object>) participantMap.get('signingMethod');
                    destinations.add(String.valueOf(signingMap.get('value')));
                }

                doc = createDocument(response.getBody());
                doc.Template__c = template.Id;
                doc.Destination__c = String.join(destinations, ',');
                doc.ExpiredDate__c = Date.today().addDays(expiredDuration / (24 * 60));
                // ver1.7 모두싸인 후처리 Process 상속Class 구현
                doc.AfterProcessClass__c = apexClass;
                
                if(externalId != null) {
                    String externalObjectType = ((Id) externalId).getSobjectType().getDescribe().getName();

                    // Oppty에서 하는 모두사인 추가
                    doc.ExternalId__c = externalId;
                    if('Contract'.equals(externalObjectType)) doc.Contract__c = externalId;
                    if('Opportunity'.equals(externalObjectType)) doc.Opportunity__c = externalId;
                }

                if(TASK_LIST.contains(objectType)) insert CommonUtilCustomController.createTask(recordId, 'ModuSign', title);

                resultMap.put('documentId', doc.Id);
                resultMap.put('statusCode', response.getStatusCode());
                resultMap.put('message', response.getBody());
            } else {
                resultMap.put('code', false);
                resultMap.put('statusCode', response.getStatusCode());
                resultMap.put('message', response.getBody());
            }
        } catch(AuraHandledException e) {
            infoMap.put('responseBody', '해당 번호는 화이트리스트에 포함되지 않습니다.');
            doc = createDocument(JSON.serialize(infoMap));

            resultMap.put('code', false);
            resultMap.put('message', e.getMessage());
        } catch(Exception e) {
            infoMap.put('responseBody', '관리자에게 문의해주세요.');
            doc = createDocument(JSON.serialize(infoMap));

            resultMap.put('code', false);
            resultMap.put('message', e.getMessage());
        } finally {
            insert doc;
        }
        System.debug(resultMap);

        return resultMap;
    }

    @AuraEnabled
    public static Map<String, Object> doCallOutSignRequestByPDF(IF_DTO.SigningRequestByPDF requestDTO, String externalId) {
        return doCallOutSignRequestByPDF(requestDTO, externalId, null);
    }

    /**
     * @param requestDTO        PDF 요청을 위한  Wrapper
     * @param externalId        Document Update를위한 ExternalId
     * @return                  Map<String, Object> Value
     * @description             Return Value Description
     *                          1. key : code, value : Boolean
     *                          2. key : message, value : String
     *                          3. (필수값 x) key : statusCode, value : String
     *                          4. (필수값 x) key : url, value : String
     *                          5. (필수값 x) key : documentId, value : String
     */
    // 신규 ObjectType(recordId)추가시 TaskFieldSet 만드시오. CommonUtilCustomController.createTask 참조
    public static Map<String, Object> doCallOutSignRequestByPDF(IF_DTO.SigningRequestByPDF requestDTO, String externalId, String apexClass) {
        /*
            1. VF Page. PDF파일 생성
            2. DTO 객체 생성 및 PDF파일 RequestBody set
                - InvalidFileException일경우. LWC에서 파일 압축필요
        */
        Map<String, Object> resultMap = new Map<String, Object>();
        resultMap.put('code', true);
        resultMap.put('message', 'Great. you\'ve got ' + Integer.valueOf(Math.random()*10) + ' points');

        Map<String, String> infoMap = new Map<String, String>{
                'id' => CommonUtilCustomController.parseIFId(InterfaceSAP.DFLT),
                'title' => requestDTO.title,
                'status' => 'FAIL'
        };

        APIDocument__c doc = new APIDocument__c();
        try {
            // 서명요청 API호출 및 Response 저장
            IF_Util ifUtil = new IF_Util(REQUEST_PDF_IF_ID);
            HttpResponse response = ifUtil.webCallout(JSON.serialize(requestDTO, true));
            if (HttpCallOutConsts.SUCCESS_CODES.contains(response.getStatusCode())) {
                String objectType = Id.valueOf(externalId).getSobjectType().getDescribe().getName();

                // ver1.4 ExpiredDate 필드 추가, Destination 추가
                Integer expiredDuration = 0;
                List<String> destinations = new List<String>();
                for(IF_DTO.Participant participant : requestDTO.participants) {
                    Integer duration = Integer.valueOf(participant.signingDuration);
                    expiredDuration = Math.max(expiredDuration, duration);

                    destinations.add(participant.signingMethod.value);
                }

                doc = createDocument(response.getBody());
                if(externalId != null) doc.ExternalId__c = doc.Contract__c = externalId;
                if(externalId != null && 'Contract'.equals(objectType)) doc.Contract__c = externalId;
                if(externalId != null && 'Opportunity'.equals(objectType)) doc.Opportunity__c = externalId;
                // ver1.7 모두싸인 후처리 Process 상속Class 구현
                doc.AfterProcessClass__c = apexClass;

                doc.Destination__c = String.join(destinations, ',');
                doc.ExpiredDate__c = Date.today().addDays(expiredDuration / (24 * 60));

                if(TASK_LIST.contains(objectType)) insert CommonUtilCustomController.createTask(externalId, 'ModuSign', requestDTO.title);

                resultMap.put('documentId', doc.Id);
                resultMap.put('statusCode', response.getStatusCode());
                resultMap.put('message', response.getBody());
            } else {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String errorType = String.valueOf(responseMap.get('type'));
                System.debug(errorType);    // https://developers.modusign.co.kr/docs/%EC%97%90%EB%9F%AC

                resultMap.put('code', false);
                resultMap.put('statusCode', response.getStatusCode());
                resultMap.put('message', response.getBody());
            }
        } catch(AuraHandledException e) {
            infoMap.put('responseBody', '해당 번호는 화이트리스트에 포함되지 않습니다.');
            doc = createDocument(JSON.serialize(infoMap));

            resultMap.put('code', false);
            resultMap.put('message', e.getMessage());
        } catch(Exception e) {
            infoMap.put('responseBody', '관리자에게 문의해주세요.');
            doc = createDocument(JSON.serialize(infoMap));

            resultMap.put('code', false);
            resultMap.put('message', e.getMessage());
        } finally {
            insert doc;
        }
        System.debug(resultMap);

        return resultMap;
    }

    /**
     * @param docId         Document Id를 통한 URLtoPDF
     * @param docStatus     변경될 Status
     * @param isLogInsert   로그 Insert여부
     * @description         서명이 완료된 문서만 유효한 PDF생성.
     *                      Return Value Description
     *                          1. key : code, value : Boolean
     *                          2. key : message, value : String
     *                          3. (필수값 x) key : statusCode, value : String
     *                          4. (필수값 x) key : url, value : String
     */
    // ver1.2 Webhook을 통한 PDF저장
    public static void doCallOutURLtoPDF(String docId, String docStatus, Boolean isLogInsert) {
        String status;
        String errorCode;
        String responseBody;
        Datetime responseTime;
        Datetime requestTime = Datetime.now();

        APIDocument__c doc = [SELECT Id, Name, FileName__c, Contract__c, Status__c, ExternalId__c FROM APIDocument__c WHERE Id =: docId];
        try {
            IF_Util ifUtil = new IF_Util(DOC_IF_ID);
            HttpResponse docResponse = ifUtil.webCallout(null, new List<String>{ doc.Name });
            if (HttpCallOutConsts.SUCCESS_CODES.contains(docResponse.getStatusCode())) {
                status = 'SUCCESS';
                responseBody = docResponse.getBody();
                responseTime = Datetime.now();

                Map<String, Object> docResponseMap = (Map<String, Object>) JSON.deserializeUntyped(docResponse.getBody());
                Map<String, Object> fileMap = (Map<String, Object>) docResponseMap.get('file');

                // URL to PDF 변환
                String url = String.valueOf(fileMap.get('downloadUrl'));
                System.debug(url);
                Blob fileBlob = IF_Util.callURLtoPDF(url);

                // PDF 저장
                String ownerId = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1].Id;
                if(Test.isRunningTest()) ownerId = UserInfo.getUserId();
                List<ContentVersion> contentList = new List<ContentVersion>();

                String fileName = doc.FileName__c;
                if('COMPLETED'.equals(docStatus)) fileName += '(최종본)';

                ContentVersion file = new ContentVersion();
                file.Title = fileName;
                file.PathOnClient = doc.FileName__c + '.pdf';
                file.VersionData = fileBlob;
                file.IsMajorVersion = true;
                file.OwnerId = ownerId;
                file.FirstPublishLocationId = docId;
                contentList.add(file);

                ContentVersion file2 = new ContentVersion();
                file2.Title = fileName;
                file2.PathOnClient = doc.FileName__c + '.pdf';
                file2.VersionData = fileBlob;
                file2.IsMajorVersion = true;
                file2.OwnerId = ownerId;
                file2.FirstPublishLocationId = doc.ExternalId__c;
                contentList.add(file2);

                // 0225 영문 PDF 저장 추가
                // ver1.6 영업기회 모두싸인 호출 대응
                System.debug(docStatus);
                System.debug(doc.FileName__c);
                System.debug(doc.Contract__c);
                if('COMPLETED(CUSTOMER)'.equals(docStatus) && doc.FileName__c.contains('계약서') && doc.Contract__c != null) {
                    /*
                    // 1. 파일 직접 생성하기 -> 도메인이 내부 도메인으로 생성되서 실패
                    PageReference pdfPage = Page.ModusignPDFTemplate; // Visualforce 페이지 이름
                    pdfPage.getParameters().put('recordId', doc.Contract__c);
                    pdfPage.getParameters().put('selectedOption', 'contract');
                    pdfPage.getParameters().put('language', 'EN');

                    // PDF 생성
                    Blob pdfBlob = pdfPage.getContentAsPDF();
                    System.debug('pdfBlob.size() ::: ' + pdfBlob.size());
                    */

                    // 2. 게스트 URL로 요청하기
                    String siteUrl = Label.GuestHost + '/apex/ModusignPDFTemplate?recordId=' + doc.ExternalId__c + '&selectedOption=contract&language=EN';

                    HttpRequest req = new HttpRequest();
                    req.setEndpoint(siteUrl);
                    req.setMethod('GET');

                    Http http = new Http();
                    HttpResponse res = !Test.isRunningTest() ? http.send(req) : new HttpResponse();

                    // PDF Blob 생성
                    Blob pdfBlob = !Test.isRunningTest() ? res.getBodyAsBlob() : Blob.valueOf('');
                    System.debug('pdfBlob.size() ::: ' + pdfBlob.size());

                    ContentVersion file3 = new ContentVersion();
                    file3.Title = '계약서(ENG)';
                    file3.PathOnClient = '계약서(ENG).pdf';
                    file3.VersionData = pdfBlob;
                    file3.IsMajorVersion = true;
                    file3.OwnerId = ownerId;
                    file3.FirstPublishLocationId = doc.ExternalId__c;
                    contentList.add(file3);
                }

                insert contentList;
            } else {
                status = 'ERROR';
                responseBody = docResponse.getBody();
                errorCode = String.valueOf(docResponse.getStatusCode());
            }
        } catch(Exception e) {
            status = 'ERROR';
            responseBody = e.getMessage();

            System.debug(e.getStackTraceString());
            System.debug(e.getMessage());
        } finally {
            // HTTP CallOut 연속호출 영향으로 수동 IF_LOG Insert
            IF_DTO.LogWrapper objLogWrapper = new IF_DTO.LogWrapper();
            objLogWrapper.requestBody = 'URL to PDF. APIDocument__c : ' + doc.Id;
            objLogWrapper.requestTime = requestTime;
            objLogWrapper.status = status;
            objLogWrapper.responseTime = responseTime;
            objLogWrapper.responseBody = responseBody;
            objLogWrapper.errorCode = errorCode;
            objLogWrapper.logType = IF_DTO.LOG_TYPE.MODUSIGN_OUT;

            if(isLogInsert) CommonUtilCustomController.setLog(objLogWrapper);
        }
    }

    /**
     * @param bodyMap           모두싸인 문서취소 설정Map
     *                          1. message : 모두싸인 서명취소요청의 사유
     *                          2. accessibleByParticipant :
     * @param documentId        모두싸인 문서취소 Document Id
     * @return                  HttpResponse
     */
    public static HttpResponse doCallOutCancel(Map<String, Object> bodyMap, String documentId) {
        // ver1.5 문서취소 API 함수
        if(!bodyMap.containsKey('message')) bodyMap.put('message', '문서의 유효성 만료. 관리자에게 문의하세요');
        if(!bodyMap.containsKey('accessibleByParticipant')) bodyMap.put('accessibleByParticipant', false);

        IF_Util ifUtil = new IF_Util(CANCEL_IF_ID);
        return ifUtil.webCallout(JSON.serialize(bodyMap), new List<String>{
                documentId, 'cancel'
        });
    }

    /* ------------------------------------------------------------------------------------------------------------------------- */
    /* ------------------------------------------------------------------------------------------------------------------------- */
    /* ------------------------------------------------------------------------------------------------------------------------- */

    /**
     * @param fieldList         Record Data의 필드 List
     * @param sObjectType       Record Data의 Object
     * @param whereField        Record Data의 WhereField ver1.4 Custom Where의 Field조건 추가
     * @param recordId          Record Data의 Id
     * @return                  SObject
     */
    public static SObject fetchRecordData(List<String> fieldList, String sObjectType, String whereField, String recordId) {
        List<String> selectFieldList = new List<String>();
        for(String field : fieldList) {
            // ver1.3 DataLabel Copy 처리
            // ex, ModuSign Template의 DataLabel명 : Copy_fm_Segment1__c2 / _Copy_Quotes.Name2
            if(field.toUpperCase().startsWith('COPY')) continue;

            // Subquery regex.DataLabel Input Copy건은 SELECT 대상에서 제외
            if(field.startsWith('(')) {
                String subQuery = field.toUpperCase();

                field = subQuery.replaceAll(',\\s*COPY[^,]*(?=,|\\sFROM)', '');
            }
            selectFieldList.add(field);
        }

        String selectField = String.join(selectFieldList, ', ');
        String query = CommonUtilController.buildQuery(
                selectField,
                sObjectType,
                CommonUtilController.buildWhereConditions(new Map<String, Object>{ whereField => recordId })
        );

        return Database.query(query);
    }

    /**
     * @param body          body Text
     * @return              List<String> value(fieldList)
     */
    private static List<String> getTemplateFields(String body) {
        List<String> fieldList = new List<String>();
        Map<String, String> subQueryMap = new Map<String, String>();

        Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(body);
        List<Object> requesterInputs = (List<Object>) parsedJson.get('requesterInputs');

        for (Object input : requesterInputs) {
            Map<String, Object> fieldData = (Map<String, Object>) input;

            // dataLabel의 값이 Custom으로 시작하지 않는 데이터들만 Put (Record의 Field들)
            if (!String.valueOf(fieldData.get('dataLabel')).toUpperCase().startsWith('CUSTOM')) {
                String field = String.valueOf(fieldData.get('dataLabel'));

                // ver1.3 DataLabel Copy 처리
                // ex, ModuSign Template의 DataLabel명 : _Quotes.Name [기본], _Copy_Quotes.Name2 [Copy 추가]
                if (field.startsWith('_')) {
                    String subQueryField = field.substring(1);      // '_' 제거
                    String[] parts = subQueryField.split('\\.');    // SubQuery 형식으로 분리
                    String relatedObject = parts[0];                // ex, 'Quotes'. 'Copy_Quotes'
                    String relatedField = parts[1];                 // ex, 'Name'

                    if(relatedObject.toUpperCase().contains('COPY')) {
                        relatedObject = relatedObject.substring(5, relatedObject.length());
                        relatedField = relatedField.substring(0, relatedField.length()-1);
                    }

                    String fields = subQueryMap.containsKey(relatedObject)
                            ? subQueryMap.get(relatedObject) + ',' + relatedField
                            : 'SELECT ' + relatedField;
                    subQueryMap.put(relatedObject, fields);
                } else {
                    // 단순 필드 처리
                    fieldList.add(field);
                }
            }
        }

        // SubQuery 변환
        for (String relatedObject : subQueryMap.keySet()) {
            String subQuery = subQueryMap.get(relatedObject) + ' FROM ' + relatedObject;

            fieldList.add('(' + subQuery + ')');
        }

        return fieldList;
    }

    /**
     * @param data              Record의 데이터
     * @param fieldList         Record의 필드 List
     * @return                  List<Map<String, Object>>
     * @description             requesterInputMappings Map의 데이터 Setting
     */
    private static List<Map<String, Object>> buildInputMapList(SObject data, List<String> fieldList) {
        List<Map<String, Object>> inputMapList = new List<Map<String, Object>>();

        for(String field : fieldList) {

            if (field.startsWith('(')) {
                // SubQuery 처리
                List<Map<String, Object>> subQueryList = handleSubQuery(data, field);

                inputMapList.addAll(subQueryList);
            } else {
                // 일반 필드 처리
                Map<String, Object> inputMap = new Map<String, Object>();

                // Lookup필드를 위한 재귀함수 호출
                Object value = CommonUtilCustomController.fetchValueRecur(data, field);
                inputMap.put('dataLabel', field);
                if(value != null)   { inputMap.put('value', value); }
                else                { inputMap.put('value', ''); }

                inputMapList.add(inputMap);
            }
        }
        return inputMapList;
    }

    /**
     * @param record        SObject 데이터
     * @param subQuery      SubQuery (ex, [SELECT Id,Name FROM Quotes])
     * @description         SubQuery 처리 함수
     * @return              List<Map<String, Object>> Type의 SubQuery
     */
    private static List<Map<String, Object>> handleSubQuery(SObject record, String subQuery) {
        // SubQuery 문자열 파싱
        subQuery = subQuery.substring(1, subQuery.length() - 1);
        String[] subQueryParts = subQuery.split(' FROM ');
        String subQueryFields = subQueryParts[0].replace('SELECT ', '');
        String subQueryObject = subQueryParts[1].trim();

        // SubQuery Records Get
        List<SObject> subRecords = record.getSObjects(subQueryObject);

        // TODO : 다중의 SubQuery Record들 처리 불가함. 필요할 경우 고려해야함
        // SubQuery의 필드 처리
        List<Map<String, Object>> subQueryList = new List<Map<String, Object>>();
        for (SObject subRecord : subRecords) {
            for (String field : subQueryFields.split(',')) {
                Map<String, Object> relatedMap = new Map<String, Object>();

                Object value = CommonUtilCustomController.fetchValueRecur(subRecord, CommonUtilCustomController.modifyField(field));
                relatedMap.put('dataLabel', '_' + subQueryObject + '.' + field);
                relatedMap.put('value', value);

                subQueryList.add(relatedMap);
            }
        }

        return subQueryList;
    }

    /**
     * @param infoMapList       서명받을 사람의 정보List
     * @return                  List<Map<String, Object>> value
     * @description             서명요청 API를 위한 participant 데이터 Setting
     */
    private static List<Map<String, Object>> buildParticipantMapList(List<Map<String, Object>> infoMapList) {
        List<Map<String, Object>> participantMapList = new List<Map<String, Object>>();

        // key : Object명. Value : List<Map<String, Object>>
        //                  Map<String, Object> | key : recordId, value : Map<String, Object>
        //                                                              key : recordId, value : Map<String, Object>
        Map<String, List<Map<String, Object>>> objectNameInfoListMap = new Map<String, List<Map<String, Object>>>();
        System.debug('\n' + JSON.serializePretty(infoMapList));
        for(Map<String, Object> infoMap : infoMapList) {
            String recordId = String.valueOf(infoMap.get('recordId'));
            String sObjectType = infoMap.containsKey('objectName')
                    ? String.valueOf(infoMap.get('objectName'))
                    : ((Id) recordId).getSobjectType().getDescribe().getName();

            List<Map<String, Object>> objectNameInfoList = objectNameInfoListMap.containsKey(sObjectType)
                    ? objectNameInfoListMap.get(sObjectType)
                    : new List<Map<String, Object>>();

            objectNameInfoList.add(infoMap);
            objectNameInfoListMap.put(sObjectType, objectNameInfoList);
        }

        for(String sObjectType : objectNameInfoListMap.keySet()) {
            List<Map<String, Object>> objectInfoList = objectNameInfoListMap.get(sObjectType);

            Map<String, Map<String, Object>> objectInfoMap = new Map<String, Map<String, Object>>();
            for(Map<String, Object> objectInfo : objectInfoList) {
                String recordId = String.valueOf(objectInfo.get('recordId'));

                objectInfoMap.put(recordId, objectInfo);
            }
            System.debug(objectInfoMap);

            // For문안에서 SQL을 태웠다고 생각하지 마시오.... Type별로만 한번씩 태움
            switch on sObjectType.toUpperCase() {
                when 'ACCOUNT' {
                    Map<Id, Account> accountMap = new Map<Id, Account> ([
                            SELECT Id, Name, PersonMobilePhone, Phone, fm_TargetMobilePhone__c
                            FROM Account
                            WHERE Id IN :objectInfoMap.keySet()
                    ]);
                    for(String accountId : objectInfoMap.keySet()) {
                        Account acc = accountMap.get(accountId);

                        Map<String, Object> infoMap = objectInfoMap.get(accountId);
                        String sendType = String.valueOf(infoMap.get('sendType')).toUpperCase();
                        String sendTypeValue;

                        String typeCase = sendType != null
                                ? 'EMAIL'.equals(sendType)
                                    ? 'EMAIL'
                                    : 'KAKAO'
                                : 'KAKAO';

                        String targetMobilePhone = acc.PersonMobilePhone != null
                            ? acc.PersonMobilePhone
                            : acc.Phone != null
                                ? acc.Phone
                                : '';

                        switch on typeCase {
                            // TODO : 이메일 필드 추가필요
                            when 'EMAIL' { sendTypeValue = acc.fm_TargetMobilePhone__c.replaceAll('-', ''); }
//                            when 'KAKAO' { sendTypeValue = acc.PersonMobilePhone.replaceAll('-', ''); }
//                            when 'KAKAO' { sendTypeValue = acc.Phone.replaceAll('-', ''); }
                            when 'KAKAO' { sendTypeValue = acc.fm_TargetMobilePhone__c.replaceAll('-', ''); }
                        }

                        infoMap.put('name', acc.Name);
                        infoMap.put('sendType', sendType);
                        infoMap.put('sendTypeValue', sendTypeValue);

                        objectInfoMap.put(accountId, infoMap);
                    }
                }
                when 'USER' {
                    Map<Id, User> userMap = new Map<Id, User> ([
                            SELECT Id, Name, MobilePhone, Email
                            FROM User
                            WHERE Id IN :objectInfoMap.keySet()
                    ]);
                    for(String userId : objectInfoMap.keySet()) {
                        User user = userMap.get(userId);

                        Map<String, Object> infoMap = objectInfoMap.get(userId);
                        String sendType = String.valueOf(infoMap.get('sendType')).toUpperCase();
                        String sendTypeValue;

                        String typeCase = sendType != null
                                ? 'EMAIL'.equals(sendType)
                                    ? 'EMAIL'
                                    : 'KAKAO'
                                : 'KAKAO';

                        switch on typeCase {
                            when 'EMAIL' { sendTypeValue = user.Email; }
                            when 'KAKAO' { sendTypeValue = user.MobilePhone.replaceAll('-', ''); }
                        }

                        infoMap.put('name', user.Name);
                        infoMap.put('sendType', sendType);
                        infoMap.put('sendTypeValue', sendTypeValue);

                        objectInfoMap.put(userId, infoMap);
                    }
                }
                when 'CONTACT' {
                    Map<Id, Contact> contactMap = new Map<Id, Contact> ([
                            SELECT Id, Name, MobilePhone, Email, RealDriver__c, RealDriverMobile__c
                            FROM Contact
                            WHERE Id IN :objectInfoMap.keySet()
                    ]);
                    for(String contactId : objectInfoMap.keySet()) {
                        Contact contact = contactMap.get(contactId);

                        Map<String, Object> infoMap = objectInfoMap.get(contactId);
                        String sendType = String.valueOf(infoMap.get('sendType')).toUpperCase();
                        String customerType = String.valueOf(infoMap.get('customerType'));

                        String name;
                        String sendTypeValue;
                        switch on customerType.toUpperCase() {
                            when 'OWNER' {
                                name = contact.Name;
                                sendTypeValue = contact.MobilePhone;
                            }
                            when 'REALDRIVER' {
                                name = contact.RealDriver__c;
                                sendTypeValue = contact.RealDriverMobile__c;
                            }
                        }

                        String typeCase = sendType != null
                                ? 'EMAIL'.equals(sendType)
                                        ? 'EMAIL'
                                        : 'KAKAO'
                                : 'KAKAO';

                        switch on typeCase {
                            when 'EMAIL' { sendTypeValue = contact.Email; }
                            when 'KAKAO' { sendTypeValue = sendTypeValue.replaceAll('-', ''); }
                        }

                        infoMap.put('name', name);
                        infoMap.put('sendType', sendType);
                        infoMap.put('sendTypeValue', sendTypeValue);

                        objectInfoMap.put(contactId, infoMap);
                    }
                }
            }

            for(String recordId : objectInfoMap.keySet()) {
                Map<String, Object> participantMap = new Map<String, Object>();
                Map<String, Object> infoMap = objectInfoMap.get(recordId);

                String role = String.valueOf(infoMap.get('role'));
                String phoneNumber = String.valueOf(infoMap.get('sendTypeValue'));
                // 0307 고객은 말일 자정에 만료, Internal은 최대값 1년
                Integer documentDuration = '고객'.equals(role) ? getSmallestValueDefault() : 525600;

                Map<String, Object> requestInfoMap = new Map<String, Object>();
                requestInfoMap.put('type', infoMap.get('sendType'));

                // 테스트 중 사고 방지를 위해 번호고정
//                requestInfoMap.put('value', '01029323033');
//                requestInfoMap.put('value', '01098868298');
                requestInfoMap.put('value', phoneNumber);
                // WhiteList ON_OFF
//                if(!Test.isRunningTest() && !MODUSIGN_WHITE_LIST.contains(phoneNumber)) throw new AuraHandledException('The destination number ' + phoneNumber + ' is not in the white list.');

                participantMap.put('name', infoMap.get('name'));
                participantMap.put('excluded', false);
                participantMap.put('signingDuration', documentDuration);
                participantMap.put('signingMethod', requestInfoMap);
                participantMap.put('role', infoMap.get('role'));
                participantMap.put('locale', infoMap.containsKey('locale')
                        ? infoMap.get('locale')
                        : DEFAULT_LOCALE);

                System.debug('\n' + JSON.serializePretty(participantMap));
                participantMapList.add(participantMap);
            }
            System.debug('\n' + JSON.serializePretty(participantMapList));
        }
        return participantMapList;
    }

    // 서명요청 API Response값 저장
    public static APIDocument__c createDocument(String responseBody) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        String documentId = String.valueOf(responseMap.get('id'));
        String fileName = String.valueOf(responseMap.get('title'));
        String status = String.valueOf(responseMap.get('status'));
        String body = responseMap.containsKey('responseBody')
                ? String.valueOf(responseMap.get('responseBody'))
                : responseBody;

        APIDocument__c doc = new APIDocument__c();
        doc.Name = documentId;
        doc.Status__c = status;
        doc.FileName__c = fileName;
        doc.Body__c = body;
        doc.RecordTypeId = RECORDTYPE_MODUSIGN;

        return doc;
    }

    public static Integer getSmallestValueDefault() {
        Datetime currentTime = Datetime.now();
        Datetime monthTime = getMonthTime(currentTime); // 다음 달 자정 계산

        // 현재 시간과 다음 달 자정까지의 분 차이 계산
        Long monthCurrentDiffSeconds = monthTime.getTime() - currentTime.getTime();
        Long monthCurrentDiffMinutes = monthCurrentDiffSeconds / 60000; // 밀리초 > 분 변환

        return Integer.valueOf(monthCurrentDiffMinutes);
    }

    // 미사용
    public static Integer getSmallestValue(Integer paramTime) {
        // Default값 14일
        Integer documentDuration = paramTime != null
                ? paramTime * 24 * 60
                : 20160;

        Datetime currentTime = Datetime.now();
        Datetime monthTime = getMonthTime(currentTime); // 다음 달 자정 계산

        // 현재 시간과 다음 달 자정까지의 분 차이 계산
        Long monthCurrentDiffSeconds = monthTime.getTime() - currentTime.getTime();
        Long monthCurrentDiffMinutes = monthCurrentDiffSeconds / 60000; // 밀리초 > 분 변환

        // 14일과 비교하여 더 작은 값 계산
        Integer smallestValue = Math.min(documentDuration, Integer.valueOf(monthCurrentDiffMinutes));

        System.debug('다음 달 자정까지 남은 시간(분) ::: ' + Integer.valueOf(monthCurrentDiffMinutes));
        System.debug('리턴 값 ::: ' + smallestValue);
        return smallestValue;
    }
    
    // 다음 달 자정을 계산하는 헬퍼 함수
    private static Datetime getMonthTime(Datetime currentTime) {
        // 현재 날짜에서 월을 1 증가시키고, 해당 월의 1일 자정(00:00:00)으로 설정
        Integer nextMonth = currentTime.month() + 1;
        Integer year = currentTime.year();

        // 다음 달이 12월일 경우, 1월로 변경하고 년도를 증가시킴
        if (nextMonth > 12) {
            nextMonth = 1;
            year++;
        }

        // 해당 월의 1일 자정을 설정
        return Datetime.newInstance(year, nextMonth, 1, 0, 0, 0);
    }
}