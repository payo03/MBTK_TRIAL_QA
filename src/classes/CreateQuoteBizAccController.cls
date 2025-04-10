/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-04-07      jh.jung           Created
*/
public with sharing class CreateQuoteBizAccController {

    @AuraEnabled
    public static Map<String, Object> createQuoteByBizAcc(Map<String, Object> inputMap) {
        System.debug('createPreQuote input ::: ' + JSON.serialize(inputMap));

        Map<String, Object> returnMap = new Map<String, Object>();

        String accountId = String.valueOf(inputMap.get('accountId'));
        String productId = String.valueOf(inputMap.get('productId'));
        Decimal totalLoan = Decimal.valueOf(String.valueOf(inputMap.get('totalLoan')));
        Decimal interestRate = Decimal.valueOf(String.valueOf(inputMap.get('interestRate')));
        Integer duration = Integer.valueOf(inputMap.get('duration'));
        String financeId = String.valueOf(inputMap.get('financeId'));
        List<String> campaignIdList = (List<String>) JSON.deserialize((String) inputMap.get('campaignIdList'), List<String>.class);

        Date closeDate = Date.newInstance(System.today().year(), 12, 31);
        Set<String> campaignIdSet = new Set<String>();

        Savepoint sp = Database.setSavepoint();

        try {
            for (String campaignId : campaignIdList) {
                if (String.isNotBlank(campaignId)) {
                    campaignIdSet.add((String)  campaignId); // String -> Id로 캐스팅
                }
            }
            List<CampaignMaster__c> campaignList = [SELECT Id, Name, DiscountPrice__c, DiscountRate__c  FROM CampaignMaster__c WHERE Id IN :campaignIdSet];
            Map<String, CampaignMaster__c> campaignMap = new Map<String, CampaignMaster__c>(campaignList);

            LeadManagementController.ProductWrap ProductWrap = getProductWrap(productId);
            Pricebook2 pricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE AND IsActive = TRUE LIMIT 1];

            Account account = [SELECT Id, Name, Owner.Agency__c FROM Account WHERE Id = :accountId];

            System.debug('ProductWrap ::: ' + ProductWrap);
            // oppty 생성
            Opportunity oppty = new Opportunity();
            oppty.AccountId = accountId;
            oppty.CloseDate = closeDate;
            oppty.StageName = 'Quotation';
            oppty.Name = account.Owner.Agency__c + '-' + account.Name + ' ' + productWrap.Name;
            insert oppty;

            PricebookEntry pricebookEntry;

            if (productWrap.pricebookEntryList != null && !productWrap.pricebookEntryList.isEmpty()) {
                pricebookEntry = productWrap.pricebookEntryList[0]; // 이미 있는 값 사용
            } else {
                // 존재하지 않으면 새로 만들기 전에 중복 체크
                List<PricebookEntry> check = [
                        SELECT Id FROM PricebookEntry
                        WHERE Pricebook2Id = :pricebook.Id
                        AND Product2Id = :productWrap.id
                        LIMIT 1
                ];
                if (!check.isEmpty()) {
                    pricebookEntry = check[0]; // 이미 존재하는 거 사용
                } else {
                    pricebookEntry = new PricebookEntry(
                            Pricebook2Id = pricebook.Id,
                            Product2Id = productWrap.id,
                            UnitPrice = productWrap.carAmt,
                            IsActive = true
                    );
                }
            }

            upsert pricebookEntry;


//            PricebookEntry pricebookEntry = new PricebookEntry(
//                    Pricebook2Id = pricebook.Id,
//                    Product2Id = productWrap.id,
//                    UnitPrice = productWrap.carAmt,
//                    IsActive = true
//            );
//            upsert pricebookEntry;

            // 할인 가격 생성
            Decimal tempPrice = productWrap.carAmt * (1 - (productWrap.salesConditionRate / 100));
            Decimal discountPrice = 0;

            for (String campaignId : campaignIdList) {
                CampaignMaster__c campaign = campaignMap.get(campaignId);
    //            tempPrice -= (campaign.DiscountRate__c != null)
    //                    ? (productWrap.carAmt * campaign.DiscountRate__c) / 100
    //                    : campaign.DiscountPrice__c;
                discountPrice += (campaign.DiscountRate__c != null)
                        ? (productWrap.carAmt * campaign.DiscountRate__c) / 100
                        : campaign.DiscountPrice__c;
            }

            tempPrice -= discountPrice;

            // OpptyLineItem 생성
            OpportunityLineItem opptyLineItem = new OpportunityLineItem();
            opptyLineItem.OpportunityId = oppty.Id;
            opptyLineItem.Product2Id = productWrap.Id;
            opptyLineItem.PricebookEntryId = productWrap.pricebookEntryList.isEmpty()
                    ? pricebookEntry.Id
                    : productWrap.pricebookEntryList[0].Id;
            opptyLineItem.UnitPrice = tempPrice;
            opptyLineItem.Quantity = 1;

            insert opptyLineItem;

            // Quote 생성
            Quote quote = new Quote();
            quote.Name = 'quoteName';
            quote.OpportunityId = oppty.Id;
            quote.Status = 'Draft';
            quote.Pricebook2Id = productWrap.pricebookEntryList.isEmpty()
                    ? pricebookEntry.Pricebook2Id
                    : productWrap.pricebookEntryList[0].Pricebook2Id;
            quote.TotalVehiclePrice__c = productWrap.carAmt;
            quote.SalesconditionDiscountAmt__c = productWrap.carAmt * (productWrap.salesConditionRate / 100);
            quote.DiscountAmt__c = discountPrice;
    //                quote.RealSalesPrice__c = tempPrice;
            quote.Deposit__c = 1000000;
            Decimal loadAmount = totalLoan != null ? totalLoan : 0;
    //                quote.LoanAmount__c = inputInfo.get('totalLoan') != null ? totalLoan : 0;
            quote.AdvancePayment__c = tempPrice - loadAmount;
    //                quote.DeliveryPrice__c = quote.TotalVehiclePrice__c - quote.Deposit__c - quote.LoanAmount__c;
            quote.DefaultInterestRate__c = interestRate != null ? interestRate : 0;
            quote.MonthDivideInputMonth__c = duration != null ? duration : 0;
            quote.MonthlyPayment__c = calPMT(quote.DefaultInterestRate__c, quote.MonthDivideInputMonth__c, loadAmount);
//            quote.Finance__c = financeId != null ? financeId : '';
            quote.Product__c = productId != null ? productId : '';

            insert quote;

            // QuoteLineItem 생성
            QuoteLineItem quoteLineItem = new QuoteLineItem();
            quoteLineItem.QuoteId = quote.Id;
            quoteLineItem.PricebookEntryId = productWrap.pricebookEntryList.isEmpty()
                    ? pricebookEntry.Id
                    : productWrap.pricebookEntryList[0].Id;
            quoteLineItem.UnitPrice = tempPrice;
            quoteLineItem.Quantity = 1;

            insert quoteLineItem;

            // quoteDetail 생성
            List<QuoteDetail__c> quoteDetailList = new List<QuoteDetail__c>();

            QuoteDetail__c quoteDetailByProduct = new QuoteDetail__c();
            quoteDetailByProduct.Quote__c = quote.Id;
            quoteDetailByProduct.Type__c = '차종';
            quoteDetailByProduct.Name = productWrap.name;
            quoteDetailByProduct.Product__c = productWrap.id;

            quoteDetailList.add(quoteDetailByProduct);

            for(CampaignMaster__c campaignMaster : campaignList) {
                QuoteDetail__c quoteDetailByCampaign = new QuoteDetail__c();
                quoteDetailByCampaign.Quote__c = quote.Id;
                quoteDetailByCampaign.Type__c = '캠페인';
                quoteDetailByCampaign.Name = campaignMaster.Name;
                quoteDetailByCampaign.CampaignMaster__c = campaignMaster.Id;

                quoteDetailList.add(quoteDetailByCampaign);
            }

            insert quoteDetailList;

            returnMap = new Map<String, Object>{
                    'accountId' => accountId,
                    'isSuccess' => quote != null,
                    'value' => quote.Id
            };
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('e.toString() ::: ' + e.toString());
            System.debug('e.getStackTraceString() ::: ' + e.getStackTraceString());
        }
        System.debug('createPreQuoteList return ::: ' + JSON.serialize(returnMap));
        return returnMap;

    }


    private static LeadManagementController.ProductWrap getProductWrap(String productId) {

        Product2 product = [
                SELECT Id, Name, Segment2__c, Quantity__c, CarAmt__c,
                (SELECT Id, UnitPrice, pricebook2Id FROM PricebookEntries), SalesConditionMaster__r.Discount__c
                FROM Product2
                WHERE Id = :productId
                LIMIT 1
        ];

        LeadManagementController.ProductWrap wrapObj = new LeadManagementController.ProductWrap();
        wrapObj.id = product.Id;
        wrapObj.segment = product.Segment2__c;
        wrapObj.name = product.Name;
        wrapObj.quantity = product.Quantity__c;
        wrapObj.carAmt = product.CarAmt__c;
        wrapObj.pricebookEntryList = product.PricebookEntries;
        wrapObj.salesConditionRate = product.SalesConditionMaster__r != null
                ? product.SalesConditionMaster__r.Discount__c
                : 0;

        return wrapObj;
    }

    private static Double calPMT(Decimal interestRate, Decimal nper, Decimal pv) {
        Double rate = (interestRate / 100) / 12;
        if(nper == 0) return 0.0;
        if(rate == 0) return pv / nper;

        Double pmtValue = (pv * rate) / (1 - Math.pow(1 + rate, -Double.valueOf(nper))); // PMT
        return Math.round(pmtValue / 10) * 10;   // 1원 절삭
    }
}