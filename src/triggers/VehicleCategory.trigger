/*************************************************************
 * @author : th.kim
 * @date : 2024-11-20
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-20      th.kim          Created
**************************************************************/
trigger VehicleCategory on VehicleCategory__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    TriggerHandler.runTriggerByCustomMeta(this);
}