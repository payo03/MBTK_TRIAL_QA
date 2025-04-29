/**
* @Author            : payo03@solomontech.net
* @Description 		 : CustomsInfo Queue Job
* @Target            : CreateVehicleStock_ba_test
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-02-28      payo03@solomontech.net           Created
  1.1      2025-04-14      payo03@solomontech.net           취소 IF 추가
*/
public without sharing class AsyncCustomsInfo implements Queueable, Database.AllowsCallouts {

    private static final Integer WEIGHT = 70;
    private static final String LOG_TYPE_S = 'CUSTOMS_INFO';
    private static final String LOG_TYPE_C = 'CUSTOMS_INFO_CANCEL';
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

        String logId = CommonUtilCustomController.parseIFId(InterfaceSAP.PREFIX_CUSTOMS_INFO);
        Boolean isCreate = dataMap.isEmpty() ? true : Boolean.valueOf(dataMap.get('isCreate'));
        String logType = isCreate ? LOG_TYPE_S : LOG_TYPE_C;

        // ver1.1 취소 IF 추가
        // 취소데이터인경우, logId를 기존것으로 재활용
        Map<String, String> logIdMap = SAPCommon.fetchLogExternalIdMap(idList, LOG_TYPE_S);   // KEY : AvisOrderInfoId, Value : Log Id
        List<AvisOrderInfo__c> infoList = SAPCommon.fetchOrderInfoList(idList);
        Map<String, SpoilerPart__c> spoilerMap = SAPCommon.fetchSpoilerMap(infoList);

        Map<String, String> keyMap = new Map<String, String>();
        Map<String, List<IF_DTO.CustomsInfo>> logCustomsInfoListMap = new Map<String, List<IF_DTO.CustomsInfo>>();
        for(AvisOrderInfo__c info : infoList) {
            // ver1.1 취소 IF 추가
            String internalLogId = !isCreate && logIdMap.containsKey(info.Id)
                    ? logIdMap.get(info.Id)
                    : logId;
            List<IF_DTO.CustomsInfo> customsInfoList = logCustomsInfoListMap.containsKey(internalLogId)
                    ? logCustomsInfoListMap.get(internalLogId)
                    : new List<IF_DTO.CustomsInfo>();

            VehicleStock__c stock = info.VehicleStock__r;
            String externalKey = info.OrderIntakeNo__c + ', ' + stock.VehicleNo__c + ', ' + stock.Name;
            keyMap.put(info.Id, externalKey);

            IF_DTO.CustomsInfo customsInfo = new IF_DTO.CustomsInfo(info, isCreate);
            customsInfo.ITEM_TYPE = 'V';
            customsInfo.IFID = internalLogId;

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
            logCustomsInfoListMap.put(internalLogId, customsInfoList);
        }

        // ver1.2 취소 IF 추가
        if(!logCustomsInfoListMap.isEmpty()) {
            for (String internalLogId : logCustomsInfoListMap.keySet()) {
                Map<String, Object> infoMap = new Map<String, Object>();

                infoMap.put('ifId', InterfaceSAP.IF_SMS012_ASYNC);
                infoMap.put('logId', internalLogId);
                infoMap.put('logType', logType);
                infoMap.put('keyMap', keyMap);
                infoMap.put('items', logCustomsInfoListMap.get(internalLogId));
                infoMap.put('isLogDetail', true);

                Map<String, Object> resultMap = InterfaceSAP.doCallOutSAPLog(infoMap);
                SAPCommon.asyncLogDetailUpdate(internalLogId, resultMap);   // Heroku 통신 완료시. Async
                SAPCommon.updateLogByExternalId(idList, LOG_TYPE_S);
            }
        }
    }
}