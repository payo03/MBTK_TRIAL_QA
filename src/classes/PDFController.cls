/*************************************************************
 * @author : chaebeom.do
 * @date : 2024-12-24
 * @description : MTBK 견적서 양식에 맞는 Visualforce 페이지에 사용할 데이터 가져오기
 * @target : QuotePdf.page
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-12-24      chaebeom.do     Created
**************************************************************/
public without sharing class PDFController {
    @AuraEnabled public static String lan {get; set;}
    @AuraEnabled public static Quote quote {get; set;}
    @AuraEnabled public static String formatStartDate {get; set;}
    @AuraEnabled public static Account acc {get; set;}
    @AuraEnabled public static Opportunity opp {get; set;}
    @AuraEnabled public static Product2 product {get; set;}
    @AuraEnabled public static VehicleStock__c vehicleStock {get; set;}
    @AuraEnabled public static List<QuoteDetail__c> optionList {get; set;}
    @AuraEnabled public static List<QuoteDetail__c> accyList {get; set;}
    @AuraEnabled public static List<QuoteDetail__c> warrantyList {get; set;}
    @AuraEnabled public static Map<String, String> warrantyDetail {get; set;}
    @AuraEnabled public static List<Map<String, String>> warrantyDetailList {get; set;}

    @AuraEnabled public static Map<String, Object> quoteDetail {get; set;}
    @AuraEnabled public static Decimal baseDiscount {get; set;}
    @AuraEnabled public static Decimal additionalLossPrice {get; set;}
    @AuraEnabled public static Decimal interestDefermentVAT {get; set;}
    
    @AuraEnabled public static List<ContentVersion> productCv {get; set;}
    @AuraEnabled public static List<ContentVersion> optionCv {get; set;}

    public ApexPages.StandardController vfController { get; set; }

    public PDFController(ApexPages.StandardController controller) {
        vfController = controller;
    }

    @AuraEnabled
    public static void getImgList() {
        try {
            // pdf 페이지수 필요할 때
            // Integer pageNumber = CommonUtilCustomController.getPDFPageNumber(text);

            String recordId = ApexPages.currentPage().getParameters().get('id');
            lan = ApexPages.currentPage().getParameters().get('language');

            quote = [
                SELECT Id, Name, AccountId, OpportunityId, 
                Opportunity.Owner.Name, Owner.Phone, Owner.Email, Product__c, VehicleStock__c,
                TotalVehiclePrice__c, fm_TotalDiscountAmt__c, fm_VehicleDiscountPrice__c,
                fm_DeliveryDiscountPrice__c, ru_OilCouponPrice__c, fm_RealSellAmt__c, 
                fm_TotalRealAndSpecialPrice__c, AdditionalDiscountRateStatus__c, AdditionalLossPrice__c, // price break down
                Deposit__c, fm_DeliveryPrice__c, AdvancePayment__c,
                fm_DefermentVAT__c, fm_TotalLoanAmount__c, CapitalDefermentAmount__c, 
                MonthlyPayment__c, fm_NotarizedFee__c, ConsignmentPrice__c,
                fm_RegistrationTax__c // financial 금액
                FROM Quote 
                WHERE Id = :recordId];
            acc = [SELECT Id, Name FROM Account WHERE Id = :quote.AccountId];
            opp = [SELECT Id, VATDefermentStatus__c, PaymentDeferredAmount__c FROM Opportunity WHERE Id = :quote.OpportunityId];
            vehicleStock = [SELECT Id, HorsePower__c, EngineRange__c FROM VehicleStock__c WHERE Id = :quote.VehicleStock__c];
            System.debug('vehicleStock :: ' + vehicleStock);
            String productId = quote.Product__c;
            product = [SELECT Id, Name, toLabel(EmissionLevel__c) FROM Product2 WHERE Id = :productId];

            Datetime conStartDate = Date.Valueof(System.today());
            formatStartDate = conStartDate.format('yyyy-MM-dd');
            
            //옵션 리스트(필수 옵션과 악세서리 따로 쿼리)
            optionList = [SELECT Type__c, Name, Product__c, VehicleOptionMaster__c, VehicleOptionMaster__r.Name, VehicleOptionMaster__r.FamliyName__c
                FROM QuoteDetail__c 
                WHERE Quote__c = :recordId
                AND (VehicleOptionMaster__r.Division__c = '필수 옵션' OR VehicleOptionMaster__r.Division__c = '옵션') ];
            System.debug('optionList :: ' + optionList);
            accyList = [SELECT Name, VehicleOptionMaster__c, VehicleOptionMaster__r.Name, VehicleOptionMaster__r.FamliyName__c
                FROM QuoteDetail__c 
                WHERE Quote__c = :recordId
                AND VehicleOptionMaster__r.Division__c = '기본제공'];
            System.debug('accyList :: ' + accyList);
            // 차량 스펙시트
            ContentDocumentLink[] cd1 = [SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :productId
            AND (ContentDocument.FileExtension = 'jpg' OR ContentDocument.FileExtension = 'png')];
            if (cd1.size() > 0) {
                productCv = [SELECT Id, VersionData, VersionDataURL 
                FROM Contentversion 
                WHERE ContentdocumentId = :cd1[0].ContentDocumentId];
            } else {
                productCv = null;
            }
            
            // 옵션 스펙시트
            List<String> cdlList = new List<String>();
            for(QuoteDetail__c option : optionList){
                ContentDocumentLink[] cd = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :option.VehicleOptionMaster__c];
                if (cd.size() > 0) {
                    cdlList.add(cd[0].ContentDocumentId);
                } else {
                    System.debug('No record found');
                }
            }
            optionCv = [SELECT Id, VersionData, VersionDataURL 
                        FROM Contentversion 
                        WHERE ContentdocumentId IN :cdlList
                        AND (FileExtension = 'jpg' OR FileExtension = 'png')];

            //서비스 품목 내용
            warrantyList = [SELECT Name, VehicleOptionMaster__c, VehicleOptionMaster__r.isRequired__c,
                VehicleOptionMaster__r.ServiceItemsMaster__r.Name, VehicleOptionMaster__r.ServiceItemsMaster__r.Description__c,
                VehicleOptionMaster__r.ServiceItemsMaster__r.firstCheck__c, VehicleOptionMaster__r.ServiceItemsMaster__r.EngineOilCheck__c,
                VehicleOptionMaster__r.ServiceItemsMaster__r.EngineValve__c, VehicleOptionMaster__r.ServiceItemsMaster__r.YearCheck__c,
                VehicleOptionMaster__r.ServiceItemsMaster__r.WinterCheck__c, VehicleOptionMaster__r.ServiceItemsMaster__r.HYVACheck__c,
                VehicleOptionMaster__r.ServiceItemsMaster__r.RearAxleCheck__c, VehicleOptionMaster__r.ServiceItemsMaster__r.GearCheck__c,
                VehicleOptionMaster__r.ServiceItemsMaster__r.CoolingWaterCheck__c, VehicleOptionMaster__r.ServiceItemsMaster__r.EHLACheck__c
                FROM QuoteDetail__c 
                WHERE Quote__c = :recordId
                AND VehicleOptionMaster__r.Division__c = '서비스품목'];
            System.debug('warrantyList :: ' + warrantyList);

            if(!warrantyList.isEmpty()) {
                for (QuoteDetail__c warranty : warrantyList) {
                    if (warranty.VehicleOptionMaster__r.isRequired__c) continue; // no carefree면 스킵
                    warrantyDetail = new Map<String, String>{
                        '초기점검:4,000~5,000km' => warranty.VehicleOptionMaster__r.ServiceItemsMaster__r.firstCheck__c,
                        '엔진오일점검/교환' => warranty.VehicleOptionMaster__r.ServiceItemsMaster__r.EngineOilCheck__c,
                        '엔진밸브 점검/조정' => warranty.VehicleOptionMaster__r.ServiceItemsMaster__r.EngineValve__c,
                        '연간점검1(연간 최대 1회)' => warranty.VehicleOptionMaster__r.ServiceItemsMaster__r.YearCheck__c,
                        '동계점검(연간 최대 1회)' => warranty.VehicleOptionMaster__r.ServiceItemsMaster__r.WinterCheck__c,
                        'HYVA 오일점검(덤프)' => warranty.VehicleOptionMaster__r.ServiceItemsMaster__r.HYVACheck__c,
                        '리어액슬 오일 점검/교환' => warranty.VehicleOptionMaster__r.ServiceItemsMaster__r.RearAxleCheck__c,
                        '기어오일 점검/교환' => warranty.VehicleOptionMaster__r.ServiceItemsMaster__r.GearCheck__c,
                        '냉각수 점검/교환' => warranty.VehicleOptionMaster__r.ServiceItemsMaster__r.CoolingWaterCheck__c,
                        'EHLA 액슬 오일 점검/교환(리프팅/조향축)' => warranty.VehicleOptionMaster__r.ServiceItemsMaster__r.EHLACheck__c
                    };
                    System.debug('test warrantyDetail :: ' + warrantyDetail);
                    // warrantyDetailList?.add(warrantyDetail2);
                    // System.debug('test warrantyDetailList :: ' + warrantyDetailList); <- Attempt to de-reference a null object 왜?
                }
            }    

            // price break down에 들어갈 금액 계산해서 보냄
            QuoteCreatorController.oppId = quote.OpportunityId;
            QuoteCreatorController.quoteId = quote.Id;
            quoteDetail = QuoteCreatorController.getQuoteDetail();
            baseDiscount = QuoteCreatorController.getBaseDiscount();
            additionalLossPrice = quote.AdditionalDiscountRateStatus__c == '승인됨' ? quote.AdditionalLossPrice__c : 0;
            interestDefermentVAT = ((QuoteCreatorController.FinancialWrap)quoteDetail.get('financial')).interestDefermentVAT != null ? 
            ((QuoteCreatorController.FinancialWrap)quoteDetail.get('financial')).interestDefermentVAT : 0;
		    // Decimal oilCouponCount = (Decimal)quoteDetail.get('oilCouponCount');
        } catch(Exception e) {
            System.debug('err :: ' + e.getMessage() + ' || ' + e.getLineNumber());
        }
    }
}