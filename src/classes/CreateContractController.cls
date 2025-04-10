/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-06
 * @description : 견적에서 기회 첨부파일 체크 후 계약서 레코드 생성
 * @target : createContract.js
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-06      chaebeom.do     Created
**************************************************************/
public without sharing class CreateContractController {
    public class QuoteWrap {
        @AuraEnabled public String id;
        @AuraEnabled public String opptyId;
        @AuraEnabled public String accId;
        @AuraEnabled public String stockId;
        @AuraEnabled public String productId;
        @AuraEnabled public String contractId;
        @AuraEnabled public String opptyContractId;
        @AuraEnabled public String segment;
        @AuraEnabled public String financeCompany;
        @AuraEnabled public Decimal interestRate;
        @AuraEnabled public Decimal totalLoanAmount;
        @AuraEnabled public Decimal loanTerm;
        @AuraEnabled public Boolean loanApproved;
        @AuraEnabled public Boolean jumin;
        @AuraEnabled public Boolean bizNo;
        @AuraEnabled public Boolean vat;
        @AuraEnabled public String vatStatus;

        public QuoteWrap(String id, String opptyId, String accId, String stockId, String productId, String contractId, String opptyContractId, String segment, String financeCompany, Decimal interestRate, Decimal totalLoanAmount, Decimal loanTerm, Boolean loanApproved, Boolean jumin, Boolean bizNo, Boolean vat, String vatStatus) {
            this.id = id;
            this.opptyId = opptyId;
            this.accId = accId;
            this.stockId = stockId;
            this.productId = productId;
            this.contractId = contractId;
            this.opptyContractId = opptyContractId;
            this.segment = segment;
            this.financeCompany = financeCompany;
            this.interestRate = interestRate;
            this.totalLoanAmount = totalLoanAmount;
            this.loanTerm = loanTerm;
            this.loanApproved = loanApproved;
            this.jumin = jumin;
            this.bizNo = bizNo;
            this.vat = vat;
            this.vatStatus = vatStatus;
        }
    }
    
    @AuraEnabled
    public static List<QuoteWrap> getQuote(String quoteId){
        String selectFields = 'Id, OpportunityId, AccountId, ContractId, Segment__c, VehicleStock__c, fm_TotalLoanAmount__c, IsApproveLoan__c, DefaultInterestRate__c, MonthDivideInputMonth__c, Finance__r.FScompany__c, Product__c, Opportunity.IsJumin__c, Opportunity.IsBusiness__c, Opportunity.IsVAT__c, Opportunity.VATDefermentStatus__c, Opportunity.ContractId';
        String whereConditions = 'Id = \'' + quoteId + '\'';
        String query = CommonUtilController.buildQuery(selectFields, 'Quote', whereConditions);

        List<Quote> quoteList = Database.query(query);

        List<QuoteWrap> quoteWraps = new List<QuoteWrap>();
        for(Quote quote : quoteList) {
            QuoteWrap quoteWrap = new quoteWrap(
                quote.Id,
                quote.OpportunityId,
                quote.AccountId,
                quote.VehicleStock__c,
                quote.Product__c,
                quote.ContractId,
                quote.Opportunity.ContractId,
                quote.Segment__c,
                quote.Finance__r.FScompany__c,
                quote.DefaultInterestRate__c,
                quote.fm_TotalLoanAmount__c,
                quote.MonthDivideInputMonth__c,
                quote.IsApproveLoan__c,
                quote.Opportunity.IsJumin__c,
                quote.Opportunity.IsBusiness__c,
                quote.Opportunity.IsVAT__c,
                quote.Opportunity.VATDefermentStatus__c
            );
            quoteWraps.add(quoteWrap);
        }
        return quoteWraps;
    }

    @AuraEnabled
    public static string createContract(Map<String, String> inputMap){
        Quote curQ = [SELECT Id, OpportunityId, IsApproveLoan__c FROM Quote WHERE Id = :inputMap.get('recordId')];
        if(Integer.valueOf(inputMap.get('totalLoanAmount')) != 0 && curQ.IsApproveLoan__c == false) {
            return 'approvalNotComplete';
        }
        Product2 product = [
            SELECT Id
            FROM Product2 
            WHERE Id = :inputMap.get('productId')
        ];
        // Product2 product = [
        //     SELECT Id
        //     FROM Product2 
        //     WHERE Id IN (SELECT Product__c FROM VehicleStock__c WHERE Id = :inputMap.get('stockId'))
        // ];
        
        List<VehicleStock__c> stockList = [
            SELECT Id
            FROM VehicleStock__c 
            WHERE Product__c = :product.Id
            AND VehicleStatus__c != '출고됨' // 이후 출고됨이면 Status__c가 판매완료로 변경되면 Status__c만 참고해도 될듯..
            ];
            
        List<PDIStep__c> stepList = [
            SELECT Id, Stage__c, IsPass__c
            FROM PDIStep__c
            WHERE VehicleStock__c IN :stockList
            AND Stage__c = 'STEP2'
            AND IsPass__c = true
            ];
        if(stepList.size() == 0) {
            return 'noStockForSelling';
        }
        Contract c = new Contract();
        c.Status = 'Draft';
        c.ConStatus__c = '승인 단계';
        c.AccountId = inputMap.get('accId');
        c.VehicleStock__c = inputMap.get('stockId');
        c.Opportunity__c = inputMap.get('opptyId');
        c.Quote__c = inputMap.get('recordId');
        c.Segment__c = inputMap.get('segment');
        c.StartDate = Date.today();
        c.Deposit__c = 1000000;
        c.ContractTerm = 1;
        insert c;

        Quote q = new Quote();
        q.Id = curQ.Id;
        q.ContractId = c.Id;
        q.Status = 'Published';
        if(Integer.valueOf(inputMap.get('totalLoanAmount')) == 0) q.IsApproveLoan__c = true;
        update q;
        //발송한 견적 이외의 기회에 달린 견적들은 단계 'Published' 였으면 'SentOut'으로 변경

        // Quote curQ = [SELECT Id, OpportunityId FROM Quote WHERE Id = :q.Id];
        List<Quote> otherQ = [SELECT Id, Status FROM Quote WHERE OpportunityId = :curQ.OpportunityId AND Id != :q.Id];
        System.debug('otherQ::: ' + otherQ);
        for (Quote el : otherQ) {
            if(el.Status == 'Published') {
                el.Status = 'SentOut';
            }
        }
        update otherQ;

        Opportunity opp = new Opportunity();
        opp.Id = inputMap.get('opptyId');
        opp.StageName = 'Contract';
        opp.ContractId = c.Id;
        opp.IsRenegotiation__c = false;
        update opp;

        createApprovalProcess(c.Id);

        return c.Id;
        // return '야호';
    }

    //승인 프로세스 생성
    @AuraEnabled
    public static String createApprovalProcess(String recordId) {
        // Create an approval request for the contract
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('계약 생성 요청_' + System.today());
        req1.setObjectId(recordId);
        // Submit the record to the existing process named PTO_Reqwuest_Process
        req1.setProcessDefinitionNameOrId('ContractCreation');
        // Submit the approval request for the contract
        Approval.ProcessResult result = Approval.process(req1);
        System.debug(result);
        return '승인 요청이 완료되었습니다.';
    }
}