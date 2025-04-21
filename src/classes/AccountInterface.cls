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
        Map<String, Object> infoMap = new Map<String, Object>{
                'sendType' => AsyncVAInfo.SEND_TYPE.S,
                'isChain' => true
        };

        System.enqueueJob(new AsyncCustomerInfo(new List<String>{recordId}, infoMap));
    }
}