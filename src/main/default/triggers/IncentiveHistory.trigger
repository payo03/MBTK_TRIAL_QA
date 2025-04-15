/*************************************************************
 * @author : th.kim
 * @date : 2025-04-07
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-04-07      th.kim          Created
**************************************************************/
trigger IncentiveHistory on IncentiveHistory__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    TriggerHandler.runTriggerByCustomMeta(this);
}