/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-06
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-06        San.Kang           Created
**************************************************************/
trigger Account on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    // Apex TriggerHandler 실행
    TriggerHandler.runTriggerByCustomMeta(this);
}