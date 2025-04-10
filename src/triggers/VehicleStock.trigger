/*************************************************************
 * @author : th.kim
 * @date : 2024-11-18
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-18      th.kim          Created
**************************************************************/
trigger VehicleStock on VehicleStock__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    TriggerHandler.runTriggerByCustomMeta(this);
}