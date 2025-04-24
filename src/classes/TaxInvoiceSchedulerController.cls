/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                   Modification
  ===================================================================================
  1.0      2025-01-24      jh.jung                  Created
  1.1      2025-02-11      payo03@solomontech.net   createHistory, fetchDelayDateSet함수 추가
  1.2      2025-02-13      payo03@solomontech.net   PTO장착여부 로직적용
*/
global without sharing class TaxInvoiceSchedulerController {

    public static Handover__c handover {get; set;}
    public static PaymentTracker__c paymentTracker {get; set;}
    public static Map<String, Object> paymentMap {get; set;}

    final static Integer MAX_NUM = 6;

    public static void getVFInfo() {

        String recordId = ApexPages.currentPage().getParameters().get('recordId');

        paymentMap = new Map<String, Object>{
            '입금 합계' => 0
            , '인도금 합계' => 0
            , '1_DEPOSIT' => 0
            , '2_DOWN_PAYMENT' => 0
            , '3_DEFERRED_PAYMENT' => 0
            , '4_VAT' => 0
            , '5_OVER_PAID' => 0
            , '99_LOAN' => 0
            , '99_SUBVENTION' => 0
        };

        try {
            handover = [
                    SELECT
                            Id
                            , Name
                            , Opportunity__c
                            , PaymentTracker__c
                            , Opportunity__r.Contract.Name
                            , Opportunity__r.Contract.ContractNumber
                            , Opportunity__r.Account.Name
                            , Opportunity__r.Account.PersonMobilePhone
                            , Opportunity__r.Account.BusinessNumber__c
                            , Opportunity__r.Account.IDNumber__pc
                    FROM Handover__c
                    WHERE Id = :recordId
            ];

            paymentTracker = [
                    SELECT
                            Id
                            , Name
                            , Opportunity__c
                            , Account__c
                            , Status__c
                            , TotalAmount__c
                            , ru_DepositAmount__c
                            , fm_IsVATDeferred__c
                            , fm_IsPaymentDeferred__c
                            , IsValid__c
                            , fm_dueDate__c
                            , ru_RecentDepositDate__c
                            , (SELECT Type__c, DepositAmount__c FROM PaymentTypes__r)
                    FROM PaymentTracker__c
                    WHERE Id =: handover.PaymentTracker__c
            ];

            Decimal totalPrice = 0;
            Decimal deliveryPrice = 0;
            for (PaymentType__c paymentType : paymentTracker.PaymentTypes__r) {
                paymentMap.put(paymentType.Type__c, formatNumber(paymentType.DepositAmount__c));

//                if(paymentType.Type__c == '5_OVER_PAID') { continue; }

                // 인도금 : 선수금 + 인도금 + 인도금유예 + 부가세유예
                if(
                    paymentType.Type__c == '2_DOWN_PAYMENT' ||
                    paymentType.Type__c == '3_DEFERRED_PAYMENT' ||
                    paymentType.Type__c == '4_VAT'
                ) {
                    deliveryPrice += paymentType.DepositAmount__c;
                }
//                totalPrice += paymentType.ru_TotalPrice__c;
            }
            paymentMap.put('입금 합계', formatNumber(paymentTracker.ru_DepositAmount__c));
            paymentMap.put('인도금 합계', formatNumber(deliveryPrice));
        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }

    private static String formatNumber(Decimal value) {
        if (value == null) return '0';
        return value.format();  // Decimal.format() 사용하여 1,000,000 형식으로 변환
    }

    // 세금계산서 발행 I/F
    @AuraEnabled
    public static void callTaxInvoice(String opptyId, Boolean isCreate) {
        List<String> opptyIdList = new List<String>{ opptyId };
        Map<String, Object> paramMap = new Map<String, Object>();
        paramMap.put('isCreate', isCreate);	// 세금계산서 취소시 false
        System.enqueueJob(new AsyncTaxInvoiceIssuance(opptyIdList, paramMap));
    }

    // Canlenar로 잠시 추가 Start

    // 날짜별 핸드오버 개수 -> TODO: 출고일 배정 관리로 변경 필요
//    @AuraEnabled
//    public static List<Object> getHandoverDateList() {
//        return [
//                SELECT COUNT(Id) title, fm_HandoverDate__c start
//                FROM Handover__c
//                WHERE fm_HandoverDate__c != NULL
//                GROUP BY fm_HandoverDate__c
//        ];
//    }
    @AuraEnabled
//    public static List<Object> getHandoverDateList(String vehicleStockId) {
    public static Map<String, Object> getCalendarInit(String vehicleStockId) {

        // default : 3일(기본 옵션)
        Map<Date, Date> availableDateMap = CommonUtilCustomController.availableDateMap(30);
        Date configDate = Date.today().addDays(3);
        Date availableDate = availableDateMap.get(configDate);

        Map<String, Date> infoMap;
        if(vehicleStockId != null) {
            infoMap = fetchDelayDateSet(new Set<String>{vehicleStockId}).get(vehicleStockId);
            configDate = infoMap.get('config');
            availableDate = infoMap.get('available');
        }
//        else {
//            Map<Date, Date> availableDateMap = CommonUtilCustomController.availableDateMap(30);
//            System.debug('availableDateMap ::: ' + JSON.serialize(availableDateMap));
//            configDate = Date.today().addDays(3);
//            availableDate = availableDateMap.get(configDate);
//        }

//        List<HandOverDateManagement__c> handoverDateList = [
//                SELECT ru_Count__c, Date__c, IsHoliday__c
//                FROM HandOverDateManagement__c
//                WHERE Date__c >= :availableDate
//        ];

        List<CustomCalendar__c> customCalendarList = [
                SELECT ru_Count__c, Date__c, IsHoliday__c
                FROM CustomCalendar__c
                WHERE Date__c >= :availableDate
        ];

        Date today = Date.today();
        Integer diffDays = today.daysBetween(configDate);

        List<ConfigDetail__c> optionDelayList = CommonUtilCustomController.getConfigDetailLow('MAN3000');
//        CommonUtilController.sortSObjectList(optionDelayList, 'Attribute1__c', true);
//        for(ConfigDetail__c configDetail : optionDelayList) {
//            // 빈 슬롯 사용
//            configDetail.Attribute18__c = '';
//            if(configDetail.Attribute2__c == String.valueOf(diffDays)) {
//                configDetail.Attribute18__c = 'true';
//            }
//        }

        return new Map<String, Object> {
            'handoverDateList' => customCalendarList
            , 'optionDelayList' => optionDelayList
            , 'diffDays' => diffDays
        };
    }

    // 해당 HandoverDate에 Oppty 몇개 있는지 확인
//    @AuraEnabled
//    public static List<Handover__c> getOpptyListByHandoverDate(String handoverDate) {
//        return [
//                SELECT Id
//                FROM Handover__c
//                WHERE fm_HandoverDate__c = :Date.valueOf(handoverDate)
//        ];
//    }

    // 바뀐 HandoverDate를 oppty에 업데이트
//    @AuraEnabled
//    public static Boolean updateHandoverDate(Object handoverInfo, String targetDate) {
//
//        Boolean result = false;
//        Map<String, String> objMap = (Map<String, String>) JSON.deserialize(JSON.serialize(handoverInfo), Map<String, String>.class);
//
//        return result;
//    }

    @AuraEnabled
    public static Boolean insertHandoverDateAllocationHistory(Date targetDate, String opptyId, String stockId) {
        Boolean result = true;

        List<Map<String, Object>> paramMapList = new List<Map<String, Object>>();
        paramMapList.add(new Map<String, Object>{
                'targetDate' => targetDate,
                'opportunityId' => opptyId,
                'stockId' => stockId
        });

        Map<String, HandoverDateAllocationHistory__c> resultMap = createHistory(paramMapList);
        List<HandoverDateAllocationHistory__c> insertList = new List<HandoverDateAllocationHistory__c>();

        for(HandoverDateAllocationHistory__c resultHistory : resultMap.values()) {
            if(resultHistory != null) {
                insertList.add(resultHistory);
            } else {
                result = false;
            }
        }

        if(insertList.isEmpty())    { result = false; }
        if(result)                  { insert insertList; }

        return result;
    }

    // ver1.1 createHistory, fetchDelayDateSet함수 추가
    /**
     * @param paramMapList      History Insert를 위한 파라미터 List
     *                          1. Date targetDate : 출고예정일 혹은 출고일(날짜 입력칸)
     *                          2. String opportunityId : 출고일 업데이트할 영업기회('출고일' 필드 업데이트는 HandoverDateAllocationHistory Trigger에서 Update)
     *                          3. String stockId : 출고일 할당시킬 차량재고
     * @return                  Return Value Description
     *                          - Key : OpportunityId, Value : HandoverDateAllocationHistory
     *                          Value값이 null일경우 생성이 불가능한 Case.
     */
    @AuraEnabled
    public static Map<String, HandoverDateAllocationHistory__c> createHistory(List<Map<String, Object>> paramMapList) {
        Map<String, HandoverDateAllocationHistory__c> returnMap = new Map<String, HandoverDateAllocationHistory__c>();

        // targetDate를 Key값으로 Map 재정렬
        Set<String> stockSet = new Set<String>();
        Map<Date, List<Map<String, Object>>> dateInfoMap = new Map<Date, List<Map<String, Object>>>();
        for(Map<String, Object> paramMap : paramMapList) {
            Date targetDate = Date.valueOf(paramMap.get('targetDate'));
            String stockId = String.valueOf(paramMap.get('stockId'));

            List<Map<String, Object>> dateInfoList = dateInfoMap.containsKey(targetDate)
                    ? dateInfoMap.get(targetDate)
                    : new List<Map<String, Object>>();

            dateInfoList.add(paramMap);
            stockSet.add(stockId);
            dateInfoMap.put(targetDate, dateInfoList);
        }

        // HandOverDateManagement SObject 조회. ru_Count 데이터 확인
        Map<String, Map<String, Date>> validDateMap = fetchDelayDateSet(stockSet);
//        List<HandOverDateManagement__c> managementList = [
//                SELECT Id, Date__c, ru_Count__c
//                FROM HandOverDateManagement__c
//                WHERE Date__c = :dateInfoMap.keySet()
//        ];
        List<CustomCalendar__c> customCalendarList = [
                SELECT Id, Date__c, ru_Count__c
                FROM CustomCalendar__c
                WHERE Date__c = :dateInfoMap.keySet()
        ];

        for(CustomCalendar__c customCalendar : customCalendarList) {
            List<Map<String, Object>> dateInfoList = dateInfoMap.get(customCalendar.Date__c);

            Integer ruCount = Integer.valueOf(customCalendar.ru_Count__c);
            for(Map<String, Object> dateInfo : dateInfoList) {
                Date targetDate = Date.valueOf(dateInfo.get('targetDate'));
                String opportunityId = String.valueOf(dateInfo.get('opportunityId'));
                String stockId = String.valueOf(dateInfo.get('stockId'));

                Date validDate = validDateMap.get(stockId).get('available');

                if (targetDate < validDate) continue;
                if (ruCount < MAX_NUM) {
                    HandoverDateAllocationHistory__c history = new HandoverDateAllocationHistory__c();
//                    history.HandOverDateManagement__c = customCalendar.Id;
                    history.CustomCalendar__c = customCalendar.Id;
                    history.VehicleStock__c = stockId;
                    history.Opportunity__c = opportunityId;
                    history.IsAssign__c = true;

                    returnMap.put(opportunityId, history);
                    ruCount++;
                }
            }
        }

        return returnMap;
    }

    // ver1.1 createHistory, fetchDelayDateSet함수 추가
    public static Map<String, Map<String, Date>> fetchDelayDateSet(Set<String> stockIdSet) {
        Map<String, Map<String, Date>> returnMap = new Map<String, Map<String, Date>>();

        Map<String, ConfigDetail__c> detailMap = new Map<String, ConfigDetail__c>();
        String selectFields = 'Id';

        // Custom설정 확인
        List<ConfigDetail__c> configDetailList = CommonUtilCustomController.getConfigDetailLow('MAN3000');
        for(ConfigDetail__c configDetail : configDetailList) {
            String key = configDetail.Name;
            detailMap.put(key, configDetail);

            if(key.toUpperCase().startsWith('CUSTOM')) continue;
            selectFields += ',' + key;     // ConfigDetail에 해당하는 값들 SELECT
        }
        String fromObject = 'VehicleStock__c';
        String whereCondition = 'Id IN ' + CommonUtilController.joinedString(stockIdSet);
        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, whereCondition);
        Map<Id, VehicleStock__c> stockMap = new Map<Id, VehicleStock__c>((List<VehicleStock__c>) Database.query(buildQuery));

        List<Quote> quotes = [
            SELECT Id, VehicleStock__c, Opportunity.VehicleStock__c, 
                (
                    SELECT Id
                    FROM QuoteDetail__r
                    WHERE VehicleOptionMaster__r.IsPTO__c = TRUE
                )
            FROM Quote
            WHERE Status = 'Published'
            AND Opportunity.VehicleStock__c IN :stockIdSet
        ];

        Map<String, String> oppStockQuoteStockMap = new Map<String, String>();    // ver1.2 PTO장착여부 로직적용
        Map<String, List<QuoteDetail__c>> quoteDetailListMap = new Map<String, List<QuoteDetail__c>>();
        for(Quote quote : quotes) {
            String key = quote.VehicleStock__c;

            oppStockQuoteStockMap.put(quote.Opportunity.VehicleStock__c, quote.VehicleStock__c);
            quoteDetailListMap.put(key, quote.QuoteDetail__r);
        }

        // Stock별 DelayDate 계산
        for(String stockId : stockMap.keySet()) {
            VehicleStock__c stock = stockMap.get(stockId);
            Integer delayDays = 0;

            for (String key : detailMap.keySet()) {
                ConfigDetail__c detail = detailMap.get(key);
                Integer delayValue = Integer.valueOf(detail.Attribute2__c);

                // ver1.2 PTO장착여부 로직적용
                if (key.toUpperCase().startsWith('CUSTOM')) {
                    // SELECT 필드x. Custom 설정들

                    if(key.toUpperCase().contains('NORMAL')) {
                        // Normal. 데이터 Get

                        delayDays = Math.max(delayValue, delayDays);
                    } else if(key.toUpperCase().contains('PTO')) {
                        // PTO 옵션장착여부 확인

                        // Default. Quote의 Stock을 가지고 Option조회
                        String quoteStockId = oppStockQuoteStockMap.containsKey(stockId) 
                            ? oppStockQuoteStockMap.get(stockId) 
                            : stockId;
                        List<QuoteDetail__c> ptoList = quoteDetailListMap.get(quoteStockId);
                        if(ptoList != null && !ptoList.isEmpty()) delayDays = Math.max(delayValue, delayDays);
                    }
                } else {
                    // Field별 데이터 Get. Type별로 데이터 형변환 필요

                    Object objValue = CommonUtilCustomController.fetchValueRecur(stock, key);
                    if (objValue instanceof Boolean) {
                        // Boolean Type일경우...
                        Boolean bool = Boolean.valueOf(objValue);
                        if (!bool) delayDays = Math.max(delayValue, delayDays);
                    } else {
                        // String Type일경우... 현재는 Axle에 따라 설정
                        List<String> conditionList = detail.Attribute20__c.replaceAll('\\s+', '').split(',');
                        for (String settingValue : conditionList) {
                            String strValue = String.valueOf(objValue);
                            if (strValue.toUpperCase().startsWith(settingValue.toUpperCase())) delayDays = Math.max(delayValue, delayDays);
                        }
                    }
                }
            }
            Map<String, Date> infoMap = new Map<String, Date>();
            infoMap.put('config', Date.today().addDays(delayDays));

            returnMap.put(stock.Id, infoMap);
        }

        // 영업일 계산하여 날짜 계산
        Map<Date, Date> availableDateMap = CommonUtilCustomController.availableDateMap(30);
        for(String key : returnMap.keySet()) {
            Map<String, Date> infoMap = returnMap.get(key);

            Date configDate = infoMap.get('config');
            Date availableDate = availableDateMap.get(configDate);
            infoMap.put('available', availableDate);

            returnMap.put(key, infoMap);
        }

        return returnMap;
    }
    // Calendar로 잠시 추가 End

    @AuraEnabled
    public static Map<String, Object> getInit() {
        return new Map<String, Object> {
                'taxInvoiceHandoverList' => SchedulerMainController.getHandoverData('Opportunity__r.HandoverDate__c >= LAST_N_MONTHS:1 AND Opportunity__r.HandoverDate__c <= NEXT_N_MONTHS:1')
                , 'userProfileName' => [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name
                , 'paymentStatusOption' => CommonUtilController.getPickList('PaymentTracker__c', 'Status__c', null)
        };
    }


    @AuraEnabled
    public static List<SchedulerMainController.HandoverWrap> getFilteredHandoverList(Map<String, String> filterMap) {


        String searchAccountName = String.escapeSingleQuotes(filterMap.get('searchAccountName')).trim();
        String searchSalesAgentName = String.escapeSingleQuotes(filterMap.get('searchSalesAgentName')).trim();
        filterMap.remove('searchAccountName');
        filterMap.remove('searchSalesAgentName');

        String whereCondition = CommonUtilController.buildWhereConditions(filterMap);

        if(searchAccountName.length() != 0) {
            whereCondition += ' AND Opportunity__r.Account.Name LIKE \'%' + searchAccountName +'%\' ';
        }
        if(searchSalesAgentName.length() != 0) {
            whereCondition += ' AND Opportunity__r.Owner.Name LIKE \'%'+ searchSalesAgentName +'%\' ';
        }

        return SchedulerMainController.getHandoverData(whereCondition);
    }

//    @AuraEnabled
//    public static Map<String, Object> generatePdfBlob(String recordId) {
//
//        Map<String, Object> resultMap;
//        try {
//            // Visualforce 페이지 생성 및 데이터 전달
//            PageReference pdfPage = Page.DepositReceiptPDF; // Visualforce 페이지 이름
//            pdfPage.getParameters().put('recordId', recordId);
//
//            // PDF 생성
//            Blob pdfBlob = pdfPage.getContentAsPDF();
//            String file = EncodingUtil.base64Encode(pdfBlob);
//
//            resultMap = new Map<String, Object> {'pdfBase64' => file};
//
//        } catch (Exception e) {
//            System.debug('error ::: ' + e.getStackTraceString());
//            throw new AuraHandledException('Failed to generate PDF Blob: ' + e.getMessage());
//        }
//
//        return resultMap;
//    }
    @AuraEnabled
    public static Map<String, Object> generatePdfBlobSave(String recordId) {

        Map<String, Object> resultMap;
        try {
            // Visualforce 페이지 생성 및 데이터 전달
            PageReference pdfPage = Page.DepositReceiptPDF; // Visualforce 페이지 이름
            pdfPage.getParameters().put('recordId', recordId);

            // PDF 생성
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Dummy PDF data'); // 테스트용 더미 데이터
            } else {
                pdfBlob = pdfPage.getContentAsPDF(); // 실제 PDF 생성
            }

            String fileName = '입금 영수증';
            String pdfBase64 = EncodingUtil.base64Encode(pdfBlob);

            // 1. 해당 레코드에 연결된 동일 이름의 PDF 검색
            List<ContentDocumentLink> existingLinks = [
                    SELECT ContentDocumentId,
                            LinkedEntityId,
                            ContentDocument.LatestPublishedVersion.Title,
                            ContentDocument.LatestPublishedVersion.FileExtension
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :recordId
            ];

            Set<Id> contentDocIdsToDelete = new Set<Id>();
            for (ContentDocumentLink link : existingLinks) {
                if (link.ContentDocument.LatestPublishedVersion.Title.contains(fileName) &&
                        link.ContentDocument.LatestPublishedVersion.FileExtension == 'pdf') {
                    contentDocIdsToDelete.add(link.ContentDocumentId);
                }
            }

            // 2. 기존 파일 삭제
            if (!contentDocIdsToDelete.isEmpty()) {
                delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocIdsToDelete];
            }

            // 3. 새 파일 업로드
            ContentVersion newVersion = new ContentVersion();
            newVersion.Title = fileName;
            newVersion.PathOnClient = fileName + '.pdf';
            newVersion.VersionData = pdfBlob;
            insert newVersion;

            // 4. ContentDocumentId 조회
            ContentVersion inserted = [
                    SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId
                    FROM ContentVersion
                    WHERE Id = :newVersion.Id
                    LIMIT 1
            ];

            // 5. 레코드에 연결 (ContentDocumentLink)
            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = inserted.ContentDocumentId;
            link.LinkedEntityId = recordId;
            link.ShareType = 'V'; // View 권한
            link.Visibility = 'AllUsers';
            insert link;

            resultMap = new Map<String, Object> {
                    'pdfBase64' => pdfBase64
                    , 'fileId' => inserted.ContentDocumentId
            };

        } catch (Exception e) {
            System.debug('error ::: ' + e.getStackTraceString());
            throw new AuraHandledException('Failed to generate PDF Blob: ' + e.getMessage());
        }

        return resultMap;
    }


}