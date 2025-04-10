/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-26      payo03@solomontech.net           Created
*/
@IsTest
public with sharing class SAPCommon_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createConfigBundle();
        TestObjectBuilder2.createIfBundle();
        TestObjectBuilder2.createOrderBundle();

        Database.executeBatch(new CreateVehicleStock_ba(null, null), 200);
    }

    @IsTest
    static void testBehavior() {

        List<String> idList = new List<String>();
        for(AvisOrderInfo__c info : [
                SELECT Id
                FROM AvisOrderInfo__c
        ]) {
            idList.add(info.Id);
        }
        Set<String> spoilerSet = new Set<String>();
        for(SpoilerPart__c part : [
                SELECT Id, SpoilerCode__c
                FROM SpoilerPart__c
        ]) {
            spoilerSet.add(part.SpoilerCode__c);
        }
        IFAuditLogDetail__c detail = [SELECT Id, fm_LogId__c FROM IFAuditLogDetail__c LIMIT 1];
        Map<String, Object> infoMap = new Map<String, Object>{
                'code' => true,
                'message' => new Map<String, String>{
                        'Code' => '0',
                        'Message' => '1'
                }
        };


        List<Map<String, String>> paramMapList = new List<Map<String, String>>();
        for(VehicleStock__c stock : [
                SELECT Id, Name, Product__r.VehicleCategory__r.ERPCode__c
                FROM VehicleStock__c
        ]) {
            Map<String, String> paramMap = new Map<String, String>{
                    'ITEMCD' => stock.Name,
                    'DISNUM' => stock.Product__r.VehicleCategory__r.ERPCode__c
            };

            paramMapList.add(paramMap);
        }

        List<AvisOrderInfo__c> infoList = SAPCommon.fetchOrderInfoList(idList);
        Map<String, SpoilerPart__c> spoilerMap = SAPCommon.fetchSpoilerMap(infoList);
        SAPCommon.asyncLogDetailUpdate(detail.fm_LogId__c, infoMap);
        SAPCommon.syncLogDetailUpdate(detail.fm_LogId__c, infoMap);
        SAPCommon.fetchSpoilerStockAPI(spoilerSet);
        SAPCommon.fetchVehicleStockAPI(paramMapList);
    }
}