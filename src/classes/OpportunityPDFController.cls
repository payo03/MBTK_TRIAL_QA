/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-05-12      payo03@solomontech.net           Created
*/
public with sharing class OpportunityPDFController {

    public ApexPages.StandardController vfController { get; set; }
    public static String recordId;
    public static OpportunityPDFWrapper pdfWrapper { get; set; }

    public OpportunityPDFController(ApexPages.StandardController controller) {
        vfController = controller;

        recordId = CommonUtilController.convert15to18DigitId(vfController.getId());
        System.debug(recordId);
    }

    public static void getVFInfo() {
        Opportunity oppty = [
                SELECT Id,  ConsentNo__c, ContractNo__c, LoanExecuteDate__c,
                        Account.Name,
                        VirtualAccount__r.fm_VirtualAccount__c,
                        VehicleStock__r.Name,
                (
                        SELECT Id, fm_TotalLoanAmount__c, SubventionAmount__c, CampaignAmount__c
                        FROM Quotes
                        WHERE Status = 'Published'
                )
                FROM Opportunity
                WHERE Id = :recordId
        ];
        Quote quote = oppty.Quotes.get(0);

        /*
        Decimal totSubsidyAmt = quote.fm_TotalLoanAmount__c - quote.SubventionAmount__c;
        Decimal subsidyMFSAmt = quote.SubventionAmount__c - quote.CampaignAmount__c;
        Decimal finalAmt = totSubsidyAmt + quote.CampaignAmount__c;
        */
        Decimal totSubsidyAmt = 100;
        Decimal subsidyMFSAmt = 100;
        Decimal finalAmt = 100;

        OpportunityPDFWrapper wrapper = new OpportunityPDFWrapper();
        wrapper.virtualAccountNo = oppty.VirtualAccount__r.fm_VirtualAccount__c != null ? oppty.VirtualAccount__r.fm_VirtualAccount__c : 'TEST';
        wrapper.chassisFrameNo = oppty.VehicleStock__r.Name != null ? oppty.VehicleStock__r.Name : 'TEST';
        wrapper.mtbkConsentNo = oppty.ConsentNo__c != null ? oppty.ConsentNo__c : 'TEST';
        wrapper.tfsContractNo = oppty.ContractNo__c != null ? oppty.ContractNo__c : 'TEST';
        wrapper.customerNm = oppty.Account.Name != null ? oppty.Account.Name : 'TEST';

        wrapper.totLoanAmt = quote.fm_TotalLoanAmount__c != null ? quote.fm_TotalLoanAmount__c : 100;
        wrapper.subsidyAmt = quote.SubventionAmount__c != null ? quote.SubventionAmount__c : 100;
        wrapper.totSubsidyAmt = totSubsidyAmt;
        wrapper.mfsCampaignAmt = quote.CampaignAmount__c != null ? quote.CampaignAmount__c : 100;
        wrapper.subsidyMFSAmt = subsidyMFSAmt;
        wrapper.finalAmt = finalAmt;
        wrapper.weeklyFundingAmt = 100;

        wrapper.executeDt = oppty.LoanExecuteDate__c != null ? oppty.LoanExecuteDate__c : Date.today();
        wrapper.weeklyFundingDt = Date.today();
        wrapper.mtbkSaleDt = Date.today();

        pdfWrapper = wrapper;
    }

    @AuraEnabled
    public static String sendMail() {
        return 'test';
    }

    public class OpportunityPDFWrapper {
        public String virtualAccountNo { get; set; }
        public String chassisFrameNo { get; set; }
        public String mtbkConsentNo { get; set; }
        public String tfsContractNo { get; set; }
        public String customerNm { get; set; }

        public Decimal totLoanAmt { get; set; }
        public Decimal subsidyAmt { get; set; }
        public Decimal totSubsidyAmt { get; set; }
        public Decimal mfsCampaignAmt { get; set; }
        public Decimal subsidyMFSAmt { get; set; }
        public Decimal finalAmt { get; set; }
        public Decimal weeklyFundingAmt { get; set; }

        public Date executeDt { get; set; }
        public Date weeklyFundingDt { get; set; }
        public Date mtbkSaleDt { get; set; }
    }
}