/**
* @Author            : payo03@solomontech.net
* @Description 		 : MFS 인터페이스 Class
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-04-29      payo03@solomontech.net           Created
*/
public without sharing class InterfaceMFS {

    public static final String DFLT = 'L';

    public static final String IF_MFS000 = 'AWS_LOAN000';   // API Health Check
    public static final String IF_MFS001 = 'AWS_LOAN001';

    @AuraEnabled
    public static void sendLoanApproval(String recordId) {
        System.debug(recordId);
        System.enqueueJob(new AsyncLoanRequestMFS(new List<String>{recordId}, new Map<String, String>()));
    }

    public static void doHealthCheck() {
        IF_Util ifUtil = new IF_Util(IF_MFS000);

        HttpResponse response = ifUtil.webCallout2(null);
        if (HttpCallOutConsts.SUCCESS_CODES.contains(response.getStatusCode())) {
            System.debug(response);
            System.debug(response.getBody());
        }
    }

    /**
     * @param ifId          Interface Id
     * @param items         Body Items
     * @param cHeaderMap    Custom Header
     * @description         SAP Interface 공통함수
     * @return              Map<String, Object> Value
     */
    public static Map<String, Object> doCallOutMFS(String ifId, List<Object> items, Map<String, String> cHeaderMap) {
        Map<String, Object> returnMap = new Map<String, Object>();
        IF_Util ifUtil = new IF_Util(ifId);
        System.debug('InterfaceId : ' + ifId);
        System.debug('cHeaderMap : ' + cHeaderMap);
        String body = JSON.serialize(items);

        HttpResponse response = ifUtil.webCallout2(body, cHeaderMap);
        if (HttpCallOutConsts.SUCCESS_CODES.contains(response.getStatusCode())) {
            returnMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        }
        return returnMap;
    }

    /**
     * @param infoMap   API Call Info
     *                  1. ifId : IF_MASTER의 호출될 Interface Id
     *                  2. logId : API 통신에 대한 Interface Id
     *                  3. logType : IFAuditLog에 남길 Type
     *                  4. isLog : IFAuditLog Insert여부. API 반복호출시 해당값 FALSE로 Finally에서 수동으로 일괄 Insert필요
     *                      DEFAULT : TRUE
     *                  5. isLogDetail : ver1.1 IF Log Detail구조 생성
     *                      DEFAULT : FALSE
     *                  6. idList : 후처리 조회할 Id List(IF_SAP 참고) OR IFAuditLogDetail 생성용 데이터
     *                  7. items : Interface보낼 Data
     * @description     SAP Interface 공통함수, 감사로그 Insert함수
     * @return          Map<String, Object> Value
     */
    public static Map<String, Object> doCallOutMFSLog(Map<String, Object> infoMap) {
        String ifId = String.valueOf(infoMap.get('ifId'));
        String logId = String.valueOf(infoMap.get('logId'));
        String type = String.valueOf(infoMap.get('logType'));
        List<Object> items = (List<Object>) infoMap.get('items');

        Boolean isLog = infoMap.containsKey('isLog')
                ? Boolean.valueOf(infoMap.get('isLog'))
                : true;
        Boolean isLogDetail = infoMap.containsKey('isLogDetail')
                ? Boolean.valueOf(infoMap.get('isLogDetail'))
                : false;

        Map<String, String> keyMap = infoMap.containsKey('keyMap')
                ? (Map<String, String>) infoMap.get('keyMap')
                : new Map<String, String>();
        Map<String, String> cHeaderMap = infoMap.containsKey('cHeaderMap')
                ? (Map<String, String>) infoMap.get('cHeaderMap')
                : new Map<String, String>();

        Map<String, Object> returnMap = new Map<String, Object>();
        String requestBody = JSON.serialize(items);
        System.debug(requestBody);

        String responseBody;
        try {
            returnMap = doCallOutMFS(ifId, items, cHeaderMap);
            responseBody = JSON.serialize(returnMap);

            System.debug(JSON.serializePretty(returnMap));
        } catch(Exception e) {
            responseBody = e.getMessage();

            System.debug(e.getMessage());
        } finally {
            IFAuditLog__c log = new IFAuditLog__c();
            log.IF_Id__c = ifId;
            log.Name = logId;
            log.Type__c = type;
            log.RawData__c = requestBody;
            log.ResponseBody__c = responseBody;
            if(isLog) insert log;

            if(isLog && isLogDetail) {
                // IFAuditLog Insert이면서 IFAudigLogDetail Insert해야하는 경우
                List<IFAuditLogDetail__c> logDetailList = new List<IFAuditLogDetail__c>();
                for(String externalId : keyMap.keySet()) {
                    System.debug(externalId);
                    String objectType = Id.valueOf(externalId).getSobjectType().getDescribe().getName();

                    IFAuditLogDetail__c logDetail = new IFAuditLogDetail__c();
                    logDetail.IFAuditLog__c = log.Id;
                    logDetail.ObjectType__c = objectType;
                    logDetail.ExternalId__c = externalId;
                    logDetail.ExternalKey__c = keyMap.get(externalId);

                    logDetailList.add(logDetail);
                }
                if(!logDetailList.isEmpty()) insert logDetailList;
            }
        }

        return returnMap;
    }
}