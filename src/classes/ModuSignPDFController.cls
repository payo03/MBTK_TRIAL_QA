/**
* @Author            : jh.jung
* @Description 		 :
* @Target            :
* @Modification Log
  Ver      Date            Author                   Modification
  ===================================================================================
  1.0      2024-12-31      jh.jung                  Created
  1.1      2025-02-13      tw.Choi                  Modified
  2.0      2025-04-02      tw.Choi                  Refactoring(Wrapper클래스 사용)
  2.1      2025-04-17      payo03@solomontech.net   모두싸인 후처리 Process 상속Class 구현
*/
public without sharing class ModuSignPDFController {

//    private static final List<String> MODUSIGN_WHITE_LIST = Label.ModuSignWhiteList.split(',');

    // ver2.0 Refactoring(Wrapper클래스 사용)
    public class ContractWrapper {
        // public String contractName { get; set; }
        public String contractNumber { get; set; }
        public Decimal contractDeposit { get; set; }
        public Decimal contractRealSalesPrice { get; set; }

        public String ownerEmail { get; set; }
        public String ownerPhone { get; set; }
        public String ownerFax { get; set; }

        public String accountName { get; set; }
        public String accountPersonMobilePhone { get; set; }
        public String accountPersonEmail { get; set; }
        public String accountRealDriverEmail { get; set; }
        public String accountBusinessNumber { get; set; }
        public String accountIDNumber { get; set; }
        public String accountBusinessCategory { get; set; }
        public String accountRealDriverAddress { get; set; }
        public String accountRealDriver { get; set; }
        public String accountRealDriverIDNumber { get; set; }
        public String accountRealDriverMobile { get; set; }
        public String accountRoadAddress { get; set; }

        public Decimal opportunityTaxDeferredAmount { get; set; }
        public Decimal opportunityPaymentDeferredAmount { get; set; }
        public String opportunityOwnerName { get; set; }

        public String quoteName { get; set; }
        public Decimal quoteInterestDefermentVAT { get; set; }
        public Decimal quoteNotarizedFee { get; set; }
        public Decimal quoteTotalLoanAmount { get; set; }
        public Decimal quoteOilCouponPrice { get; set; }
        public Decimal quoteDefaultInterestRate { get; set; }
        public Decimal quoteRegistrationTax { get; set; }
        public Decimal quoteConsignmentPrice { get; set; }
        public Decimal quoteCapitalDefermentAmount { get; set; }
        public Decimal quoteDeliveryDiscountPrice { get; set; }
        public Decimal quoteTotalRealAndSpecialPrice { get; set; }
        public Decimal quoteVehicleDiscountPrice { get; set; }
        public Decimal quoteAdvancePayment { get; set; }
        public Decimal quoteMonthlyPayment { get; set; }
        public Decimal quoteTotalDiscountAmt { get; set; }
        public Decimal quoteMonthDivideInputMonth { get; set; }
        public Decimal quoteTotalVehiclePrice { get; set; }
        public String quoteFinanceName { get; set; }
        public String quoteProductName { get; set; }
        public String quoteProductColour { get; set; }

        public String idNumber { get; set; }
        public String virtualAccount { get; set; }
        public Decimal totalDownVATDefer { get; set; }
        public Decimal loanAmount { get; set; }
        public Decimal totalCapitalAmount { get; set; }
        public String formatStartDate { get; set; }
        public Decimal baseDiscount { get; set; }
        public Decimal realSaleDiscount {get; set;}
        public Decimal oilCouponCount { get; set; }

        public Product product { get; set; }

        public List<Deferment> defermentList { get; set; }
        public List<Option> optionList { get; set; }
        public List<Promotion> promotionList { get; set; }
        public List<Special> specialList { get; set; }
    }

    public class Deferment {
        public Decimal requestDays { get; set; }
    }

    public class Product {
        public Decimal productPrice { get; set; }
        public String productName { get; set; }
    }

    public class Option {
        public String optionName { get; set; }
        public Decimal optionPrice { get; set; }
    }

    public class Promotion {
        public String promotionName { get; set; }
        public Decimal promotionDiscountPrice { get; set; }
        public Decimal promotionDiscountRate { get; set; }
    }

    public class Special {
        public String specialSubOption { get; set; }
        public Decimal specialPrice { get; set; }
    }

    public static String lang { get; set; }

    public static ContractWrapper pdfWrapper { get; set; }
    private static Integer MDS_PAGE = 2;
    private static Integer RIO_PAGE = 1;
    private static Integer CONTRACT_LAST_PAGE = 0;

    public static String selectedOption {get; set;}
    public static Boolean isDefermentReq {get; set;}
    public static Contract contract {get; set;}
    public static String formatStartDate {get; set;}
    public static String formatTaxDate {get; set;}
    public static String iDNumber {get; set;}
    public static Quote quote {get; set;}
    public static VirtualAccount__c virtualAcc {get; set;}
    public static List<DefermentRequest__c> defermentReqList {get; set;}
    public static Opportunity opp {get; set;}
    public static Map<String, Object> quoteDetail {get; set;}
    public static Decimal baseDiscount {get; set;}
    public static Decimal totalDownVATDefer {get; set;}
    // public static Decimal loanAmount {get; set;}
    

    public static void getVFInfo() {

        System.debug('getVFInfo INIT ::: ');
        try {
            String recordId = ApexPages.currentPage().getParameters().get('recordId');
            selectedOption = ApexPages.currentPage().getParameters().get('selectedOption');
            lang = ApexPages.currentPage().getParameters().get('language');
            // System.debug('lang :::  ' + lang);
            if (String.isEmpty(lang)) {
                lang = 'ko'; // lang 파라미터가 없으면 기본값 'ko' 설정
            }

            contract = [
                SELECT Id, Name, Owner.Email, Owner.Phone, Owner.Fax, ContractNumber, Deposit__c, fm_RealSalesPrice__c,
                        Account.Name,
                        Account.PersonMobilePhone,
                        Account.PersonEmail,
                        Account.RealDriverEmail__pc,
                        Account.BusinessNumber__c,
                        Account.IDNumber__pc,
                        Account.BusinessCategory__c,
                        Account.RealDriverAddress__pc,
                        Account.RealDriver__pc,
                        Account.RealDriverIDNumber__pc,
                        Account.RealDriverMobile__pc,
                        Account.RoadAddress__c,
                        Opportunity__c,
                        Opportunity__r.PaymentDeferredAmount__c,
                        Opportunity__r.TaxInvoiceDate__c,
                        Opportunity__r.TaxDeferredAmount__c,
                        Opportunity__r.VATDefermentStatus__c,
                        Opportunity__r.Owner.Name,
                        Quote__c,
                        Quote__r.InterestDefermentVAT__c,
                        Quote__r.AccountId,
                        Quote__r.OpportunityId,
                        Quote__r.Product__c,
                        Quote__r.ContractId,
                        Quote__r.Finance__r.Name,
                        Quote__r.DefaultInterestRate__c,
                        Quote__r.ConsignmentPrice__c,
                        Quote__r.CapitalDefermentAmount__c,
                        Quote__r.AdvancePayment__c,
                        Quote__r.MonthlyPayment__c,
                        Quote__r.MonthDivideInputMonth__c,
                        Quote__r.fm_RegistrationTax__c,
                        Quote__r.fm_DeliveryDiscountPrice__c,
                        Quote__r.fm_TotalRealAndSpecialPrice__c,
                        Quote__r.fm_VehicleDiscountPrice__c,
                        Quote__r.fm_TotalDiscountAmt__c,
                        Quote__r.fm_NotarizedFee__c,
                        Quote__r.fm_TotalLoanAmount__c,
                        Quote__r.ru_OilCouponPrice__c,
                        Quote__r.TotalVehiclePrice__c,
                        Quote__r.Product__r.Name,
                        Quote__r.Product__r.Colour__c
                FROM Contract
                WHERE Id = :recordId
            ];
            System.debug(contract);
            // iDNumber = contract.Account.IDNumber__pc;


            // iDNumber = contract.Account.IDNumber__pc != null ? contract.Account.IDNumber__pc : '';

            // System.debug('iDNumber :::: ' + iDNumber);
            quote = contract.Quote__r;
            opp = contract.Opportunity__r;

            List<VirtualAccount__c> virtualAccountList = [
                SELECT Id, fm_VirtualAccount__c, Account__c, Account__r.name
                FROM VirtualAccount__c
                WHERE Opportunity__r.ContractId =:contract.Id
                LIMIT 1
            ];
            if (!virtualAccountList.isEmpty()) {
                virtualAcc = virtualAccountList[0];
            } else {
                virtualAcc = new VirtualAccount__c();
            }

            defermentReqList = [
                SELECT Id, RequestDays__c
                FROM DefermentRequest__c
                WHERE Opportunity__c = : contract.Opportunity__c
                AND Status__c = 'COMPLETED'
                AND Type__c = 'VATDeferred'
                AND Opportunity__r.ContractId = :recordId
            ];

            // isDefermentReq = defermentReqList.isEmpty();

            // if (isDefermentReq) {
            //     defermentReqList = new List<DefermentRequest__c>();
            // }

            // if (defermentReqList.isEmpty()) {
            //     defermentReqList = new List<DefermentRequest__c>();
            // } else {
            //     for (DefermentRequest__c req : defermentReqList) {
            //         if (req.RequestDays__c != null) {
            //             req.RequestDays__c = (req.RequestDays__c / 30).setScale(1, RoundingMode.HALF_UP);
            //         } else {
            //             req.RequestDays__c = 0;
            //         }
            //     }
            // }

            // Decimal advancePayment = contract.Quote__r != null ? contract.Quote__r.AdvancePayment__c : 0;
            // Decimal taxDeferred = contract.Opportunity__r != null ? contract.Opportunity__r.TaxDeferredAmount__c : 0; // 부가세 유예 금액
            // Decimal paymentDeferred = contract.Opportunity__r != null ? contract.Opportunity__r.PaymentDeferredAmount__c : 0; // 인도금 유예 금액
            // Decimal quoteloan = contract.Quote__r != null ? contract.Quote__r.fm_TotalLoanAmount__c : 0;
            // Decimal capitalDefer = contract.Quote__r != null ? contract.Quote__r.CapitalDefermentAmount__c : 0;
            // Decimal deliveryDiscountPrice = contract.Quote__r != null ? contract.Quote__r.fm_DeliveryDiscountPrice__c : 0; // 선수금

            Datetime taxInvoiceDate = null;
            if (contract.Opportunity__r.TaxInvoiceDate__c != null) {
                taxInvoiceDate = Date.valueOf(contract.Opportunity__r.TaxInvoiceDate__c);
            }
            String formatTaxDate = (taxInvoiceDate != null) ? taxInvoiceDate.format('yyyy-MM-dd') : null;


            System.debug('selectedOption ::: ' + selectedOption);

            QuoteCreatorController.oppId = quote.OpportunityId;
            QuoteCreatorController.quoteId = quote.Id;
            quoteDetail = QuoteCreatorController.getQuoteDetail();

            System.debug('quoteDetail test :::: ' +  quoteDetail);
            baseDiscount = QuoteCreatorController.getBaseDiscount();

            // ver2.0 Refactoring(Wrapper클래스 사용)
            ContractWrapper wrapper = new ContractWrapper();

            wrapper.contractNumber = contract.ContractNumber != null ? contract.ContractNumber : '';
            wrapper.contractDeposit = contract.Deposit__c  != null ? contract.Deposit__c : 0;
            wrapper.contractRealSalesPrice = contract.fm_RealSalesPrice__c != null ? contract.fm_RealSalesPrice__c : 0;

            wrapper.ownerEmail = contract.Owner.Email != null ? contract.Owner.Email : '';
            wrapper.ownerPhone = contract.Owner.Phone != null ? contract.Owner.Phone : '';
            wrapper.ownerFax = contract.Owner.Fax != null ? contract.Owner.Fax : '';

            wrapper.accountName = contract.Account.Name != null ? contract.Account.Name : '';
            wrapper.accountPersonMobilePhone = contract.Account.PersonMobilePhone != null ? contract.Account.PersonMobilePhone : '';
            wrapper.accountPersonEmail = contract.Account.PersonEmail != null ? contract.Account.PersonEmail : '';
            wrapper.accountRealDriverEmail = contract.Account.RealDriverEmail__pc != null ? contract.Account.RealDriverEmail__pc : '';
            wrapper.accountBusinessNumber = contract.Account.BusinessNumber__c != null ? contract.Account.BusinessNumber__c : '';
            wrapper.accountIDNumber = contract.Account.IDNumber__pc != null ? contract.Account.IDNumber__pc : '';
            wrapper.accountBusinessCategory = contract.Account.BusinessCategory__c != null ? contract.Account.BusinessCategory__c : '';
            wrapper.accountRealDriverAddress = contract.Account.RealDriverAddress__pc != null ? contract.Account.RealDriverAddress__pc : '';
            wrapper.accountRealDriver = contract.Account.RealDriver__pc != null ? contract.Account.RealDriver__pc : '';
            wrapper.accountRealDriverIDNumber = contract.Account.RealDriverIDNumber__pc != null ? contract.Account.RealDriverIDNumber__pc : '';
            wrapper.accountRealDriverMobile = contract.Account.RealDriverMobile__pc != null ? contract.Account.RealDriverMobile__pc : '';
            wrapper.accountRoadAddress = contract.Account.RoadAddress__c != null ? contract.Account.RoadAddress__c : '';

            wrapper.opportunityTaxDeferredAmount = contract.Opportunity__r.TaxDeferredAmount__c != null ? contract.Opportunity__r.TaxDeferredAmount__c : 0;
            wrapper.opportunityPaymentDeferredAmount = contract.Opportunity__r.PaymentDeferredAmount__c != null ? contract.Opportunity__r.PaymentDeferredAmount__c : 0;
            wrapper.opportunityOwnerName = contract.Opportunity__r.Owner.Name != null ? contract.Opportunity__r.Owner.Name : '';

            wrapper.quoteInterestDefermentVAT = contract.Quote__r.InterestDefermentVAT__c != null ? contract.Quote__r.InterestDefermentVAT__c : 0;
            wrapper.quoteNotarizedFee = contract.Quote__r.fm_NotarizedFee__c != null ? contract.Quote__r.fm_NotarizedFee__c : 0;
            wrapper.quoteTotalLoanAmount = contract.Quote__r.fm_TotalLoanAmount__c != null ? contract.Quote__r.fm_TotalLoanAmount__c : 0;
            wrapper.quoteOilCouponPrice = contract.Quote__r.ru_OilCouponPrice__c != null ? contract.Quote__r.ru_OilCouponPrice__c : 0;
            wrapper.quoteDefaultInterestRate = contract.Quote__r.DefaultInterestRate__c != null ? contract.Quote__r.DefaultInterestRate__c : 0;
            wrapper.quoteRegistrationTax = contract.Quote__r.fm_RegistrationTax__c != null ? contract.Quote__r.fm_RegistrationTax__c : 0;
            wrapper.quoteConsignmentPrice = contract.Quote__r.ConsignmentPrice__c != null ? contract.Quote__r.ConsignmentPrice__c : 0;
            wrapper.quoteCapitalDefermentAmount = contract.Quote__r.CapitalDefermentAmount__c != null ? contract.Quote__r.CapitalDefermentAmount__c : 0;
            wrapper.quoteDeliveryDiscountPrice = contract.Quote__r.fm_DeliveryDiscountPrice__c != null ? contract.Quote__r.fm_DeliveryDiscountPrice__c : 0;
            wrapper.quoteTotalRealAndSpecialPrice = contract.Quote__r.fm_TotalRealAndSpecialPrice__c != null ? contract.Quote__r.fm_TotalRealAndSpecialPrice__c : 0;
            wrapper.quoteVehicleDiscountPrice = contract.Quote__r.fm_VehicleDiscountPrice__c != null ? contract.Quote__r.fm_VehicleDiscountPrice__c : 0;
            wrapper.quoteAdvancePayment = contract.Quote__r.AdvancePayment__c != null ? contract.Quote__r.AdvancePayment__c : 0;
            wrapper.quoteMonthlyPayment = contract.Quote__r.MonthlyPayment__c != null ? contract.Quote__r.MonthlyPayment__c : 0;
            wrapper.quoteTotalDiscountAmt = contract.Quote__r.fm_TotalDiscountAmt__c != null ? contract.Quote__r.fm_TotalDiscountAmt__c : 0;
            wrapper.quoteMonthDivideInputMonth = contract.Quote__r.MonthDivideInputMonth__c != null ? contract.Quote__r.MonthDivideInputMonth__c : 0;
            wrapper.quoteTotalVehiclePrice = contract.Quote__r.TotalVehiclePrice__c != null ? contract.Quote__r.TotalVehiclePrice__c : 0;
            wrapper.quoteFinanceName = contract.Quote__r.Finance__r.Name != null ? contract.Quote__r.Finance__r.Name : '';
            wrapper.quoteProductName = contract.Quote__r.Product__r.Name != null ? contract.Quote__r.Product__r.Name : '';
            wrapper.quoteProductColour = contract.Quote__r.Product__r.Colour__c != null ? contract.Quote__r.Product__r.Colour__c : '';

            wrapper.idNumber = contract.Account.IDNumber__pc != null ? contract.Account.IDNumber__pc : '';
            wrapper.virtualAccount = !virtualAccountList.isEmpty() ? virtualAccountList.get(0).fm_VirtualAccount__c : '';
            wrapper.totalDownVATDefer = wrapper.contractDeposit + wrapper.quoteDeliveryDiscountPrice + wrapper.opportunityTaxDeferredAmount + wrapper.opportunityPaymentDeferredAmount;
            wrapper.loanAmount = wrapper.quoteTotalLoanAmount - wrapper.quoteCapitalDefermentAmount;
            // 총 대출금
            wrapper.totalCapitalAmount = wrapper.loanAmount + wrapper.quoteCapitalDefermentAmount;
            wrapper.formatStartDate = String.valueOf(Date.today());
            wrapper.baseDiscount = baseDiscount != null ? baseDiscount : 0;
            wrapper.realSaleDiscount = wrapper.contractRealSalesPrice - wrapper.quoteDeliveryDiscountPrice;

            List<Deferment> defermentList = new List<Deferment>();
            for(DefermentRequest__c defermentReq : defermentReqList) {
                Deferment deferment = new Deferment();
                deferment.requestDays = defermentReq.RequestDays__c != null ? (defermentReq.RequestDays__c / 30).setScale(1, RoundingMode.HALF_UP) : 0;

                defermentList.add(deferment);
            }
            wrapper.defermentList = defermentList;


            wrapper.quoteName = quoteDetail.containsKey('name') ? String.valueOf(quoteDetail.get('name')) : '';
            wrapper.oilCouponCount = quoteDetail.containsKey('oilCouponCount') ? Decimal.valueOf(String.valueOf(quoteDetail.get('oilCouponCount'))) : 0;

            QuoteCreatorController.ProductWrap productWrap = (QuoteCreatorController.ProductWrap) quoteDetail.get('product');
            Product product = new ModuSignPDFController.Product();
            product.productPrice = productWrap.price != null ? productWrap.price : 0;
            product.productName = productWrap.name != null ? productWrap.name : '';
            wrapper.product = product;

            List<QuoteCreatorController.OptionWrap> optionWrapList = (List<QuoteCreatorController.OptionWrap>) quoteDetail.get('option');
            List<Option> optionList = new List<Option>();
            for(QuoteCreatorController.OptionWrap optionWrap : optionWrapList) {
                Option option = new Option();

                option.optionName = optionWrap.name != null ? optionWrap.name : '';
                option.optionPrice = optionWrap.price != null ? optionWrap.price : 0;
                optionList.add(option);
            }
            wrapper.optionList = optionList;

            List<QuoteCreatorController.PromotionWrap> promotionWrapList = (List<QuoteCreatorController.PromotionWrap>) quoteDetail.get('promotion');
            List<Promotion> promotionList = new List<Promotion>();
            for(QuoteCreatorController.PromotionWrap promotionWrap : promotionWrapList) {
                Promotion promotion = new Promotion();

                promotion.promotionName = promotionWrap.name != null ? promotionWrap.name : '';
                promotion.promotionDiscountPrice = promotionWrap.discountPrice != null ? promotionWrap.discountPrice : 0;
                promotion.promotionDiscountRate = promotionWrap.discountRate != null ? promotionWrap.discountRate : 0;
                promotionList.add(promotion);
            }
            wrapper.promotionList = promotionList;

            List<QuoteCreatorController.SpecialWrap> specialWrapList = (List<QuoteCreatorController.SpecialWrap>) quoteDetail.get('special');
            List<Special> specialList = new List<Special>();
            for(QuoteCreatorController.SpecialWrap specialWrap : specialWrapList) {
                Special special = new Special();

                special.specialSubOption = specialWrap.subOption != null ? specialWrap.subOption : '';
                special.specialPrice = specialWrap.price != null ? specialWrap.price : 0;
                specialList.add(special);
            }
            wrapper.specialList = specialList;

            pdfWrapper = wrapper;
            System.debug(pdfWrapper);
            System.debug('pdfWrapper.product ::: ' + pdfWrapper.product);
            System.debug('pdfWrapper.optionList ::: ' + pdfWrapper.optionList);
            System.debug('pdfWrapper.promotionList ::: ' + pdfWrapper.promotionList);
            System.debug('pdfWrapper.specialList ::: ' + pdfWrapper.specialList);

        } catch(Exception e) {
            System.debug('err :: ' + e.getMessage() + ' || ' + e.getLineNumber());
        }
    }

//    @AuraEnabled
//    public static Account getAccountInfo(String recordId) {
//        return [
//                SELECT Id, Name, Phone, RoadAddress__c, DetailAddress__c, PostalCode__c, PersonMobilePhone, RecordType.DeveloperName,
//                (SELECT Id, Name, RoadAddress__c, DetailAddress__c, PostalCode__c, MobilePhone, RealDriverMobile__c, RealDriver__c, RealDriverAddress__c FROM Contacts)
//                FROM Account
//                WHERE Id IN (SELECT AccountId FROM Contract WHERE Id = :recordId)
//        ];
//    }
    @AuraEnabled
    public static Map<String, Object> getAccountInfo(String recordId) {
        Map<String, Object> returnMap = new Map<String, Object>();
        Account account = [
                SELECT Id, Name, Phone, RoadAddress__c, DetailAddress__c, PostalCode__c, PersonMobilePhone, RecordType.DeveloperName,
                (SELECT Id, Name, RoadAddress__c, DetailAddress__c, PostalCode__c, MobilePhone, RealDriverMobile__c, RealDriver__c, RealDriverAddress__c FROM Contacts)
                FROM Account
                WHERE Id IN (SELECT AccountId FROM Contract WHERE Id = :recordId)
                LIMIT 1
        ];
        User internalUser = [
                SELECT Id, Name, FirstName, EmployeeNumber, CompanyName, MobilePhone
                FROM User
                WHERE Id IN (SELECT Approver1__c FROM ApprovalHierarchy__c WHERE Stage__c = 'Contract Modusign Final')
                LIMIT 1
        ];
        Contract contractInfo = [
                SELECT Id, Opportunity__r.NoMDSStatus__c
                FROM Contract
                WHERE Id = :recordId
                LIMIT 1
        ];

        returnMap.put('account', account);
        returnMap.put('internalUser', internalUser);
        returnMap.put('opptyInfo', contractInfo.Opportunity__r);
        return returnMap;
    }

    @AuraEnabled
    public static Map<String, Object> getAccInfoByOppty(String recordId) {
        Opportunity opptyInfo = [
                SELECT Account.Name, Account.RecordType.Name, Account.Phone, Account.PersonMobilePhone
                FROM Opportunity
                WHERE Id = :recordId
                LIMIT 1
        ];
        Quote publishQuote = [
                SELECT Id
                FROM Quote
                WHERE OpportunityId = :recordId
                AND Status = 'Published'
                LIMIT 1
        ];
        Map<String, Object> returnMap = new Map<String, Object>{
                'account' => opptyInfo.Account
                , 'publishQuoteId' => publishQuote.Id
        };
        return returnMap;
    }

//    // 계약서 VF로 생성할 경우
//    @AuraEnabled
//    public static Map<String, Object> generatePdfBlob(String recordId, String selectedOption, Map<String, String> signInfo, String language ) {
//        System.debug('generatePdfBlob ::: ' + recordId);
//        // System.debug('날짜 ::: ' + System.today().addDays(+3));
//
//        Map<String, String> fileNameMap = new Map<String, String> {
//            'all' => '계약서 + RIO & MDS'
//            , 'contract' => '계약서'
//            , 'riomds' => 'RIO & MDS'
//        };
//
//        Map<String, Object> resultMap = new Map<String, Object>();
//        try {
//            // Visualforce 페이지 생성 및 데이터 전달
//            PageReference pdfPage = Page.ModusignPDFTemplate; // Visualforce 페이지 이름
//
//            pdfPage.getParameters().put('recordId', recordId);
//            pdfPage.getParameters().put('selectedOption', selectedOption);
//            pdfPage.getParameters().put('language', language);
//
//
//            // PDF 생성
//            Blob pdfBlob = pdfPage.getContentAsPDF();
//
//            String file = EncodingUtil.base64Encode(pdfBlob);
//            System.debug('이미지 인코딩 길이 ::: ' + file.length());
//            System.debug('PDF 생성 완료 - 언어: ' + language);
//
//            // Heroku 타고 PDF 페이지 수 알아오기
//            Integer lastPageNum = CommonUtilCustomController.getPDFPageNumber(file);
//
//            System.debug('total page :::' + lastPageNum);
//
//            IF_DTO.SigningRequestByPDF signingRequest = createRequest(file, selectedOption, recordId, signInfo, lastPageNum);
//
//            // PDF View
//             resultMap = new Map<String, Object> {'pdfBase64' => file, 'code' => false};
//            // 모두사인 요청
////            resultMap = InterfaceModuSign.doCallOutSignRequestByPDF(signingRequest, recordId);
//        } catch (CustomException e) {
//            System.debug('error ::: ' + e.getMessage());
//            System.debug('error ::: ' + e.getStackTraceString());
//
//            resultMap = new Map<String, Object> {
//                'code' => false
//                , 'errorMessage' => '해당 번호는 화이트리스트에 포함되지 않습니다.'
//            };
//        }  catch (Exception e) {
//            System.debug('error ::: ' + e.getMessage());
//            System.debug('error ::: ' + e.getStackTraceString());
//
//            resultMap = new Map<String, Object> {
//                'code' => false
//                , 'errorMessage' => '관리자에게 문의'
//            };
//        } finally {
//            // 보내기 성공 && 계약서가 포함된 경우
////            System.debug('resultMap ::: ' + JSON.serialize(resultMap));
//            System.debug('code ::: ' + resultMap.get('code'));
//            if(resultMap != null && Boolean.valueOf(resultMap.get('code')) && (selectedOption.equals('all') || selectedOption.equals('contract'))) {
//                Contract contract = new Contract(Id = recordId);
//                contract.ConStatus__c = '모두싸인 발송';
//                update contract;
//            }
//        }
//        return resultMap;
//    }

    // 03/28 비동기 호출 추가
    @AuraEnabled
    public static void asyncGeneratePdfBlob(String recordId, String selectedOption, Map<String, String> signInfo, String language ) {
        try {
            asyncModuSignAndKakao(recordId, selectedOption, signInfo, language);
        } catch(Exception e) {
            System.debug(e.getMessage() + ' / ' + e.getLineNumber());
        }
    }

    @Future(Callout=true)
    private static void asyncModuSignAndKakao(String recordId, String selectedOption, Map<String, String> signInfo, String language ) {
        System.debug('asyncGeneratePdfBlob ::: ' + recordId);

        Map<String, String> fileNameMap = new Map<String, String> {
                'all' => '계약서 + RIO & MDS'
                , 'contract' => '계약서'
                , 'riomds' => 'RIO & MDS'
        };

        Map<String, String> kakaoNameMap = new Map<String, String> {
                'all' => '계약서 및 MDS/RIO 동의서 서명 요청',
                'contract' => '계약서 서명 요청',
                'riomds' => 'MDS/RIO 동의서 서명 요청'
        };

        try {
            // Visualforce 페이지 생성 및 데이터 전달
            PageReference pdfPage = Page.ModusignPDFTemplate; // Visualforce 페이지 이름

            pdfPage.getParameters().put('recordId', recordId);
            pdfPage.getParameters().put('selectedOption', selectedOption);
            pdfPage.getParameters().put('language', language);

            Blob pdfBlob;
            // PDF 생성
            if(!Test.isRunningTest())       pdfBlob = pdfPage.getContentAsPDF();
            else                            pdfBlob = Blob.valueOf('test Blob');

            String file = EncodingUtil.base64Encode(pdfBlob);
            System.debug('이미지 인코딩 길이 ::: ' + file.length());
            System.debug('PDF 생성 완료 - 언어: ' + language);

            // Heroku 타고 PDF 페이지 수 알아오기
            Integer lastPageNum = CommonUtilCustomController.getPDFPageNumber(file);

            System.debug('total page :::' + lastPageNum);

            IF_DTO.SigningRequestByPDF signingRequest = createRequest(file, selectedOption, recordId, signInfo, lastPageNum);

            // 모두사인 요청
//            Map<String, Object> responseMap = InterfaceModuSign.doCallOutSignRequestByPDF(signingRequest, recordId);
            // ver2.1 모두싸인 후처리 Process 상속Class 구현
            String apexClass = 'StageUpdateCommonController';
            Map<String, Object> responseMap = InterfaceModuSign.doCallOutSignRequestByPDF(signingRequest, recordId, apexClass);

            System.debug('code ::: ' + responseMap.get('code'));

            // 계약서가 포함된 경우에만 계약 상태 업데이트
            if(responseMap != null &&
                Boolean.valueOf(responseMap.get('code')) &&
                ('all'.equals(selectedOption) || 'contract'.equals(selectedOption))) {

                Contract contract = new Contract(Id = recordId);
                contract.ConStatus__c = '모두싸인 발송';
                update contract;
            }

            // 성공시 카카오톡
            if (HttpCallOutConsts.SUCCESS_CODES.contains(Integer.valueOf(responseMap.get('statusCode')))) {
                //this.recordId, this.selectedRowInfo["Id"], this.selectedOption
                Map<Object, Object> infoMap = new Map<Object, Object>{
                        'recordId' => signInfo.get('Id')
                        , 'customerType' => '실차주'.equals(signInfo.get('Info')) ? 'realdriver' : 'owner'
                };

                Map<String, Object> paramMap = new Map<String, Object>{
                        'templateTitle' => kakaoNameMap.get(selectedOption),
                        'recordId' => recordId,
                        'infoMapList' => new List<Object>{
                            infoMap
                        },
                        'externalId' => recordId
                };

                System.enqueueJob(new AsyncKakaoByCreatePDF(paramMap));

//                Map<String, Object> resultMap = InterfaceKakao.doCallOutKakaoAlimTalk(paramMap);
//                System.debug('ModuSignPDFKakao ::: ' + JSON.serialize(resultMap));
//                // 실패시 로그 남기기
//                if (!HttpCallOutConsts.SUCCESS_CODES.contains(Integer.valueOf(resultMap.get('statusCode')))) {
//                    System.debug('카카오톡 에러... 따로 로그는 안남김');
//                }
            }
        } catch (CustomException e) {

            Map<String, String> errorMap = new Map<String, String> {
                'id' => CommonUtilCustomController.parseIFIdSAP('')
                , 'title' => fileNameMap.get(selectedOption)
                , 'status' => 'FAIL'
            };
            APIDocument__c failDocument = InterfaceModuSign.createDocument(JSON.serialize(errorMap));
            failDocument.Description__c = '해당 번호는 화이트리스트에 포함되지 않습니다.';
            failDocument.Destination__c = signInfo.get('MobilePhone');
            failDocument.ExternalId__c = recordId;
            failDocument.Contract__c = recordId;
            insert failDocument;

            System.debug('error ::: ' + e.getMessage());
            System.debug('error ::: ' + e.getStackTraceString());
        } catch (Exception e) {
            System.debug('error ::: ' + e.getMessage());
            System.debug('error ::: ' + e.getStackTraceString());
        }
    }

    @TestVisible
    private static IF_DTO.SigningRequestByPDF createRequest(String base64ByPdfBlob, String selectedOption, String recordId, Map<String, String> signInfo, Integer lastPageNum) {

        Boolean isRioMds;
        Boolean isContract;
        String fileName;

        // {Id=003H2000017iwXIIAY, Info=고객, MobilePhone=010-9886-8298, Name=이상엽, RoadAddress=서울 노원구 화랑로 335-11, idx=0}

        if(selectedOption.equals('all')) {
            isRioMds = true;
            isContract = true;
            fileName = '계약서 + RIO & MDS';
            CONTRACT_LAST_PAGE = lastPageNum - 2;
            RIO_PAGE = lastPageNum - 1;
            MDS_PAGE = lastPageNum;
        }
        if(selectedOption.equals('contract')) {
            isRioMds = false;
            isContract = true;
            fileName = '계약서';
            CONTRACT_LAST_PAGE = lastPageNum;
        }
        if(selectedOption.equals('riomds')) {
            isRioMds = true;
            isContract = false;
            fileName = 'RIO & MDS';
            RIO_PAGE = 1;
            MDS_PAGE = 2;
        }

        // ------------------ isRioMds / isContract 값에 따라 Request 결정 --------------------

        // 고정 텍스트에 필요한 레코드 정보
        // TODO: 조회 개별로 하지말고 한번에 가져오기
        // 계약
        Contract contract = [SELECT Id, AccountId, ContractNumber FROM Contract WHERE Id = :recordId];
        // 고객
        Account account = [SELECT Id, Name, Phone, LastName, FirstName, RoadAddress__c, PersonEmail, PersonMobilePhone, BusinessNumber__c, DetailAddress__c, PostalCode__c, OwnerId FROM Account WHERE Id = :contract.AccountId];
//            contact = [SELECT Id, AccountId, LastName, RoadAddress__c, DetailAddress__c, PostalCode__c, Email, MobilePhone, RealDriverMobile__c, RealDriverAddress__c, RealDriver__c FROM Contact WHERE Id = :contactId];
        // 판매자
        User user = [SELECT Name, FirstName, EmployeeNumber, CompanyName, MobilePhone, Agency__c FROM User WHERE Id = :account.OwnerId];
        // 최종 모두사인 받는 Internal 유저
//        User InternalUser = [SELECT Name, FirstName, EmployeeNumber, CompanyName, MobilePhone FROM User WHERE Id = :Label.MTBK_Internal_Modusign];
        User InternalUser = [SELECT Name, FirstName, EmployeeNumber, CompanyName, MobilePhone FROM User WHERE Id IN (SELECT Approver1__c FROM ApprovalHierarchy__c WHERE Stage__c = 'Contract Modusign Final')];
        // 견적
        Quote quote = [SELECT Id, Product__r.Name FROM Quote WHERE ContractId = :recordId];

        // 서명자
        IF_DTO.Participant participantMain = new IF_DTO.Participant();

        // SigningMethod 고객 설정
        IF_DTO.SigningMethod signingMethodMain = new IF_DTO.SigningMethod();
        signingMethodMain.type = 'KAKAO';
        // TODO :: 화이트리스트 반영 필요
        String phoneNumber = signInfo.get('MobilePhone').replace('-', '');
        signingMethodMain.value = phoneNumber;
        // 테스트 중 사고 방지를 위해 01098868298 으로 고정
//        signingMethodMain.value = '01098868298';
//        signingMethodMain.value = '01075782125';

        IF_DTO.Participant participantInternal = new IF_DTO.Participant();
        // SigningMethod Internal 설정
        IF_DTO.SigningMethod signingMethodInternal = new IF_DTO.SigningMethod();
        signingMethodInternal.type = 'KAKAO';

        // TODO :: 화이트리스트 반영 필요
        signingMethodInternal.value = InternalUser.MobilePhone.replace('-', '');

        // 테스트 중 사고 방지를 위해 01098868298 으로 고정
//        signingMethodInternal.value = '01098868298';
//        signingMethodInternal.value = '01075782125';

//        if(!Test.isRunningTest()) {
//            // WhiteList ON_OFF
//            if(!MODUSIGN_WHITE_LIST.contains(signingMethodMain.value)) throw new CustomException('The destination number ' + phoneNumber + ' is not in the white list.');
//            if(!MODUSIGN_WHITE_LIST.contains(signingMethodInternal.value)) throw new CustomException('The destination number ' + user.MobilePhone + ' is not in the white list.');
//        }



        participantMain.locale = 'ko';
        participantMain.signingDuration = InterfaceModuSign.getSmallestValueDefault();
        participantMain.role = signInfo.get('Info');
        participantMain.name = signInfo.get('Name');
        participantMain.signingOrder = 1;
        participantMain.signingMethod = signingMethodMain;
        participantMain.fields = new List<IF_DTO.Field>();

        participantInternal.locale = 'ko';
//        participantInternal.signingDuration = InterfaceModuSign.getSmallestValueDefault();
        participantInternal.signingDuration = 525600;  // 최대값 1년
        participantInternal.role = 'MTBK INTERNAL';
        participantInternal.name = InternalUser.Name;
        participantInternal.signingOrder = 2;
        participantInternal.signingMethod = signingMethodInternal;
        participantInternal.fields = new List<IF_DTO.Field>();

        // Request
        IF_DTO.SigningRequestByPDF signingRequest = new IF_DTO.SigningRequestByPDF();

        // 고정 텍스트 넣는 곳
        signingRequest.requesterInputs = new List<IF_DTO.RequesterInput>();

        // 계약서 파트
        if(isContract) {
            // 고객 계약서 서명
            List<IF_DTO.Position> signaturePosContract = new List<IF_DTO.Position>{
                    new IF_DTO.Position(0.8099, 0.8850, CONTRACT_LAST_PAGE - 3)
            };

            // TODO: 계약서 부분(RIO 이전)에 체크박스, 서명 필요한 경우 여기서 participantMain.fields에 추가하기
            participantMain.fields.addAll(createSignatureFields(signaturePosContract));
        }
        // RIO & MDS 파트
        if(isRioMds) {

            // RIO 체크박스
            List<IF_DTO.Position> checkboxPosRIO = new List<IF_DTO.Position>{
                    new IF_DTO.Position(0.1194, 0.5801, RIO_PAGE),
                    new IF_DTO.Position(0.1194, 0.6420, RIO_PAGE),
                    new IF_DTO.Position(0.1211, 0.7906, RIO_PAGE)
            };
            List<Boolean> checkboxRequiredRIO = new List<Boolean> {
                    true,
                    true,
                    false
            };

            // RIO 서명
            List<IF_DTO.Position> signaturePosRIO = new List<IF_DTO.Position>{
                    new IF_DTO.Position(0.5838, 0.8325, RIO_PAGE)
            };

            // MDS 체크박스
            List<IF_DTO.Position> checkboxPosMDS = new List<IF_DTO.Position>{
                    new IF_DTO.Position(0.3917, 0.2837, MDS_PAGE),
                    new IF_DTO.Position(0.3917, 0.4692, MDS_PAGE),
                    new IF_DTO.Position(0.3883, 0.9449, MDS_PAGE),
                    new IF_DTO.Position(0.8585, 0.2683, MDS_PAGE),
                    new IF_DTO.Position(0.8569, 0.7130, MDS_PAGE),
                    new IF_DTO.Position(0.8552, 0.8783, MDS_PAGE),
                    new IF_DTO.Position(0.8561, 0.9235, MDS_PAGE)
            };
            List<Boolean> checkboxRequiredMDS = new List<Boolean> {
                    false,
                    false,
                    true,
                    true,
                    true,
                    false,
                    false
            };

            // MDS 서명
            List<IF_DTO.Position> signaturePosMDS = new List<IF_DTO.Position>{
                    new IF_DTO.Position(0.8572, 0.9318, MDS_PAGE)
            };

            participantMain.fields.addAll(createCheckboxFields(checkboxPosRIO, checkboxRequiredRIO));
            participantMain.fields.addAll(createSignatureFields(signaturePosRIO));
            participantMain.fields.addAll(createCheckboxFields(checkboxPosMDS, checkboxRequiredMDS));
            participantMain.fields.addAll(createSignatureFields(signaturePosMDS));

            // TODO: participantMain 정보를 Account에 있는걸로 가져왔는데 Contact으로 덮어써야 할 경우 존재?

            // RIO, MDS에 넣어줘야 할 고정 값
            // 긴 텍스트
            // -0.008, +0.014
            List<IF_DTO.Position> RequesterInputPosLarge = new List<IF_DTO.Position>{
                    new IF_DTO.Position(0.1194, 0.1537, RIO_PAGE),  // RIO 회사
                    new IF_DTO.Position(0.1194, 0.1929, RIO_PAGE),  // RIO 이름
                    new IF_DTO.Position(0.1194, 0.2345, RIO_PAGE),  // RIO 도로명
                    new IF_DTO.Position(0.1194, 0.3121, RIO_PAGE),  // RIO 이메일 주소
                    new IF_DTO.Position(0.5333, 0.1560, RIO_PAGE),  // RIO 사업자등록번호
                    new IF_DTO.Position(0.5333, 0.1929, RIO_PAGE),  // RIO 성
                    new IF_DTO.Position(0.5333, 0.2345, RIO_PAGE),  // RIO 건물번호
                    new IF_DTO.Position(0.5333, 0.2705, RIO_PAGE),  // RIO 국가명
                    new IF_DTO.Position(0.5333, 0.3121, RIO_PAGE),  // RIO 전화번호

                    new IF_DTO.Position(0.3637, 0.0912, MDS_PAGE)   // MDS 차종
            };
            List<String> RequesterInputValuesLarge = new List<String>{
                    account.Name                == null ? '' : account.Name,                        // RIO 회사
                    signInfo.get('Name') == null ? '' : signInfo.get('Name'),                       // RIO 이름
                    signInfo.get('RoadAddress') == null ? '' : signInfo.get('RoadAddress'),         // RIO 도로명
                    '',                                                                             // RIO 이메일 주소
                    account.BusinessNumber__c   == null ? '' : account.BusinessNumber__c,           // RIO 사업자등록번호
                    '',                                                                             // RIO 성
                    '',                                                                             // RIO 건물번호
                    '대한민국',                                                                      // RIO 국가명
                    signInfo.get('MobilePhone') == null ? '' : signInfo.get('MobilePhone'),         // RIO 전화번호
                    quote.Product__r.Name       == null ? '' : quote.Product__r.Name                // MDS 차종
            };

            // 짧은 텍스트
            List<IF_DTO.Position> RequesterInputPosSmall = new List<IF_DTO.Position>{
                    new IF_DTO.Position(0.1228, 0.2705, RIO_PAGE),  // RIO 우편번호
                    new IF_DTO.Position(0.3245, 0.2705, RIO_PAGE),  // RIO 도시명
                    new IF_DTO.Position(0.1279, 0.3823, RIO_PAGE),  // RIO 판매담당자 이름
                    new IF_DTO.Position(0.3968, 0.3823, RIO_PAGE),  // RIO 판매담당자 성
                    new IF_DTO.Position(0.6590, 0.3823, RIO_PAGE),  // RIO 판매담당자 사원번호
                    new IF_DTO.Position(0.1245, 0.8452, RIO_PAGE),  // RIO 장소
                    new IF_DTO.Position(0.3211, 0.8452, RIO_PAGE),  // RIO 일자

                    new IF_DTO.Position(0.0590, 0.0905, MDS_PAGE),  // MDS 계약번호
                    new IF_DTO.Position(0.2085, 0.0905, MDS_PAGE)   // MDS 구입장소
            };
            List<String> RequesterInputValuesSmall = new List<String>{
                    signInfo.get('PostalCode')   == null ? '' : signInfo.get('PostalCode'),         // RIO 우편번호
//                    contact.RoadAddress__c  == null ? '' : contact.RoadAddress__c.split(' ')[0],    // RIO 도시명
                    signInfo.get('RoadAddress') == null ? '' : signInfo.get('RoadAddress').split(' ')[0],       // RIO 도시명
                    user.Name               == null ? '' : user.Name,                               // RIO 판매담당자 이름
                    '',                                                                             // RIO 판매담당자 성
                    '',                                                                             // RIO 판매담당자 사원번호
                    user.Agency__c          == null ? '' : user.Agency__c,                          // RIO 장소
                    Date.today().format(),                                                          // RIO 일자
                    contract.ContractNumber == null ? '' : contract.ContractNumber,                 // MDS 계약번호
                    user.Agency__c          == null ? '' : user.Agency__c                           // MDS 구입장소
            };

            // MDS 날짜 작은 글씨
            List<IF_DTO.RequesterInput> requesterInputsTodayInfo = new List<IF_DTO.RequesterInput>();
            IF_DTO.Size textSize = new IF_DTO.Size();
            textSize.width = 0.100;
            textSize.height = 0.020;

            IF_DTO.TextStyle textStyle = new IF_DTO.TextStyle();
            textStyle.size = 8;
            textStyle.font = IF_DTO.FontType.NOTO_SANS;

            IF_DTO.RequesterInput requesterInputYear = new IF_DTO.RequesterInput();
            requesterInputYear.type = IF_DTO.FieldType.TEXT;
            requesterInputYear.size = textSize;
            requesterInputYear.position = new IF_DTO.Position(0.5260, 0.9467, MDS_PAGE);
            requesterInputYear.value = Date.today().year().toString();
            requesterInputYear.textStyle = textStyle;

            IF_DTO.RequesterInput requesterInputMonth = new IF_DTO.RequesterInput();
            requesterInputMonth.type = IF_DTO.FieldType.TEXT;
            requesterInputMonth.size = textSize;
            requesterInputMonth.position = new IF_DTO.Position(0.5915, 0.9467, MDS_PAGE);
            requesterInputMonth.value = Date.today().month().toString();
            requesterInputMonth.textStyle = textStyle;

            IF_DTO.RequesterInput requesterInputDay = new IF_DTO.RequesterInput();
            requesterInputDay.type = IF_DTO.FieldType.TEXT;
            requesterInputDay.size = textSize;
            requesterInputDay.position = new IF_DTO.Position(0.6403, 0.9467, MDS_PAGE);
            requesterInputDay.value = Date.today().day().toString();
            requesterInputDay.textStyle = textStyle;

            requesterInputsTodayInfo.add(requesterInputYear);
            requesterInputsTodayInfo.add(requesterInputMonth);
            requesterInputsTodayInfo.add(requesterInputDay);


//            signingRequest.requesterInputs = new List<IF_DTO.RequesterInput>();
            signingRequest.requesterInputs.addAll(createRequesterInputTextFields(RequesterInputPosLarge, RequesterInputValuesLarge, 'large'));
            signingRequest.requesterInputs.addAll(createRequesterInputTextFields(RequesterInputPosSmall, RequesterInputValuesSmall, 'small'));
            signingRequest.requesterInputs.addAll(requesterInputsTodayInfo);
        }

        IF_DTO.File file = new IF_DTO.File();
        file.extension = 'pdf';
//        file.base64 = EncodingUtil.base64Encode(pdfBlob);
        file.base64 = base64ByPdfBlob;

        signingRequest.participants = new List<IF_DTO.Participant>();
        signingRequest.title = fileName;
        signingRequest.file = file;
        signingRequest.participants.add(participantMain);
        signingRequest.participants.add(participantInternal);

        return signingRequest;
    }


//    private static Integer getSmallestValue() {
//        // 현재 시간 (현재 시간 기준)
//        DateTime currentTime = DateTime.now();
//
//        // 다음 달 자정 계산
//        DateTime nextMonthMidnight = getNextMonthMidnight(currentTime);
//
//        // 현재 시간과 다음 달 자정까지의 분 차이 계산
//        Long millisecondsUntilNextMonthMidnight = nextMonthMidnight.getTime() - currentTime.getTime();
//        Long minutesUntilNextMonthMidnight = millisecondsUntilNextMonthMidnight / 60000; // 밀리초를 분으로 변환
//
//        // 20160분 (14일)와 비교하여 더 작은 값 계산
//        Integer smallestValue = Math.min(20160, Integer.valueOf(minutesUntilNextMonthMidnight));
//
//        System.debug('다음 달 자정까지 남은 시간(분) ::: ' + Integer.valueOf(minutesUntilNextMonthMidnight));
//        System.debug('리턴 값 ::: ' + smallestValue);
//        return smallestValue;
//    }
//
//    // 다음 달 자정을 계산하는 헬퍼 함수
//    private static DateTime getNextMonthMidnight(DateTime currentTime) {
//        // 현재 날짜에서 월을 1 증가시키고, 해당 월의 1일 자정(00:00:00)으로 설정
//        Integer nextMonth = currentTime.month() + 1;
//        Integer year = currentTime.year();
//
//        // 다음 달이 12월일 경우, 1월로 변경하고 년도를 증가시킴
//        if (nextMonth > 12) {
//            nextMonth = 1;
//            year++;
//        }
//
//        // 해당 월의 1일 자정을 설정
//        DateTime nextMonthMidnight = DateTime.newInstance(year, nextMonth, 1, 0, 0, 0);
//        return nextMonthMidnight;
//    }

    private static List<IF_DTO.Field> createCheckboxFields(List<IF_DTO.Position> positions, List<Boolean> required) {

        List<IF_DTO.Field> fields = new List<IF_DTO.Field>();
        IF_DTO.Size checkboxSize = new IF_DTO.Size();
        checkboxSize.width = 0.02;
        checkboxSize.height = 0.02;

        for (Integer i = 0; i < positions.size(); i++) {
            IF_DTO.Field checkboxField = new IF_DTO.Field();
            checkboxField.type = IF_DTO.FieldType.CHECKBOX;
            checkboxField.required = required[i];
            checkboxField.size = checkboxSize;
            checkboxField.position = positions[i];

            fields.add(checkboxField);
        }

        return fields;
    }
    private static List<IF_DTO.Field> createSignatureFields(List<IF_DTO.Position> positions) {

        List<IF_DTO.Field> fields = new List<IF_DTO.Field>();
        IF_DTO.Size signatureSize = new IF_DTO.Size();
        signatureSize.width = 0.142;
        signatureSize.height = 0.06;

        for (Integer i = 0; i < positions.size(); i++) {
            IF_DTO.Field signatureField = new IF_DTO.Field();
            signatureField.type = IF_DTO.FieldType.SIGNATURE;
            signatureField.required = true;
            signatureField.size = signatureSize;
            signatureField.position = positions[i];
            signatureField.signatureTypes = new List<IF_DTO.SignatureType>();
            signatureField.signatureTypes.add(IF_DTO.SignatureType.SIGN);
//            signatureField.signatureTypes.add(IF_DTO.SignatureType.STAMP);

            fields.add(signatureField);
        }

        return fields;
    }

    private static List<IF_DTO.RequesterInput> createRequesterInputTextFields(List<IF_DTO.Position> positions, List<String> values, String size) {

        List<IF_DTO.RequesterInput> requesterInputs = new List<IF_DTO.RequesterInput>();
        IF_DTO.Size textSize = new IF_DTO.Size();
        if(size.toLowerCase().equals('large')) {
            textSize.width = 0.450;
        } else {
            textSize.width = 0.250;
        }
        textSize.height = 0.022;

        IF_DTO.TextStyle textStyle = new IF_DTO.TextStyle();
        textStyle.size = 12;
        textStyle.font = IF_DTO.FontType.NOTO_SANS;

        for (Integer i = 0; i < positions.size(); i++) {
            IF_DTO.RequesterInput requesterInput = new IF_DTO.RequesterInput();
            requesterInput.type = IF_DTO.FieldType.TEXT;
            requesterInput.size = textSize;
            requesterInput.position = positions[i];
            requesterInput.value = values[i];
            requesterInput.textStyle = textStyle;

            requesterInputs.add(requesterInput);
        }

        return requesterInputs;
    }

}