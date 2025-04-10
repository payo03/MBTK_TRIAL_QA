/**
* @Author            : payo03@solomontech.net
* @Description 		 : 카카오톡 Interface
* @Target            : 카카오톡 공통모듈. sampleLWC 참조
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-26      payo03@solomontech.net           Created
  1.1      2025-01-08      payo03@solomontech.net           Casting 변환 오류해결
  1.2      2025-01-13      payo03@solomontech.net           Custom Where의 Field조건 추가
*/
public with sharing class InterfaceKakao {

    private static final String RECORDTYPE_KAKAO = Schema.SObjectType.APIDocument__c.getRecordTypeInfosByDeveloperName().get('KAKAO').getRecordTypeId();

    private final static String HEROKU_KAKAO_SAMPLE = 'HEROKU_KAKAO_000';
    private final static String KAKAO_SENDER_KEY = Label.KakaoSenderKey;
    private final static String KAKAO_WEBHOOK_URL = Label.GuestHost + '/services/apexrest/api/webhook/kakao';
    private final static String MAN_TEL = Label.MANTel;

    private final static List<String> TASK_LIST = new List<String>{
            'Contract', 'Opportunity', 'VirtualAccount__c'
    };

    /**
     * @param paramMap      카카오톡 호출을 위한 파라미터 정보
     *                      1. [v] templateTitle : 카카오톡 Template명
     *                      2. object : 카카오톡 Template Body를 설정할 Object명
     *                      3. [v] recordId : 카카오톡 Template Body를 설정할 Object의 recordId
     *                      4. externalId : 문서에 연결할 외부 Id
     *                      5. [v] infoMapList : 카카오톡 수신자의 recordId(PhoneNumber를 가져오기 위함)
     *                              5-1. objectName : Object명
     *                              5-2. [v] recordId : Object Record Id
     *                      6. buttonMap : 카카오톡 Template중 버튼이 있을경우 Setting
     *                         - Map<String, Map<String, String>> type
     *                              6-1. key : WiseMoka Template의 "버튼명"
     *                              6-2. value : Map<String, String>
     *                                   6-2-1. key : #{변수} Key 값
     *                                   6-2-2. value : #{변수} Value 값
     *                      7. whereField : Custom Where의 Field조건 추가. ver1.2
     * @return              Map<String, Object> value
     * @description         Salesforce -> Heroku -> Infobip API 호출
     *                      Heroku API Token값 : Heroku Settings(Config) 확인
     */
    // 신규 ObjectType(recordId)추가시 TaskFieldSet 만드시오. CommonUtilCustomController.createTask 참조
    @AuraEnabled
    public static Map<String, Object> doCallOutKakaoAlimTalk(Map<String, Object> paramMap) {
        System.debug(paramMap);
        Map<String, Object> resultMap = new Map<String, Object>();
        resultMap.put('code', true);
        resultMap.put('message', 'Great. you\'ve got ' + Integer.valueOf(Math.random() * 10) + ' points');

        String templateTitle = String.valueOf(paramMap.get('templateTitle'));
        String recordId = String.valueOf(paramMap.get('recordId'));
        String whereField = paramMap.containsKey('whereField')
                ? String.valueOf(paramMap.get('whereField'))
                : 'Id';
        String sObjectType = paramMap.containsKey('object')
                ? String.valueOf(paramMap.get('object'))
                : ((Id) recordId).getSobjectType().getDescribe().getName();
        Map<Object, Object> buttonObjectMap = paramMap.containsKey('buttonMap')
                ? (Map<Object, Object>) paramMap.get('buttonMap')
                : new Map<Object, Object>();
        String externalId = String.valueOf(paramMap.get('externalId'));

        // 버튼 Map
        Map<String, Object> buttonMap = new Map<String, Object>();
        for (Object obj : buttonObjectMap.keySet()) {
            buttonMap.put(String.valueOf(obj), buttonObjectMap.get(obj));
        }

        // 알림수신 List
        List<Map<String, Object>> infoMapList = new List<Map<String, Object>>();
        List<Object> objectList = (List<Object>) paramMap.get('infoMapList');
        for (Object obj : objectList) {
            Map<Object, Object> objMap = (Map<Object, Object>) obj;

            Map<String, Object> infoMap = new Map<String, Object>();
            for (Object key : objMap.keySet()) {
                infoMap.put(String.valueOf(key), objMap.get(key));
            }
            infoMapList.add(infoMap);
        }

        try {
            // 1. Template에 필요한 Object Record Get
            Template__c template = [
                    SELECT Id, Name, Body__c, TemplateId__c, fm_TemplateTitle__c,
                        (SELECT Id, Name, ButtonName__c, MobileURL__c, PCURL__c, LinkType__c FROM TemplateButtons__r)
                    FROM Template__c
                    WHERE fm_TemplateTitle__c = :templateTitle
            ];
            String title = template.Name.substringAfter('^');
            List<String> fieldList = getTemplateFields(template.Body__c);

            //fieldList에 값이 없다면 쿼리되지 않도록 수정
            SObject data;
            if(!fieldList.isEmpty()) data = fetchRecordData(fieldList, sObjectType, whereField, recordId);

            // 2. Request Body 생성
            Map<String, Object> bodyMap = new Map<String, Object>();
            List<Object> messages = new List<Object>();

            Map<String, Object> content = new Map<String, Object>();
            String text = buildContent(template.Body__c, data, fieldList);
            content.put('text', text);
            content.put('templateCode', template.TemplateId__c.replace('HEROKU_', ''));
            content.put('type', 'TEMPLATE');
            if(!''.equals(title)) content.put('title', title);
            if(!template.TemplateButtons__r.isEmpty()) content.put('buttons', buildButtons(template.TemplateButtons__r, buttonMap));

            Map<String, Object> message = new Map<String, Object>();
            message.put('sender', KAKAO_SENDER_KEY);
            message.put('destinations', buildDestinations(infoMapList));
            message.put('options', buildSMSFailover(text));
            message.put('webhooks', buildWebhook());
            message.put('content', content);

            messages.add(message);
            bodyMap.put('messages', messages);
            System.debug('\n' + JSON.serializePretty(bodyMap));

            String body = JSON.serialize(bodyMap);
//            // Sample Text 데이터
//            String receiver = '821035717683';
//            String manTel = MAN_TEL;
//            body =
//                '{' +
//                '  "messages": [{' +
//                '      "sender": "85d506c54e71a52daa4598efb194ac5ed21732d8",' +
//                '      "destinations": [{' +
//                '          "to": "' + receiver + '"' +
//                '        }],' +
//                '      "options": {' +
//                '        "smsFailover" : {' +
//                '          "text" : "Sample Template Test\\nURL Link. Test~~~~",' +
//                '          "sender" : "' + manTel + '"' +
//                '        },' +
//                '        "validityPeriod" : {' +
//                '          "amount" : "15"' +
//                '        }' +
//                '      },' +
//                '      "content": {' +
//                '        "templateCode": "KAKAO_000",' +
//                '        "text": "Sample Template Test\\nURL Link. Test~~~~",' +
//                '        "title": "개인정보 활용동의",' +
//                '        "type": "TEMPLATE",' +
//                '        "buttons": [{' +
//                '            "type": "URL",' +
//                '            "name": "WebButton",' +
//                '            "urlMobile": "https://app-force-1035--partial.sandbox.my.site.com/Agreement/s/",' +
//                '            "urlPc": "https://app-force-1035--partial.sandbox.my.site.com/Agreement/s/"' +
//                '          }]' +
//                '      },' +
//                '      "webhooks": {' +
//                '        "delivery": {' +
//                '          "url": "https://app-force-1035--partial.sandbox.my.salesforce-sites.com/guest/services/apexrest/api/webhook/kakao",' +
//                '          "intermediateReport": "true"' +
//                '        },' +
//                '        "contentType": "application/json"' +
//                '      }' +
//                '    }]' +
//                '}';
            IF_Util ifUtil = new IF_Util(HEROKU_KAKAO_SAMPLE);
            HttpResponse response = ifUtil.webCallout(body);
            if (HttpCallOutConsts.SUCCESS_CODES.contains(response.getStatusCode())) {
                String responseBody = response.getBody();
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

                Integer statusCode = 500;
                String messageString = String.valueOf(responseMap.get('message'));
                if(Boolean.valueOf(responseMap.get('code'))) {
                    // 카카오톡 전송이 성공일경우만
                    statusCode = response.getStatusCode();
                    String objectType = Id.valueOf(recordId).getSobjectType().getDescribe().getName();

                    APIDocument__c doc = createDocument(responseBody);
                    doc.Template__c = template.Id;
                    if (externalId != null) doc.ExternalId__c = externalId;

                    insert doc;
                    if(TASK_LIST.contains(objectType)) insert CommonUtilCustomController.createTask(recordId, 'Kakao', template.fm_TemplateTitle__c);
                }
                resultMap.put('statusCode', statusCode);
                resultMap.put('message', messageString);
            } else {
                resultMap.put('code', false);
                resultMap.put('statusCode', response.getStatusCode());
                resultMap.put('message', response.getBody());
            }
        } catch(Exception e) {
            resultMap.put('code', false);
            resultMap.put('message', e.getMessage());
            System.debug('err msg ::'+ e.getMessage() +' err :: '+e.getStackTraceString() + ' line :: ' + e.getLineNumber());
        }

        return resultMap;
    }

    /**
     * @param body          Body Text
     * @return              List<String> value(fieldList)
     */
    private static List<String> getTemplateFields(String body) {
        List<String> fieldList = new List<String>();
        Map<String, String> subQueryMap = new Map<String, String>();

        // 정규식 사용. #{...} 패턴 매칭되는 부분 찾기
        Pattern pattern = Pattern.compile('\\#\\{(.*?)\\}');
        Matcher matcher = pattern.matcher(body);

        while (matcher.find()) {
            // #{...} 안의 값 추출
            String field = matcher.group(1);

            // ex. _Quotes.Name
            if(field.startsWith('_')) {
                String subQueryField = field.substring(1);      // '_' 제거
                String[] parts = subQueryField.split('\\.');    // SubQuery 형식으로 분리
                String relatedObject = parts[0];                // ex, 'Quotes'
                String relatedField = parts[1];                 // ex, 'Name'

                String fields = subQueryMap.containsKey(relatedObject)
                        ? subQueryMap.get(relatedObject) + ',' + relatedField
                        : 'SELECT ' + relatedField;
                subQueryMap.put(relatedObject, fields);
            } else {
                // 단일 필드 추가
                fieldList.add(field);
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
     * @param fieldList         Record Data의 필드 List
     * @param sObjectType       Record Data의 Object
     * @param whereField        Record Data의 WhereField
     * @param recordId          Record Data의 Id
     * @return                  SObject
     */
    public static SObject fetchRecordData(List<String> fieldList, String sObjectType, String whereField, String recordId) {
        String selectFields = String.join(fieldList, ', ');
        String query = CommonUtilController.buildQuery(
                selectFields,
                sObjectType,
                CommonUtilController.buildWhereConditions(new Map<String, Object>{ whereField => recordId })
        );

        System.debug(query);
        return Database.query(query);
    }

    /**
     * @param text              Kakao Template의 String body값
     * @param data              Record의 데이터
     * @param fieldList         Select Field List
     * @description             변수값에 따른 데이터 Replace한 후 Return
     * @return                  String value
     */
    private static String buildContent(String text, SObject data, List<String> fieldList) {
        // Field List에 따른 Text값 동적 매핑
        for(String field : fieldList) {
            String replaceField = '#{' + field + '}';

            if(field.startsWith('(')) {
                // SubQuery 처리
                text = handleSubQuery(text, data, field);
            } else {
                // 일반 필드 처리
                String value = String.valueOf(CommonUtilCustomController.fetchValueRecur(data, field));
                System.debug('replaceField::'+replaceField);
                System.debug('value::'+value);
                text = text.replace(replaceField, value);
            }
        }

        return text;
    }

    /**
     * @return          Map<String, Object> Value
     */
    private static Map<String, Object> buildWebhook() {
        Map<String, Object> returnMap = new Map<String, Object>();

        Map<String, Object> deliveryMap = new Map<String, Object>();
        deliveryMap.put('url', KAKAO_WEBHOOK_URL);
        deliveryMap.put('intermediateReport', 'true');

        returnMap.put('contentType', 'application/json');
        returnMap.put('delivery', deliveryMap);
        return returnMap;
    }

    /**
     * @param text      SMS Text
     * @return          Map<String, Object> value
     */
    private static Map<String, Object> buildSMSFailover(String text) {
        Map<String, Object> returnMap = new Map<String, Object>();

        Map<String, String> SMSMap = new Map<String, String>();
        SMSMap.put('sender', MAN_TEL.replaceAll('-', ''));
        SMSMap.put('text', text);

        Map<String, String> validityMap = new Map<String, String>();
        validityMap.put('amount', '15');

        returnMap.put('validityPeriod', validityMap);
        returnMap.put('smsFailover', SMSMap);

        return returnMap;
    }

    private static List<Map<String, Object>> buildDestinations(List<Map<String, Object>> infoMapList) {

        List<Map<String, Object>> destinationMapList = new List<Map<String, Object>>();
        String consentType ='';
        // key : Object명. Value : List<Map<String, Object>>
        //                  Map<String, Object> | key : recordId, value : Map<String, Object>
        //                                                              key : recordId, value : Map<String, Object>
        Map<String, List<Map<String, Object>>> objectNameInfoListMap = new Map<String, List<Map<String, Object>>>();
        for(Map<String, Object> infoMap : infoMapList) {
            String recordId = String.valueOf(infoMap.get('recordId'));
            String objectName = infoMap.containsKey('objectName')
                    ? String.valueOf(infoMap.get('objectName'))
                    : ((Id) recordId).getSobjectType().getDescribe().getName();

            List<Map<String, Object>> objectNameInfoList = objectNameInfoListMap.containsKey(objectName)
                    ? objectNameInfoListMap.get(objectName)
                    : new List<Map<String, Object>>();

            objectNameInfoList.add(infoMap);
            objectNameInfoListMap.put(objectName, objectNameInfoList);
            // Consent Type에 따른 실차주, 고객 알림톡 수신자 변수 선언
            consentType = infoMap.get('type') != null ? String.valueOf(infoMap.get('type')) : null;
        }

        for(String objectName : objectNameInfoListMap.keySet()) {
            List<Map<String, Object>> objectInfoList = objectNameInfoListMap.get(objectName);

            Map<String, Map<String, Object>> objectInfoMap = new Map<String, Map<String, Object>>();
            for(Map<String, Object> objectInfo : objectInfoList) {
                String recordId = String.valueOf(objectInfo.get('recordId'));

                objectInfoMap.put(recordId, objectInfo);
            }
            System.debug(objectInfoMap);

            // For문안에서 SQL을 태웠다고 생각하지 마시오.... Type별로만 한번씩 태움
            /**
              * @author San.Kang
              * @description : Consent Type에 따른 실차주, 고객 알림톡 수신자 분기처리 업데이트
              *              1. 341 Line => RealDriverMobile__pc 필드쿼리 추가
              *              2. 347~351 Line => Consent Type에 따른 실차주, 고객 분기처리 로직 추가
              */
            switch on objectName.toUpperCase() {
                when 'ACCOUNT' {
                    Map<Id, Account> accountMap = new Map<Id, Account> ([
                            SELECT Id, PersonMobilePhone,RealDriverMobile__pc, fm_TargetMobilePhone__c
                            FROM Account
                            WHERE Id IN :objectInfoMap.keySet()
                    ]);
                    for(String accountId : objectInfoMap.keySet()) {
                        Map<String, Object> infoMap = objectInfoMap.get(accountId);
                        infoMap.put('phone', accountMap.get(accountId).fm_TargetMobilePhone__c);

                        // Account에서 Consent 발송 로직 삭제
//                        if(consentType == '실차주' && consentType != null){
//                            infoMap.put('phone', '010-2932-3033');
//                            // 기존 수신자 로직
//                            infoMap.put('phone', accountMap.get(accountId).RealDriverMobile__pc);
//                        } else {
//                            infoMap.put('phone', '010-2932-3033');
//                            // 기존 수신자 로직
//                            infoMap.put('phone', accountMap.get(accountId).PersonMobilePhone);
//                        }
//                        if(accountMap.get(accountId).AccountConsent__r[0].Type__c == '고객' ){
//                            infoMap.put('phone', accountMap.get(accountId).PersonMobilePhone);
//                        }else{
//                            infoMap.put('phone', accountMap.get(accountId).RealDriverMobile__pc);
//                        }
                        objectInfoMap.put(accountId, infoMap);
                    }
                }
                when 'USER' {
                    Map<Id, User> userMap = new Map<Id, User> ([
                            SELECT Id, MobilePhone
                            FROM User
                            WHERE Id IN :objectInfoMap.keySet()
                    ]);
                    for(String userId : objectInfoMap.keySet()) {
                        Map<String, Object> infoMap = objectInfoMap.get(userId);
                        infoMap.put('phone', '010-2932-3033');
                        // 기존 수신자 로직
                        infoMap.put('phone', userMap.get(userId).MobilePhone);

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
                        infoMap.put('phone', '010-2932-3033');

                        String customerType = String.valueOf(infoMap.get('customerType'));

                        String phone;
                        infoMap.put('phone', '010-2932-3033');
                        switch on customerType.toUpperCase() {
                            when 'OWNER' {
                                phone = contact.MobilePhone;
                            }
                            when 'REALDRIVER' {
                                phone = contact.RealDriverMobile__c;
                            }
                        }

                        infoMap.put('phone', phone);

                        objectInfoMap.put(contactId, infoMap);
                    }
                }
                // Light Consent 카카오 알림 발송 로직 추가
                when 'LEAD' {
                    Map<Id, Lead> leadMap = new Map<Id, Lead> ([
                            SELECT Id, MobilePhone
                            FROM Lead
                            WHERE Id IN :objectInfoMap.keySet()
                    ]);
                    for(String leadId : objectInfoMap.keySet()) {
                        Map<String, Object> infoMap = objectInfoMap.get(leadId);
//                        infoMap.put('phone', '010-2767-8983');
                        infoMap.put('phone', leadMap.get(leadId).MobilePhone);

                        objectInfoMap.put(leadId, infoMap);
                    }
                }
            }


            for(String recordId : objectInfoMap.keySet()) {
                Map<String, Object> destinationMap = new Map<String, Object>();

                Map<String, Object> infoMap = objectInfoMap.get(recordId);
                String phoneNumber = String.valueOf(infoMap.get('phone'));

                destinationMap.put('to', parseKakaoNumber(phoneNumber));
                destinationMapList.add(destinationMap);
            }
            System.debug('\n' + JSON.serializePretty(destinationMapList));
        }
        return destinationMapList;
    }

    /**
     * @param buttons       TemplateButton 데이터
     * @param keyMap        ButtonMap(Param)
     * @description         카카오톡 Template 버튼 데이터 Mapping
     * @return              List<Map<String, String>> Value
     */
    private static List<Map<String, String>> buildButtons(List<TemplateButton__c> buttons, Map<String, Object> keyMap) {
        List<Map<String, String>> buttonMapList = new List<Map<String, String>>();
        for(TemplateButton__c button : buttons) {
            Map<String, String> buttonMap = new Map<String, String>();
            Object objMap = keyMap.get(button.ButtonName__c);
            Map<String, Object> infoMap = new Map<String, String>();

            System.debug(button.ButtonName__c);
            System.debug(buttons);
            System.debug(keyMap);
            System.debug(objMap);
            // ver1.1 Casting 변환 오류해결
            if(objMap instanceof Map<String, Object>) {
                infoMap = (Map<String, Object>) objMap;
            } else {
                String jsonString = String.valueOf(objMap).replace('{', '').replace('}', '');
                for (String pair : jsonString.split(',')) {
                    List<String> splitList = pair.split('=');

                    infoMap.put(splitList[0].trim(), splitList[1].trim());
                }
            }
            System.debug(infoMap);

//            String name = button.Name;
            String linkType = button.LinkType__c;
            String mobileURL = button.MobileURL__c;
            String PCURL = button.PCURL__c;
            System.debug('before ::: ' + mobileURL);
            System.debug('before ::: ' + PCURL);
            for(String key : infoMap.keySet()) {
                // varKey 특수문자 앞에 \\를 붙여야 함
                String varKey = '\\#\\{' + key + '\\}';
                System.debug('varKey ::: ' + varKey);
                mobileURL = mobileURL.replaceAll(varKey, String.valueOf(infoMap.get(key)));
                PCURL = PCURL.replaceAll(varKey, String.valueOf(infoMap.get(key)));
            }
            System.debug('after ::: ' + mobileURL);
            System.debug('after ::: ' + PCURL);

//            switch on name {
            switch on linkType {
                when 'WL' { buttonMap.put('type', 'URL'); }
            }
            buttonMap.put('name', button.ButtonName__c);
            buttonMap.put('urlMobile', mobileURL);
            buttonMap.put('urlPc', PCURL);
            buttonMapList.add(buttonMap);
        }

        return buttonMapList;
    }

    /**
     * @param text          Text body
     * @param record        SObject 데이터
     * @param subQuery      SubQuery (ex, [SELECT Id,Name FROM Quotes])
     * @description         SubQuery 처리 함수
     * @return              String Value
     */
    private static String handleSubQuery(String text, SObject record, String subQuery) {
        // SubQuery 문자열 파싱
        subQuery = subQuery.substring(1, subQuery.length() - 1);
        String[] subQueryParts = subQuery.split(' FROM ');
        String subQueryFields = subQueryParts[0].replace('SELECT ', '');
        String subQueryObject = subQueryParts[1].trim();

        // SubQuery Records Get
        List<SObject> subRecords = record.getSObjects(subQueryObject);

        // TODO : 다중의 SubQuery Record들 처리 불가함. 필요할 경우 고려해야함
        // SubQuery의 필드 처리
        for (SObject subRecord : subRecords) {
            for (String field : subQueryFields.split(',')) {
                String replaceField = '#{_' + subQueryObject + '.' + field + '}';

                String value = String.valueOf(CommonUtilCustomController.fetchValueRecur(subRecord, field));
                text = text.replace(replaceField, value);
            }
        }

        return text;
    }

    private static String parseKakaoNumber(String phoneNumber) {
        return '82' + phoneNumber.replaceAll('-', '').substring(1);
    }

    private static String parsePhoneNumber(String kakaoNumber) {
        String phoneNumber = kakaoNumber.replaceFirst('82', '0');

        return phoneNumber.substring(0, 3) + '-' +
                phoneNumber.substring(3, 7) + '-' +
                phoneNumber.substring(7, 11);
    }

    // 카카오톡 전송 API Response값 저장
    private static APIDocument__c createDocument(String responseBody) {
        // Message Template은 한건에 한개 적용원칙. 여러건을 보내고자 한다면 해당 Response의 bulkId가 아닌 messasgeId로 해야함
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        String messageString;
        if(Test.isRunningTest()) {
            messageString = JSON.serialize(responseMap.get('message'));
        } else {
            messageString = String.valueOf(responseMap.get('message'));
        }
        Map<String, Object> messageListMap = (Map<String, Object>) JSON.deserializeUntyped(messageString);
        List<Object> messageList = (List<Object>) messageListMap.get('messages');
        Map<String, Object> messageMap = (Map<String, Object>) messageList[0];
        Map<String, Object> status = (Map<String, Object>) messageMap.get('status');

        String bulkId = String.valueOf(messageListMap.get('bulkId'));
        String groupName = String.valueOf(status.get('groupName'));
        String destination = String.valueOf(messageMap.get('destination'));

        APIDocument__c doc = new APIDocument__c();
        doc.Name = bulkId;
        doc.Status__c = groupName;
        doc.Body__c = responseBody;
        doc.Destination__c = parsePhoneNumber(destination);
        doc.RecordTypeId = RECORDTYPE_KAKAO;

        return doc;
    }
}