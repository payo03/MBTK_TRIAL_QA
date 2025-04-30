/**
* @Author            : payo03@solomontech.net
* @Description 		 : 재고이동요청 Queue Job, PDI Step4. 재고이동요청
* @Target            : Opportunity_tr_test
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-05      payo03@solomontech.net           Created
*/
public without sharing class AsyncStockRequest implements Queueable, Database.AllowsCallouts {
    
    private static final String LOG_TYPE = 'STOCK_REQUEST';
    private static final String IF_ID = InterfaceSAP.IF_SMS004;
    public List<Map<String, Object>> paramInfoMapList;

    // KEY1 : stockId(String), KEY2 : isAttach(Boolean)
    public AsyncStockRequest(List<Map<String, Object>> paramInfoMapList) {
        this.paramInfoMapList = paramInfoMapList;
    }

    public void execute(QueueableContext context) {
        String status = 'SUCCESS';
        String requestBody = JSON.serializePretty(paramInfoMapList);
        String responseBody;
        String responseStatusCode = '200';
        Datetime requestTime = Datetime.now();
        Datetime responseTime;

        List<VehicleStock__c> updateList = new List<VehicleStock__c>();
        Map<String, IFAuditLog__c> logMap = new Map<String, IFAuditLog__c>();
        Map<String, IFAuditLogDetail__c> logDetailMap = new Map<String, IFAuditLogDetail__c>();
        try {
            Map<String, Boolean> stockAttachMap = new Map<String, Boolean>();
            for(Map<String, Object> paramInfoMap : paramInfoMapList) {
                String stockId = String.valueOf(paramInfoMap.get('stockId'));
                Boolean isAttach = Boolean.valueOf(paramInfoMap.get('isAttach'));

                stockAttachMap.put(stockId, isAttach);
            }

            Map<Id, VehicleStock__c> stockIdMap = new Map<Id, VehicleStock__c>([
                    SELECT Id, Name, VehicleNo__c,
                            AvisOrderInfo__r.OrderIntakeNo__c,
                            Product__r.VehicleCategory__r.ERPCode__c
                    FROM VehicleStock__c
                    WHERE Id IN :stockAttachMap.keySet()
            ]);

            List<String> vinKeyList = new List<String>();  // Test용 데이터
            Map<String, VehicleStock__c> stockKeyMap = new Map<String, VehicleStock__c>();
            List<Map<String, String>> paramMapList = new List<Map<String, String>>();
            for(String stockId : stockAttachMap.keySet()) {
                VehicleStock__c stock = stockIdMap.get(stockId);

                String ERPCode = stock.Product__r.VehicleCategory__r.ERPCode__c;
                String key = ERPCode + '^' + stock.Name;

                Map<String, String> paramMap = new Map<String, String>{
                        'ITEMCD' => ERPCode,
                        'DISNUM' => stock.Name
                };

                paramMapList.add(paramMap);
                stockKeyMap.put(key, stock);
                if(!vinKeyList.contains(key)) vinKeyList.add(key);    // Test용 데이터
            }

            // SAP I/F. 재고결과 조회
            IF_DTO.VehicleStock vehicleStock = SAPCommon.fetchVehicleStockAPI(paramMapList);
            for (IF_DTO.VehicleStockInfo stockInfo : vehicleStock.ResultData) {
                // WareHouse 수량
                Map<String, Integer> codeWHMap = new Map<String, Integer>();
                for (IF_DTO.WarehouseInfo WHInfo : stockInfo.STK) {
                    codeWHMap.put(WHInfo.WHSCD, Integer.valueOf(WHInfo.QTY));
                }
                stockInfo.WHMAP = codeWHMap;
            }

            // Stock-WH 재고 확인 및 이동처리
            if(Test.isRunningTest()) vehicleStock = testDTOBody();
            for(IF_DTO.VehicleStockInfo vehicleStockInfo : vehicleStock.ResultData) {
                // Validation Start
                String key = vehicleStockInfo.ITEMCD + '^' + vehicleStockInfo.DISNUM;
                if(stockKeyMap.get(key) == null) continue;  // Test용 데이터
                VehicleStock__c stock = stockKeyMap.get(key);

                if(stockAttachMap.get(stock.Id) == null) continue;  // Test용 데이터
                Boolean isAttach = stockAttachMap.get(stock.Id);
                String stdKey = isAttach ? 'P11' : 'P21';  // 재고이동 창고
                Integer qty = vehicleStockInfo.WHMAP.get(stdKey);

                // 재고 미존재시
                if(qty == null || qty < 0) {
                    stock.StockResultMessage__c = '재고가 부족하여 차량 재고이동요청을 수행하지 못하였습니다';
                    updateList.add(stock);

                    continue;
                }
                String externalKey = stock.AvisOrderInfo__r.OrderIntakeNo__c + ', ' + stock.VehicleNo__c + ', ' + stock.Name;

                // 재고 이동요청 Start
                List<IF_DTO.StockInfo> stockInfoList = new List<IF_DTO.StockInfo>();
                String logId = CommonUtilCustomController.parseIFId(InterfaceSAP.PREFIX_STOCK);

                List<IF_DTO.StockDetailInfo> detailInfos = new List<IF_DTO.StockDetailInfo>();
                IF_DTO.StockDetailInfo detailInfo = new IF_DTO.StockDetailInfo(
                        logId,
                        stock.Product__r.VehicleCategory__r.ERPCode__c,
                        '1',
                        stock.Name,
                        ''
                );
                detailInfos.add(detailInfo);

                IF_DTO.StockInfo stockInfo = new IF_DTO.StockInfo(true, isAttach, detailInfos);
                stockInfo.IFID = logId;
                stockInfo.DOCNO = logId;
                stockInfo.MOVTP = 'A';
                stockInfo.PTMOVTP = 'A';
                stockInfo.RMK = '';
                stockInfoList.add(stockInfo);

                // SAP 재고이동요청 전송
                // 2025-02-27 최윤석대리와 Teams미팅간 내용. SMS004, SMS007. SMS009는 단건밖에 안된다고 함......
                Map<String, Object> infoMap = new Map<String, Object>();
                String reqBody = CommonUtilCustomController.parseStringSAP(IF_ID, stockInfoList, logId);

                infoMap.put('ifId', IF_ID);
                infoMap.put('logId', logId);
                infoMap.put('LOG_TYPE', LOG_TYPE);
                infoMap.put('items', stockInfoList);
                infoMap.put('isLog', false);

                Map<String, Object> resultMap = InterfaceSAP.doCallOutSAPLog(infoMap);
                if(Test.isRunningTest()) resultMap = (Map<String, Object>) JSON.deserializeUntyped(IF_Util.makeSampleBody2());

                Boolean isSuccess = !resultMap.isEmpty() && Boolean.valueOf(resultMap.get('code'));
                String resBody = JSON.serializePretty(resultMap);
                responseBody += JSON.serializePretty(resultMap) + '\n';

                // SAP I/F 감사로그 Bulk Insert
                // IFAuditLog
                IFAuditLog__c log = new IFAuditLog__c();
                log.IF_Id__c = IF_ID;
                log.Name = logId;
                log.Type__c = LOG_TYPE;
                log.RawData__c = reqBody;
                log.ResponseBody__c = resBody;
                logMap.put(logId, log);

                // IFAuditLogDetail
                IFAuditLogDetail__c logDetail = new IFAuditLogDetail__c();
                logDetail.ObjectType__c = Id.valueOf(stock.Id).getSobjectType().getDescribe().getName();
                logDetail.ExternalId__c = stock.Id;
                logDetail.IsRequest__c = isSuccess;
                logDetail.ExternalKey__c = externalKey;
                if (isSuccess) {
                    // Heroku 통신 완료시. Sync
                    String herokuMessage = String.valueOf(resultMap.get('message'));
                    Map<String, Object> sapMap = (Map<String, Object>) JSON.deserializeUntyped(herokuMessage);
                    String resultCode = String.valueOf(sapMap.get('Code')) == '0' ? 'Y' : 'C';
                    String resultMessage = String.valueOf(sapMap.get('Message'));

                    logDetail.IsResponse__c = resultCode;
                    logDetail.IsResult__c = resultCode;
                    logDetail.Description__c = resultMessage;
                    logDetail.ResultDatetime__c = Datetime.now();
                }
                logDetailMap.put(logId, logDetail);
            }
            responseTime = Datetime.now();
        } catch(Exception e) {
            status = 'ERROR';
            responseBody = e.getMessage();
            responseStatusCode = '500';
            responseTime = Datetime.now();

            System.debug(e.getMessage());
        } finally {
            if(!updateList.isEmpty()) update updateList;    // 재고이동요청 결과 Update
            if(!logMap.isEmpty()) {
                // SAP I/F 감사로그 Bulk Insert
                insert logMap.values();

                List<IFAuditLogDetail__c> details = new List<IFAuditLogDetail__c>();
                for(String logId : logDetailMap.keySet()) {
                    IFAuditLogDetail__c detail = logDetailMap.get(logId);

                    detail.IFAuditLog__c = logMap.get(logId).Id;
                    details.add(detail);
                }
                insert details;
            }

            IF_DTO.LogWrapper objLogWrapper = new IF_DTO.LogWrapper();
            objLogWrapper.status = status;
            objLogWrapper.requestBody = requestBody;
            objLogWrapper.responseBody = responseBody;
            objLogWrapper.errorCode = responseStatusCode;
            objLogWrapper.requestTime = requestTime;
            objLogWrapper.responseTime = responseTime;
            objLogWrapper.logType = IF_DTO.LOG_TYPE.HEROKU_SAP_OUT;

            CommonUtilCustomController.setLog(objLogWrapper);
        }
    }

    private static IF_DTO.VehicleStock testDTOBody() {

        VehicleStock__c stock = [
                SELECT Id, Name, Product__r.VehicleCategory__r.ERPCode__c
                FROM VehicleStock__c
                WHERE Product__r.VehicleCategory__r.ERPCode__c != NULL
                LIMIT 1
        ];

        IF_DTO.VehicleStock vStock = new IF_DTO.VehicleStock();

        IF_DTO.WarehouseInfo whInfo = new IF_DTO.WarehouseInfo();
        whInfo.QTY = '1';
        whInfo.WHSCD = 'P11';
        whInfo.WHSNM = 'P21';

        IF_DTO.WarehouseInfo whInfo2 = new IF_DTO.WarehouseInfo();
        whInfo2.QTY = '1';
        whInfo2.WHSCD = 'P21';
        whInfo2.WHSNM = 'P11';

        IF_DTO.VehicleStockInfo vStockInfo = new IF_DTO.VehicleStockInfo();
        vStockInfo.ITEMCD = stock.Product__r.VehicleCategory__r.ERPCode__c;
        vStockInfo.DISNUM = stock.Name;
        vStockInfo.STK = new List<IF_DTO.WarehouseInfo>{whInfo, whInfo2};
        vStockInfo.WHMAP = new Map<String, Integer>{
                'P11' => 1,
                'P21' => 1
        };

        vStock.ResultData = new List<IF_DTO.VehicleStockInfo>{vStockInfo};

        return vStock;
    }
}