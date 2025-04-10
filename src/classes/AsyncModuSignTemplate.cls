/**
* @Author            : payo03@solomontech.net
* @Description 		 : ModuSign Template Job
* @Target            : Template_ba
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-03      payo03@solomontech.net           Created
*/
public without sharing class AsyncModuSignTemplate implements Queueable, Database.AllowsCallouts {

    private static final String TEMPLATE_MODUSIGN_LIST_IF_ID = 'MDSIGN_001';
    private static final String TEMPLATE_MODUSIGN_IF_ID = 'MDSIGN_002';
    private final static String RECORDTYPE_MODUSIGN = Schema.SObjectType.Template__c.getRecordTypeInfosByDeveloperName().get('MODUSIGN').getRecordTypeId();

    public void execute(QueueableContext context) {
        Map<String, Map<String, Object>> moduSignInfoMap = new Map<String, Map<String, Object>>();
        Map<String, Template__c> recordMap = new Map<String, Template__c>();

        for(Template__c template : [
                SELECT Id, Name, Body__c, TemplateId__c
                FROM Template__c
                WHERE RecordTypeId = :RECORDTYPE_MODUSIGN
        ]) {
            recordMap.put(template.TemplateId__c, template);
        }

        String status;
        String requestBody;
        String responseBody;
        String responseStatusCode;
        Datetime requestTime;
        Datetime responseTime;
        try {
            requestTime = Datetime.now();
            // A-1. 모두싸인 Template API 호출
            IF_Util moduSignTemplateAllUtil = new IF_Util(TEMPLATE_MODUSIGN_LIST_IF_ID);
            HttpResponse moduSignTemplateAllRespnse = moduSignTemplateAllUtil.webCallout(null);
            if (HttpCallOutConsts.SUCCESS_CODES.contains(moduSignTemplateAllRespnse.getStatusCode())) {
                Map<String, Object> response1Map = (Map<String, Object>) JSON.deserializeUntyped(moduSignTemplateAllRespnse.getBody());

                status = 'SUCCESS';
                responseTime = Datetime.now();
                responseBody = JSON.serializePretty(response1Map);
                responseStatusCode = String.valueOf(moduSignTemplateAllRespnse.getStatusCode());

                List<Object> templateList = (List<Object>) response1Map.get('templates');
                for (Object template : templateList) {
                    Map<String, Object> templateMap = (Map<String, Object>) template;

                    String templateId = String.valueOf(templateMap.get('id'));
                    IF_Util moduSignTemplateUtil = new IF_Util(TEMPLATE_MODUSIGN_IF_ID);
                    HttpResponse moduSignTemplateRespnse = moduSignTemplateUtil.webCallout2(null, new List<String>{
                            templateId
                    });

                    if (HttpCallOutConsts.SUCCESS_CODES.contains(moduSignTemplateRespnse.getStatusCode())) {
                        Map<String, Object> response2Map = (Map<String, Object>) JSON.deserializeUntyped(moduSignTemplateRespnse.getBody());

                        moduSignInfoMap.put(String.valueOf(response2Map.get('id')), response2Map);
                    }
                }
            }

            // A-2. 각각의 Template에 대한 단일호출 후 Upsert
            List<Template__c> moduSignList = new List<Template__c>();
            for (String templateId : moduSignInfoMap.keySet()) {
                Map<String, Object> infoMap = moduSignInfoMap.get(templateId);

                Template__c template = recordMap.containsKey(templateId) ? recordMap.get(templateId) : new Template__c();
                template.Name = String.valueOf(infoMap.get('title'));
                template.Body__c = JSON.serializePretty(infoMap);
                template.TemplateId__c = templateId;
                template.RecordTypeId = RECORDTYPE_MODUSIGN;

                moduSignList.add(template);
            }
            if (!moduSignList.isEmpty()) upsert moduSignList TemplateId__c;
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
            objLogWrapper.logType = IF_DTO.LOG_TYPE.MODUSIGN_OUT;

            CommonUtilCustomController.setLog(objLogWrapper);
        }
    }
}