/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-18
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-18        San.Kang           Created
**************************************************************/
trigger CustomerConsent on CustomerConsent__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerHandler.runTriggerByCustomMeta(this);
}