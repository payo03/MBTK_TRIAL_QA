/*************************************************************
 * @author : th.kim
 * @date : 2025-01-06
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-06      th.kim          Created
**************************************************************/
trigger Quote on Quote (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    TriggerHandler.runTriggerByCustomMeta(this);
}