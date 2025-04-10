/**
* @Author            : payo03@solomontech.net
* @Description 		 : Kakao Template Job
* @Target            : KakaoTemplate_ba
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-03      payo03@solomontech.net           Created
  1.1      2025-01-09      payo03@solomontech.net           카카오톡 Template Button 삭제 및 Insert
*/
public without sharing class AsyncKakaoTemplate implements Queueable, Database.AllowsCallouts {

    // Type. YYYYMMDDHHMMSS / ex, 20241215093000
    public String baseDate;

    private static final String TEMPLATE_KAKAO_IF_ID = 'HEROKU_WSMOKA_001';
    private final static String WS_MOKA_SENDER_KEY = Label.WiseMokaSenderKey;
    private final static String RECORDTYPE_KAKAO = Schema.SObjectType.Template__c.getRecordTypeInfosByDeveloperName().get('KAKAO').getRecordTypeId();

    public AsyncKakaoTemplate(String baseDate) {
        this.baseDate = baseDate;
    }

    public void execute(QueueableContext context) {
        Map<String, Map<String, Object>> WSMokaMap = new Map<String, Map<String, Object>>();
        Map<String, Template__c> recordMap = new Map<String, Template__c>();

        for(Template__c template : [
                SELECT Id, Name, Body__c, TemplateId__c,
                    (
                        SELECT Id
                        FROM TemplateButtons__r
                    )
                FROM Template__c
                WHERE RecordTypeId = :RECORDTYPE_KAKAO
        ]) {
            recordMap.put(template.TemplateId__c, template);
        }
        if(baseDate == null) baseDate = CommonUtilController.formatDate(Datetime.now().addDays(-7), 'C') + '000000';  // Default. 수정된이력 7일이내

        String status;
        String requestBody;
        String responseBody;
        String responseStatusCode;
        Datetime requestTime;
        Datetime responseTime;
        try {
            requestTime = Datetime.now();
            // B-1. 와이즈모카 Template 조회 API 호출 및 Upsert
            String body = 'senderKey=' + WS_MOKA_SENDER_KEY + '&since=' + baseDate;

            IF_Util WSMokaTemplateUtil = new IF_Util(TEMPLATE_KAKAO_IF_ID);
            HttpResponse WSMokaTemplateResponse = WSMokaTemplateUtil.webCallout(body);
            if (HttpCallOutConsts.SUCCESS_CODES.contains(WSMokaTemplateResponse.getStatusCode())) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(WSMokaTemplateResponse.getBody());

                status = 'SUCCESS';
                responseTime = Datetime.now();
                responseBody = JSON.serializePretty(responseMap);
                responseStatusCode = String.valueOf(WSMokaTemplateResponse.getStatusCode());

                String jsonMessage;
                if (Test.isRunningTest()) {
                    jsonMessage = JSON.serialize(responseMap.get('message'));
                } else {
                    jsonMessage = String.valueOf(responseMap.get('message'));
                }
                Map<String, Object> messageMap = (Map<String, Object>) JSON.deserializeUntyped(jsonMessage);
                Map<String, Object> data = (Map<String, Object>) messageMap.get('data');

                List<Object> objList = (List<Object>) data.get('list');
                for (Object obj : objList) {
                    Map<String, Object> objMap = (Map<String, Object>) obj;
                    String templateCode = 'HEROKU_' + String.valueOf(objMap.get('templateCode'));

                    WSMokaMap.put(templateCode, objMap);
                }
            }

            List<Template__c> kakaoList = new List<Template__c>();
            List<TemplateButton__c> deleteButtonList = new List<TemplateButton__c>();
            for (String templateCode : WSMokaMap.keySet()) {
                Map<String, Object> infoMap = WSMokaMap.get(templateCode);
                String templateName = String.valueOf(infoMap.get('templateName'));
                String templateTitle = String.valueOf(infoMap.get('templateTitle'));
                if (templateTitle != null) templateName += '^' + templateTitle;

                Template__c template = recordMap.containsKey(templateCode) ? recordMap.get(templateCode) : new Template__c();
                template.Name = templateName;
                template.Body__c = String.valueOf(infoMap.get('templateContent'));
                template.TemplateId__c = templateCode;
                template.RecordTypeId = RECORDTYPE_KAKAO;

                kakaoList.add(template);
                deleteButtonList.addAll(template.TemplateButtons__r);   // ver1.1 카카오톡 Template Button 삭제 및 Insert
                recordMap.put(templateCode, template);
            }
            if (!kakaoList.isEmpty()) upsert kakaoList TemplateId__c;
            if (!deleteButtonList.isEmpty()) delete deleteButtonList;   // ver1.1 카카오톡 Template Button 삭제 및 Insert

            // B-2. Template Button Insert
            List<TemplateButton__c> insertButtonList = new List<TemplateButton__c>();
            for (String templateCode : WSMokaMap.keySet()) {
                Template__c template = recordMap.get(templateCode);
                Map<String, Object> infoMap = WSMokaMap.get(templateCode);
                List<Object> buttons = (List<Object>) infoMap.get('buttons');

                for (Object obj : buttons) {
                    Map<String, Object> buttonMap = (Map<String, Object>) obj;

                    // ver1.1 카카오톡 Template Button 삭제 및 Insert
                    TemplateButton__c button = new TemplateButton__c();
                    button.Template__c = template.Id;
                    button.ButtonName__c = String.valueOf(buttonMap.get('name'));
                    button.LinkType__c = String.valueOf(buttonMap.get('linkType'));
                    button.MobileURL__c = String.valueOf(buttonMap.get('linkMo'));
                    button.PCURL__c = String.valueOf(buttonMap.get('linkPc'));

                    insertButtonList.add(button);
                }
            }
            if (!insertButtonList.isEmpty()) insert insertButtonList;
        } catch(Exception e) {
            status = 'ERROR';
            responseBody = e.getMessage();
            responseStatusCode = '500';
            responseTime = Datetime.now();
        } finally {
            IF_DTO.LogWrapper objLogWrapper = new IF_DTO.LogWrapper();
            objLogWrapper.status = status;
            objLogWrapper.requestBody = requestBody;
            objLogWrapper.responseBody = responseBody;
            objLogWrapper.errorCode = responseStatusCode;
            objLogWrapper.requestTime = requestTime;
            objLogWrapper.responseTime = responseTime;
            objLogWrapper.logType = IF_DTO.LOG_TYPE.HEROKU_KAKAO_OUT;

            CommonUtilCustomController.setLog(objLogWrapper);
        }
    }
}