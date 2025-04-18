/**
* @Author            : payo03@solomontech.net
* @Description 		 : PurchaseInvoice Queue Job
* @Target            : FetchSAPResult_ba_test
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-16      payo03@solomontech.net           Created
  1.1      2025-02-18      payo03@solomontech.net           Spoiler 존재할경우 SAP 전송대상 추가
  1.2      2025-04-14      payo03@solomontech.net           취소 IF 추가
*/
public without sharing class AsyncPurchaseInvoice implements Queueable, Database.AllowsCallouts {

    private static final String LOG_TYPE_S = 'PURCHASE_INVOICE';
    private static final String LOG_TYPE_C = 'PURCHASE_INVOICE_CANCEL';
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
        String logType = isCreate ? LOG_TYPE_S : LOG_TYPE_C;

        // ver1.2 취소 IF 추가
        // 취소데이터인경우, logId를 기존것으로 재활용
        Map<String, String> logIdMap = SAPCommon.fetchLogIdMap(idList, LOG_TYPE_S);   // KEY : AvisOrderInfoId, Value : Log Id
        List<AvisOrderInfo__c> infoList = SAPCommon.fetchOrderInfoList(idList);
        Map<String, SpoilerPart__c> spoilerMap = SAPCommon.fetchSpoilerMap(infoList);

        Map<String, String> keyMap = new Map<String, String>();
        Map<String, List<IF_DTO.PurchaseInvoice>> logInvoiceListMap = new Map<String, List<IF_DTO.PurchaseInvoice>>();
        for(AvisOrderInfo__c info : infoList) {
            // ver1.2 취소 IF 추가
            String internalLogId = !isCreate && logIdMap.containsKey(info.Id)
                    ? logIdMap.get(info.Id)
                    : logId;
            List<IF_DTO.PurchaseInvoice> invoiceList = logInvoiceListMap.containsKey(internalLogId)
                    ? logInvoiceListMap.get(internalLogId)
                    : new List<IF_DTO.PurchaseInvoice>();

            VehicleStock__c stock = info.VehicleStock__r;
            String externalKey = info.OrderIntakeNo__c + ', ' + stock.VehicleNo__c + ', ' + stock.Name;
            keyMap.put(info.Id, externalKey);

            IF_DTO.PurchaseInvoice invoice = new IF_DTO.PurchaseInvoice(info, isCreate);
            invoice.ITEM_TYPE = 'V';
            invoice.IFID = internalLogId;

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
            logInvoiceListMap.put(internalLogId, invoiceList);
        }

        // ver1.2 취소 IF 추가
        if(!logInvoiceListMap.isEmpty()) {
            for (String internalLogId : logInvoiceListMap.keySet()) {
                Map<String, Object> infoMap = new Map<String, Object>();

                infoMap.put('ifId', InterfaceSAP.IF_SMS011_ASYNC);
                infoMap.put('logId', internalLogId);
                infoMap.put('logType', logType);
                infoMap.put('keyMap', keyMap);
                infoMap.put('items', logInvoiceListMap.get(internalLogId));
                infoMap.put('isLogDetail', true);

                Map<String, Object> resultMap = InterfaceSAP.doCallOutSAPLog(infoMap);
                SAPCommon.asyncLogDetailUpdate(internalLogId, resultMap);   // Heroku 통신 완료시. Async
            }
        }
    }
}