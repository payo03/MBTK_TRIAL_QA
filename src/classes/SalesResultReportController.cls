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

    public class DefaultWrapper {
        public ProductOption__c productOption { get; set; }
        public Integer index { get; set; }
        public DefaultWrapper(ProductOption__c defaultOption, Integer i) {
            this.productOption = defaultOption;
            this.index = i;
        }
    }
    public class OtherWrapper {
        public ProductOption__c productOption { get; set; }
        public Integer index { get; set; }
        public OtherWrapper(ProductOption__c otherOption, Integer i) {
            this.productOption = otherOption;
            this.index = i;
        }
    }

    public class needDocWrapper {//2페이지 Wrapper Class
        public String gubun { get; set; }
        public String title { get; set; }
        public String quantity { get; set; }
        public String pub { get; set; }

        public needDocWrapper(String title) {
            this.title = title;
        }
        public needDocWrapper(String paramGubun, String paramTitle, String paramQuantity, String paramPub) {
            this.gubun = paramGubun;
            this.title = paramTitle;
            this.quantity = paramQuantity;
            this.pub = paramPub;
        }
    }
    public Integer docLen { get; private set; }
    public Opportunity opportunity { get; private set;}
    public Product2 product2 { get; private set; }
    public VehicleStock__c vehicleStock { get; private set; }
    public List<DefaultWrapper> defaultWrappers { get; set; }
    public List<OtherWrapper> otherWrappers { get; set; }
    public List<needDocWrapper> needDocWrappers { get; set; }

    public PaymentTracker__c paymentTracker { get; set; }
    public PaymentType__c paymentType { get; set; }
    public Quote quote { get; set; }
    public String mode { get; set; }
    public Decimal totIntAmt { get; set; }
    public Decimal optionAmt { get; set; }
    public Decimal defaultProductAmt { get; set; }
    public Decimal otherProductAmt { get; set; }
    public Decimal firstRate { get; set; }
    public Decimal promotionRate { get; set; }
    public Decimal collectRate { get; set; }
    public Decimal differencies { get; set; }
    public Decimal minusCommissionNew { get; set; }
    public String phone { get; set; }
    public String expect { get; set; }
    public String paymentStatus { get; set; }
    public String docImage1{get;set;}
    public String name{get;set;}
    public String compRegNum{get;set;}
    public String businessNumber{get;set;}
    public String phoneNumber{get;set;}
    public String realDriver{get;set;}
    public String address{get;set;}
    public String contractNumber{get;set;}
    public String vehicleName{get;set;}
    public String carColor{get;set;}
//    public String vehicleName{get;set;}

    public String taxInvoiceDate{get;set;}


    public SalesResultReportController() {
    }

    public SalesResultReportController(ApexPages.StandardController controller) {
        opportunity = PDFCommonController.getOpportunity(controller.getId()).get(0);
        docImage1 = PDFCommonController.getDocumentId('MAN_Truck_Bus_Korea_LOGO');
        paymentTracker = PDFCommonController.getPaymentTracker(opportunity.Id).get(0);
        paymentType = paymentTracker?.PaymentTypes__r[0];
        expect = paymentTracker.Status__c == 'COMPLETE' ?  '판매정산결과' : '판매정산 (가)';
        System.debug('123123'+paymentTracker.Status__c);

        Integer index = 1;
        defaultWrappers = new List<DefaultWrapper>();
        List<ProductOption__c> defaultProductOptions = PDFCommonController.getProductOption(opportunity.VehicleStock__r.Product__c, true);
        List<ProductOption__c> otherProductOptions= PDFCommonController.getProductOption(opportunity.VehicleStock__r.Product__c, false);
        quote = PDFCommonController.getQuote(opportunity.ContractId);


        if (opportunity != null) {
            taxInvoiceDate = opportunity.TaxInvoiceDate__c != null ? DateTime.newInstance(opportunity.TaxInvoiceDate__c, Time.newInstance(0, 0, 0, 0)).format('yyyy년 MM월 dd일') : '' ;
            if(opportunity.VehicleStock__c != null){
                VehicleStock__c vehicleStcok = opportunity.VehicleStock__r;
                vehicleName = vehicleStcok.Name;
                carColor = opportunity.VehicleStock__r.CarColor__c;
            }
            if(opportunity.ContractId != null){
                Contract contract = opportunity.Contract;
                contractNumber = contract.ContractNumber;
            }
            if(opportunity.AccountId != null){
                Account account = opportunity.Account;
                name = account.Name;
                String idNumber = account.IDNumber__pc != null ? account.IDNumber__pc.substring(0, 6) + '-XXXXXXX' : '';
                compRegNum = account.CompRegNum__c == null ? idNumber : account.CompRegNum__c;
                phoneNumber = account.PersonMobilePhone;
                realDriver = account.RealDriver__pc;
                address = account.RoadAddress__c + account.DetailAddress__c;
                businessNumber = account.BusinessNumber__c;
            }
        }
//        collectRate = safeDivide(paymentTracker.ru_DepositAmount__c,paymentTracker.TotalAmount__c);
//        promotionRate = opportunity.VehicleStock__r.LongtermDiscountRate__c + opportunity.VehicleStock__r.OptionDiscountRate__c + opportunity.VehicleStock__r.SpecialDiscountRate__c
//                            + opportunity.fm_DiscountRate__c;
//        differencies = opportunity.fm_DiscountRate__c - promotionRate;
//        minusCommissionNew = opportunity.CarAmt__c /1.1 * ((differencies / 100).setScale(4,System.RoundingMode.HALF_UP)*-1).setScale(-3, System.RoundingMode.HALF_UP);
//        defaultProductAmt = 0;
//        if(!defaultProductOptions.isEmpty()){
//            for(ProductOption__c productOption : defaultProductOptions) {
//                defaultWrappers.add(new DefaultWrapper(productOption,index++));
//                if(productOption.VehicleOptionMaster__r.Price__c == null) productOption.VehicleOptionMaster__r.Price__c = 0;
//                System.debug('default:: '+productOption.VehicleOptionMaster__r.Price__c);
//                defaultProductAmt = defaultProductAmt + productOption.VehicleOptionMaster__r.Price__c;
//            }
//
//            for(; index <=5; index++) defaultWrappers.add(new DefaultWrapper(new ProductOption__c(),index));
//        }
//

        index = 1;
        otherWrappers = new List<OtherWrapper>();
        otherProductAmt = 0;
        if (!otherProductOptions.isEmpty()) {
            for (ProductOption__c productOption : otherProductOptions) {
                otherWrappers.add(new OtherWrapper(productOption, index++));

                Decimal price = 0;
                if (productOption.VehicleOptionMaster__r != null && productOption.VehicleOptionMaster__r.Price__c != null) {
                    price = productOption.VehicleOptionMaster__r.Price__c;
                }

                productOption.VehicleOptionMaster__r = (productOption.VehicleOptionMaster__r == null)
                        ? new VehicleOptionMaster__c(Price__c = 0)
                        : productOption.VehicleOptionMaster__r;

                productOption.VehicleOptionMaster__r.Price__c = price;
                otherProductAmt += price;

            }
        }
//        optionAmt = defaultProductAmt + opportunity.CarAmt__c;
        for(; index <= 8; index++) otherWrappers.add(new OtherWrapper(new ProductOption__c(), index));

        /////////////////2페이지/////////////////////////////////////////////
        needDocWrappers = new List<needDocWrapper>();
        if (opportunity.Account.RecordType.Name == '법인사업자') {//법인
            needDocWrappers.add(new needDocWrapper('', '', '', '시.군.구/ 읍.면.동/ 시군구 및'));
            needDocWrappers.add(new needDocWrapper('', '사업자등록증', '', '읍면 등기소'));
            needDocWrappers.add(new needDocWrapper('기본서류', '인감증명서(법인)', '1', '가까운 구청 및 동주민센터'));
            needDocWrappers.add(new needDocWrapper('', '법인 등기부등본', '', '*인터넷: 민원24 등기소'));
            needDocWrappers.add(new needDocWrapper('', '', '', '*인터넷: 인터넷 등기소 개인/법인'));
        }
        if (opportunity.Account.RecordType.Name == '개인') {//개인
            needDocWrappers.add(new needDocWrapper('', '', '', '시.군.구/ 읍.면.동/ 시군구 및'));
            needDocWrappers.add(new needDocWrapper('', '인감증명서', '', '읍면 등기소'));
            needDocWrappers.add(new needDocWrapper('기본서류', '주민등록등본', '1', '가까운 구청 및 동주민센터'));
            needDocWrappers.add(new needDocWrapper('', '', '', '*인터넷: 민원24 등기소'));
            needDocWrappers.add(new needDocWrapper('', '', '', '*인터넷: 인터넷 등기소 개인/법인'));
        }
        if (opportunity.Account.RecordType.Name  == '개인사업자') {//개인사업자
            needDocWrappers.add(new needDocWrapper('', '', '', ''));
            needDocWrappers.add(new needDocWrapper('', '사업자등록증', '', '시.군.구/ 읍.면.동 등기소,'));
            needDocWrappers.add(new needDocWrapper('기본서류', '인감증명서(개인)', '1', '가까운 구청 및 동주민센터'));
            needDocWrappers.add(new needDocWrapper('', '주민등록등본', '', '*인터넷: 민원24 등기소'));
            needDocWrappers.add(new needDocWrapper('', '', '', '*인터넷: 인터넷 등기소 개인/법인'));
        }
        if (paymentType.Type__c == '4_VAT' && paymentType.RequestAmount__c > 0) {
            needDocWrappers.add(new needDocWrapper('', '합의서', '', ''));
            needDocWrappers.add(new needDocWrapper('', '백지어음보증권 부여증', '', ''));
            needDocWrappers.add(new needDocWrapper('부가세 후취', '위임장', '1', '영업지점'));
            needDocWrappers.add(new needDocWrapper('관련서류', '약속어음\r\n국세환급금양도요구서', '', ''));
            needDocWrappers.add(new needDocWrapper('', '보증인 인감증명서', '인원수', '*시.군.구/ 읍.면.동 주민센터'));
        }
        if ([SELECT COUNT() FROM Opportunity WHERE AccountId = :opportunity.AccountId AND Id != :opportunity.Id] > 0) {
            needDocWrappers.add(new needDocWrapper('', '', '', '전국 도청, 시청, 구청, 동주민센터, 차량등록사업소'));
            needDocWrappers.add(new needDocWrapper('재구매인경우', '차량등록증', '1', '(서울시의 경우 구청 및 동주민센터 발급)'));
            needDocWrappers.add(new needDocWrapper('차량등록증', '차량 등록원부(갑부, 을부)', '', '*인터넷: 민원24, 자동차대국민포털사이트'));
            needDocWrappers.add(new needDocWrapper('', '', '', '(단, 법인은 신청 불가 개인만 신청 가능하며, '));
            needDocWrappers.add(new needDocWrapper('', '', '', '차주의 공인인증서 필요)'));
        }
        docLen = needDocWrappers.size();
        paymentStatus = opportunity.PaymentStatus__c == 'COMPLETE' ? '입금완료' : '입금미완료';
//        totIntAmt = paymentType.Type__c == '99_LOAN' ? opportunity.fm_InterestTotal__c : 0.0;
//            if (totIntAmt > 0.0) {
//                DepositCondition__c mDc = new DepositCondition__c();
//                mDc.Amount__c = totIntAmt;
//                mDc.Content__c = '캐피탈이자';
//                mDc.Depositor__c = taxAc != null ? taxAc.Name : account.name;
//                mDc.depositDate__c = opportunity.WantedOutDT__c != null ? opportunity.WantedOutDT__c : opportunity.PlannedOutDT__c;
//                deposit.add(mDc);
//                totalDepositAmount += totIntAmt;//8.24 추가
//            }
//            deposit.addAll([SELECT Id, Depositor__c, depositDate__c, Content__c, Amount__c FROM DepositCondition__c WHERE Opportunity__c = :opportunity.Id ORDER BY Seq__c, depositDate__c, Depositor__c]);

            //Hq세명도장
//            if (opportunity.isApprovedInSales__c) {
//                String sign1userId = opportunity.HqApproverId1__c;
//                if (!String.isEmpty(sign1userId)) {
//                    List<Signature__c> sigs = [SELECT Id, Url__c FROM Signature__c WHERE User__c = :sign1userId AND signType__c = :'직원서명'];
//                    if (!sigs.isEmpty())
//                        Sign_Admin1 = sigs[0].Url__c;
//                }
//
//                String sign2userId = opportunity.HqApproverId2__c;
//                if (!String.isEmpty(sign2userId)) {
//                    List<Signature__c> sigs = [SELECT Id, Url__c FROM Signature__c WHERE User__c = :sign2userId AND signType__c = :'직원서명'];
//                    if (!sigs.isEmpty())
//                        Sign_Admin2 = sigs[0].Url__c;
//                }
//            }
//            if (opportunity.PaymentStatus__c == 'COMPLETE') {
//                String sign3userId;
//                sign3userId = opportunity.HqApproverId3__c;
//
//                if (!String.isEmpty(sign3userId)) {
//                    List<Signature__c> sigs = [SELECT Id, Url__c FROM Signature__c WHERE User__c = :sign3userId AND signType__c = :'직원서명'];
//                    if (!sigs.isEmpty())
//                        Sign_Admin3 = sigs[0].Url__c;
//                }
//            }
//            if (opportunity.DepositConfirmComplete__c) {
//                String sign4userId = opportunity.DepositConfirmId1__c;
//
//                if (!String.isEmpty(sign4userId)) {
//                    List<Signature__c> sigs = [SELECT Id, Url__c FROM Signature__c WHERE User__c = :sign4userId AND signType__c = :'직원서명'];
//                    if (!sigs.isEmpty())
//                        Sign_Admin4 = sigs[0].Url__c;
//                }
//
//                String sign5userId = opportunity.DepositConfirmId2__c;
//                if (!String.isEmpty(sign5userId)) {
//                    List<Signature__c> sigs = [SELECT Id, Url__c FROM Signature__c WHERE User__c = :sign5userId AND signType__c = :'직원서명'];
//                    if (!sigs.isEmpty())
//                        Sign_Admin5 = sigs[0].Url__c;
//                }
//            }
//
//        } else if (mode == 'q') {
//            //Sales두명도장
//            //if(opportunity.isApprovedInSales__c){
//            if (opportunity.SalesApproverId1__c != null && opportunity.SalesApproverId1__c != '') {
//                List<Signature__c> sigs = [SELECT Id, Url__c FROM Signature__c WHERE User__c = :opportunity.SalesApproverId1__c AND signType__c = :'직원서명'];
//                if (!sigs.isEmpty())
//                    Sign_Sales1 = sigs[0].Url__c;
//            }
//
//            if (opportunity.SalesApproverId2__c != null && opportunity.SalesApproverId2__c != '') {
//                List<Signature__c> sigs = [SELECT Id, Url__c FROM Signature__c WHERE User__c = :opportunity.SalesApproverId2__c AND signType__c = :'직원서명'];
//                if (!sigs.isEmpty())
//                    Sign_Sales2 = sigs[0].Url__c;
//            }
//            //}

    }


    public static Decimal safeDivide(Decimal numerator, Decimal denominator) {
        Decimal divide = (numerator / denominator) * 100;

        if(numerator == null || denominator == null || denominator == 0) {
            return 0.0;
        }
        return divide = divide.setScale(2, RoundingMode.HALF_UP);
    }
}