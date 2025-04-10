/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-20      jh.jung           Created
*/
trigger Lead on Lead (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerHandler.runTriggerByCustomMeta(this);
}