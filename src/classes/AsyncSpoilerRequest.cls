/**
* @Author            : payo03@solomontech.net
* @Description 		 : 재고이동요청 Queue Job, PDI Step4. Spoiler 장착
* @Target            : AsyncInterface_test
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-02-28      payo03@solomontech.net           Created
*/
public without sharing class AsyncSpoilerRequest implements Queueable, Database.AllowsCallouts {

    private final static String LOG_TYPE = 'SPOILER_REQUEST';
    private final static String IF_ID = InterfaceSAP.IF_SMS004;
    public List<Map<String, Object>> paramMapList;

    public AsyncSpoilerRequest(List<Map<String, Object>> paramMapList) {
        this.paramMapList = paramMapList;
    }

    /*
    # Param Sample
        List<Map<String, Object>> paramMapList = new List<Map<String, Object>>();
        Map<String, Object> paramMap = new Map<String, Object>{
                'stockId' => 'a0IH2000004uWXLMA2',
                'spoilerCode' => 'ML120000453',
                'isAttach' => true
        };
        paramMapList.add(paramMap);
        paramMap = new Map<String, Object>{
                'stockId' => 'a0IH2000004uYdJMAU',
                'spoilerCode' => 'ML120000547',
                'isAttach' => true
        };
        paramMapList.add(paramMap);
    */
    public void execute(QueueableContext context) {
        String status = 'SUCCESS';
        String requestBody = JSON.serializePretty(paramMapList);
        String responseBody;
        String responseStatusCode = '200';
        Datetime requestTime = Datetime.now();
        Datetime responseTime;

        List<VehicleStock__c> failList = new List<VehicleStock__c>();
        Map<String, IFAuditLog__c> logMap = new Map<String, IFAuditLog__c>();
        Map<String, IFAuditLogDetail__c> logDetailMap = new Map<String, IFAuditLogDetail__c>();
        try {

            // SpoilerCode별 데이터 조회
            Map<String, List<Map<String, Object>>> spoilerInfoListMap = new Map<String, List<Map<String, Object>>>();
            Set<String> stockIdSet = new Set<String>();
            Set<String> spoilerCodeSet = new Set<String>();
            for (Map<String, Object> paramMap : paramMapList) {
                String stockId = String.valueOf(paramMap.get('stockId'));
                String key = String.valueOf(paramMap.get('spoilerCode'));

                List<Map<String, Object>> spoilerInfoList = spoilerInfoListMap.containsKey(key)
                        ? spoilerInfoListMap.get(key)
                        : new List<Map<String, Object>>();
                spoilerInfoList.add(paramMap);

                stockIdSet.add(stockId);
                spoilerCodeSet.add(key);
                spoilerInfoListMap.put(key, spoilerInfoList);
            }

            // VIN Number Get 및 SAP Install Update를 위한 VehicleStock조회
            Map<Id, VehicleStock__c> stockMap = new Map<Id, VehicleStock__c>([
                    SELECT Id, Name, VehicleNo__c,
                            AvisOrderInfo__r.OrderIntakeNo__c
                    FROM VehicleStock__c
                    WHERE Id IN :stockIdSet
            ]);

            // SAP I/F. 재고결과 조회
            IF_DTO.PartStock partStock = SAPCommon.fetchSpoilerStockAPI(spoilerCodeSet);
            if(Test.isRunningTest()) partStock = testDTOBody();

            // 탈부착 여부 - StockId 재고조회
            for (IF_DTO.PartStockInfo detailInfo : partStock.ResultData) {
                String spoilerCode = detailInfo.ITEMCD;

                // SpoilerCode별 WareHouse 수량
                Map<String, Integer> codeWHMap = new Map<String, Integer>();
                for (IF_DTO.WarehouseInfo WHInfo : detailInfo.STK) {
                    codeWHMap.put(WHInfo.WHSCD, Integer.valueOf(WHInfo.QTY));
                }

                // 스포일러별 요청한 Stock List
                List<Map<String, Object>> spoilerInfoList = spoilerInfoListMap.get(spoilerCode);
                for (Map<String, Object> spoilerInfo : spoilerInfoList) {
                    Boolean isAttach = Boolean.valueOf(spoilerInfo.get('isAttach'));
                    String WHKey = isAttach ? 'P11' : 'P21';
                    Integer qty = codeWHMap.get(WHKey) - 1;

                    Boolean isPass = qty >= 0 ? false : true;   // 탈부착 가능여부. true : 가능, false : 불가능
                    spoilerInfo.put('isPass', isPass);

                    codeWHMap.put(WHKey, qty);
                }
            }

            // 재고요청 데이터 ADD
            for (String spoilerCode : spoilerInfoListMap.keySet()) {
                // 재고이동 요청은 Spoiler : Request = 1 : 1
                List<IF_DTO.StockInfo> stockInfoList = new List<IF_DTO.StockInfo>();
                String logId = CommonUtilCustomController.parseIFId(InterfaceSAP.PREFIX_OPTION);

                // 스포일러별 Info
                Integer i = 1;
                Map<Boolean, List<IF_DTO.StockDetailInfo>> detailInfoMap = new Map<Boolean, List<IF_DTO.StockDetailInfo>>();    // 부착 : true, 탈착 : false
                String stockOneId;
                String externalKey;
                for (Map<String, Object> spoilerInfo : spoilerInfoListMap.get(spoilerCode)) {
                    System.debug(spoilerInfo);

                    Boolean isPass = spoilerInfo.containsKey('isPass')
                            ? Boolean.valueOf(spoilerInfo.get('isPass'))
                            : false;    // 재고조회 실패 or 재고수량 부족일경우
                    Boolean isAttach = Boolean.valueOf(spoilerInfo.get('isAttach'));
                    String stockId = String.valueOf(spoilerInfo.get('stockId'));
                    String action = isAttach ? '부착' : '탈착';

                    // 탈부착 불가는 PASS
                    if (isPass) {
                        VehicleStock__c failStock = new VehicleStock__c(Id = stockId);
                        failStock.SpoilerResultMessage__c = '[' + spoilerCode + '] 재고가 부족하여 스포일러 ' + action + '을 수행하지 못하였습니다';
                        failList.add(failStock);

                        continue;
                    }
                    VehicleStock__c stock = stockMap.get(stockId);

                    IF_DTO.StockDetailInfo detailInfo = new IF_DTO.StockDetailInfo(
                            logId,
                            spoilerCode,
                            String.valueOf(i++),
                            stock.Name,
                            ''
                    );
                    // 탈부착에 따른 재고이동요청 묶음 List
                    List<IF_DTO.StockDetailInfo> detailInfos = detailInfoMap.containsKey(isAttach)
                            ? detailInfoMap.get(isAttach)
                            : new List<IF_DTO.StockDetailInfo>();

                    detailInfos.add(detailInfo);
                    detailInfoMap.put(isAttach, detailInfos);

                    // 2025-02-27 최윤석대리와 Teams미팅간 내용. SMS004, SMS009는 단건밖에 안된다고 함...... 차량 하나에 동일 스포일러 탈-부착을 여러번 하진 않을테니 일단 KEEP
                    stockOneId = stockId;
                    externalKey = stock.AvisOrderInfo__r.OrderIntakeNo__c + ', ' + stock.VehicleNo__c + ', ' + stock.Name;
                }

                // 탈부착 여부에 따라 창고 시작점이 다름으로.. 묶음으로 진행
                for (Boolean isAttach : detailInfoMap.keySet()) {
                    List<IF_DTO.StockDetailInfo> detailInfos = detailInfoMap.get(isAttach);
                    IF_DTO.StockInfo stockInfo = new IF_DTO.StockInfo(true, isAttach, detailInfos);
                    stockInfo.IFID = logId;
                    stockInfo.DOCNO = logId;
                    stockInfo.MOVTP = 'P';
                    stockInfo.PTMOVTP = 'A';
                    stockInfo.RMK = '';

                    stockInfoList.add(stockInfo);
                }

                if(!stockInfoList.isEmpty()) {
                    // SAP 재고이동요청 전송
                    // 2025-02-27 최윤석대리와 Teams미팅간 내용. SMS004, SMS009는 단건밖에 안된다고 함...... 차량 하나에 동일 스포일러 탈-부착을 여러번 하진 않을테니 일단 KEEP
                    Map<String, Object> infoMap = new Map<String, Object>();
                    String reqBody = CommonUtilCustomController.parseStringSAP(IF_ID, stockInfoList, logId);

                    infoMap.put('ifId', IF_ID);
                    infoMap.put('logId', logId);
                    infoMap.put('logType', LOG_TYPE);
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
                    logDetail.ObjectType__c = Id.valueOf(stockOneId).getSobjectType().getDescribe().getName();
                    logDetail.ExternalId__c = stockOneId;
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
            }
            responseTime = Datetime.now();
        } catch(Exception e) {
            status = 'ERROR';
            responseBody = e.getMessage();
            responseStatusCode = '500';
            responseTime = Datetime.now();

            System.debug(e.getMessage());
        } finally {
            if(!failList.isEmpty()) update failList;    // 탈부착 불가 Stock Update
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

    private static IF_DTO.PartStock testDTOBody() {
        VehicleStock__c stock = [
                SELECT Id, SpoilerPart__r.SpoilerCode__c
                FROM VehicleStock__c
                WHERE SpoilerPart__r.SpoilerCode__c != NULL
                LIMIT 1
        ];

        IF_DTO.PartStock pStock = new IF_DTO.PartStock();

        IF_DTO.WarehouseInfo whInfo = new IF_DTO.WarehouseInfo();
        whInfo.QTY = '1';
        whInfo.WHSCD = 'P11';
        whInfo.WHSNM = 'P21';

        IF_DTO.WarehouseInfo whInfo2 = new IF_DTO.WarehouseInfo();
        whInfo2.QTY = '1';
        whInfo2.WHSCD = 'P21';
        whInfo2.WHSNM = 'P11';

        IF_DTO.PartStockInfo pStockInfo = new IF_DTO.PartStockInfo();
        pStockInfo.ITEMCD = stock.SpoilerPart__r.SpoilerCode__c;
        pStockInfo.STK = new List<IF_DTO.WarehouseInfo>{whInfo, whInfo2};
        pStockInfo.WHMAP = new Map<String, Integer>();

        pStock.ResultData = new List<IF_DTO.PartStockInfo>{pStockInfo};

        return pStock;
    }
}