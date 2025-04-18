/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-04-17      jh.jung                          Created
*/
public with sharing class ModuSignIDProcess extends CommonAfterProcess {

    public override Object doAfterProcess(Object obj) {
        String opptyId = String.valueOf(obj);

        try {
            APIDocument__c doc = [SELECT Id, Status__c, FileName__c FROM APIDocument__c WHERE ExternalId__c = :opptyId];
            if (!'COMPLETED'.equals(doc.Status__c)) throw new CustomException('서명이 완료되지 않았습니다');

            Account acc = [
                    SELECT Id, IsTaxIDNumber__c
                    FROM Account
                    WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id = :opptyId)
            ];
            acc.IsTaxIDNumber__c = true;
            update acc;
        } catch(Exception e) {

            System.debug(e.getMessage());
        }

        return null;
    }
}