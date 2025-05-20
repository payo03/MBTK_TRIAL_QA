/**
* @Author            : payo03@solomontech.net
* @Description 		 : VirtualAccountMaster_tr
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-05-20      payo03@solomontech.net           Created
*/
public without sharing class VirtualAccountMaster_tr extends TriggerHandler {
    private static final String LOG_TYPE = 'VA_RELEASE';
    private static final String IF_ID = InterfaceSAP.IF_SMS021;

    /** TriggerHandler **/
    private List<VirtualAccountMaster__c>    newList { get; set; }
    private List<VirtualAccountMaster__c>    oldList { get; set; }
    private Map<Id, VirtualAccountMaster__c> newMap  { get; set; }
    private Map<Id, VirtualAccountMaster__c> oldMap  { get; set; }
    
    public VirtualAccountMaster_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap  = (Map<Id, VirtualAccountMaster__c>) Trigger.newMap;
        oldMap  = (Map<Id, VirtualAccountMaster__c>) Trigger.oldMap;
    }

    public override void afterUpdate() {
        System.debug('VirtualAccountMaster_tr.afterUpdate - start');
        doSetDefaultValues();
    }

    private void doSetDefaultValues() {

        List<VirtualAccountMaster__c> releaseList = new List<VirtualAccountMaster__c>();
        for(VirtualAccountMaster__c newObj : newList) {
            VirtualAccountMaster__c oldObj = oldMap.get(newObj.Id);

            if('사용가능'.equals(newObj.Status__c) && oldObj.Status__c != newObj.Status__c) releaseList.add(newObj);
        }
        if(!releaseList.isEmpty()) releaseVirtualAccount(JSON.serialize(releaseList));
    }

    @Future(Callout=true)
    private static void releaseVirtualAccount(String releaseListStr) {
        List<VirtualAccountMaster__c> vaList = (List<VirtualAccountMaster__c>) JSON.deserialize(releaseListStr, List<VirtualAccountMaster__c>.class);

        List<IF_DTO.VirtualAccountRelease> releaseList = new List<IF_DTO.VirtualAccountRelease>();
        Map<String, String> keyMap = new Map<String, String>();

        IF_DTO.VirtualAccountRelease release = new IF_DTO.VirtualAccountRelease();
        List<String> virtualNumList = new List<String>();
        for (VirtualAccountMaster__c va : vaList) {

            virtualNumList.add(va.VirtualAccountNum__c);
            keyMap.put(va.Id, va.VirtualAccountNum__c);
        }
        release.V_ACC_NO = virtualNumList;
        releaseList.add(release);

        String logId = CommonUtilCustomController.parseIFId(InterfaceSAP.DFLT);
        Map<String, Object> infoMap = new Map<String, Object>();

        infoMap.put('ifId', IF_ID);
        infoMap.put('logId', logId);
        infoMap.put('logType', LOG_TYPE);
        infoMap.put('keyMap', keyMap);
        infoMap.put('items', releaseList);
        infoMap.put('isLogDetail', true);

        Map<String, Object> resultMap = InterfaceSAP.doCallOutSAPLog(infoMap);
        resultMap.put('isAll', true);
        SAPCommon.syncLogDetailUpdate(logId, resultMap);    // Heroku 통신 완료시. Sync
    }

    @TestVisible
    private void test(List<VirtualAccountMaster__c> objList) {
        newList = new List<VirtualAccountMaster__c>();
        newList.addAll(objList);

        oldList = new List<VirtualAccountMaster__c>();
        oldMap = new Map<Id, VirtualAccountMaster__c>();
        for(VirtualAccountMaster__c obj : objList) {
            VirtualAccountMaster__c oldObj = obj.clone(false);
            oldObj.Status__c = '할당중';

            oldList.add(oldObj);
            oldMap.put(obj.Id, oldObj);
        }
    }
}