/**
* @Author            : payo03@solomontech.net
* @Description 		 : HandoverDateAllocationHistory_tr
* @Target            : Opportunity, HandoverDateAllocationHistory__c
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-02-12      payo03@solomontech.net           Created
*/
public without sharing class HandoverDateAllocationHistory_tr extends TriggerHandler {

    /** TriggerHandler **/
    private List<HandoverDateAllocationHistory__c>    newList { get; set; }
    private List<HandoverDateAllocationHistory__c>    oldList { get; set; }
    private Map<Id, HandoverDateAllocationHistory__c> newMap  { get; set; }
    private Map<Id, HandoverDateAllocationHistory__c> oldMap  { get; set; }
    
    public HandoverDateAllocationHistory_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap  = (Map<Id, HandoverDateAllocationHistory__c>) Trigger.newMap;
        oldMap  = (Map<Id, HandoverDateAllocationHistory__c>) Trigger.oldMap;
    }

    public override void afterInsert() {
        System.debug('HandoverDateAllocationHistory_tr.afterInsert - start');
        doSetDefaultValues();
    }

    // Opportunity의 출고일 변경. 신규 ASSIGN된 이외날짜 데이터 CANCEL처리
    private void doSetDefaultValues() {
        // 1. Base Data Select
        Map<String, List<String>> opportunityIdListMap = new Map<String, List<String>>();
        Set<String> opportunitySet = new Set<String>();
        for (HandoverDateAllocationHistory__c newHistory : newList) {
            if(newHistory.IsAssign__c) {
//                String key = newHistory.HandOverDateManagement__c;
                String key = newHistory.CustomCalendar__c;
                
                List<String> idList = opportunityIdListMap.containsKey(key) ? opportunityIdListMap.get(key) : new List<String>();
                idList.add(newHistory.Opportunity__c);
                opportunitySet.add(newHistory.Opportunity__c);
                
//                opportunityIdListMap.put(newHistory.HandOverDateManagement__c, idList);
                opportunityIdListMap.put(newHistory.CustomCalendar__c, idList);
            }
        }

        // 2. Opportunity 출고일 Update
        Map<Id, CustomCalendar__c> calendarMap = new Map<Id, CustomCalendar__c>([
                SELECT Id, Date__c
                FROM CustomCalendar__c
                WHERE Id IN :opportunityIdListMap.keySet()
        ]);
        List<Opportunity> updateOpportunities = new List<Opportunity>();
        for(Id handOverDateId : calendarMap.keySet()) {
            for(String opportunityId : opportunityIdListMap.get(handOverDateId)) {
                Opportunity opportunity = new Opportunity(Id = opportunityId);
                opportunity.HandoverDate__c = calendarMap.get(handOverDateId).Date__c;

                updateOpportunities.add(opportunity);
            }
        }
        if(!updateOpportunities.isEmpty()) update updateOpportunities;

        // 3. 기존 할당 내역 조회 및 취소 처리
        List<HandoverDateAllocationHistory__c> existHistories = [
                SELECT Id, IsAssign__c
                FROM HandoverDateAllocationHistory__c
                WHERE Opportunity__c IN :opportunitySet
                AND (NOT Id IN :newMap.keySet())
        ];
        for (HandoverDateAllocationHistory__c existHistory : existHistories) {
            existHistory.IsAssign__c = false;
        }
        if(!existHistories.isEmpty()) update existHistories;
    }

}