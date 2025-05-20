/*************************************************************
 * @author : th.kim
 * @date : 2025-01-20
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-20      th.kim          Created
**************************************************************/
@IsTest
private class QuoteCreatorController_test {

    static final Opportunity opportunity;
    static final Quote quote;
    static final Product2 product;
    static final VehicleOptionMaster__c option;
    static final CampaignMaster__c campaign;
    static final Account account;
    static final Finance__c finance;

    static {
//        TestObjectBuilder.createObjects();
        update TestObjectBuilder2.createPricebook();
        TestObjectBuilder2.createAccountBundle();
        TestObjectBuilder2.createCampaignBundle();
        TestObjectBuilder2.createOpportunityBundle();
        TestObjectBuilder2.createQuoteBundle();
        opportunity = TestObjectBuilder2.opportunity;
        quote = TestObjectBuilder2.quote;
        product = TestObjectBuilder2.product;
        option = TestObjectBuilder2.option;
        campaign = TestObjectBuilder2.amtCampaign;
        account = TestObjectBuilder2.accountCompany;
        finance = TestObjectBuilder2.finance;
    }

    @IsTest
    static void testGetInit() {

        Test.startTest();

        QuoteCreatorController.getInit(opportunity.Id, null);
        QuoteCreatorController.getInit(null, quote.Id);
        QuoteCreatorController.getInit(null, null);
        QuoteCreatorController.getInit(opportunity.Id, quote.Id);

        Test.stopTest();
    }

    @IsTest
    static void testGetProductChangeData() {

        Test.startTest();

        QuoteCreatorController.getProductChangeData(opportunity.Id, null);
        QuoteCreatorController.getProductChangeData(null, product.Id);
        QuoteCreatorController.getProductChangeData(null, null);
        QuoteCreatorController.getProductChangeData(opportunity.Id, product.Id);

        Test.stopTest();
    }

    @IsTest
    static void testGetServiceItem() {

        Test.startTest();

        QuoteCreatorController.getServiceItem(option.Id);

        Test.stopTest();
    }

    @IsTest
    static void testGetFilteredOptionList() {

        Test.startTest();

        QuoteCreatorController.getFilteredOptionList(null);
        Map<String, String> paramMap = new Map<String, String>{
            'type' => null,
            'product' => product.Id
        };
        QuoteCreatorController.getFilteredOptionList(paramMap);

        paramMap.put('type', '서비스품목');
        paramMap.put('name', 'Carefree');
        QuoteCreatorController.getFilteredOptionList(paramMap);

        Test.stopTest();
    }

    @IsTest
    static void testDoSaveQuote() {

        Test.startTest();

        System.debug('option :: ' + option);
        List<QuoteCreatorController.OptionWrap> optionList = new List<QuoteCreatorController.OptionWrap>{
            new QuoteCreatorController.OptionWrap(
                option.Id,
                option.Name,
                option.Division__c,
                option.Price__c,
                false,
                false
            )
        };

        QuoteCreatorController.ProductWrap product = new QuoteCreatorController.ProductWrap(
            product.Id,
            product.Name,
            product.CarAmt__c,
            product.Segment2__c,
            product.LocalYear__c,
            product.ModelYear__c
        );
        product.optionList = optionList;

        QuoteCreatorController.PromotionWrap promotion = new QuoteCreatorController.PromotionWrap(
            null,
            null,
            null,
            0,
            null,
            null
        );
        promotion.promotionList = new List<QuoteCreatorController.PromotionWrap>{
            new QuoteCreatorController.PromotionWrap(
                campaign.Id,
                campaign.Name,
                String.valueOf(campaign.ExpireDate__c),
                0,
                0,
                0
            )
        };

        List<QuoteCreatorController.SpecialWrap> special = new List<QuoteCreatorController.SpecialWrap>{
            new QuoteCreatorController.SpecialWrap(
                account.Id,
                '캡섀시 - 미완성',
                '윙바디',
                2000000,
                ''
            )
        };

        QuoteCreatorController.FinancialWrap financial = new QuoteCreatorController.FinancialWrap(
            finance.Id,
            finance.Name,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        );

        QuoteCreatorController.ExtraExpensesWrap extraExpenses = new QuoteCreatorController.ExtraExpensesWrap(
            0, 0, 0, 0, 0, 0
        );

        QuoteCreatorController.DataWrap dataWrap = new QuoteCreatorController.DataWrap(
            product,
            optionList,
            promotion,
            special,
            financial,
            extraExpenses
        );

        Map<String, Decimal> summaryDataMap = new Map<String, Decimal>{
            'realSalesPrice' => 0,
            'specialPrice' => 0,
            'totalRealAndSpecialPrice' => 0,
            'monthlyPayment' => 0,
            'totalPaymentBeforeReleased' => 0
        };

        Map<String, String> paramMap = new Map<String, String>{
            'oppId' => opportunity.Id,
            'quoteId' => quote.Id,
            'handoverDate' => '2025-01-20',
            'stockId' => '',
            'oilCouponCount' => '100',
            'dataMap' => JSON.serialize(dataWrap),
            'summaryData' => JSON.serialize(summaryDataMap)
        };
        QuoteCreatorController.doSaveQuote(paramMap);

        quote.Status = 'SentOut';
        // quote.IsPublished__c = true;
        update quote;
        QuoteCreatorController.doSaveQuote(paramMap);

        Test.stopTest();
    }
}