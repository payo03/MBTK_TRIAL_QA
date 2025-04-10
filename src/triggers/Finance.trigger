/*************************************************************
 * @author : San.Kang
 * @date : 2025-01-23
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-01-23        San.Kang           Created
**************************************************************/
trigger Finance on Finance__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    // Apex TriggerHandler 실행
    TriggerHandler.runTriggerByCustomMeta(this);
}