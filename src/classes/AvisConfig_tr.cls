/**
* @Author            : payo03@solomontech.net
* @Description 		 : AvisConfig_tr
* @Target            : AvisOrderInfo_tr 연관있음
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-10      payo03@solomontech.net           Created
*/
public without sharing class AvisConfig_tr extends TriggerHandler {

    // 10분 이후에 config 재수행시 기존데이터 Deactivate 처리
    private static final Integer ADJUST_MINUTES = -10;

    /** TriggerHandler **/
    private List<AvisConfig__c>    newList { get; set; }
    private List<AvisConfig__c>    oldList { get; set; }
    private Map<Id, AvisConfig__c> newMap  { get; set; }
    private Map<Id, AvisConfig__c> oldMap  { get; set; }
    
    public AvisConfig_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap  = (Map<Id, AvisConfig__c>) Trigger.newMap;
        oldMap  = (Map<Id, AvisConfig__c>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        System.debug('AvisConfig_tr.beforeInsert - start');
        doSetDefaultValues();
    }

    public override void afterInsert() {
        System.debug('AvisConfig_tr.afterInsert - start');
        doUpdateAvisOrder();
    }

    private void doSetDefaultValues() {
        Set<String> orderNumberSet = new Set<String>();
        Map<String, AvisConfig__c> configMap = new Map<String, AvisConfig__c>();
        for(AvisConfig__c newConfig : newList) {
            String key = newConfig.OrderIntakeNo__c + '-' + newConfig.CodeNo__c;

            orderNumberSet.add(newConfig.OrderIntakeNo__c);
            configMap.put(key, newConfig);
        }

        // 기존에 있었던 Config데이터들 비활성화
        List<AvisConfig__c> deleteList = new List<AvisConfig__c>();
        List<AvisConfig__c> updateList = new List<AvisConfig__c>();
        for(AvisConfig__c existConfig : [
                SELECT Id, OrderIntakeNo__c, CodeNo__c,
                IsActive__c, DeactivateTime__c
                FROM AvisConfig__c
                WHERE OrderIntakeNo__c IN: orderNumberSet
                AND LastModifiedDate <= :Datetime.now().addMinutes(ADJUST_MINUTES)
                AND IsActive__c = TRUE
        ]) {
            String key = existConfig.OrderIntakeNo__c + '-' + existConfig.CodeNo__c;

            existConfig.IsActive__c = false;
            existConfig.DeactivateTime__c = Datetime.now();

            // 기존데이터 삭제, 비활성화(Key값 불일치할경우)
            if(configMap.get(key) != null) {
                deleteList.add(existConfig);
            } else {
                updateList.add(existConfig);
            }
        }
        if(!updateList.isEmpty()) update updateList;
        if(!deleteList.isEmpty()) delete deleteList;
    }

    private void doUpdateAvisOrder() {
        List<AvisOrderInfo__c> updateList = new List<AvisOrderInfo__c>();

        Set<String> orderSet = new Set<String>();
        for(AvisConfig__c newConfig : newList) {

            if(newConfig.fm_Intarder__c == 1) orderSet.add(newConfig.OrderIntakeNo__c);
            if(newConfig.fm_Pretarder__c == 1) orderSet.add(newConfig.OrderIntakeNo__c);
            if(newConfig.fm_Hypoid__c == 1) orderSet.add(newConfig.OrderIntakeNo__c);
            if(newConfig.fm_PTO__c == 1) orderSet.add(newConfig.OrderIntakeNo__c);
            if(newConfig.fm_Spoiler__c == 1) orderSet.add(newConfig.OrderIntakeNo__c);
            if(newConfig.fm_HQMY__c != null) orderSet.add(newConfig.OrderIntakeNo__c);
            if(newConfig.fm_EmissionLevel__c != null) orderSet.add(newConfig.OrderIntakeNo__c);
        }

        // AvisOrderInfo_tr에서 Update하도록 Trigger 호출 ( Intarder, Pretarder, Hypoid, PTO, Spoiler, LocalYear, EmissionLevel )
        for(AvisOrderInfo__c info : [SELECT Id FROM AvisOrderInfo__c WHERE OrderIntakeNo__c IN: orderSet]) {
            updateList.add(info);
        }

        if(!updateList.isEmpty()) update updateList;
    }

    @TestVisible
    private void test(List<AvisConfig__c> configs) {
        newList = new List<AvisConfig__c>();
        newList.addAll(configs);

        oldList = new List<AvisConfig__c>();
        oldMap = new Map<Id, AvisConfig__c>();
        for(AvisConfig__c config : configs) {
            AvisConfig__c oldConfig = config.clone(false);

            if(oldConfig.CodeNo__c == '0P0JX') oldConfig.CodeNo__c = '0PHZN';
            if(oldConfig.CodeNo__c == '0PHOQ') oldConfig.CodeNo__c = '0PHOR';

            oldList.add(oldConfig);
            oldMap.put(config.Id, oldConfig);
        }
    }
}