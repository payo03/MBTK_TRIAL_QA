/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author            Modification
  ===================================================================================
  1.0      2024-11-22      jh.jung           Created
*/
public with sharing class CampaignUtilityBarController {

    @AuraEnabled
    public static List<CampaignMaster__c> getCampaignList() {
        return [
                SELECT Id, Name, StartDate__c,
                        ExpireDate__c, DiscountRate__c, DiscountPrice__c
//                        , (SELECT Id, Name, Product__r.Name, Product__r.Id FROM CampaignJunction__r)
                FROM CampaignMaster__c
                WHERE Status__c = '진행중'
        ];
    }

}