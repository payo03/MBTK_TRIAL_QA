/**
* @Author            : payo03@solomontech.net
* @Description 		 : CustomsInfo Queue Job
* @Target            : CreateVehicleStock_ba_test
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-02-28      payo03@solomontech.net           Created
*/
public without sharing class AsyncCustomsInfo implements Queueable, Database.AllowsCallouts {

    private static final Integer WEIGHT = 70;
    public List<String> idList;
    public Map<String, Object> infoMap;

    public AsyncCustomsInfo(List<String> idList, Map<String, Object> infoMap) {
        this.idList = idList;
        this.infoMap = infoMap;
    }

    public void execute(QueueableContext context) {
        Map<String, Object> dataMap = infoMap == null || infoMap.isEmpty()
                ? new Map<String, Object>()
                : infoMap;

        String logId = CommonUtilCustomController.parseIFIdSAP(InterfaceSAP.PREFIX_CUSTOMS_INFO);
        Boolean isCreate = dataMap.isEmpty() ? true : Boolean.valueOf(dataMap.get('isCreate'));

        List<AvisOrderInfo__c> infoList = SAPCommon.fetchOrderInfoList(idList);
        Map<String, SpoilerPart__c> spoilerMap = SAPCommon.fetchSpoilerMap(infoList);

        List<IF_DTO.CustomsInfo> customsInfoList = new List<IF_DTO.CustomsInfo>();
        Map<String, String> keyMap = new Map<String, String>();
        for(AvisOrderInfo__c info : infoList) {
            VehicleStock__c stock = info.VehicleStock__r;
            String externalKey = info.OrderIntakeNo__c + ', ' + stock.VehicleNo__c + ', ' + stock.Name;
            keyMap.put(info.Id, externalKey);

            IF_DTO.CustomsInfo customsInfo = new IF_DTO.CustomsInfo(info, isCreate);
            customsInfo.IFID = logId;
            customsInfo.ITEM_TYPE = 'V';

            // Spoiler 패키지 항목추가
            String key = CommonUtilCustomController.getSpoilerKey(info);
            SpoilerPart__c spoilerPart = spoilerMap.get(key);
            if(info.IsSpoiler__c > 0 && spoilerPart != null) {
                String price = String.valueOf(spoilerPart.Price__c);

                IF_DTO.CustomsInfo spoilerCustom = customsInfo.clone();
                spoilerCustom.ITEM_TYPE = 'P';
                spoilerCustom.ITEMCD = spoilerPart.SpoilerCode__c;
                spoilerCustom.PRCAMT = price;
                spoilerCustom.ITEMAMT = price;
                spoilerCustom.WEGHT = String.valueOf(WEIGHT);
                customsInfoList.add(spoilerCustom);

                // Spoiler존재시 기존데이터 차감적용
                String subPriceAmt = String.valueOf(Decimal.valueOf(customsInfo.PRCAMT) - Decimal.valueOf(price));

                customsInfo.PRCAMT = subPriceAmt;
                customsInfo.ITEMAMT = subPriceAmt;
            }
            customsInfoList.add(customsInfo);
        }

        if(!customsInfoList.isEmpty()) {
            Map<String, Object> infoMap = new Map<String, Object>();
            infoMap.put('ifId', InterfaceSAP.IF_SMS012_ASYNC);
            infoMap.put('logId', logId);
            infoMap.put('logType', 'CUSTOMS_INFO');
            infoMap.put('keyMap', keyMap);
            infoMap.put('items', customsInfoList);
            infoMap.put('isLogDetail', true);

            Map<String, Object> resultMap = InterfaceSAP.doCallOutSAPLog(infoMap);
            SAPCommon.asyncLogDetailUpdate(logId, resultMap);   // Heroku 통신 완료시. Async
        }
    }
}