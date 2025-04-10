/*************************************************************
 * @author : th.kim
 * @date : 2025-01-07
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-07      th.kim          Created
**************************************************************/
trigger QuoteLineItem on QuoteLineItem (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    TriggerHandler.runTriggerByCustomMeta(this);
}