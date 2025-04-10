/*************************************************************
 * @author : th.kim
 * @date : 2025-02-10
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-02-10      th.kim          Created
**************************************************************/
trigger PaymentTracker on PaymentTracker__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    TriggerHandler.runTriggerByCustomMeta(this);
}