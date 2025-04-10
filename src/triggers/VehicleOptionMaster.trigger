/*************************************************************
 * @author : th.kim
 * @description : 
 * @target : 
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-26      th.kim          Created
**************************************************************/
trigger VehicleOptionMaster on VehicleOptionMaster__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    TriggerHandler.runTriggerByCustomMeta(this);
}