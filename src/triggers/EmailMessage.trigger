trigger EmailMessage on EmailMessage (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    // Apex TriggerHandler 실행
    TriggerHandler.runTriggerByCustomMeta(this);
}