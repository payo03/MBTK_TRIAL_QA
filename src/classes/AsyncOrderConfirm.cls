/**
* @Author            : payo03@solomontech.net
* @Description 		 : OrderConfirm Queue Job
* @Target            : CreateVehicleStock_ba_test
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-16      payo03@solomontech.net           Created
  1.1      2025-02-18      payo03@solomontech.net           Spoiler 존재할경우 SAP 전송대상 추가
  1.2      2025-04-14      payo03@solomontech.net           취소 IF 추가
*/
public without sharing class AsyncOrderConfirm implements Queueable, Database.AllowsCallouts {

    private static final Integer WEIGHT = 70;
    private static final String LOG_TYPE_S = 'ORDER_CONFIRM';
    private static final String LOG_TYPE_C = 'ORDER_CONFIRM_CANCEL';
    public List<String> idList;
    public Map<String, Object> infoMap;

    public AsyncOrderConfirm(List<String> idList, Map<String, Object> infoMap) {
        this.idList = idList;
        this.infoMap = infoMap;
    }

    public void execute(QueueableContext context) {
        Map<String, Object> dataMap = infoMap == null || infoMap.isEmpty()
                ? new Map<String, Object>()
                : infoMap;

        String logId = CommonUtilCustomController.parseIFIdSAP(InterfaceSAP.PREFIX_ORDER_CONFIRM);
        Boolean isCreate = dataMap.isEmpty() ? true : Boolean.valueOf(dataMap.get('isCreate'));
        String logType = isCreate ? LOG_TYPE_S : LOG_TYPE_C;

        // ver1.2 취소 IF 추가
        // 취소데이터인경우, logId를 기존것으로 재활용
        Map<String, String> logIdMap = SAPCommon.fetchLogExternalIdMap(idList, LOG_TYPE_S); // KEY : AvisOrderInfoId, Value : Log Id
        List<AvisOrderInfo__c> infoList = SAPCommon.fetchOrderInfoList(idList);
        Map<String, SpoilerPart__c> spoilerMap = SAPCommon.fetchSpoilerMap(infoList);

        Map<String, String> keyMap = new Map<String, String>();
        Map<String, List<IF_DTO.OrderConfirm>> logConfirmListMap = new Map<String, List<IF_DTO.OrderConfirm>>();
        for(AvisOrderInfo__c info : infoList) {
            // ver1.2 취소 IF 추가
            String internalLogId = !isCreate && logIdMap.containsKey(info.Id)
                    ? logIdMap.get(info.Id)
                    : logId;
            List<IF_DTO.OrderConfirm> confirmList = logConfirmListMap.containsKey(internalLogId)
                    ? logConfirmListMap.get(internalLogId)
                    : new List<IF_DTO.OrderConfirm>();

            VehicleStock__c stock = info.VehicleStock__r;
            String externalKey = info.OrderIntakeNo__c + ', ' + stock.VehicleNo__c + ', ' + stock.Name;
            keyMap.put(info.Id, externalKey);

            IF_DTO.OrderConfirm confirm = new IF_DTO.OrderConfirm(info, isCreate);
            confirm.ITEM_TYPE = 'V';
            confirm.IFID = internalLogId;

            // Spoiler 패키지 항목추가
            String key = CommonUtilCustomController.getSpoilerKey(info);
            SpoilerPart__c spoilerPart = spoilerMap.get(key);
            if(info.IsSpoiler__c > 0 && spoilerPart != null) {
                String price = String.valueOf(spoilerPart.Price__c);

                IF_DTO.OrderConfirm spoilerConfirm = confirm.clone();
                spoilerConfirm.ITEM_TYPE = 'P';
                spoilerConfirm.ITEMCD = spoilerPart.SpoilerCode__c;
                spoilerConfirm.PRCAMT = price;
                spoilerConfirm.ITEMAMT = price;
                spoilerConfirm.WEGHT = String.valueOf(WEIGHT);
                confirmList.add(spoilerConfirm);

                // Spoiler존재시 기존데이터 차감적용
                String subPriceAmt = String.valueOf(Decimal.valueOf(confirm.PRCAMT) - Decimal.valueOf(price));
                Decimal subWeight = Decimal.valueOf(confirm.WEGHT) - WEIGHT;
                String subWeightStr = String.valueOf(subWeight > 0 ? subWeight : Decimal.valueOf(confirm.WEGHT));

                confirm.PRCAMT = subPriceAmt;
                confirm.ITEMAMT = subPriceAmt;
                confirm.WEGHT = subWeightStr;
            }
            confirmList.add(confirm);
            logConfirmListMap.put(internalLogId, confirmList);
        }

        // ver1.2 취소 IF 추가
        if(!logConfirmListMap.isEmpty()) {
            for(String internalLogId : logConfirmListMap.keySet()) {
                Map<String, Object> infoMap = new Map<String, Object>();

                infoMap.put('ifId', InterfaceSAP.IF_SMS010_ASYNC);
                infoMap.put('logId', internalLogId);
                infoMap.put('logType', logType);
                infoMap.put('keyMap', keyMap);
                infoMap.put('items', logConfirmListMap.get(internalLogId));
                infoMap.put('isLogDetail', true);

                Map<String, Object> resultMap = InterfaceSAP.doCallOutSAPLog(infoMap);
                SAPCommon.asyncLogDetailUpdate(internalLogId, resultMap);   // Heroku 통신 완료시. Async
                SAPCommon.updateLogByExternalId(idList, LOG_TYPE_S);
            }
        }
    }
}