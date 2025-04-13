/**
* @Author            : payo03@solomontech.net
* @Description 		 : 고객정보 전송
* @Target            : AsyncInterface_test
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-12      payo03@solomontech.net           Created
*/
public without sharing class AsyncCustomerInfo implements Queueable, Database.AllowsCallouts {

    private static final String LOG_TYPE = 'CUSTOMER_BP';
    private static final String IF_ID = InterfaceSAP.IF_SMS007;

    public List<String> idList;
    public AsyncVAInfo.SEND_TYPE sendType;
    public AsyncCustomerInfo(List<String> idList, AsyncVAInfo.SEND_TYPE sendType) {
        this.idList = idList;
        this.sendType = sendType;
    }

    public void execute(QueueableContext context) {
        String status = 'SUCCESS';
        String requestBody = JSON.serializePretty(idList);
        String responseBody;
        String responseStatusCode = '200';
        Datetime requestTime = Datetime.now();
        Datetime responseTime;

        Map<String, IFAuditLog__c> logMap = new Map<String, IFAuditLog__c>();
        Map<String, IFAuditLogDetail__c> logDetailMap = new Map<String, IFAuditLogDetail__c>();
        try {
            // BP코드 전송
            List<Account> accList = [
                    SELECT Id, RecordTypeId, Name, IDNumber__pc, BPCode__c, PersonEmail,
                            BusinessNumber__c, BusinessName__c, Phone, RoadAddress__c, DetailAddress__c, PostalCode__c
                    FROM Account
                    WHERE Id = :idList
            ];

            List<IF_DTO.CustomerInfo> infoList = new List<IF_DTO.CustomerInfo>();
            for(Account acc : accList) {
                String logId = CommonUtilCustomController.parseIFIdSAP(InterfaceSAP.PREFIX_BP);

                IF_DTO.CustomerInfo info = new IF_DTO.CustomerInfo(acc, true);
                info.IFID = logId;
                infoList.add(info);

                // 2025-02-27 최윤석대리와 Teams미팅간 내용. SMS004, SMS007. SMS009는 단건밖에 안된다고 함......
                Map<String, Object> infoMap = new Map<String, Object>();
                String reqBody = CommonUtilCustomController.parseStringSAP(IF_ID, infoList, logId);

                infoMap.put('ifId', IF_ID);
                infoMap.put('logId', logId);
                infoMap.put('logType', LOG_TYPE);
                infoMap.put('items', infoList);
                infoMap.put('isLog', false);

                Map<String, Object> resultMap = InterfaceSAP.doCallOutSAPLog(infoMap);
                Boolean isSuccess = !resultMap.isEmpty() && Boolean.valueOf(resultMap.get('code'));
                String resBody = JSON.serializePretty(resultMap);
                responseBody += resBody + '\n';

                // SAP I/F 감사로그 Bulk Insert
                // IFAuditLog
                IFAuditLog__c log = new IFAuditLog__c();
                log.IF_Id__c = IF_ID;
                log.Name = logId;
                log.Type__c = LOG_TYPE;
                log.RawData__c = reqBody;
                log.ResponseBody__c = resBody;
                logMap.put(logId, log);

                // IFAuditLogDetail
                IFAuditLogDetail__c logDetail = new IFAuditLogDetail__c();
                logDetail.ObjectType__c = Id.valueOf(acc.Id).getSobjectType().getDescribe().getName();
                logDetail.ExternalId__c = acc.Id;
                logDetail.IsRequest__c = isSuccess;
                logDetail.ExternalKey__c = acc.BPCode__c;
                if (isSuccess) {
                    // Heroku 통신 완료시. Sync
                    String herokuMessage = String.valueOf(resultMap.get('message'));
                    Map<String, Object> sapMap = (Map<String, Object>) JSON.deserializeUntyped(herokuMessage);
                    String resultCode = String.valueOf(sapMap.get('Code')) == '0' ? 'Y' : 'C';
                    String resultMessage = String.valueOf(sapMap.get('Message'));

                    logDetail.IsResponse__c = resultCode;
                    logDetail.IsResult__c = resultCode;
                    logDetail.Description__c = resultMessage;
                    logDetail.ResultDatetime__c = Datetime.now();
                }
                logDetailMap.put(logId, logDetail);
            }
            responseTime = Datetime.now();
        } catch(Exception e) {
            status = 'ERROR';
            responseBody = e.getMessage();
            responseStatusCode = '500';
            responseTime = Datetime.now();

            System.debug(e.getMessage());
        } finally {
            if(!logMap.isEmpty()) {
                // SAP I/F 감사로그 Bulk Insert
                insert logMap.values();

                List<String> logIdList = new List<String>();
                List<IFAuditLogDetail__c> details = new List<IFAuditLogDetail__c>();
                for(String logId : logDetailMap.keySet()) {
                    IFAuditLogDetail__c detail = logDetailMap.get(logId);
                    IFAuditLog__c log = logMap.get(logId);

                    detail.IFAuditLog__c = log.Id;
                    details.add(detail);

                    if('Y'.equals(detail.IsResult__c)) logIdList.add(log.Name);
                }
                insert details;

                // 고객정보전송(SMS007) 완료시 가상계좌-BP정보(SMS018) 전송
                if(!logIdList.isEmpty()) System.enqueueJob(new AsyncVAInfo(logIdList, this.sendType)); 
            }

            IF_DTO.LogWrapper objLogWrapper = new IF_DTO.LogWrapper();
            objLogWrapper.status = status;
            objLogWrapper.requestBody = requestBody;
            objLogWrapper.responseBody = responseBody;
            objLogWrapper.errorCode = responseStatusCode;
            objLogWrapper.requestTime = requestTime;
            objLogWrapper.responseTime = responseTime;
            objLogWrapper.logType = IF_DTO.LOG_TYPE.HEROKU_SAP_OUT;

            CommonUtilCustomController.setLog(objLogWrapper);
        }
    }
}