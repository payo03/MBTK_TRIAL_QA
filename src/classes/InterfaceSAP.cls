/**
* @Author            : payo03@solomontech.net
* @Description 		 : SAP(ERP) 인터페이스 Class
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-13      payo03@solomontech.net           Created
  1.1      2025-03-05      payo03@solomontech.net           IF Log Detail구조 생성
*/
public without sharing class InterfaceSAP {

    // TODO : Interface할 Object데이터들에 대해 IF_ID Field생성필요
    public static final String PREFIX_CUSTOMS_INFO = 'A';
    public static final String PREFIX_ORDER_CONFIRM = 'C';
    public static final String PREFIX_MODEL = 'M';
    public static final String PREFIX_INVOICE_INFO = 'N';
    public static final String PREFIX_OPTION = 'O';
    public static final String PREFIX_STOCK = 'T';
    public static final String PREFIX_BP = 'U';
    public static final String PREFIX_TAX = 'V';
    public static final String DFLT = 'Z';

    public static final String IF_SMS000 = 'HEROKU_SMS000';                 // API Health Check
    public static final String IF_SMS004 = 'HEROKU_SMS004';                 // 재고이동요청
    public static final String IF_SMS007 = 'HEROKU_SMS007';                 // BP 전송
    public static final String IF_SMS009 = 'HEROKU_SMS009';                 // 차종전송
    public static final String IF_SMS013 = 'HEROKU_SMS013';                 // 매출확정정보 전송
    public static final String IF_SMS018 = 'HEROKU_SMS018';                 // 가상계좌-BP코드 전송
    public static final String IF_SMS020 = 'HEROKU_SMS020';                 // 입금-송장 반제처리 전송

    public static final String IF_SMS010_ASYNC = 'HEROKU_SMS010(Async)';    // 구매오더확정 전송
    public static final String IF_SMS011_ASYNC = 'HEROKU_SMS011(Async)';    // 구매인보이스 전송
    public static final String IF_SMS012_ASYNC = 'HEROKU_SMS012(Async)';    // 통관정보 전송

    public static final String IF_SMS001 = 'HEROKU_SMS001';                 // 부품재고조회
    public static final String IF_SMS002 = 'HEROKU_SMS002';                 // 차량재고 조회

    // 단순 화면조회(미구현)
    public static final String IF_SMS006 = 'HEROKU_SMS006';                 // 재고이동요청결과2
    public static final String IF_SMS008 = 'HEROKU_SMS008';                 // BP 조회

    // FetchSAPResult_ba
    public static final String IF_SMS005 = 'HEROKU_SMS005';                 // 재고이동요청결과
    public static final String IF_SMS014 = 'HEROKU_SMS014';                 // 구매오더확정 조회
    public static final String IF_SMS015 = 'HEROKU_SMS015';                 // 구매인보이스 조회
    public static final String IF_SMS016 = 'HEROKU_SMS016';                 // 통관정보 조회
    public static final String IF_SMS017 = 'HEROKU_SMS017';                 // 매출확정정보 조회

    public static void doHealthCheck() {
        IF_DTO.CommonResult result = new IF_DTO.CommonResult();
        IF_Util ifUtil = new IF_Util(IF_SMS000);

        HttpResponse response = ifUtil.webCallout(null);
        if (HttpCallOutConsts.SUCCESS_CODES.contains(response.getStatusCode())) {
            try {
                result = (IF_DTO.CommonResult) JSON.deserialize(response.getBody(), IF_DTO.CommonResult.class);
            } catch(Exception e) {
                System.debug(e.getMessage());
            }
        }
        System.debug(result);
    }

    public static Map<String, Object> doCallOutSAP(String ifId, List<Object> items) {
        return doCallOutSAP(ifId, items, null);
    }

    /**
     * @param ifId      Interface Id
     * @param items     Body Items
     * @param logId     Update대상 logId
     * @description     SAP Interface 공통함수
     * @return          Map<String, Object> Value
     */
    public static Map<String, Object> doCallOutSAP(String ifId, List<Object> items, String logId) {
        Map<String, Object> returnMap = new Map<String, Object>();
        IF_Util ifUtil = new IF_Util(ifId);
        System.debug('InterfaceId : ' + ifId);
        System.debug('Log Id : ' + logId);
        String body = CommonUtilCustomController.parseStringSAP(ifId, items, logId);

        HttpResponse response = ifUtil.webCallout(body);
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
    public static Map<String, Object> doCallOutSAPLog(Map<String, Object> infoMap) {
        String ifId = String.valueOf(infoMap.get('ifId'));
        String logId = String.valueOf(infoMap.get('logId'));
        String type = String.valueOf(infoMap.get('logType'));

        Boolean isLog = infoMap.containsKey('isLog')
                ? Boolean.valueOf(infoMap.get('isLog'))
                : true;
        Boolean isLogDetail = infoMap.containsKey('isLogDetail')
                ? Boolean.valueOf(infoMap.get('isLogDetail'))
                : false;

        Map<String, String> keyMap = infoMap.containsKey('keyMap')
                ? (Map<String, String>) infoMap.get('keyMap')
                : new Map<String, String>();
        List<Object> items = (List<Object>) infoMap.get('items');

        Map<String, Object> returnMap = new Map<String, Object>();
        String requestBody = CommonUtilCustomController.parseStringSAP(ifId, items, logId);
        System.debug(requestBody);
        String responseBody;
        try {
            returnMap = doCallOutSAP(ifId, items, logId);
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