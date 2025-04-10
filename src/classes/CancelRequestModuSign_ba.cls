/**
* @Author            : payo03@solomontech.net
* @Description 		 : 모두싸인 만료기간에 따른 서명요청 취소 API 호출
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-13      payo03@solomontech.net           Created
  1.1      2025-02-07      payo03@solomontech.net           문서취소 API 함수
*/
public without sharing class CancelRequestModuSign_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    private static final String RECORDTYPE_MODUSIGN = Schema.SObjectType.APIDocument__c.getRecordTypeInfosByDeveloperName().get('MODUSIGN').getRecordTypeId();
    private final static Integer BATCH_SIZE = 200;   // Schedule 배치 200 Size고정
    private static final String CANCEL_IF_ID = 'MDSIGN_008';
    public String dynamicCondition;                  // 특정조건으로만 Batch 실행

    public CancelRequestModuSign_ba(String dynamicCondition) {
        if(dynamicCondition != null) this.dynamicCondition = dynamicCondition;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String selectFields =       getFields();
        String fromObject =         'APIDocument__c ';

        String whereConditions =    'RecordTypeId = \'' + RECORDTYPE_MODUSIGN + '\' ';
                                    // + 'AND Status__c = \'ON_GOING\' ';
//                                    + ' AND ExpiredDate__c < Today';
        // if(this.dynamicCondition != null) whereConditions += this.dynamicCondition;
        //250324 chaebeom.do : 계약 취소 프로세스로 인한 조건 수정
        whereConditions += this.dynamicCondition != null ? this.dynamicCondition : 'AND Status__c = \'ON_GOING\' ';

        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, whereConditions);
        System.debug(buildQuery);
        return Database.getQueryLocator(buildQuery);
    }

    public void execute(SchedulableContext context) {
        String dynamicCondition = null;
        if(this.dynamicCondition != null) dynamicCondition = this.dynamicCondition;

        Database.executeBatch(new CancelRequestModuSign_ba(dynamicCondition), BATCH_SIZE);
    }

    public void execute(Database.BatchableContext context, List<SObject> records) {

        Map<String, Object> bodyMap = new Map<String, Object>();
        bodyMap.put('message', '문서 유효기간 만료');
        bodyMap.put('accessibleByParticipant', false);

        List<IF_DTO.LogWrapper> logList = new List<IF_DTO.LogWrapper>();
        for(SObject record : records) {
            APIDocument__c doc = (APIDocument__c) record;

            Datetime requestTime = Datetime.now();
            String status = 'ERROR';
            String responseBody = '';
            String responseStatusCode = '';

            /*
            IF_Util ifUtil = new IF_Util(MODUSIGN_CANCEL_IF_ID);
            HttpResponse response = ifUtil.webCallout(JSON.serialize(bodyMap), new List<String>{
                    doc.Name, 'cancel'
            });
            */
            // ver1.1 문서취소 API 함수. TODO API 100건 GovernetLimit 고려필요
            HttpResponse response = InterfaceModuSign.doCallOutCancel(bodyMap, doc.Name);

            if (HttpCallOutConsts.SUCCESS_CODES.contains(response.getStatusCode())) {
                status = 'SUCCESS';
                responseBody = response.getBody();
                responseStatusCode = String.valueOf(response.getStatusCode());
            }

            IF_DTO.LogWrapper objLogWrapper = new IF_DTO.LogWrapper();
            objLogWrapper.requestTime = requestTime;
            objLogWrapper.requestBody = JSON.serialize(bodyMap);
            objLogWrapper.status = status;
            objLogWrapper.responseTime = Datetime.now();
            objLogWrapper.responseBody = responseBody;
            objLogWrapper.errorCode = responseStatusCode;
            objLogWrapper.logType = IF_DTO.LOG_TYPE.MODUSIGN_OUT;

            logList.add(objLogWrapper);
        }
        if(!logList.isEmpty()) CommonUtilCustomController.setLogList(logList);
    }

    public void finish(Database.BatchableContext context) {

        System.debug('########## CancelRequestModuSign_ba Finish ##########');
        System.debug('dynamicCondition : ' + this.dynamicCondition);
    }

    public static String getFields() {
//        return 'Id, Name, ExpiredDate__c ';
        return 'Id, Name ';
    }
}