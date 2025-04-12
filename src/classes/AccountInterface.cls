/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-26      payo03@solomontech.net           Created
*/
public with sharing class AccountInterface {
    
    @AuraEnabled
    public static Account fetchRecord(String recordId) {
        System.debug('TEST86');
        System.debug('TEST87');
        System.debug('TEST89');
        return [
                SELECT Id, BusinessNumber__c, BusinessName__c, IDNumber__pc, PersonEmail, PostalCode__c, RoadAddress__c, PersonMobilePhone
                FROM Account
                WHERE Id = :recordId
        ];
    }

    @AuraEnabled
    public static void updateRecord(Account account) {
        update account;
    }

    @AuraEnabled
    public static void sendCustomerInfo(String recordId) {

        System.enqueueJob(new AsyncCustomerInfo(new List<String>{recordId}, AsyncVAInfo.SEND_TYPE.S));
    }
}
