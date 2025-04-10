/**
* @Author            : payo03@solomontech.net
* @Description 		 : PurchaseInvoice Queue Job
* @Target            : CreateVehicleStock_ba
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-16      payo03@solomontech.net           Created
  1.1      2025-02-18      payo03@solomontech.net           Spoiler 존재할경우 SAP 전송대상 추가
*/
public without sharing class AsyncPurchaseInvoice implements Queueable, Database.AllowsCallouts {

    public List<String> idList;
    public Map<String, Object> infoMap;

    public AsyncPurchaseInvoice(List<String> idList, Map<String, Object> infoMap) {
        this.idList = idList;
        this.infoMap = infoMap;
    }

    public void execute(QueueableContext context) {
        Map<String, Object> dataMap = infoMap == null || infoMap.isEmpty()
                ? new Map<String, Object>()
                : infoMap;

        String logId = CommonUtilCustomController.parseIFIdSAP(InterfaceSAP.PREFIX_INVOICE_INFO);
        Boolean isCreate = dataMap.isEmpty() ? true : Boolean.valueOf(dataMap.get('isCreate'));

        List<AvisOrderInfo__c> infoList = SAPCommon.fetchOrderInfoList(idList);
        Map<String, SpoilerPart__c> spoilerMap = SAPCommon.fetchSpoilerMap(infoList);

        List<IF_DTO.PurchaseInvoice> invoiceList = new List<IF_DTO.PurchaseInvoice>();
        Map<String, String> keyMap = new Map<String, String>();
        for(AvisOrderInfo__c info : infoList) {
            VehicleStock__c stock = info.VehicleStock__r;
            String externalKey = info.OrderIntakeNo__c + ', ' + stock.VehicleNo__c + ', ' + stock.Name;
            keyMap.put(info.Id, externalKey);

            IF_DTO.PurchaseInvoice invoice = new IF_DTO.PurchaseInvoice(info, isCreate);
            invoice.ITEM_TYPE = 'V';
            invoice.IFID = logId;

            // Spoiler 패키지 항목추가
            String key = CommonUtilCustomController.getSpoilerKey(info);
            SpoilerPart__c spoilerPart = spoilerMap.get(key);
            if(info.IsSpoiler__c > 0 && spoilerPart != null) {
                String price = String.valueOf(spoilerPart.Price__c);

                IF_DTO.PurchaseInvoice spoilerInvoice = invoice.clone();
                spoilerInvoice.ITEM_TYPE = 'P';
                spoilerInvoice.ITEMCD = spoilerPart.SpoilerCode__c;
                spoilerInvoice.PRCAMT = price;
                spoilerInvoice.ITEMAMT = price;
                invoiceList.add(spoilerInvoice);

                // Spoiler존재시 기존데이터 차감적용
                String subPriceAmt = String.valueOf(Decimal.valueOf(invoice.PRCAMT) - Decimal.valueOf(price));

                invoice.PRCAMT = subPriceAmt;
                invoice.ITEMAMT = subPriceAmt;
            }
            invoiceList.add(invoice);
        }

        if(!invoiceList.isEmpty()) {
            Map<String, Object> infoMap = new Map<String, Object>();
            infoMap.put('ifId', InterfaceSAP.IF_SMS011_ASYNC);
            infoMap.put('logId', logId);
            infoMap.put('logType', 'PURCHASE_INVOICE');
            infoMap.put('keyMap', keyMap);
            infoMap.put('items', invoiceList);
            infoMap.put('isLogDetail', true);

            Map<String, Object> resultMap = InterfaceSAP.doCallOutSAPLog(infoMap);
            SAPCommon.asyncLogDetailUpdate(logId, resultMap);   // Heroku 통신 완료시. Async
        }
    }
}