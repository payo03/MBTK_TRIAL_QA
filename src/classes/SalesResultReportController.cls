/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-18
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-18        San.Kang           Created
**************************************************************/
public with sharing class SalesResultReportController {

    //기본제공품목
    public class DefaultWrapper {
        public String productOptionName { get; set; }
        public String amount { get; set; }
        public String price { get; set; }
        public Integer index { get; set; }
        public DefaultWrapper(String productOptionName, String amount, String price, Integer i) {
            this.productOptionName = productOptionName;
            this.amount = amount;
            this.price = price;
            this.index = i;
        }
    }

    //시책 품목
    public class OtherWrapper {
        public ProductOption__c productOption { get; set; }
        public String price { get; set; }
        public Integer index { get; set; }
        public OtherWrapper(ProductOption__c otherOption, Integer i, String price) {
            this.productOption = otherOption;
            this.price = price;
            this.index = i;
        }
    }

    public String fontSize { get; set; } // 기본제공품목, 시책품목에 따른 폰트사이즈 조절
    public Opportunity opportunity { get; private set;} // 기회
    public List<DefaultWrapper> defaultWrappers { get; set; } //기본제공품목
    public List<OtherWrapper> otherWrappers { get; set; } //시책 품목

    public String expect { get; set; } // 판매정산 Report 문구
    public String docImage1{get;set;}  // 만트럭 로고
    public String name{get;set;} // 고객명
    public String compRegNum{get;set;} // 주민등록(법인)번호
    public String businessNumber{get;set;} // 사업자등록번호
    public String phoneNumber{get;set;} //핸드폰 번호
    public String realDriver{get;set;} // 실차주명
    public String address{get;set;} // 주소
    public String contractNumber{get;set;} // 계약서 번호
    public String vehicleName{get;set;} // 차 종
    public String carColor{get;set;} // 색 상
    public String carAmt{get;set;} // 차량 가격
    public String totalPrice{get;set;} // 옵션 포함 차량가격
    public String paymentDeferredAmount{get;set;} // 인도금 할인
    public String realSalesPrice{get;set;} // 실판매가격 (부가세 포함)
    public String totaldefaultPrice{get;set;} // 시책 합계
    public String depositDate{get;set;} // 계약금 입금일
    public String depositPrice{get;set;} //계약금
    public String downPaymentDate{get;set;} // 인도금 입금일
    public String downPaymentPrice{get;set;} // 인도금
    public String loanDate{get;set;} // 대출 입금일
    public String loanPrice{get;set;} // 대출금
    public String totalPayment{get;set;} // 입금액 합계
    public String deferredPrice{get;set;} // 인도유예금
    public String vatPrice{get;set;} // 부가세유예금
    public String totaldeferred{get;set;} // 인도금 합계
    public String fScompany{get;set;} // 할부금융사
    public String realLoanAmt{get;set;} // 할부원금
    public String capitalDefermentAmt{get;set;} // 캐피탈유예금
    public String totalloanAmountStr{get;set;} // 대출금 합계
    public String defaultInterestRate{get;set;} // 할부이율
    public String monthDivideInputMonth{get;set;} // 분납개월수
    public String monthlyPayment{get;set;} // 1회 납입금액
    public String monthlyPaymentDate{get;set;} // 할부초회납입일자
    public String totalCommissionSum{get;set;} // 판매수수료
    public String notarizedFee{get;set;} //공증료
    public String consignmentPrice{get;set;} //탁송료
    public String registrationTax{get;set;} //취등록세
    public String totalExtraExpenses{get;set;} //부대비용 합계
    public String agency{get;set;} // 판매지점
    public String salesName{get;set;} // 판매직원
    public String taxInvoiceOwner{get;set;} // 세금계산서명의
    public String emailTaxInvoice{get;set;} // 세금계산서이메일
    public String transferAccount{get;set;} // 양도증 명의
//    public String vehicleName{get;set;}

    public String taxInvoiceDate{get;set;}


    public SalesResultReportController(ApexPages.StandardController controller) {
        opportunity = PDFCommonController.getOpportunity(controller.getId()).isEmpty() ? null
                : PDFCommonController.getOpportunity(controller.getId()).get(0);
    }

    public void init() {

        docImage1 = PDFCommonController.getDocumentId('MAN_Truck_Bus_Korea_LOGO');

        PaymentTracker__c paymentTracker = (opportunity != null) ? PDFCommonController.getPaymentTracker(opportunity.Id).get(0) : new PaymentTracker__c();

        List<ProductOption__c> defaultProductOptions = (opportunity?.VehicleStock__r != null) ?
                PDFCommonController.getProductOption(opportunity.VehicleStock__r.Product__c, true) : new List<ProductOption__c>();

        List<ProductOption__c> otherProductOptions = (opportunity?.VehicleStock__r != null) ?
                PDFCommonController.getProductOption(opportunity.VehicleStock__r.Product__c, false) : new List<ProductOption__c>();

        Quote quote = (opportunity != null) ? PDFCommonController.getQuote(opportunity.Id) : new Quote();

        List<QuoteDetail__c> quoteDetails = (quote != null) ? PDFCommonController.getQuoteDetail(quote.Id) : new List<QuoteDetail__c>();

        QuoteDetail__c quoteDetail = (!quoteDetails.isEmpty()) ? quoteDetails[0] : null;
        expect = paymentTracker.Status__c == 'COMPLETE' ?  '판매정산결과' : '판매정산 (가)';

        defaultWrappers = new List<DefaultWrapper>();
        otherWrappers = new List<OtherWrapper>();
        Decimal otherProductAmt = 0;
        Integer index = 0;

        // 옵션
        if (!otherProductOptions.isEmpty()) {
            for (ProductOption__c productOption : otherProductOptions) {
                Decimal price = 0;
                if (productOption.VehicleOptionMaster__r != null && productOption.VehicleOptionMaster__r.Price__c != null) {
                    price = productOption.VehicleOptionMaster__r.Price__c;
                }

                productOption.VehicleOptionMaster__r = (productOption.VehicleOptionMaster__r == null) ? new VehicleOptionMaster__c(Price__c = 0)
                        : productOption.VehicleOptionMaster__r;
                otherWrappers.add(new OtherWrapper(productOption, index++, setScale(price)));
                otherProductAmt += price;
            }
        }
        for(; index <= 8; index++) otherWrappers.add(new OtherWrapper(new ProductOption__c(), index, '0원'));

        index = 0;
        Decimal defaultProductAmt = 0;
        // 기본제공품목
        if (!defaultProductOptions.isEmpty()) {
            for (ProductOption__c productOption : defaultProductOptions) {
                Decimal price = 0;
                if (productOption.VehicleOptionMaster__r != null && productOption.VehicleOptionMaster__r.Price__c != null) {
                    price = productOption.VehicleOptionMaster__r.Price__c;
                }
                if (productOption.VehicleOptionMaster__r == null) productOption.VehicleOptionMaster__r = new VehicleOptionMaster__c(Price__c = 0);

                defaultWrappers.add(new DefaultWrapper(productOption.Name, '1개', setScale(price), index++));
                otherProductAmt += price;
                if (productOption.VehicleOptionMaster__r.Price__c == null) productOption.VehicleOptionMaster__r.Price__c = 0;

                defaultProductAmt += productOption.VehicleOptionMaster__r.Price__c;
            }
            if(quoteDetail != null){
                defaultWrappers.add(new DefaultWrapper(
                        quoteDetail.Name,
                        String.valueOf(quoteDetail.OilCouponCount__c) + '개',
                        setScale(quoteDetail.fm_Price__c), index++));
                defaultProductAmt += (quoteDetail.fm_Price__c != null) ? quoteDetail.fm_Price__c : 0;
            }
            totaldefaultPrice = setScale(defaultProductAmt);
            for (; index <= 5; index++) {
                defaultWrappers.add(new DefaultWrapper('', '0개', '0원', index));
            }
        }

        fontSize = defaultWrappers.size() + otherProductOptions.size() > 16 ? '8pt' : '9.5pt';
        // 기회 데이터
        if (opportunity != null) {
            taxInvoiceDate = opportunity.TaxInvoiceDate__c != null ? setDateType(opportunity.TaxInvoiceDate__c) : '' ;
            paymentDeferredAmount = setScale(opportunity.PaymentDeferredAmount__c);
            realLoanAmt = setScale(opportunity.fm_TotalLoan__c);
            monthlyPaymentDate = opportunity.HandoverDate__c != null ? setDateType(opportunity.HandoverDate__c.addMonths(1)) : '';
            Decimal totalloamAmount  = opportunity.fm_TotalLoan__c;
            // 견적 데이터
            if(quote != null){
                capitalDefermentAmt   = setScale(quote.CapitalDefermentAmount__c != null ? quote.CapitalDefermentAmount__c : 0);
                defaultInterestRate   = String.valueOf(quote.DefaultInterestRate__c) + '%';
                monthDivideInputMonth = String.valueOf(quote.MonthDivideInputMonth__c) + '개월';
                monthlyPayment        = setScale(quote.MonthlyPayment__c != null ? quote.MonthlyPayment__c : 0);
                notarizedFee          = setScale(quote.fm_NotarizedFee__c != null ? quote.fm_NotarizedFee__c : 0);
                consignmentPrice      = setScale(quote.ConsignmentPrice__c != null ? quote.ConsignmentPrice__c : 0);
                registrationTax       = setScale(quote.RegistrationTax__c != null ? quote.RegistrationTax__c : 0);
                totalExtraExpenses    = setScale(quote.fm_TotalExtraExpenses__c != null ? quote.fm_TotalExtraExpenses__c : 0);
                totalloanAmountStr = setScale(totalloamAmount + (quote.CapitalDefermentAmount__c == null ? 0 : quote.CapitalDefermentAmount__c));

                if(quote.Finance__c != null){
                    Finance__c finance = quote.Finance__r;
                    fScompany = finance.FScompany__c;
                }
            }
            // 차량재고 데이터
            if(opportunity.VehicleStock__c != null){
                VehicleStock__c vehicleStcok = opportunity.VehicleStock__r;
                carColor = opportunity.VehicleStock__r.CarColor__c;
                if(vehicleStcok.Product__c != null){
                    Product2 product2 = vehicleStcok.Product__r;
                    vehicleName = product2.Name;
                    carAmt = setScale(product2.CarAmt__c);
                    totalPrice = setScale(otherProductAmt + product2.CarAmt__c);
                }
            }

            // 계약 데이터
            if(opportunity.ContractId != null){
                Contract contract = opportunity.Contract;
                contractNumber = contract.ContractNumber;
                realSalesPrice = setScale(contract.fm_RealSalesPrice__c);
            }



            // 계정 데이터
            if(opportunity.AccountId != null){
                Account account = opportunity.Account;
                Account realDriverAccount = opportunity.RealDriverAccount__c != null ?  opportunity.RealDriverAccount__r : account;
                name = account.Name;
                String idNumber = realDriverAccount.IDNumber__pc != null && realDriverAccount.IDNumber__pc.length() > 7
                        ? realDriverAccount.IDNumber__pc.substring(0, 6) + '-XXXXXXX' : '';
                compRegNum = account.CompRegNum__c == null ? idNumber : account.CompRegNum__c;
                phoneNumber = account.PersonMobilePhone;
                realDriver = realDriverAccount.LastName;
                address = account.RoadAddress__c + account.DetailAddress__c;
                businessNumber = account.BusinessNumber__c;
                transferAccount = opportunity.TransferAccount__c != null ? opportunity.TransferAccount__r.Name : account.Name;
                taxInvoiceOwner = account.Name;
                emailTaxInvoice = account.EmailTaxInvoice__c;
                if(account.Id != opportunity.fm_TaxAccountId__c){
                    Account taxAccount = [SELECT Name, EmailTaxInvoice__c FROM Account WHERE Id =:opportunity.fm_TaxAccountId__c];
                    taxInvoiceOwner = taxAccount.Name;
                    emailTaxInvoice = taxAccount.EmailTaxInvoice__c;
                }

                if(account.OwnerId != null){
                    User user = account.Owner;
                    agency = user.Agency__c;
                    salesName = user.Name;
                    List<CommissionHistory__c> commissionHistories = [SELECT Id,fm_NetPaymentTotal__c FROM CommissionHistory__c WHERE Opportunity__c =:opportunity.Id];
                    totalCommissionSum = setScale(0);
                    if(!commissionHistories.isEmpty()) totalCommissionSum = setScale(commissionHistories[0].fm_NetPaymentTotal__c);
                }
            }
            // 입금내역 및 인도금
            if (paymentTracker != null) {
                Decimal totalPaymentPrice = 0;
                Decimal totaldeferredPrice = 0;
                deferredPrice = '0원';
                vatPrice = '0원';
                if (!paymentTracker.PaymentTypes__r.isEmpty()) {
                    for (PaymentType__c paymentType : paymentTracker.PaymentTypes__r) {

                        if (paymentType.Type__c == null) continue;
                        switch on paymentType.Type__c {
                            when '1_DEPOSIT' {
                                depositDate = setDateType(Date.valueOf(paymentTracker.ru_RecentDepositDate__c));
                                depositPrice = setScale(paymentType.DepositAmount__c);
                                totalPaymentPrice += paymentType.DepositAmount__c;
                                totaldeferredPrice += paymentType.RequestAmount__c;
                            }
                            when '2_DOWN_PAYMENT' {
                                downPaymentDate = setDateType(Date.valueOf(paymentTracker.ru_RecentDepositDate__c));
                                downPaymentPrice = setScale(paymentType.DepositAmount__c);
                                totalPaymentPrice += paymentType.DepositAmount__c;
                                totaldeferredPrice += paymentType.RequestAmount__c;
                            }
                            when '3_DEFERRED_PAYMENT' {
                                deferredPrice = setScale(paymentType.DepositAmount__c);
                                totaldeferredPrice += paymentType.RequestAmount__c;
                            }
                            when '4_VAT' {
                                vatPrice = setScale(paymentType.DepositAmount__c);
                                totaldeferredPrice += paymentType.RequestAmount__c;
                            }
                            when '99_LOAN' {
                                loanDate = setDateType(Date.valueOf(paymentTracker.ru_RecentDepositDate__c));
                                loanPrice = setScale(paymentType.DepositAmount__c);
                                totalPaymentPrice += paymentType.DepositAmount__c;
                            }
                        }
                    }
                    totalPayment = setScale(totalPaymentPrice);
                    totaldeferred = setScale(totaldeferredPrice);
                }
            }
        }
    }

    public static String setScale(Decimal price) {
        price = price != null ? price : 0;
        return price.setScale(0).format() + '원';
    }

    public static String setDateType(Date dateValue) {
        if(dateValue == null) return '';
        return Datetime.newInstance(dateValue, Time.newInstance(0, 0, 0, 0)).format('yyyy년 MM월 dd일');
    }
}