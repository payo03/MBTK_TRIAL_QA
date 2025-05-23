/**
* @Author            : payo03@solomontech.net
* @Description 		 : 대출심사요청 MFS
* @Target            : AsyncInterface_test
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-04-04      payo03@solomontech.net           Created
*/
public without sharing class AsyncLoanRequestMFS implements Queueable, Database.AllowsCallouts {

    private static final String LOG_TYPE = 'MFS_LOAN_REQUEST';
    private static final String IF_ID = InterfaceMFS.IF_MFS001;
    private static final String BANK_NM = '만트럭';
    private static final String BANK_CD = '027';    // https://www.kftc.or.kr/search/searchAll?keyword=%EA%B8%88%EC%9C%B5%ED%9A%8C%EC%82%AC%EC%BD%94%EB%93%9C
    private static final String X_API_KEY = CommonUtilCustomController.parseIFId(InterfaceMFS.DFLT);

    public List<String> quoteIdList;
    public Map<String, Object> paramMap;

    public AsyncLoanRequestMFS(List<String> quoteIdList, Map<String, Object> paramMap) {
        this.quoteIdList = quoteIdList;
        this.paramMap = paramMap;
    }

    public void execute(QueueableContext context) {
        Map<String, Object> paramInfoMap = paramMap == null || paramMap.isEmpty()
                ? new Map<String, Object>()
                : paramMap;
        Boolean isCreate = paramInfoMap.isEmpty() ? true : Boolean.valueOf(paramInfoMap.get('isCreate'));

        /* ------------------------------------------------------------------- */
        /* -------------------- 세금계산서 발행필요 List End -------------------- */
        /* ------------------------------------------------------------------- */

        List<Quote> quoteList = [
                SELECT Id, CreatedById, CreatedBy.Name, DefaultInterestRate__c, MonthDivideInputMonth__c, TotalVehiclePrice__c, AdvancePayment__c, CapitalDefermentAmount__c,
                        fm_TotalLoanAmount__c, RegistrationTax__c, fm_DeliveryDiscountPrice__c, fm_TotalExtraExpenses__c, fm_SubsidyAmount__c, ru_SpecialPrice__c,
                        OpportunityId, Opportunity.Name, Opportunity.TaxInvoiceDate__c,
                        Opportunity.VirtualAccount__r.fm_VirtualAccount__c,
                        Account.Name, Account.PersonEmail, Account.BusinessNumber__c, Account.IDNumber__pc, Account.PersonMobilePhone, Account.RoadAddress__c,
                        VehicleStock__r.Name,
                        Product__r.Name, Product__r.SpecShort__c, toLabel(Product__r.CabMark__c), toLabel(Product__r.WheelBase__c),
                        (
                            SELECT Id, Name, Type__c, fm_Price__c, SpecialPrice__c,
                                    VehicleOptionMaster__r.fm_CFDivision__c
                            FROM QuoteDetail__r
                            WHERE Type__c IN ('특장', '주유상품권')
                        )
                FROM Quote
                WHERE Id IN :quoteIdList
        ];

        // SaleAgent 정보
        Map<String, Account> SAIdMap = new Map<String, Account>();
        for(Quote quote : quoteList) {
            SAIdMap.put(quote.CreatedById, null);
        }
        for(Account acc : [
                SELECT Id, User__c, Phone
                FROM Account
                WHERE User__c IN :SAIdMap.keySet()
        ]) {
            if(acc.User__c != null) {
                SAIdMap.put(acc.User__c, acc);
            } else {
                
            }
        }

        // 차량 Code정보
        Map<String, String> keyCodeMap = new Map<String, String>();
        for(ConfigDetail__c detail : CommonUtilCustomController.getConfigDetailLow('MAN4000')) {
            keyCodeMap.put(detail.Attribute20__c, detail.Name);
        }

        Map<String, String> keyMap = new Map<String, String>();
        List<IF_DTO.LoanRequestInfo> loanRequestInfoList = new List<IF_DTO.LoanRequestInfo>();
        for(Quote quote : quoteList) {
            IF_DTO.LoanRequestInfo loanRequestInfo = new IF_DTO.LoanRequestInfo();

            loanRequestInfo.quote_id = quote.Id;
            loanRequestInfo.sale_agent_nm = quote.CreatedBy.Name;
            loanRequestInfo.apply_rate = String.valueOf(quote.DefaultInterestRate__c);
            loanRequestInfo.loan_term = String.valueOf(quote.MonthDivideInputMonth__c);
            loanRequestInfo.vhc_price = String.valueOf(quote.TotalVehiclePrice__c);
            loanRequestInfo.vhc_dc = String.valueOf(quote.fm_DeliveryDiscountPrice__c);
            loanRequestInfo.vhc_exp = String.valueOf(quote.fm_TotalExtraExpenses__c);
            loanRequestInfo.loan_amt = String.valueOf(quote.fm_TotalLoanAmount__c);
            loanRequestInfo.reg_tax = String.valueOf(quote.RegistrationTax__c);
            loanRequestInfo.spc_vhc_price = String.valueOf(quote.ru_SpecialPrice__c);
            loanRequestInfo.pre_amt = String.valueOf(quote.AdvancePayment__c);
            loanRequestInfo.campaign = '캠페인 이름 받아야함';
            loanRequestInfo.campaign_dc_amt = String.valueOf(quote.fm_SubsidyAmount__c);

            String amt = String.valueOf(quote.CapitalDefermentAmount__c);
            loanRequestInfo.mfs_vat_amt = amt;
            loanRequestInfo.mfs_vat_request = amt != '0' ? 'Y' : 'N';

            loanRequestInfo.opp_id = quote.OpportunityId;
            loanRequestInfo.invoice_dt = String.valueOf(quote.Opportunity.TaxInvoiceDate__c);
            loanRequestInfo.virtual_acc = quote.Opportunity.VirtualAccount__r.fm_VirtualAccount__c;

            loanRequestInfo.bsn_no = quote.Account.BusinessNumber__c;
            loanRequestInfo.rrn = quote.Account.IDNumber__pc;
            loanRequestInfo.bsn_nm = quote.Account.Name;
            loanRequestInfo.bsn_tel = quote.Account.PersonMobilePhone;
            loanRequestInfo.bsn_add = quote.Account.RoadAddress__c;
            loanRequestInfo.email_add = quote.Account.PersonEmail;

            // contact -> account 로 변경
            loanRequestInfo.tel_no = quote.Account.PersonMobilePhone;
            loanRequestInfo.cs_nm = quote.Account.Name;

            loanRequestInfo.stock_no = quote.VehicleStock__r.Name;
            loanRequestInfo.vhc_model_nm = quote.Product__r.Name;

            Decimal optionPrice = 0;
            String CFDivision = '';
            String productKey = quote.Product__r.SpecShort__c + ' ' + quote.Product__r.CabMark__c + ' ' + quote.Product__r.WheelBase__c;
            for(QuoteDetail__c detail : quote.QuoteDetail__r) {
                optionPrice += detail.fm_Price__c;
                switch on detail.Type__c {
                    when '특장'       { loanRequestInfo.spc_vhc = detail.Name; }
                    when '주유상품권'  { loanRequestInfo.o_coupon_price = String.valueOf(detail.fm_Price__c); }
                }

                String CF = detail.VehicleOptionMaster__r.fm_CFDivision__c;
                if (!'NC'.equals(CF)) CFDivision = CF;
            }
            loanRequestInfo.option_price = String.valueOf(optionPrice);

            // MFS ModelCode
            String codeKey = productKey + (CFDivision != '' ? '_' + CFDivision : CFDivision);
            loanRequestInfo.model_cd = keyCodeMap.containsKey(codeKey) ? keyCodeMap.get(codeKey) : '';

            Account accountSA = SAIdMap.get(quote.CreatedById);
            loanRequestInfo.sale_agent_id = accountSA.Id;
            loanRequestInfo.sale_agent_tel = accountSA.Phone;

            loanRequestInfo.virtual_acc_nm = BANK_NM;
            loanRequestInfo.virtual_acc_cd = BANK_CD;
            loanRequestInfo.loan_request_dt = String.valueOf(Date.today());

            loanRequestInfoList.add(loanRequestInfo);
            keyMap.put(quote.Id, quote.Opportunity.Name);
        }

        if(!loanRequestInfoList.isEmpty()) {
            Map<String, Object> infoMap = new Map<String, Object>();

            infoMap.put('ifId', IF_ID);
            infoMap.put('logId', X_API_KEY);
            infoMap.put('logType', LOG_TYPE);
            infoMap.put('items', loanRequestInfoList);
            infoMap.put('keyMap', keyMap);
            infoMap.put('isLogDetail', true);

            Map<String, String> cHeaderMap = new Map<String, String>{
                    'X-API-KEY' => X_API_KEY
            };
            infoMap.put('cHeaderMap', cHeaderMap);

            Map<String, Object> resultMap = InterfaceMFS.doCallOutMFSLog(infoMap);
            System.debug(JSON.serializePretty(resultMap));
        }
    }
}