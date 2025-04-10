/**
* @Author            : payo03@solomontech.net
* @Description 		 : IFAuditLogDetail_tr
* @Target            : IF실패 이메일전송
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-19      payo03@solomontech.net           Created
*/
public without sharing class IFAuditLogDetail_tr extends TriggerHandler {

    private final static String EMAIL_CODE = 'MAN2000';
    private final static String IF_MAIL_CODE = 'MAN2002';

    private final static String LOG_OBJ_NAME = 'IFAuditLogDetail__c';
    private final static String LOG_CSV_FILENAME = 'log.csv';
    private final static String LOG_CSV_HEADER = 'CreatedDate, logId, logType, ExternalId, Request, Response, Result, Description';
    private final static String LOG_CSV_BODY = 'CreatedDate, fm_LogId__c, fm_LogType__c, ExternalId__c, IsRequest__c, IsResponse__c, IsResult__c, Description__c';

    /** TriggerHandler **/
    private List<IFAuditLogDetail__c>    newList { get; set; }
    private List<IFAuditLogDetail__c>    oldList { get; set; }
    private Map<Id, IFAuditLogDetail__c> newMap  { get; set; }
    private Map<Id, IFAuditLogDetail__c> oldMap  { get; set; }

    public IFAuditLogDetail_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap  = (Map<Id, IFAuditLogDetail__c>) Trigger.newMap;
        oldMap  = (Map<Id, IFAuditLogDetail__c>) Trigger.oldMap;
    }

    public override void afterInsert() {
        System.debug('IFAuditLogDetail_tr.beforeInsert - start');
        doSetDefaultValues();
    }

    public override void afterUpdate() {
        System.debug('IFAuditLogDetail_tr.beforeUpdate - start');
        doSetDefaultValues();
    }

    // IF 실패시 메일전송
    private void doSetDefaultValues() {

        Map<String, List<String>> objectIdListMap = new Map<String, List<String>>();
        Map<String, List<String>> objectExternalIdListMap = new Map<String, List<String>>();
        for(IFAuditLogDetail__c newObj : newList) {
            IFAuditLogDetail__c oldObj = new IFAuditLogDetail__c();
            if (oldMap != null) oldObj = oldMap.get(newObj.Id);

            String objectType = newObj.ObjectType__c;
            // Response기준. 취소 Update(Async) 혹은 취소로 생성(Sync)
            if(
                (Trigger.isUpdate && oldObj.IsResponse__c != 'C' && newObj.IsResponse__c == 'C') ||
                (Trigger.isInsert && newObj.IsResponse__c == 'C')
            ) {

                List<String> objectLogIdList = objectIdListMap.containsKey(objectType)
                        ? objectIdListMap.get(objectType)
                        : new List<String>();
                List<String> objectLogExternalIdList = objectExternalIdListMap.containsKey(objectType)
                        ? objectExternalIdListMap.get(objectType)
                        : new List<String>();

                objectLogIdList.add(newObj.Id);
                objectLogExternalIdList.add(newObj.ExternalId__c);
                
                objectIdListMap.put(objectType, objectLogIdList);
                objectExternalIdListMap.put(objectType, objectLogExternalIdList);
            }
        }

        // 도착대상이 존재하여 Mail 전송이 필요한 경우
        if(!objectIdListMap.isEmpty()) {
            // ver1.1 도착대상에 대한 CSV 첨부
            Map<String, ConfigDetail__c> configMap = CommonUtilCustomController.getCodeMap(EMAIL_CODE).get(IF_MAIL_CODE);

            List<Map<String, Object>> mailInfoList = new List<Map<String, Object>>();
            for(String objectType : objectIdListMap.keySet()) {
                ConfigDetail__c detail = configMap.get(objectType);
                if(detail == null) continue;    // Email설정건 미존재시 PASS

                List<String> idList = objectIdListMap.get(objectType);
                List<String> externalIdList = objectExternalIdListMap.get(objectType);

                String sender = detail.Attribute1__c;
                String subject = detail.Attribute2__c;
                String emailBody = detail.Attribute3__c;
                String emailEnd = detail.Attribute4__c;

                String fileName = detail.Attribute5__c;
                String csvHeader = detail.Attribute6__c;
                String csvBody = detail.Attribute7__c;

                List<String> toAddresses = detail.Attribute20__c.trim().split(',');
                List<String> ccAddresses = new List<String>();  // 참조자
                List<String> bccAddresses = new List<String>(); // 숨은 참조자

                Map<String, Object> mailInfo = new Map<String, Object>();
                mailInfo.put('subject', subject);
                mailInfo.put('body', emailBody + emailEnd);
                mailInfo.put('sender', sender);
                mailInfo.put('to', toAddresses);
                mailInfo.put('cc', ccAddresses);
                mailInfo.put('bcc', bccAddresses);

                // ver1.1 도착대상에 대한 CSV 첨부
                // File1. raw 데이터
                // File2. Custom설정 데이터
                List<Messaging.EmailFileAttachment> fileList = new List<Messaging.EmailFileAttachment>{
                        EmailConfigController.returnCSV(LOG_OBJ_NAME, idList, LOG_CSV_FILENAME, LOG_CSV_HEADER, LOG_CSV_BODY),
                        EmailConfigController.returnCSV(objectType, externalIdList, fileName, csvHeader, csvBody)
                };
                mailInfo.put('fileList', fileList);

                mailInfoList.add(mailInfo);
            }
            EmailConfigController.sendEmail(mailInfoList);
        }
    }
}