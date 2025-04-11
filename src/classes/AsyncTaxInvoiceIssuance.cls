/**
* @Author            : payo03@solomontech.net
* @Description 		 : 세금계산서 발행
* @Target            : AsyncInterface_test
* @Modification Log
  Ver      Date            Author                           Modification
  =================================================================================== 
  1.0      2025-03-13      payo03@solomontech.net           Created
*/
public without sharing class AsyncTaxInvoiceIssuance implements Queueable, Database.AllowsCallouts {

    private static final Integer VAT_RATE = 11;
    private static final String LOG_TYPE = 'TAX_INVOICE';
    private static final String IF_ID = InterfaceSAP.IF_SMS013;

    public List<String> opptyIdList;
    public Map<String, Object> paramMap;

    public AsyncTaxInvoiceIssuance(List<String> opptyIdList, Map<String, Object> paramMap) {
        this.opptyIdList = opptyIdList;
        this.paramMap = paramMap;
    }

    public void execute(QueueableContext context) {
        Map<String, Object> paramInfoMap = paramMap == null || paramMap.isEmpty()
                ? new Map<String, Object>()
                : paramMap;
        Boolean isCreate = paramInfoMap.isEmpty() ? true : Boolean.valueOf(paramInfoMap.get('isCreate'));

        // 취소데이터인경우, logId를 기존것으로 재활용
        Map<String, String> logIdMap = new Map<String, String>();   // KEY : OpportunityId, Value : Log Id
        for(IFAuditLogDetail__c existIFLog : [
                SELECT Id, ExternalId__c, fm_LogId__c
                FROM IFAuditLogDetail__c
                WHERE ExternalId__c IN :opptyIdList
                AND fm_LogType__c = :LOG_TYPE
                AND IsResponse__c = 'Y'         // 전송완료한건에 대해서 GET
                ORDER BY CreatedDate
        ]) {
            logIdMap.put(existIFLog.ExternalId__c, existIFLog.fm_LogId__c);
        }

        // Opportunity별 견적 가져오기
        Map<String, Quote> opptyQuoteMap = new Map<String, Quote>();
        for(Quote quote : [
                SELECT Id, VehicleStock__c, OpportunityId,
                        Opportunity.VehicleStock__c,
                        Opportunity.TaxInvoiceDate__c,
                        Opportunity.HandoverDate__c,
                        Opportunity.DiscountAmt__c,
                        Opportunity.VATType__c,
                        // 2 Level
                        Opportunity.Owner.Name,
                        Opportunity.Owner.Agency__c,
                        Opportunity.Account.BPCode__c,
                        Opportunity.VehicleStock__r.Name,
                        Opportunity.VehicleStock__r.SpecShort__c,
                        Opportunity.VehicleStock__r.EngineType__c,
                        Opportunity.VehicleStock__r.EmissionLevelEu__c,
                        Opportunity.VehicleStock__r.PDIChubuOutDate__c,
                        // 3 Level
                        Opportunity.VehicleStock__r.Product__r.CarAmt__c,
                        Opportunity.VehicleStock__r.Product__r.PurePrice__c,
                        Opportunity.VehicleStock__r.Product__r.PurePriceWsc__c,
                        Opportunity.VehicleStock__r.Product__r.PurePriceWscCfx__c,
                        toLabel(Opportunity.VehicleStock__r.Product__r.CabMark__c),
                        Opportunity.VehicleStock__r.AvisOrderInfo__r.fm_Segment1__c,
                        Opportunity.VehicleStock__r.AvisOrderInfo__r.FinalSpec__c,
                        // 4 Level
                        Opportunity.VehicleStock__r.Product__r.VehicleCategory__r.ERPCode__c,
                (
                        SELECT Id, Type__c, OilCouponCount__c,
                                fm_DetailType__c, fm_Price__c, fm_ERPCode__c,
                                VehicleOptionMaster__r.Name,
                                VehicleOptionMaster__r.OptionCode__c,
                                VehicleOptionMaster__r.OptionCodeRMC__c,
                                VehicleOptionMaster__r.Division__c,
                                VehicleOptionMaster__r.fm_CFDivision__c,
                                VehicleOptionMaster__r.EwWscPrice__c,
                                VehicleOptionMaster__r.RmcPrice__c
                        FROM QuoteDetail__r
                )
                FROM Quote
                WHERE Status = 'Published'
                AND OpportunityId IN :opptyIdList
        ]) {
            // Quote[Published] : Oppty = 1 : 1
            opptyQuoteMap.put(quote.OpportunityId, quote);
        }

        /* ------------------------------------------------------------------- */
        /* ------------------- 세금계산서 발행필요 List Start ------------------- */
        /* ------------------------------------------------------------------- */
        Map<String, List<IF_DTO.SalesInfo>> logSalesInfoListMap = new Map<String, List<IF_DTO.SalesInfo>>();
        Map<String, List<Opportunity>> logOpportunityListMap = new Map<String, List<Opportunity>>();
        for(String opptyId : opptyIdList) {
            // 취소데이터인경우, logId를 기존것으로 활용(CRTP = 'C')
            String logId = !isCreate && logIdMap.containsKey(opptyId)
                    ? logIdMap.get(opptyId)
                    : CommonUtilCustomController.parseIFIdSAP(InterfaceSAP.PREFIX_TAX);
            List<IF_DTO.SalesInfo> salesInfoList = logSalesInfoListMap.containsKey(logId)
                    ? logSalesInfoListMap.get(logId)
                    : new List<IF_DTO.SalesInfo>();
            List<Opportunity> opportunityList = logOpportunityListMap.containsKey(logId)
                    ? logOpportunityListMap.get(logId)
                    : new List<Opportunity>();

            Quote quote = opptyQuoteMap.get(opptyId);
            List<QuoteDetail__c> quoteDetailList = quote.QuoteDetail__r;
            Opportunity oppty = quote.Opportunity;
            VehicleStock__c stock = oppty.VehicleStock__r;

            Date releaseDate = oppty.HandoverDate__c;       // 출고희망일
            Decimal sumSaleTOT = 0;                         // 합계금액
            Decimal sumSaleVAT = 0;                         // 세액
            Decimal sumSalePrice = 0;                       // 공급가액 총합계
            Decimal optionPrice = 0;                        // 옵션금액. (TO_BE 변환)

            String CFDivision = 'NC';
            Integer seq = 1;
            String vatType = oppty.VATType__c;
            List<IF_DTO.SalesDetailInfo> detailInfoList = new List<IF_DTO.SalesDetailInfo>();

            /* ------------------------------------------------------------------- */
            /* ------------------------- 옵션 List Start ------------------------- */
            /* ------------------------------------------------------------------- */
            for(QuoteDetail__c quoteDetail : quoteDetailList) {

                if(quoteDetail.fm_ERPCode__c != null) {
                    // ERP 코드 있는경우

                    IF_DTO.SalesDetailInfo detailInfo = new IF_DTO.SalesDetailInfo();
                    detailInfo.ISREQNO = logId;
                    detailInfo.ROWNO = String.valueOf(seq++);
                    detailInfo.ITEMCD = quoteDetail.fm_ERPCode__c;
                    detailInfo.PRICE = String.valueOf(quoteDetail.fm_Price__c);

                    VehicleOptionMaster__c optionMaster = quoteDetail.VehicleOptionMaster__r;
                    if(optionMaster != null) {
                        // AS_IS기준. 주유상품권 외 항목

                        String detailType = optionMaster.Division__c;
                        if ('기본제공'.equals(detailType)) {
                            // AS_IS기준. 출고기념품 / 차량 총액금액 합산
                            // ERP 전송건 x.
                            // AS_IS 주석 History로 추측컨데... 예전에는 항목으로 보냈으나, 현재는 제외하여 보내지 않는것으로 보임

                            /* 25-03-26 송찬영.
                                # 차량 총액
                                    AS_IS 차량 총액에 판가를 더함
                            */
                            optionPrice += quoteDetail.fm_Price__c;
                        } else {
                            // ERP 전송건들

                            Decimal innerOptionPrice = quoteDetail.fm_Price__c;
                            Decimal innerOptionVAT = vatType != 'A61'
                                    ? (innerOptionPrice / VAT_RATE).setScale(0, RoundingMode.HALF_UP)
                                    : 0;
                            Decimal innerCalPrice = innerOptionPrice - innerOptionVAT;
                            if ('필수 옵션'.equals(detailType)) {
                                // AS_IS기준. 인도 후 장착품 / 차량 Total금액 합산
                                detailInfo.ITEMTP = 'J';
                                detailInfo.AMT = String.valueOf(innerOptionPrice);
                                detailInfo.VAT = String.valueOf(innerOptionVAT);
                                detailInfo.LINETOTAL = String.valueOf(innerCalPrice);

                                detailInfoList.add(detailInfo); // ERP 전송건들 ADD
                                /* 25-03-26 송찬영.
                                    # 세금계산서 발행 총액(sumSaleTOT)
                                        AS_IS 세금계산서 발행금액에 ERPPrice를 더하고있으나
                                        데이터는 0원임으로 로직 제외함
                                    # 차량 총액
                                        AS_IS 차량 총액에 판가를 더함
                                */
                                optionPrice += quoteDetail.fm_Price__c;
                            } else if ('서비스품목'.equals(detailType)) {
                                // AS_IS기준. EW, RMC
                                // No Carefree는 Default. 추가선택시 해당옵션으로 금액반영
                                if (!'NC'.equals(CFDivision)) CFDivision = optionMaster.fm_CFDivision__c;

                                Decimal ERPPrice = optionMaster.EwWscPrice__c;
                                Decimal ERPOptionVAT = vatType != 'A61'
                                        ? (ERPPrice / VAT_RATE).setScale(0, RoundingMode.HALF_UP)
                                        : 0;
                                Decimal ERPCalPrice = ERPPrice - ERPOptionVAT;

                                detailInfo.ITEMTP = 'E';
                                detailInfo.AMT = String.valueOf(ERPPrice);
                                detailInfo.VAT = String.valueOf(ERPOptionVAT);
                                detailInfo.LINETOTAL = String.valueOf(ERPCalPrice);

                                detailInfoList.add(detailInfo); // ERP 전송건들 ADD

                                /* 25-03-26 송찬영.
                                    # 세금계산서 발행 총액(sumSaleTOT)
                                        AS_IS 세금계산서 발행금액에 ERPPrice를 더함
                                    # 차량 총액
                                        AS_IS
                                        1. 차량 총액에 판가를 더함
                                        2. 차량 총액에 EOPrice(Engine Oil Price)를 가감. 데이터 0원이므로 로직 제외
                                        3. Option.DefaultEwRmc = false일때, ERP가격을 가감. 데이터 0원이므로 로직 제외
                                */
                                sumSaleTOT += ERPPrice;
                                sumSaleVAT += ERPOptionVAT;
                                sumSalePrice += ERPCalPrice;

                                optionPrice += quoteDetail.fm_Price__c;

                                // 1행 -> 2행으로 분리한것처럼 전송해야함
                                if (optionMaster.OptionCodeRMC__c != null) {
                                    ERPPrice = optionMaster.RmcPrice__c;
                                    ERPOptionVAT = vatType != 'A61'
                                            ? (ERPPrice / VAT_RATE).setScale(0, RoundingMode.HALF_UP)
                                            : 0;
                                    ERPCalPrice = ERPPrice - ERPOptionVAT;

                                    IF_DTO.SalesDetailInfo detailInfoExtra = detailInfo.clone();
                                    detailInfoExtra.ITEMTP = 'R';
                                    detailInfo.AMT = String.valueOf(ERPPrice);
                                    detailInfo.VAT = String.valueOf(ERPOptionVAT);
                                    detailInfo.LINETOTAL = String.valueOf(ERPCalPrice);

                                    detailInfoList.add(detailInfoExtra);

                                    /* 25-03-26 송찬영.
                                        # 세금계산서 발행 총액(sumSaleTOT)
                                            AS_IS 세금계산서 발행금액에 ERPPrice를 더함
                                        # 차량 총액
                                            AS_IS
                                            1. 차량 총액에 판가를 더함
                                            2. 차량 총액에 EOPrice(Engine Oil Price)를 가감. 데이터 0원이므로 로직 제외
                                            3. Option.DefaultEwRmc = false일때, ERP가격을 가감. 데이터 0원이므로 로직 제외
                                    */
                                    sumSaleTOT += ERPPrice;
                                    sumSaleVAT += ERPOptionVAT;
                                    sumSalePrice += ERPCalPrice;

                                    optionPrice += quoteDetail.fm_Price__c;
                                }
                            }
                        }
                    } else {
                        // AS_IS기준. 주유상품권
                        // ERP 전송건

                        detailInfo.PRICE = '0';
                        detailInfo.ITEMCD = 'C';
                        detailInfo.QTY = String.valueOf(quoteDetail.OilCouponCount__c);

                        detailInfoList.add(detailInfo);  // ERP 전송건 ADD
                    }
                } else {
                    // ERP 전송 x / 차량 Total금액 합산
                    /* 25-03-26 송찬영.
                        # 차량 총액
                            AS_IS 차량 총액에 판가를 더함
                    */

                    optionPrice += quoteDetail.fm_Price__c;
                }
            }
            /* ------------------------------------------------------------------- */
            /* -------------------------- 옵션 List End -------------------------- */
            /* ------------------------------------------------------------------- */

            // TODO. 데이터 원천 확인(Opportunity - DiscountAmt)
            Decimal discountAmt = oppty.DiscountAmt__c != null ? oppty.DiscountAmt__c : 0;
            Decimal vehiclePrice = 0;
            switch on CFDivision {
                when 'NC'   { vehiclePrice = stock.Product__r?.PurePrice__c          != null ? stock.Product__r?.PurePrice__c         : 0; }
                when 'CF'   { vehiclePrice = stock.Product__r?.PurePriceWsc__c       != null ? stock.Product__r?.PurePriceWsc__c      : 0; }
                when 'CFX'  { vehiclePrice = stock.Product__r?.PurePriceWscCfx__c    != null ? stock.Product__r?.PurePriceWscCfx__c   : 0; }
            }

            Decimal carTOT = vehiclePrice + optionPrice - discountAmt;
            Decimal carVAT = vatType != 'A61'
                    ? (carTOT / VAT_RATE).setScale(0, RoundingMode.HALF_UP)
                    : 0;
            Decimal carPrice = carTOT - carVAT;
            /* 25-03-26 송찬영.
                # 세금계산서 발행 총액(sumSaleTOT)
                    AS_IS 세금계산서 발행금액에 차량가격을 더함
            */
            sumSaleTOT += carTOT;
            sumSaleVAT += carVAT;
            sumSalePrice += carPrice;

            // 차량
            IF_DTO.SalesDetailInfo carInfo = new IF_DTO.SalesDetailInfo();
            carInfo.ISREQNO = logId;
            carInfo.ROWNO = String.valueOf(seq++);
            carInfo.ITEMTP = 'V';
            carInfo.ITEMCD = stock.Product__r.VehicleCategory__r.ERPCode__c;
            carInfo.PRICE = String.valueOf(carTOT);
            carInfo.AMT = String.valueOf(carTOT);
            carInfo.VAT = String.valueOf(carVAT);
            carInfo.LINETOTAL = String.valueOf(carPrice);
            carInfo.DISCAMT = String.valueOf(oppty.DiscountAmt__c != null ? oppty.DiscountAmt__c : 0);
            detailInfoList.add(carInfo);

            Map<String, String> specMap = CommonUtilCustomController.getSpecMap(stock.SpecShort__c);
            String modelType = specMap.get('modelType');
            String weightCapacity = specMap.get('weightCapacity');
            String horsePower = specMap.get('horsePower');

            // 차량 ADD
            IF_DTO.SalesInfo salesInfo = new IF_DTO.SalesInfo(isCreate, detailInfoList);
            salesInfo.ISREQNO = logId;
            salesInfo.IFID = logId;
            salesInfo.DISNUM = stock.Name;
            salesInfo.CARDCD = oppty.Account.BPCode__c;         // TODO. 실드라이버 - 고객 체크필요
            salesInfo.BCARDCD = oppty.Account.BPCode__c;
            salesInfo.BRANCH = oppty.Owner.Agency__c;           // 03-14. 강희주임 설명. 한글데이터 필요
            salesInfo.SLPCD = oppty.Owner.Name.left(8);
            salesInfo.DREQDT = String.valueOf(releaseDate);
            salesInfo.VATGRPD = vatType;
            salesInfo.VATGRP = vatType != 'A61' ? 'A' : 'C';
            salesInfo.ISSUDT = String.valueOf(releaseDate);

            salesInfo.SALEAMT = String.valueOf(sumSaleTOT);
            salesInfo.SALEVAT = String.valueOf(sumSaleVAT);
            salesInfo.SALEPRICE = String.valueOf(sumSalePrice);

            salesInfo.emission = stock.EmissionLevelEu__c;
            salesInfo.model_type = modelType;
//            salesInfo.model_detail1 = stock.CarTypeIdName__c;           // TODO. 데이터 원천 확인. 사용목적 확인
            salesInfo.model_detail1 = stock.AvisOrderInfo__r.fm_Segment1__c;
            salesInfo.model_detail2 = stock.AvisOrderInfo__r.FinalSpec__c;
            salesInfo.model_detail3 = modelType + stock.AvisOrderInfo__r.fm_Segment1__c + '(' + weightCapacity + '.' + horsePower.left(1) + ')';    // TODO. segment1 한글로 변경필요??
            salesInfo.engine_type = stock.EngineType__c;
            salesInfo.hp = horsePower;
            salesInfo.cap = stock.Product__r.CabMark__c;
            salesInfo.sales_agency = oppty.Owner.Agency__c;     // 03-14. 강희주임 설명. 한글데이터 필요
            salesInfo.sales_people = oppty.Owner.Name;
            salesInfo.hand_over_date = String.valueOf(stock.PDIChubuOutDate__c);    // TODO. 데이터 원천 확인

            salesInfoList.add(salesInfo);
            logSalesInfoListMap.put(logId, salesInfoList);
            opportunityList.add(oppty);
            logOpportunityListMap.put(logId, opportunityList);
        }
        /* ------------------------------------------------------------------- */
        /* -------------------- 세금계산서 발행필요 List End -------------------- */
        /* ------------------------------------------------------------------- */

        // SAP API Call
        if(!logSalesInfoListMap.isEmpty()) {
            String status = 'SUCCESS';
            String ifLogRequestBody = JSON.serializePretty(opptyIdList);
            String ifLogResponseBody;
            String responseStatusCode = '200';
            Datetime requestTime = Datetime.now();
            Datetime responseTime;

            List<Opportunity> updateList = new List<Opportunity>();
            Map<String, IFAuditLog__c> internalLogMap = new Map<String, IFAuditLog__c>();
            Map<String, IFAuditLogDetail__c> internalLogDetailMap = new Map<String, IFAuditLogDetail__c>();
            try {
                // 세금계산서 또한.... LogId - 데이터 1개로 추정... 내가 고치지 뭐...
                for (String logId : logSalesInfoListMap.keySet()) {
                    // SAP 세금계산서 발행 시작
                    List<IF_DTO.SalesInfo> salesInfoList = logSalesInfoListMap.get(logId);
                    Opportunity oppty = logOpportunityListMap.get(logId).get(0);

                    // 취소면 신규LogId 생성, 신규일경우 추출한 logId사용
                    // 취소Case. Body값의 logId는 기존 전송건
                    String internalLogId = isCreate
                            ? logId
                            : CommonUtilCustomController.parseIFIdSAP(InterfaceSAP.PREFIX_TAX);

                    Map<String, Object> infoMap = new Map<String, Object>();
                    String reqBody = CommonUtilCustomController.parseStringSAP(IF_ID, salesInfoList, internalLogId);

                    infoMap.put('ifId', IF_ID);
                    infoMap.put('logId', internalLogId);
                    infoMap.put('logType', LOG_TYPE);
                    infoMap.put('items', salesInfoList);
                    infoMap.put('isLog', false);

                    Map<String, Object> resultMap = InterfaceSAP.doCallOutSAPLog(infoMap);
                    if(Test.isRunningTest()) resultMap = (Map<String, Object>) JSON.deserializeUntyped(IF_Util.makeSampleBody2());

                    String responseBody = JSON.serializePretty(resultMap);
                    ifLogResponseBody += responseBody;
                    // Heroku 통신 완료시. Sync

                    // SAP I/F 감사로그 Bulk Insert
                    // IFAuditLog
                    IFAuditLog__c log = new IFAuditLog__c();
                    log.IF_Id__c = IF_ID;
                    log.Name = internalLogId;
                    log.Type__c = LOG_TYPE;
                    log.RawData__c = reqBody;
                    log.ResponseBody__c = responseBody;
                    internalLogMap.put(internalLogId, log);

                    // Heroku 통신 완료시. Sync
                    // IFAuditLogDetail
                    Boolean isSuccess = !resultMap.isEmpty() && Boolean.valueOf(resultMap.get('code'));
                    String message = String.valueOf(resultMap.get('message'));

//                    oppty.TaxInvoiceDate__c = oppty.HandoverDate__c;
                    oppty.TaxInvoiceDate__c = Date.today();
                    oppty.OffsetAmount__c = Decimal.valueOf(salesInfoList.get(0).SALEAMT);
                    if(!isCreate) oppty.TaxInvoiceDate__c = null;

                    IFAuditLogDetail__c logDetail = new IFAuditLogDetail__c();
                    logDetail.ObjectType__c = Id.valueOf(oppty.Id).getSobjectType().getDescribe().getName();
                    logDetail.ExternalId__c = oppty.Id;
                    logDetail.IsRequest__c = isSuccess;
                    logDetail.Description__c = message;
                    logDetail.ExternalKey__c = oppty.Id;

                    // Heroku 통신성공시
                    if (isSuccess) {
                        Map<String, Object> sapMap = (Map<String, Object>) JSON.deserializeUntyped(message);
                        String resultCode = String.valueOf(sapMap.get('Code')) == '0' ? 'Y' : 'C';
                        String resultMessage = String.valueOf(sapMap.get('Message'));

                        logDetail.IsResponse__c = resultCode;
                        logDetail.Description__c = resultMessage;

                        // 세금계산서 발행 성공시 일자 Update
                        if(resultCode == 'Y') updateList.add(oppty);
                    }
                    internalLogDetailMap.put(internalLogId, logDetail);
                }
                responseTime = Datetime.now();
            } catch(Exception e) {
                status = 'ERROR';
                ifLogResponseBody = e.getMessage();
                responseStatusCode = '500';
                responseTime = Datetime.now();

                System.debug(e.getMessage());
            } finally {
                if(isCreate && !updateList.isEmpty()) update updateList;    // 세금계산서 발행일때, 발행일 Update
                if(!internalLogMap.isEmpty()) {
                    // SAP I/F 감사로그 Bulk Insert
                    insert internalLogMap.values();

                    List<IFAuditLogDetail__c> details = new List<IFAuditLogDetail__c>();
                    for(String internalLogId : internalLogDetailMap.keySet()) {
                        IFAuditLogDetail__c detail = internalLogDetailMap.get(internalLogId);

                        detail.IFAuditLog__c = internalLogMap.get(internalLogId).Id;
                        details.add(detail);
                    }
                    insert details;
                }

                IF_DTO.LogWrapper objLogWrapper = new IF_DTO.LogWrapper();
                objLogWrapper.status = status;
                objLogWrapper.requestBody = ifLogRequestBody;
                objLogWrapper.responseBody = ifLogResponseBody;
                objLogWrapper.errorCode = responseStatusCode;
                objLogWrapper.requestTime = requestTime;
                objLogWrapper.responseTime = responseTime;
                objLogWrapper.logType = IF_DTO.LOG_TYPE.HEROKU_SAP_OUT;

                CommonUtilCustomController.setLog(objLogWrapper);
            }
        }
    }
}