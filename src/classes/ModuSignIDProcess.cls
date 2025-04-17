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
        Account acc = [
                SELECT Id, IsTaxIDNumber__c
                FROM Account
                WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id = :opptyId)
        ];
        acc.IsTaxIDNumber__c = true;
        update acc;

        return null;
    }
}