/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-07
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-07      chaebeom.do     Created
 * 2.0          2025-03-14      chaebeom.do     사전배정 프로세스 삭제로 인한 이름 변경
**************************************************************/
trigger AssignRequest on AssignRequest__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerHandler.runTriggerByCustomMeta(this);
}