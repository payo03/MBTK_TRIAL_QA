/*************************************************************
 * @author : th.kim
 * @date : 2025-01-22
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-22      th.kim          Created
**************************************************************/
trigger Handover on Handover__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    TriggerHandler.runTriggerByCustomMeta(this);
}