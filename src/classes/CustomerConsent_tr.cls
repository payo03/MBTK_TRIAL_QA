/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-18
 * @description : Light Consent, Declined Consent 로직
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-18        San.Kang           Created
**************************************************************/
public without sharing class CustomerConsent_tr extends TriggerHandler {
    /** TriggerHandler */
    private final List<CustomerConsent__c> newList { get; set; }
    private final List<CustomerConsent__c> oldList { get; set; }
    private final Map<Id, CustomerConsent__c> oldMap { get; set; }
    private final Map<Id, CustomerConsent__c> newMap { get; set; }

    public CustomerConsent_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap = (Map<Id, CustomerConsent__c>) Trigger.newMap;
        oldMap = (Map<Id, CustomerConsent__c>) Trigger.oldMap;
    }

    public override void beforeInsert() {

    }

    public override void beforeUpdate() {

    }

    public override void afterInsert() {
        // Light Consent 발송 로직 추가
        SendLightConsent_sc.scheduleBatchWithParam(newList[0].Id);
    }

    public override void afterUpdate() {
        // declinedConsent 로직 추가
        declinedConsent();
    }

    // declinedConsent 로직 추가
    private void declinedConsent(){
        Set<Id> customerConsentIds = new Set<Id>();
        try{
            for(Id customerConsentId : newMap.keySet()){
                if((oldMap.get(customerConsentId).ConsentStatus__c != newMap.get(customerConsentId).ConsentStatus__c) && newMap.get(customerConsentId).ConsentStatus__c == '거절됨'){
                    customerConsentIds.add(customerConsentId);
                }
            }

            if(!customerConsentIds.isEmpty()) {
                List<CustomerConsent__c> customerConsents = [SELECT Id, Lead__c, Opportunity__c, ConsentStatus__c FROM CustomerConsent__c WHERE Id =:customerConsentIds];
                LandingPageController.declinedConsent(customerConsents);
            }

        }catch (Exception e){
            System.debug('exception => ' + e);
        }
    }

}