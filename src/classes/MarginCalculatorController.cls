/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-03-12      jh.jung           Created
*/
public with sharing class MarginCalculatorController {

    @AuraEnabled(Cacheable=true)
    public static Map<String, Object> getInit() {

        Map<String, Map<String, Object>> returnMap = new Map<String, Map<String, Object>>();

//        List<ConfigDetail__c> configDetailList = CommonUtilCustomController.getConfigDetailLow('MAN6000');
//
//        Map<String, ConfigDetail__c> configDetailMap = new Map<String, ConfigDetail__c>();
//        for (ConfigDetail__c config : configDetailList) {
//            configDetailMap.put(config.Name, config);
//        }

        List<AvgLocalCost__c> avgLocalCostList = [
                SELECT ReportSpec__c, LocalCostAvg__c, PdiCostAvg__c, OtherCostAvg__c
                FROM AvgLocalCost__c
                WHERE Active__c = TRUE
        ];

        Map<String, AvgLocalCost__c> avgLocalCostMap = new Map<String, AvgLocalCost__c>();
        for (AvgLocalCost__c tempObj : avgLocalCostList) {
            avgLocalCostMap.put(tempObj.ReportSpec__c, tempObj);
        }


        List<Product2> productList = [
                SELECT
                        Id, Name, IsOTV__c, IsLNS__c, TrimLevel__c, VehicleCategory__r.Name, toLabel(EmissionLevel__c),
                        SalesConditionMaster__r.Discount__c, CarAmt__c, (SELECT AvisOrderInfo__r.BuyingPrice__c  FROM VehicleStock__r)
                FROM Product2
                WHERE SalesConditionMaster__c != NULL
//                WHERE VehicleCategory__r.Name IN :avgLocalCostMap.keySet()
//                AND Id IN (
//                        SELECT Product__c
//                        FROM VehicleStock__c
//                        WHERE VehicleStatus__c IN ('입고', '항구도착', '항구도착전')
//                )
                ORDER BY VehicleCategory__r.Name, Name
        ];

        for(Product2 product : productList) {
            Map<String, Object> objMap = new Map<String, Object> {
                    'product' => product
                    , 'config' => avgLocalCostMap.get(product.VehicleCategory__r.Name)
            };
//                returnMap.put(product.Id, objMap);
            returnMap.put(product.Name, objMap);
        }

        return returnMap;
    }
}