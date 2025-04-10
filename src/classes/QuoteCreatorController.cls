/*************************************************************
 * @author : th.kim
 * @date : 2024-12-16
 * @description : 견적 구성기 Controller
 * @target : quoteCreator
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-12-16      th.kim          Created
**************************************************************/
public without sharing class QuoteCreatorController {

    public static String oppId;
    private static String accountId;
    public static String quoteId;
    private static String productId;
    public static List<CampaignPreventDuplicate__c> campaignDupList = new List<CampaignPreventDuplicate__c>();

    /**
     * @author th.kim
     * @description 페이지 로드 시 초기 세팅 데이터 가져오기
     * @param oppId 기회 Id
     * @param quoteId 견적 Id
     *
     * @return 초기 세팅 데이터
     */
    @AuraEnabled
    public static Map<String, Object> getInit(String oppId, String quoteId) {

        QuoteCreatorController.oppId = oppId;
        QuoteCreatorController.quoteId = quoteId;

        return new Map<String, Object>{
            'oppData' => getOppData(),
            'optionFilter' => CommonUtilController.getPickList('VehicleOptionMaster__c', 'Division__c'),
            'quoteDetail' => getQuoteDetail(),
            'productData' => getProductData(),
            'optionList' => String.isNotBlank(productId) ? getOptionList('') : null,
            'campaignList' => String.isNotBlank(productId) ? getCampaignList() : null,
            'campaignDupList' => campaignDupList,
            'baseDiscount' => String.isNotBlank(productId) ? getBaseDiscount() : null,
//            'availableOilCouponQty' => getAvailableOilCouponQty(),
            'financialList' => getFinancialList()
        };
    }

    /**
     * @author th.kim
     * @description 차종 변경시 선택한 차종 관련 데이터 가져오기
     * @param oppId 기회 Id
     * @param productId 차종 Id
     *
     * @return 차종 관련 데이터
     */
    @AuraEnabled
    public static Map<String, Object> getProductChangeData(String oppId, String productId) {

        QuoteCreatorController.oppId = oppId;
        QuoteCreatorController.productId = productId;

        return new Map<String, Object>{
            'productData' => getProductData(),
            'optionList' => String.isNotBlank(productId) ? getOptionList('') : null,
            'campaignList' => getCampaignList(),
            'campaignDupList' => campaignDupList,
            'baseDiscount' => getBaseDiscount(),
            'financialList' => getFinancialList()
        };
    }

    /**
     * @author th.kim
     * @description 현재 선택한 서비스 품목 옵션의 서비스 품목 데이터 가져오기
     * @param serviceItemId 서비스품목 Id
     *
     * @return 서비스 품목 필드셋
     */
    @AuraEnabled
    public static Map<String, Object> getServiceItem(String serviceItemId) {

        List<VehicleOptionMaster__c> optionList = [SELECT Id, ServiceItemsMaster__c FROM VehicleOptionMaster__c WHERE Id = :serviceItemId];

        if (optionList.isEmpty()) return null;

        VehicleOptionMaster__c serviceOption = optionList[0];

        if (serviceOption.ServiceItemsMaster__c == null) return null;

        Schema.FieldSet fieldSet = Schema.getGlobalDescribe().get('ServiceItemsMaster__c').getDescribe().fieldSets.getMap().get('QuoteServiceItemFieldSet');

        List<String> fieldNameList = new List<String>();

        // 조회할 필드 Name 가져오기
        for (Schema.FieldSetMember fsm : fieldSet.getFields()) {
            String fieldPath = fsm.getFieldPath();
            String fieldName;

            // 타입별 필드 정의
            switch on fsm.getType() {
                when PICKLIST {
                    fieldName = 'toLabel(' + fieldPath + ')';
                }
                when REFERENCE {
                    String viewName = '.Name';
                    if (fieldPath.endsWith('__c')) {
                        fieldName = fieldPath.replace('__c', '__r') + viewName;
                    } else {
                        fieldName = fieldPath + viewName;
                    }
                }
                when DATETIME {
                    fieldName = 'FORMAT(' + fieldPath + ')';
                }
                when else {
                    fieldName = fieldPath;
                }
            }
            fieldNameList.add(fieldName);
        }

        // 쿼리를 동적으로 생성하여 관련 레코드의 데이터 가져오기
        String query =
            ' SELECT Id, Name, ' + String.join(fieldNameList, ',') +
            ' FROM ServiceItemsMaster__c ' +
            ' WHERE Id = \'' + serviceOption.ServiceItemsMaster__c + '\'';
        List<SObject> listRecord = Database.query(query);

        if (listRecord.isEmpty()) {
            return null;
        }

        SObject record = listRecord[0];
        List<FieldSetWrap> fieldSetWrapList = new List<FieldSetWrap>();
        for (Schema.FieldSetMember fsm : fieldSet.getFields()) {

            // 일반부품 보증 3년 TRUE일 시에만 필드 추가
            if (fsm.getFieldPath() != 'IsNormal__c' || Boolean.valueOf(record.get(fsm.getFieldPath()))) {
                // 필드 label, value 데이터 추가
                fieldSetWrapList.add(new FieldSetWrap(fsm.getLabel(), record.get(fsm.getFieldPath())));
            }
        }
        return new Map<String, Object>{
            'name' => record.get('Name'),
            'fieldList' => fieldSetWrapList
        };
    }

    /**
     * @author th.kim
     * @description 필터링된 옵션 리스트 검색
     * @param filterMap 옵션 조건
     *
     * @return 필터링된 옵션 리스트
     */
    @AuraEnabled
    public static List<OptionWrap> getFilteredOptionList(Map<String, String> filterMap) {

        String whereCondition = filterMap != null ? CommonUtilController.buildWhereConditions(new Map<String, Object>{
            'VehicleOptionMaster__r.Division__c' => filterMap.get('type'),
            'Product__c' => filterMap.get('product')
        }) : null;
        String name = filterMap?.get('name') ?? null;
        if (String.isNotBlank(whereCondition)) {
            if (String.isNotBlank(name)) {
                whereCondition += ' AND VehicleOptionMaster__r.Name LIKE \'%' + name + '%\'';
            }
        } else {
            whereCondition = 'VehicleOptionMaster__r.Name LIKE \'%' + name + '%\'';
        }
        return getOptionList(whereCondition);
    }

    /**
     * @author th.kim
     * @description 견적 저장
     * @param paramMap 저장할 견적 데이터 맵
     *
     * @return 저장한 견적 Id
     */
    @AuraEnabled
    public static String doSaveQuote(Map<String, String> paramMap) {

        Savepoint savepoint = Database.setSavepoint();
        try {
            quoteId = paramMap.get('quoteId');
            oppId = paramMap.get('oppId');
            Date handoverDate = paramMap.get('handoverDate') != null ? Date.valueOf(paramMap.get('handoverDate')) : null;
            String stockId = paramMap.get('stockId');
            Integer oilCouponCount = paramMap.get('oilCouponCount') != null ? Integer.valueOf(paramMap.get('oilCouponCount')) : 0;
            DataWrap dataWrap = (DataWrap) JSON.deserialize(paramMap.get('dataMap'), DataWrap.class);
            Map<String, Decimal> summaryData = (Map<String, Decimal>) JSON.deserialize(paramMap.get('summaryData'), Map<String, Decimal>.class);
            ProductWrap product = dataWrap.product;
            List<OptionWrap> defaultOptionList = dataWrap.defaultOptions;
            PromotionWrap promotion = dataWrap.promotion;
            List<SpecialWrap> specialWrapList = dataWrap.special;
            FinancialWrap financial = dataWrap.financial;
            ExtraExpensesWrap extraExpenses = dataWrap.extraExpenses;

            Decimal totalPromotionPrice = 0;
            if (promotion != null && !promotion.promotionList.isEmpty()) {
                for (PromotionWrap wrap : promotion.promotionList) {
                    if (wrap.discountPrice != null) {
                        totalPromotionPrice += wrap.discountPrice;
                    }
                }
            }
            Quote quote;
            if (String.isNotBlank(quoteId)) quote = getCurrentQuote();

            productId = product.id;
            if (String.isBlank(stockId)) {
                stockId = [
                    SELECT Id
                    FROM VehicleStock__c
                    WHERE Product__c = :productId
                    AND Status__c = '재고 노출'
                    AND VehicleStatus__c != '출고됨'
                    AND (NOT Id IN :getAssignStockList())
                    ORDER BY EopDate__c ASC NULLS LAST
                    LIMIT 1
                ]?.Id;
            }

            Pricebook2 pricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE AND IsActive = TRUE LIMIT 1];

            // 버전업 조건
            Boolean isNewQuote = (quote == null || quote.Status == 'SentOut' || quote.Status == 'Published' || quote.Status == 'Canceled' || quote.Product__c != productId);

            // 기회 소유자 가져오기
            String ownerId = [SELECT OwnerId FROM Opportunity WHERE Id = :oppId].OwnerId;

            if (isNewQuote) quote = new Quote();

            quote.IsConfigured__c = true;
            quote.OpportunityId = oppId;
            quote.Pricebook2Id = pricebook.Id;
            quote.DiscountAmt__c = totalPromotionPrice;
            quote.Product__c = productId;
            quote.CarAmt__c = product.price;
            quote.HopeHandoverDate__c = handoverDate;
            quote.VehicleStock__c = stockId;
            quote.SalesconditionDiscountAmt__c = promotion.baseDiscount;
            quote.Finance__c = financial.financeId;
            quote.DefaultInterestRate__c = financial.interestRate;
            quote.Deposit__c = financial.deposit;
            quote.CapitalDefermentAmount__c = financial.capitalDeferment;
            quote.AdvancePayment__c = financial.advancePayment;
            quote.MonthDivideInputMonth__c = financial.loanTermMonth;
            quote.InterestDefermentVAT__c = financial.interestDefermentVAT;
            quote.ConsignmentPrice__c = extraExpenses.consignment;
            quote.InsurancePrice__c = extraExpenses.insurance;
            quote.StampDuty__c = extraExpenses.stampDuty;
            quote.TotalVehiclePrice__c = summaryData.get('totalPrice');
            quote.MonthlyPayment__c = summaryData.get('monthlyPayment');

            if (isNewQuote) {
                quote.OwnerId = ownerId;
                insert quote;
            } else {
                update quote;
            }

            String quoteId = quote.Id;

            List<QuoteDetail__c> beforeQuoteDetailList = [SELECT Id FROM QuoteDetail__c WHERE Quote__c = :quoteId];
            List<QuoteLineItem> beforeQuoteLineItemList = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :quoteId];
            if (!beforeQuoteDetailList.isEmpty()) delete beforeQuoteDetailList;
            if (!beforeQuoteLineItemList.isEmpty()) delete beforeQuoteLineItemList;

            List<QuoteLineItem> quoteLineItemList = new List<QuoteLineItem>();
            List<QuoteDetail__c> quoteDetailList = new List<QuoteDetail__c>();
//            OpportunityLineItem opportunityLineItem;
            if (product != null) {
                List<PricebookEntry> pricebookEntryList = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebook.Id AND IsActive = TRUE AND Product2Id = :product.id LIMIT 1];
                if (pricebookEntryList.isEmpty()) {
                    PricebookEntry insertPricebookEntry = new PricebookEntry(
                        Pricebook2Id = pricebook.Id,
                        Product2Id = product.id,
                        UnitPrice = product.price,
                        IsActive = true
                    );
                    insert insertPricebookEntry;
                }
                PricebookEntry pricebookEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebook.Id AND IsActive = TRUE AND Product2Id = :product.id LIMIT 1];
                quoteDetailList.add(new QuoteDetail__c(
                    Quote__c = quoteId,
                    Type__c = '차종',
                    Name = product.name,
                    Product__c = product.id
                ));
                quoteLineItemList.add(new QuoteLineItem(
                    QuoteId = quoteId,
                    Product2Id = product.id,
                    UnitPrice = product.price,
                    PricebookEntryId = pricebookEntry.Id,
                    Quantity = 1
                ));

                if (!product.optionList.isEmpty()) {
                    for (OptionWrap optionWrap : product.optionList) {
                        quoteDetailList.add(new QuoteDetail__c(
                            Quote__c = quoteId,
                            Type__c = '옵션',
                            Name = optionWrap.name,
                            VehicleOptionMaster__c = optionWrap.id
                        ));
                    }
                }
            }
            if (defaultOptionList != null && !defaultOptionList.isEmpty()) {
                for (OptionWrap option : defaultOptionList) {
                    quoteDetailList.add(new QuoteDetail__c(
                        Quote__c = quoteId,
                        Type__c = '옵션',
                        Name = option.name,
                        VehicleOptionMaster__c = option.id
                    ));
                }
            }
            if (promotion != null && !promotion.promotionList.isEmpty()) {
                for (PromotionWrap promotionWrap : promotion.promotionList) {
                    quoteDetailList.add(new QuoteDetail__c(
                        Quote__c = quoteId,
                        Type__c = '캠페인',
                        Name = promotionWrap.name,
                        CampaignMaster__c = promotionWrap.id
                    ));
                }
            }
            if (oilCouponCount > 0) {
                quoteDetailList.add(new QuoteDetail__c(
                    Quote__c = quoteId,
                    Type__c = '주유상품권',
                    Name = '주유상품권',
                    OilCouponCount__c = oilCouponCount
                ));
            }
            if (specialWrapList != null && !specialWrapList.isEmpty()) {
                for (SpecialWrap specialWrap : specialWrapList) {
                    if (String.isNotBlank(specialWrap.subOption)) {
                        quoteDetailList.add(new QuoteDetail__c(
                            Quote__c = quoteId,
                            Type__c = '특장',
                            Name = specialWrap.subOption,
                            SpecialAccount__c = specialWrap.accountId,
                            SpecialOption__c = specialWrap.option,
                            SpecialSubOption__c = specialWrap.subOption,
                            SpecialPrice__c = specialWrap.price,
                            SpecialFinal__c = specialWrap.specialFinal
                        ));
                    }
                }
            }
            if (!quoteDetailList.isEmpty()) insert quoteDetailList;
            if (!quoteLineItemList.isEmpty()) insert quoteLineItemList;

            return quote.Id;
        } catch (Exception e) {
            Database.rollback(savepoint);
            System.debug('err :: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @author th.kim
     * @description 현재 견적의 데이터, 옵션, 캠페인 리스트 가져오기
     * @return 현재 견적의 데이터 Map
     */
    public static Map<String, Object> getQuoteDetail() {

        try {
            System.debug(oppId);
            Map<String, Object> returnValue = new Map<String, Object>{
                'name' => String.join(new List<String>{
                    getOppData()?.Owner.Name ?? '',
                    getOppData()?.Id.toString().substring(oppId.length() - 6) ?? '',
                    'Q1',
                    'V1'
                }, '-')
            };

            if (String.isBlank(quoteId)) {
                List<Quote> quoteList = new List<Quote>();
                quoteList = [
                    SELECT Id
                    FROM Quote
                    WHERE OpportunityId = :oppId
                    AND Status = 'Published'
                    ORDER BY ConfigurationNo__c DESC NULLS LAST, VersionNo__c DESC NULLS LAST
                    LIMIT 1
                ];
                if (quoteList.isEmpty()) {
                    quoteList = [
                        SELECT Id
                        FROM Quote
                        WHERE OpportunityId = :oppId
                        AND Status = 'Canceled'
                        ORDER BY ConfigurationNo__c DESC NULLS LAST, VersionNo__c DESC NULLS LAST
                        LIMIT 1
                    ];
                }
                if (quoteList.isEmpty()) {
                    quoteList = [
                        SELECT Id
                        FROM Quote
                        WHERE OpportunityId = :oppId
                        ORDER BY ConfigurationNo__c DESC NULLS LAST, VersionNo__c DESC NULLS LAST
                        LIMIT 1
                    ];
                }
                System.debug('quoteList :: ' + quoteList);
                if (!quoteList.isEmpty()) {
                    quoteId = quoteList[0].Id;
                } else {
                    return returnValue;
                }
            }

            Quote quote = getCurrentQuote();

            if (quote == null) {
                return returnValue;
            }

            List<OptionWrap> optionWrapList = new List<OptionWrap>();
            List<PromotionWrap> promotionWrapList = new List<PromotionWrap>();
            List<SpecialWrap> specialWrapList = new List<SpecialWrap>();
            ProductWrap productWrap;
            Decimal oilCouponCount = 0;
            for (QuoteDetail__c detail : quote.QuoteDetail__r) {
                String type = detail.Type__c;
                switch on type {
                    when '차종' {
                        productId = detail.Product__c;
                        Product2 product = detail.Product__r;
                        productWrap = new ProductWrap(product?.Id, product?.Name, product?.CarAmt__c, product?.Segment2__c, product?.LocalYear__c, product?.ModelYear__c);
                    }
                    when '옵션' {
                        VehicleOptionMaster__c option = detail.VehicleOptionMaster__r;
                        optionWrapList.add(new OptionWrap(option?.Id, option?.Name, option?.Division__c, option?.Price__c, option?.IsOilCouponExclude__c, option?.IsRequired__c));
                    }
                    when '캠페인' {
                        CampaignMaster__c campaign = detail.CampaignMaster__r;
                        Decimal discountRatePercent = campaign?.DiscountRate__c != null ? campaign?.DiscountRate__c / 100 : 0;
                        promotionWrapList.add(new PromotionWrap(campaign?.Id, campaign?.Name, String.valueOf(campaign?.ExpireDate__c), 0, campaign?.DiscountPrice__c, discountRatePercent));
                    }
                    when '주유상품권' {
                        oilCouponCount = detail.OilCouponCount__c;
                    }
                    when '특장' {
                        SpecialWrap specialWrap = new SpecialWrap(detail.SpecialAccount__c, detail.SpecialOption__c, detail.SpecialSubOption__c, detail.SpecialPrice__c, detail.SpecialFinal__c);
                        specialWrap.idx = specialWrapList.isEmpty() ? 0 : specialWrapList.size() - 1;
                        specialWrapList.add(specialWrap);
                    }
                }
            }

            String financeId;
            String financialName;
            if (String.isNotBlank(quote.Finance__c)) {
                Finance__c finance = [SELECT Id, Name FROM Finance__c WHERE Id = :quote.Finance__c];
                financeId = finance.Id;
                financialName = finance.Name;
            }

            FinancialWrap financialWrap = new FinancialWrap(financeId, financialName, quote.AdvancePayment__c, quote.DefaultInterestRate__c, quote.MonthDivideInputMonth__c, quote.Deposit__c, quote.CapitalDefermentAmount__c, null, null, quote.InterestDefermentVAT__c);
            ExtraExpensesWrap extraExpensesWrap = new ExtraExpensesWrap(quote.ConsignmentPrice__c, quote.InsurancePrice__c, quote.StampDuty__c, null, null/*, quote.RegistrationTax__c*/);

            return new Map<String, Object>{
                'name' => quote.Name,
                'quote' => quote,
                'product' => productWrap,
                'option' => optionWrapList,
                'promotion' => promotionWrapList,
                'oilCouponCount' => oilCouponCount,
                'special' => specialWrapList,
                'financial' => financialWrap,
                'extraExpenses' => extraExpensesWrap
            };
        } catch (Exception e) {
            System.debug('err :: ' + e.getMessage() + ' line :: ' + e.getStackTraceString());
            return null;
        }
    }

    /**
     * @author th.kim
     * @description 금융 데이터 선택목록으로 가져오기
     *
     * @return 금융 데이터 List<Map<String, String>>
     */
    @AuraEnabled
    public static List<Map<String, Object>> getFinancialList() {

        List<Product2> productList = [SELECT Id, Segment2__c FROM Product2 WHERE Id = :productId];
        if (productList.isEmpty()) {
            return null;
        }

        Product2 product = productList[0];

        List<Finance__c> financialList = [
            SELECT Id, Name, MinimumInterestRate__c, MaximumInterestRate__c, MinimumDuration__c, MaximumDuration__c,
                VATFree__c, SubventionRate__c, Extras__c
            FROM Finance__c
            WHERE IsActive__c = TRUE
            AND (Segment2__c = :product.Segment2__c OR AllSegment2__c = TRUE)
            ORDER BY Name
        ];
        List<Map<String, Object>> financialMapList = new List<Map<String, Object>>();
        for (Finance__c finance : financialList) {
            financialMapList.add(new Map<String, Object>{
                'label' => finance.Name,
                'value' => finance.Id,
                'minInterestRate' => finance.MinimumInterestRate__c,
                'maxInterestRate' => finance.MaximumInterestRate__c,
                'minimumDuration' => finance.MinimumDuration__c,
                'maximumDuration' => finance.MaximumDuration__c,
                'VATFree' => finance.VATFree__c,
                'subvention' => finance.SubventionRate__c,
                'extra' => finance.Extras__c
            });
        }
        return financialMapList;
    }

    /**
     * @author th.kim
     * @description 현재 기회 데이터 가져오기
     * @return 현재 기회
     */
    public static Opportunity getOppData() {

        List<Opportunity> oppList = [
            SELECT Id, Name, AccountId, Account.Name, OwnerId, Owner.Name, Owner.MobilePhone, Owner.Email, Owner.Fax,
                VATDefermentStatus__c, VATDeferredDays__c, PaymentDeferredAmount__c, (SELECT Product2Id FROM OpportunityLineItems ORDER BY CreatedDate DESC)
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        if (oppList.isEmpty()) {
            return null;
        }

        Opportunity oppData = oppList[0];
        accountId = oppData.AccountId;
        productId = String.isNotBlank(quoteId)
            ? [SELECT Product__c FROM Quote WHERE Id = :quoteId LIMIT 1]?.Product__c
            : (oppData.OpportunityLineItems.isEmpty() ? null : oppData.OpportunityLineItems[0].Product2Id);

        return oppData;
    }

    /**
     * @author th.kim
     * @description 현재 견적 데이터 가져오기
     *
     * @return 현재 견적 데이터
     */
    private static Quote getCurrentQuote() {
        List<Quote> quoteList = [
            SELECT Id, Name, Status, OpportunityId, SalesconditionDiscountAmt__c, DefaultInterestRate__c, MonthDivideInputMonth__c, DiscountAmt__c,
                Product__c, Finance__c, Finance__r.Name, /*LoanAmount__c,*/ ConsignmentPrice__c, InsurancePrice__c, VehicleStock__c, HopeHandoverDate__c,
                /*RegistrationTax__c,*/ StampDuty__c, /*TotalSpecialPrice__c,*/ Deposit__c, InterestDefermentVAT__c, AdditionalLossPrice__c,
                AdvancePayment__c, CapitalDefermentAmount__c, fm_VehicleDiscountPrice__c, Opportunity.OwnerId, (
                SELECT Id, Type__c, Product__c, CampaignMaster__c, OilCouponCount__c, SpecialOption__c, SpecialSubOption__c, SpecialPrice__c,
                    SpecialAccount__c, SpecialFinal__c, CampaignMaster__r.Name, CampaignMaster__r.ExpireDate__c, CampaignMaster__r.DiscountPrice__c,
                    CampaignMaster__r.DiscountRate__c, VehicleOptionMaster__r.Name, VehicleOptionMaster__r.Division__c,
                    VehicleOptionMaster__r.Price__c, VehicleOptionMaster__r.IsOilCouponExclude__c, VehicleOptionMaster__r.IsRequired__c,
                    Product__r.Name, Product__r.CarAmt__c, Product__r.Segment2__c, Product__r.LocalYear__c, Product__r.ModelYear__c
                FROM QuoteDetail__r
            )
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];

        if (quoteList.isEmpty()) {
            return null;
        }

        return quoteList[0];
    }

    /**
     * @author th.kim
     * @description Product 데이터 가져오기
     * @return ProductWrap
     */
    private static ProductWrap getProductData() {

        List<Product2> productList = [
            SELECT Id, Name, CarAmt__c, Segment2__c, LocalYear__c, ModelYear__c, (
                SELECT Id, toLabel(CarColor__c), ModelYear__c, LongtermDiscountRate__c, SpecialDiscountRate__c, OptionDiscountRate__c, Deviation__c, Remarks__c
                FROM VehicleStock__r
                WHERE Status__c = '재고 노출'
                AND (
                    LongTermStock__c = TRUE
                    OR IsSpecial__c = TRUE
                    OR IsOptionDiscount__c = TRUE
                )
                AND (NOT Id IN :getAssignStockList())
                ORDER BY EopDate__c ASC
            )
            FROM Product2
            WHERE Id = :productId
        ];

        if (productList.isEmpty()) {
            return null;
        }

        Product2 item = productList[0]; // 공통으로 사용할 SObject 변수

        ProductWrap productWrap = new ProductWrap(
            item.Id,
            item.Name,
            item.CarAmt__c,
            item.Segment2__c,
            item.LocalYear__c,
            item.ModelYear__c
        );
        for (VehicleStock__c stock : item.VehicleStock__r) {
            stock.LongtermDiscountRate__c = stock.LongtermDiscountRate__c != null ? stock.LongtermDiscountRate__c / 100 : 0;
            stock.SpecialDiscountRate__c = stock.SpecialDiscountRate__c != null ? stock.SpecialDiscountRate__c / 100 : 0;
            stock.OptionDiscountRate__c = stock.OptionDiscountRate__c != null ? stock.OptionDiscountRate__c / 100 : 0;
        }
        productWrap.stockList = item.VehicleStock__r;

        return productWrap;
    }

    /**
     * @author th.kim
     * @description 현재 차량의 옵션 데이터 가져오기
     * @param whereCondition 옵션 구분, 옵션명 필터
     *
     * @return 옵션 리스트
     */
    private static List<OptionWrap> getOptionList(String whereCondition) {

        String selectFields = 'Id, Product__c, VehicleOptionMaster__c, VehicleOptionMaster__r.Name, VehicleOptionMaster__r.Division__c,' +
            'VehicleOptionMaster__r.Price__c, VehicleOptionMaster__r.IsOilCouponExclude__c, VehicleOptionMaster__r.IsRequired__c';
        if (String.isBlank(whereCondition) && String.isNotBlank(productId)) whereCondition = 'Product__c = \'' + productId + '\'';

        List<ProductOption__c> optionList = Database.query(CommonUtilController.buildQuery(selectFields, 'ProductOption__c', whereCondition, 'VehicleOptionMaster__r.Division__c ASC'));
        List<OptionWrap> optionWrapList = new List<OptionWrap>();
        for (ProductOption__c option : optionList) {
            VehicleOptionMaster__c optionMaster = option.VehicleOptionMaster__r;
            optionWrapList.add(new OptionWrap(optionMaster?.Id, optionMaster?.Name, optionMaster?.Division__c, optionMaster?.Price__c, optionMaster?.IsOilCouponExclude__c, optionMaster?.IsRequired__c));
        }
        return optionWrapList;
    }

    /**
     * @author th.kim
     * @description 현재 Product의 캠페인 리스트 가져오기
     * @return 캠페인 리스트
     */
    private static List<PromotionWrap> getCampaignList() {

        Set<Id> campaignIdSet = new Set<Id>();
        for (CampaignJunction__c campaignJunction : [
            SELECT CampaignMaster__c
            FROM CampaignJunction__c
            WHERE (
                Product__c = :productId
                AND Product__c != NULL
            ) OR (
                Account__c = :accountId
                AND Account__c != NULL
            )
        ]) {
            campaignIdSet.add(campaignJunction.CampaignMaster__c);
        }

        List<CampaignMaster__c> campaignList = [
            SELECT Id, Name, ExpireDate__c, DiscountPrice__c, DiscountRate__c, Memo__c
            FROM CampaignMaster__c
            WHERE Status__c = '진행중'
            AND (
                AllModelCheck__c = TRUE
                OR Id IN :campaignIdSet
            )
        ];

        campaignDupList = [
            SELECT Id, Name, CampaignMaster__c, CampaignMaster2__c, CampaignMaster__r.Name, CampaignMaster2__r.Name
            FROM CampaignPreventDuplicate__c
            WHERE IsActive__c = TRUE
            AND (
                CampaignMaster__c IN :campaignList OR CampaignMaster2__c IN :campaignList
            )
        ];

        List<PromotionWrap> promotionWrapList = new List<PromotionWrap>();
        for (CampaignMaster__c campaign : campaignList) {
            Decimal discountRatePercent = campaign.DiscountRate__c != null ? campaign.DiscountRate__c / 100 : 0;
            PromotionWrap promotionWrap = new PromotionWrap(
                campaign.Id,
                campaign.Name,
                String.valueOf(campaign.ExpireDate__c),
                null,
                campaign.DiscountPrice__c,
                discountRatePercent
            );
            promotionWrap.memo = campaign.Memo__c;
            promotionWrapList.add(promotionWrap);
        }
        return promotionWrapList;
    }

    /**
     * @author th.kim
     * @description 기준할인(세일즈컨디션) 가격 가져오기
     * @return 할인 가격(%)
     */
    public static Decimal getBaseDiscount() {

        List<SalesConditionMaster__c> salesConditionMasterList = [
            SELECT Id, Name, Discount__c
            FROM SalesConditionMaster__c
            WHERE IsActive__c = TRUE
            AND Id IN (
                SELECT SalesConditionMaster__c
                FROM Product2
                WHERE Id = :productId
            )
            LIMIT 1
        ];

        if (salesConditionMasterList.isEmpty()) {
            return 0;
        } else {
            return salesConditionMasterList[0].Discount__c;
        }
    }

    /**
     * @author th.kim
     * @description 가용 주유상품권 수량을 가져옴
     *
     *  @return 가용 주유상품권 수량 || 0
     */
//    private static Decimal getAvailableOilCouponQty() {
//
//        return [SELECT Quantity__c FROM OilCouponMaster__c LIMIT 1]?.Quantity__c ?? 0;
//    }

    /**
     * @author th.kim
     * @description 배정된 기회 차량 제외
     * @return 배정된 기회 Set<Id>
     */
    private static Set<Id> getAssignStockList() {

        List<Opportunity> opportunityList = [
            SELECT VehicleStock__c
            FROM Opportunity
            WHERE VehicleStock__r.Product__c = :productId
        ];

        Set<Id> stockIdSet = new Set<Id>();
        for (Opportunity opp : opportunityList) {
            stockIdSet.add(opp.VehicleStock__c);
        }

        return stockIdSet;
    }

    @TestVisible
    private class DataWrap {
        @AuraEnabled public ProductWrap product;
        @AuraEnabled public List<OptionWrap> defaultOptions;
        @AuraEnabled public PromotionWrap promotion;
        @AuraEnabled public List<SpecialWrap> special;
        @AuraEnabled public FinancialWrap financial;
        @AuraEnabled public ExtraExpensesWrap extraExpenses;
        public DataWrap(ProductWrap product, List<OptionWrap> defaultOptions, PromotionWrap promotion, List<SpecialWrap> special, FinancialWrap financial, ExtraExpensesWrap extraExpenses) {
            this.product = product;
            this.defaultOptions = defaultOptions;
            this.promotion = promotion;
            this.special = special;
            this.financial = financial;
            this.extraExpenses = extraExpenses;
        }
    }

    public class ProductWrap {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Decimal price { get; set; }
        @AuraEnabled public Decimal totalPrice { get; set; }
        @AuraEnabled public String segment { get; set; }
        @AuraEnabled public String LMY { get; set; }
        @AuraEnabled public String VMY { get; set; }
        @AuraEnabled public List<OptionWrap> optionList { get; set; }
        @AuraEnabled public List<VehicleStock__c> stockList { get; set; }

        public ProductWrap(String id, String name, Decimal price, String segment, String LMY, String VMY) {
            this.id = id;
            this.name = name;
            this.price = price;
            this.segment = segment;
            this.LMY = LMY;
            this.VMY = VMY;
            optionList = new List<OptionWrap>();
        }
    }

    public class OptionWrap {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public Decimal price { get; set; }
        @AuraEnabled public Boolean isOilCouponExclude { get; set; }
        @AuraEnabled public Boolean isRequired { get; set; }

        public OptionWrap(String id, String name, String type, Decimal price, Boolean isOilCouponExclude, Boolean isRequired) {
            this.id = id;
            this.name = name;
            this.type = type;
            this.price = price;
            this.isOilCouponExclude = isOilCouponExclude;
            this.isRequired = isRequired;
        }
    }

    public class PromotionWrap {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String expireDate { get; set; }
        @AuraEnabled public Decimal baseDiscount { get; set; }
        @AuraEnabled public Decimal discountPrice { get; set; }
        @AuraEnabled public Decimal discountRate { get; set; }
        @AuraEnabled public String memo { get; set; }
        @AuraEnabled public List<PromotionWrap> promotionList { get; set; }

        public PromotionWrap(String id, String name, String expireDate, Decimal baseDiscount, Decimal discountPrice, Decimal discountRate) {
            this.id = id;
            this.name = name;
            this.expireDate = expireDate;
            this.baseDiscount = baseDiscount;
            this.discountPrice = discountPrice;
            this.discountRate = discountRate;
            promotionList = new List<PromotionWrap>();
        }
    }

    public class SpecialWrap {
        @AuraEnabled public Decimal idx { get; set; }
        @AuraEnabled public String accountId { get; set; }
        @AuraEnabled public String option { get; set; }
        @AuraEnabled public String subOption { get; set; }
        @AuraEnabled public Decimal price { get; set; }
        @AuraEnabled public String specialFinal { get; set; }

        public SpecialWrap(String accountId, String option, String subOption, Decimal price, String specialFinal) {
            this.accountId = accountId;
            this.option = option;
            this.subOption = subOption;
            this.price = price;
            this.specialFinal = specialFinal;
        }
    }

    public class FinancialWrap {
        @AuraEnabled public String financeId { get; set; }
        @AuraEnabled public String financialName { get; set; }
//        @AuraEnabled public String interestRateRange { get; set; }
        @AuraEnabled public Decimal advancePayment { get; set; }
        @AuraEnabled public Decimal interestRate { get; set; }
        @AuraEnabled public Decimal loanTermMonth { get; set; }
        @AuraEnabled public Decimal deposit { get; set; }
        @AuraEnabled public Decimal capitalDeferment { get; set; }
        @AuraEnabled public Decimal defermentVAT { get; set; }
        @AuraEnabled public Decimal monthlyPayment { get; set; }
        @AuraEnabled public Decimal interestDefermentVAT { get; set; }

        public FinancialWrap(
            String financeId,
            String financialName,
            Decimal advancePayment,
            Decimal interestRate,
            Decimal loanTermMonth,
            Decimal deposit,
            Decimal capitalDeferment,
            Decimal defermentVAT,
            Decimal monthlyPayment,
            Decimal interestDefermentVAT
        ) {
            this.financeId = financeId;
            this.financialName = financialName;
            this.deposit = deposit;
            this.capitalDeferment = capitalDeferment;
            this.defermentVAT = defermentVAT;
            this.advancePayment = advancePayment;
            this.interestRate = interestRate;
            this.loanTermMonth = loanTermMonth;
            this.monthlyPayment = monthlyPayment;
            this.interestDefermentVAT = interestDefermentVAT;
        }
    }

    public class ExtraExpensesWrap {
        @AuraEnabled public Decimal consignment { get; set; }
        @AuraEnabled public Decimal insurance { get; set; }
        @AuraEnabled public Decimal stampDuty { get; set; }
        @AuraEnabled public Decimal notarizedFee { get; set; }
        @AuraEnabled public Decimal totalExpenses { get; set; }
//        @AuraEnabled public Decimal registrationTax { get; set; }
        @AuraEnabled public Boolean isStampDuty { get; set; }

        public ExtraExpensesWrap(Decimal consignment, Decimal insurance, Decimal stampDuty, Decimal notarizedFee, Decimal totalExpenses/*, Decimal registrationTax*/) {
            this.consignment = consignment;
            this.insurance = insurance;
            this.stampDuty = stampDuty;
            this.notarizedFee = notarizedFee;
            this.totalExpenses = totalExpenses;
//            this.registrationTax = registrationTax;
            this.isStampDuty = stampDuty > 0;
        }
    }

    private class FieldSetWrap {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Object value { get; set; }
        public FieldSetWrap(String label, Object value) {
            this.label = label;
            this.value = value;
        }
    }
}