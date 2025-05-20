/**
* @Author            : payo03@solomontech.net
* @Description 		 : AWS PrivateLink를 통한 IF Redirect
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-04-23      payo03@solomontech.net           Created
*/
@RestResource(UrlMapping='/v1/aws/*')
global without sharing class IF_MFS {
    global static final Map<String, String> LOAN_RESULT_MAP = CommonUtilController.getPickListMap('Quote', 'LoanResult__c', true);

    global static String status;
    global static Datetime responseTime;
    global static Datetime requestTime;

    global static RestRequest request;
    global static RestResponse response;

    @HttpGet
    global static void doGet() {
        String pathCase = RestContext.request.requestURI.substringAfter('/v1/aws/');
        System.debug(pathCase);

        requestTime = Datetime.now();
        request = RestContext.request;
        response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');

        switch on pathCase {
            // Health Check
            when 'healthcheck' { returnHealthcheck(); }
        }
    }

    @HttpPost
    global static void doPost() {
        String pathCase = RestContext.request.requestURI.substringAfter('/v1/aws/');
        System.debug(pathCase);

        requestTime = Datetime.now();
        request = RestContext.request;
        response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');

        switch on pathCase {
            // Health Check
            when 'healthcheck' { returnHealthcheck(); }
            // 대출심사 결과
            when 'loan/response' { updateLoanResult(); }
        }
    }

    private static void returnHealthcheck() {
        IF_HealthCheck.Result result = new IF_HealthCheck.Result('v1. Hyperforce Health Check');
        String requestBody = JSON.serialize(result);
        String responseMessage = 'IFAWS.HealthCheck';

        try {
            status = 'SUCCESS';
            responseTime = Datetime.now();

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(requestBody);
        } catch(Exception e) {
            status = 'ERROR';
            responseTime = Datetime.now();
            responseMessage = JSON.serialize(e.getMessage());

            response.responseBody = Blob.valueOf(responseMessage);
            response.statusCode = 500;
        } finally {
            IF_DTO.LogWrapper objLogWrapper = new IF_DTO.LogWrapper();

            objLogWrapper.requestTime = requestTime;
            objLogWrapper.requestBody = requestBody;
            objLogWrapper.status = status;
            objLogWrapper.responseTime = responseTime;
            objLogWrapper.responseBody = responseMessage;
            objLogWrapper.errorCode = String.valueOf(response.statusCode);
            objLogWrapper.logType = IF_DTO.LOG_TYPE.AWS_IN;

            CommonUtilCustomController.setLog(objLogWrapper);
        }
    }

    // TODO : Log Update로직 필요
    private static void updateLoanResult() {
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Custom' LIMIT 1];
        String requestBody = request.requestBody.toString();
        System.debug(requestBody);

        IF_DTO.LoanResponseInfo dtoInfo = (IF_DTO.LoanResponseInfo) JSON.deserialize(requestBody, IF_DTO.LoanResponseInfo.class);
        LoanResponseInfoVar responseInfo = new LoanResponseInfoVar(dtoInfo);

        String responseMessage;
        try {
            status = 'SUCCESS';
            responseTime = Datetime.now();
            responseMessage = JSON.serialize(dtoInfo);

            Quote quote = [
                    SELECT Id, OwnerId, OpportunityId, IsApproveLoan__c, Status,
                            // 비교대상 : 대출금리, 대출금액, Subsidy금액, 원금상환 개월수, 캠페인금액(MFS)
                            DefaultInterestRate__c, fm_TotalLoanAmount__c, fm_SubsidyAmount__c, MonthDivideInputMonth__c, Finance__r.CampaignAmount__c,
                            // Update 대상 : 결과, 결과메시지, 캠페인금액, 보조금금액
                            LoanResult__c, Comment__c, SubventionAmount__c, CampaignAmount__c
                    FROM Quote
                    WHERE Id =: responseInfo.quoteId
            ];
            Boolean boolApplyRate = quote.DefaultInterestRate__c.equals(Decimal.valueOf(responseInfo.applyRate));
            Boolean boolLoanAmt = quote.fm_TotalLoanAmount__c.equals(Decimal.valueOf(responseInfo.loanAmt));
            Boolean boolSubsidyAmt = quote.fm_SubsidyAmount__c.equals(Decimal.valueOf(responseInfo.subsidyAmt));
//            Boolean boolMFSCampAmt = !quote.Finance__r.CampaignAmount__c.equals(Decimal.valueOf(responseInfo.mfsCampAmt));
            Boolean boolLoanTerm = quote.MonthDivideInputMonth__c.equals(Decimal.valueOf(responseInfo.loanTerm));

            String title = '[MFS 대출심사 ' + LOAN_RESULT_MAP.get(responseInfo.loanResult) + ']';
            String body = responseInfo.comment;
            if(!boolApplyRate) body += '\n<요청>금리 : "' + quote.DefaultInterestRate__c + '", <승인>금리 : "' + responseInfo.applyRate + '"';
            if(!boolLoanAmt) body += '\n<요청>금액 : "' + quote.fm_TotalLoanAmount__c + '", <승인>금액 : "' + responseInfo.loanAmt + '"';
            if(!boolSubsidyAmt) body += '\n<요청>보조금 금액 : "' + quote.fm_SubsidyAmount__c + '", <승인>보조금 금액 : "' + responseInfo.subsidyAmt + '"';
            /*
            else if(!boolMFSCampAmt) {
                body += '\n<요청>캠페인 금액 : "' + quote.Finance__r.CampaignAmount__c + '", <승인>캠페인 금액 : "' + responseInfo.mfsCampAmt + '"';
            }
            */
            if(!boolLoanTerm) body += '\n<요청>상환개월수 : "' + quote.MonthDivideInputMonth__c + '", <승인>상환개월수 : "' + responseInfo.loanTerm + '"';

            quote.SubventionAmount__c = Decimal.valueOf(responseInfo.subsidyAmt);
            quote.CampaignAmount__c = Decimal.valueOf(responseInfo.mfsCampAmt);
            quote.LoanResult__c = responseInfo.loanResult;
            quote.Comment__c = body;
            switch on responseInfo.loanResult {
                when 'A' {
                    Opportunity oppty = new Opportunity(Id = quote.OpportunityId);

                    oppty.VATAmount__c = Decimal.valueOf(responseInfo.mfsVatAmt);       // 대상부가세 유예 금액(MFS)
                    oppty.VATExpiredDate__c = Date.valueOf(CommonUtilController.stringToDate(responseInfo.mfsVatDt));      // 부가세 유예 만기일(MFS)
                    oppty.LoanExecuteDate__c = Date.valueOf(CommonUtilController.stringToDate(responseInfo.exctDt));       // 대출 실행일자(MFS)
                    oppty.ContractNo__c = responseInfo.cntrNo;                          // TFS 계약번호(MFS)
                    oppty.ConsentNo__c = responseInfo.mtbkCnsnNo;                       // MTBK 품의번호(MFS)
                    update oppty;

                    quote.IsApproveLoan__c = true;
                }
                when 'E' {
                    Opportunity oppty = new Opportunity(Id = quote.OpportunityId);

                    oppty.VATAmount__c = Decimal.valueOf(responseInfo.mfsVatAmt);       // 대상부가세 유예 금액(MFS)
                    oppty.VATExpiredDate__c = Date.valueOf(CommonUtilController.stringToDate(responseInfo.mfsVatDt));      // 부가세 유예 만기일(MFS)
                    oppty.LoanExecuteDate__c = Date.valueOf(CommonUtilController.stringToDate(responseInfo.exctDt));       // 대출 실행일자(MFS)
                    oppty.ContractNo__c = responseInfo.cntrNo;                          // TFS 계약번호(MFS)
                    oppty.ConsentNo__c = responseInfo.mtbkCnsnNo;                       // MTBK 품의번호(MFS)
                    update oppty;
                }
                // TODO. 보완요청이면 Canceled를 하는게 맞음?? 파일만 주면 될꺼같은데 대기상태로 해야하지 않나
                when else { // 거절, 보완요청
                    quote.Status = 'Canceled';
                }
            }
            update quote;

            CommonUtilController.NotificationWrap notiWrap = new CommonUtilController.NotificationWrap(
                    title,
                    body,
                    notificationType.Id,
                    UserInfo.getUserId(),
                    quote.Id,
                    new Set<String>{quote.OwnerId}
            );
            CommonUtilController.sendNotification(notiWrap);

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(responseMessage);
        } catch(Exception e) {
            status = 'ERROR';
            responseTime = Datetime.now();
            responseMessage = JSON.serialize(e.getMessage());

            response.responseBody = Blob.valueOf(JSON.serialize(e.getMessage()));
            response.statusCode = 400;
        } finally {
            IF_DTO.LogWrapper objLogWrapper = new IF_DTO.LogWrapper();

            objLogWrapper.requestTime = requestTime;
            objLogWrapper.requestBody = requestBody;
            objLogWrapper.status = status;
            objLogWrapper.responseTime = responseTime;
            objLogWrapper.responseBody = responseMessage;
            objLogWrapper.errorCode = String.valueOf(response.statusCode);
            objLogWrapper.logType = IF_DTO.LOG_TYPE.AWS_IN;

            CommonUtilCustomController.setLog(objLogWrapper);
        }
    }

    public class LoanResponseInfoVar {
        public String oppId { get; set; }
        public String quoteId { get; set; }
        public String saleAgentId { get; set; }
        public String loanResult { get; set; }
        public String comment { get; set; }
        public String applyRate { get; set; }
        public String loanAmt { get; set; }
        public String loanTerm { get; set; }
        public String mfsVatAmt { get; set; }
        public String mfsVatDt { get; set; }
        public String exctDt { get; set; }
        public String cntrNo { get; set; }
        public String mtbkCnsnNo { get; set; }
        public String subsidyAmt { get; set; }
        public String mfsCampAmt { get; set; }

        public LoanResponseInfoVar(IF_DTO.LoanResponseInfo info) {
            this.oppId = info.opp_id;
            this.quoteId = info.quote_id;
            this.saleAgentId = info.sale_agent_id;
            this.loanResult = info.loan_result;
            this.comment = info.comment;
            this.applyRate = info.apply_rate;
            this.loanAmt = info.loan_amt;
            this.loanTerm = info.loan_term;
            this.mfsVatAmt = info.mfs_vat_amt;
            this.mfsVatDt = info.mfs_vat_dt;
            this.exctDt = info.exct_dt;
            this.cntrNo = info.cntr_no;
            this.mtbkCnsnNo = info.mtbk_cnsn_no;
            this.subsidyAmt = info.subsidy_amt;
            this.mfsCampAmt = info.mfs_camp_amt;
        }
    }
}