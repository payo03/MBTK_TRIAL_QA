/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-13
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-13      chaebeom.do     Created
**************************************************************/
trigger Contract on Contract (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerHandler.runTriggerByCustomMeta(this);
}