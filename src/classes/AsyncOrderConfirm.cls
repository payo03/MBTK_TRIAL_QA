/**
* @Author            : payo03@solomontech.net
* @Description 		 : OrderConfirm Queue Job
* @Target            : CreateVehicleStock_ba
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-16      payo03@solomontech.net           Created
  1.1      2025-02-18      payo03@solomontech.net           Spoiler 존재할경우 SAP 전송대상 추가
*/
public without sharing class AsyncOrderConfirm implements Queueable, Database.AllowsCallouts {

    private static final Integer WEIGHT = 70;
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

        List<AvisOrderInfo__c> infoList = SAPCommon.fetchOrderInfoList(idList);
        Map<String, SpoilerPart__c> spoilerMap = SAPCommon.fetchSpoilerMap(infoList);

        List<IF_DTO.OrderConfirm> confirmList = new List<IF_DTO.OrderConfirm>();
        Map<String, String> keyMap = new Map<String, String>();
        for(AvisOrderInfo__c info : infoList) {
            VehicleStock__c stock = info.VehicleStock__r;
            String externalKey = info.OrderIntakeNo__c + ', ' + stock.VehicleNo__c + ', ' + stock.Name;
            keyMap.put(info.Id, externalKey);

            IF_DTO.OrderConfirm confirm = new IF_DTO.OrderConfirm(info, isCreate);
            confirm.ITEM_TYPE = 'V';
            confirm.IFID = logId;
            
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
        }

        if(!confirmList.isEmpty()) {
            Map<String, Object> infoMap = new Map<String, Object>();
            infoMap.put('ifId', InterfaceSAP.IF_SMS010_ASYNC);
            infoMap.put('logId', logId);
            infoMap.put('logType', 'ORDER_CONFIRM');
            infoMap.put('keyMap', keyMap);
            infoMap.put('items', confirmList);
            infoMap.put('isLogDetail', true);

            Map<String, Object> resultMap = InterfaceSAP.doCallOutSAPLog(infoMap);
            SAPCommon.asyncLogDetailUpdate(logId, resultMap);   // Heroku 통신 완료시. Async
        }
    }
}