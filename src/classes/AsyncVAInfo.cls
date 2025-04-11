/**
* @Author            : payo03@solomontech.net
* @Description 		 : 가상계좌 정보 전송, AsyncCustomerInfo Chaining Queue
* @Target            : AsyncInterface_test
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-12      payo03@solomontech.net           Created
*/
public without sharing class AsyncVAInfo implements Queueable, Database.AllowsCallouts {

    // O : 영업기회, S : 영업사원(User)
    public enum SEND_TYPE {
        O, S
    }
    public List<String> paramLogIdList;
    public SEND_TYPE sendType;
    public AsyncVAInfo(List<String> paramLogIdList, SEND_TYPE sendType) {
        this.paramLogIdList = paramLogIdList;
        this.sendType = sendType;
    }

    public void execute(QueueableContext context) {
        try {
            Set<String> transferAccSet = new Set<String>();
            for(IFAuditLogDetail__c logDetail : [
                    SELECT Id, ExternalId__c
                    FROM IFAuditLogDetail__c
                    WHERE fm_LogId__c IN :paramLogIdList
            ]) {
                transferAccSet.add(logDetail.ExternalId__c);
            }

            String logId = CommonUtilCustomController.parseIFIdSAP(InterfaceSAP.DFLT);
            Map<String, String> keyMap = new Map<String, String>();
            List<IF_DTO.AccountVAInfo> vaInfoList = new List<IF_DTO.AccountVAInfo>();
            for(Opportunity oppty : [
                    SELECT Id, VirtualAccount__c,
                            Account.BPCode__c,
                            VirtualAccount__r.fm_VirtualAccount__c
                    FROM Opportunity
                    WHERE AccountId IN :transferAccSet
            ]) {
                String virtualAccountNum = oppty.VirtualAccount__r.fm_VirtualAccount__c;

                IF_DTO.AccountVAInfo info = new IF_DTO.AccountVAInfo(true);
                info.U_CardCD = oppty.Account.BPCode__c;
                info.U_ACCNO = virtualAccountNum;
                info.TYPE = sendType.equals(SEND_TYPE.S) ? 'S' : 'O';

                vaInfoList.add(info);
                keyMap.put(oppty.VirtualAccount__c, virtualAccountNum);
            }

            if(!vaInfoList.isEmpty()) {
                Map<String, Object> infoMap = new Map<String, Object>();
                String logType = 'VA_CUSTOMER_INFO';

                infoMap.put('ifId', InterfaceSAP.IF_SMS018);
                infoMap.put('logId', logId);
                infoMap.put('logType', logType);
                infoMap.put('items', vaInfoList);
                infoMap.put('keyMap', keyMap);
                infoMap.put('isLogDetail', true);

                Map<String, Object> resultMap = InterfaceSAP.doCallOutSAPLog(infoMap);
                resultMap.put('isAll', true);
                SAPCommon.syncLogDetailUpdate(logId, resultMap);    // Heroku 통신 완료시. Sync
            }
        } catch(Exception e) {

            System.debug(e.getMessage());
        }
    }
}