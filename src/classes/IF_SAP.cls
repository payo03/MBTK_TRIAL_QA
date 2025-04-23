/**
* @Author            : payo03@solomontech.net
* @Description 		 : SAP > Heroku > SFDC Interface
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-08      payo03@solomontech.net           Created
  1.1      2025-04-21      payo03@solomontech.net           대출금 입금상태 반영로직 추가
*/
@RestResource(UrlMapping='/api/sap/*')
global without sharing class IF_SAP {
    global static final String TRACKER_ID = Label.DummyTracker;

    global static String status;
    global static Datetime responseTime;
    global static Datetime requestTime;

    global static RestRequest request;
    global static RestResponse response;

    @HttpPost
    global static void doPost() {
        String pathCase = RestContext.request.requestURI.substringAfter('/api/sap/');
        System.debug(pathCase);

        requestTime = Datetime.now();
        request = RestContext.request;
        response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');

        switch on pathCase {
            // 가상계좌 입금금액 Update
            when 'sms019' { updateAmount(); }
            // 구매오더 확정전송 Response(Async)
            when 'async/sms010' { asyncOrderConfirm(); }
            // 구매오더 확정전송 Response(Async)
            when 'async/sms011' { asyncInvoiceConfirm(); }
            // Customs(세관) 전송 Response(Async)
            when 'async/sms012' { asyncCustomsInfo(); }
        }
    }

    // 금액 Update. 수신이 아닌 송신 Response로 진행해야함
    private static void updateAmount() {
        final String DEPOSIT_KEY = '1_DEPOSIT';
        final String DOWM_PAYMENT_KEY = '2_DOWN_PAYMENT';
        final String DEFERRED_PAYMENT_KEY = '3_DEFERRED_PAYMENT';
        final String VAT_KEY = '4_VAT';
        final String OVER_PAID_KEY = '5_OVER_PAID';
        final String LOAN_KEY = '99_LOAN';
//        final String SUBVENTION_KEY = '99_SUBVENTION';
//        final String CAMPAIGN_KEY = '99_CAMPAIGN';
        final Set<String> TARGET_KEY_SET = new Set<String>{
                DEPOSIT_KEY, DOWM_PAYMENT_KEY, DEFERRED_PAYMENT_KEY, VAT_KEY, OVER_PAID_KEY, LOAN_KEY
        };

        String requestBody = request.requestBody.toString();
        System.debug(requestBody);

        IF_DTO.PaymentDetailInfo info = (IF_DTO.PaymentDetailInfo) JSON.deserialize(requestBody, IF_DTO.PaymentDetailInfo.class);
        String virtualAccountNumber = info.acc_no;
        String documentId = info.doc_num;
        String BPCode = info.card_cd;
        Integer depositAmount = Integer.valueOf(info.doc_total);

        PaymentLog__c paymentLog = new PaymentLog__c();
        paymentLog.PaymentTracker__c = TRACKER_ID;   // Dummy용 데이터. 오류없을시 finally에서 실데이터로 매핑
        paymentLog.Name = CommonUtilController.formatDate(Datetime.now(), 'C') + '_' + virtualAccountNumber;
        paymentLog.Amount__c = depositAmount;
        paymentLog.InternalDocumentId__c = documentId;
        paymentLog.Account__c = [SELECT Id FROM Account WHERE BPCode__c = :BPCode].Id;

        String responseMessage;
        String paymentTrackerId;
        String contractId;
        try {
            status = 'SUCCESS';
            responseTime = Datetime.now();
            responseMessage = JSON.serialize(info);

            // 1. KEY : Type(입금계정), VALUE : Record
            Map<String, PaymentType__c> targetKeyMap = new Map<String, PaymentType__c>();
            for(PaymentType__c objType : [
                    SELECT Id, Type__c, fm_LeftAmount__c, DepositAmount__c, UpdateStage__c,
                            PaymentTracker__c, PaymentTracker__r.Opportunity__r.ContractId
                    FROM PaymentType__c
                    WHERE PaymentTracker__r.IsValid__c = TRUE
                    AND PaymentTracker__r.Opportunity__r.VirtualAccount__r.fm_VirtualAccount__c = :virtualAccountNumber
                    AND PaymentTracker__r.Account__r.BPCode__c = :BPCode
//                    AND fm_LeftAmount__c != 0
                    AND Type__c IN :TARGET_KEY_SET  // ver1.1 대출금 입금상태 반영로직 추가
                    ORDER BY Type__c
            ]) {
                if(paymentTrackerId == null) paymentTrackerId = objType.PaymentTracker__c;
                if(contractId == null) contractId = objType.PaymentTracker__r.Opportunity__r.ContractId;

                targetKeyMap.put(objType.Type__c, objType);
            }

            // 영업기회 / SA 비용관련 분기처리
            if(!targetKeyMap.isEmpty()) {
                // 2. 입금금액에 맞게 Payment Type 계정별 Update
                List<PaymentType__c> updateList = new List<PaymentType__c>();
                Boolean updateFlag = false;                 // 계약금 입금완료시
                Boolean loanClear = false;                  // ver1.1 대출금 입금상태 반영로직 추가
                String adjustStatus;                        // 최종반영 Status
                Integer adjustAmount = depositAmount;       // 입금금액 Start

                // 3. 금액처리
                // 3-1. 대출계정 처리
                // Capital에서 입금해준 금액으로 매핑이 아닌. 입금한 사람의 정보를 가지고 로직 필요하지 않나... 100분의 1의 확률로 사용자가 Capital의 금액을 입금하면 어떡하지
                PaymentType__c loanType = targetKeyMap.remove(LOAN_KEY);
                if (loanType.fm_LeftAmount__c == 0) loanClear = true;   // ver1.1 대출금 입금상태 반영로직 추가. 기반영건 확인

                if (!loanClear && adjustAmount.equals(loanType.fm_LeftAmount__c)) {
                    loanClear = true;   // ver1.1 대출금 입금상태 반영로직 추가. 신규입금건

                    loanType.DepositAmount__c = adjustAmount;
                    updateList.add(loanType);
                    adjustAmount = 0;   // 잔여금액 끝

                    // ver1.1 대출금 입금상태 반영로직 추가. 기 반영데이터 확인 -> Update
                    for (String targetKey : targetKeyMap.keySet()) {
                        PaymentType__c type = targetKeyMap.get(targetKey);

                        if (type.fm_LeftAmount__c == 0) {
                            adjustStatus = type.UpdateStage__c;                                     // 가장 마지막 UpdateStage 조회
                        } else {
                            if (OVER_PAID_KEY.equals(targetKey) && type.DepositAmount__c > 0) adjustStatus = 'OVER_PAID'; // 초과금 납부 Case
                            break;                                                                  // Update 대상 OUT
                        }
                    }
                }

                // 3-2. 대출계정 외 처리
                for (String targetKey : targetKeyMap.keySet()) {
                    PaymentType__c type = targetKeyMap.get(targetKey);

                    if (adjustAmount <= 0) break;               // 입금금액 소진시 End.
                    if (type.fm_LeftAmount__c == 0) continue;   // ver1.1 대출금 입금상태 반영로직 추가. 기 입금완료시 PASS
                    System.debug('잔여금액 : ' + adjustAmount);

                    // 계정별 금액 할당 Process
                    Integer leftAmount = Integer.valueOf(type.fm_LeftAmount__c);
                    Integer assignAmount = Math.min(leftAmount, adjustAmount);
                    type.DepositAmount__c += assignAmount;
                    updateList.add(type);
                    adjustAmount -= assignAmount;               // 잔여금액 반영(다음 Loop에서 사용)

                    // 납부금에 따른 Logic
                    if (OVER_PAID_KEY.equals(targetKey)) adjustStatus = 'OVER_PAID';                 // 초과금 납부 시작시
                    if (leftAmount.equals(assignAmount)) adjustStatus = type.UpdateStage__c;         // 계정별 납입금 완료시
                    if (adjustStatus != null && 'DEPOSIT'.equals(adjustStatus)) updateFlag = true;   // 계약금 완료시
                }

                paymentLog.PaymentTracker__c = paymentTrackerId;                                     // Process 완료 후 PaymentTracker 매핑처리
                if (!updateList.isEmpty()) update updateList;                                        // PaymentType Update(DepositAmount__c)
                if (
                    adjustStatus != null &&                         // 상태값 존재
                    (loanClear || 'DEPOSIT'.equals(adjustStatus))   // 대출완료 or 계약금 납입
                ) update new PaymentTracker__c(Id = paymentTrackerId, Status__c = adjustStatus);     // PaymentTracker Update(Status__c)
                if (updateFlag) StageUpdateCommonController.doUpdateOpportunity(contractId);         // 계약금 입금 확인. Opportunity Update
            }

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(responseMessage);
        } catch(Exception e) {
            status = 'ERROR';
            responseTime = Datetime.now();
            responseMessage = JSON.serialize(e.getMessage());

            response.responseBody = Blob.valueOf(JSON.serialize(e.getMessage()));
            response.statusCode = 500;
        } finally {
            IF_DTO.LogWrapper objLogWrapper = new IF_DTO.LogWrapper();

            objLogWrapper.requestTime = requestTime;
            objLogWrapper.requestBody = requestBody;
            objLogWrapper.status = status;
            objLogWrapper.responseTime = responseTime;
            objLogWrapper.responseBody = responseMessage;
            objLogWrapper.errorCode = String.valueOf(response.statusCode);
            objLogWrapper.logType = IF_DTO.LOG_TYPE.HEROKU_SAP_IN;

            CommonUtilCustomController.setLog(objLogWrapper);
            insert paymentLog;  // PaymentLog는 무조건 INSERT
        }
    }

    private static void asyncOrderConfirm() {
        String requestBody = request.requestBody.toString();
        System.debug(requestBody);

        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        String responseMessage;
        try {
            status = 'SUCCESS';
            responseTime = Datetime.now();
            responseMessage = JSON.serialize(requestMap);

            String status = String.valueOf(requestMap.get('Code')) == '0' ? 'Y' : 'C';
            String logId = String.valueOf(requestMap.get('LOG_ID'));
            String message = String.valueOf(requestMap.get('Message'));

            // LogDetail. 호출결과 Update
            List<IFAuditLogDetail__c> logDetailList = SAPCommon.fetchLogIdList(new List<String>{logId});
            for(IFAuditLogDetail__c logDetail : logDetailList) {

                logDetail.IsResponse__c = status;
                logDetail.Description__c = message;
            }
            if(!logDetailList.isEmpty()) update logDetailList;

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(responseMessage);
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
            objLogWrapper.logType = IF_DTO.LOG_TYPE.HEROKU_SAP_IN;

            CommonUtilCustomController.setLog(objLogWrapper);
        }
    }

    private static void asyncInvoiceConfirm() {
        String requestBody = request.requestBody.toString();
        System.debug(requestBody);

        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        String responseMessage;
        try {
            status = 'SUCCESS';
            responseTime = Datetime.now();
            responseMessage = JSON.serialize(requestMap);
            
            String status = String.valueOf(requestMap.get('Code')) == '0' ? 'Y' : 'C';
            String logId = String.valueOf(requestMap.get('LOG_ID'));
            String message = String.valueOf(requestMap.get('Message'));

            // LogDetail. 호출결과 Update
            List<IFAuditLogDetail__c> logDetailList = SAPCommon.fetchLogIdList(new List<String>{logId});
            for(IFAuditLogDetail__c logDetail : logDetailList) {

                logDetail.IsResponse__c = status;
                logDetail.Description__c = message;
            }
            if(!logDetailList.isEmpty()) update logDetailList;

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(responseMessage);
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
            objLogWrapper.logType = IF_DTO.LOG_TYPE.HEROKU_SAP_IN;

            CommonUtilCustomController.setLog(objLogWrapper);
        }
    }

    private static void asyncCustomsInfo() {
        String requestBody = request.requestBody.toString();
        System.debug(requestBody);

        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        String responseMessage;
        try {
            status = 'SUCCESS';
            responseTime = Datetime.now();
            responseMessage = JSON.serialize(requestMap);

            String status = String.valueOf(requestMap.get('Code')) == '0' ? 'Y' : 'C';
            String logId = String.valueOf(requestMap.get('LOG_ID'));
            String message = String.valueOf(requestMap.get('Message'));

            List<IFAuditLogDetail__c> logDetailList = SAPCommon.fetchLogIdList(new List<String>{logId});
            for(IFAuditLogDetail__c logDetail : logDetailList) {

                logDetail.IsResponse__c = status;
                logDetail.Description__c = message;
            }
            if(!logDetailList.isEmpty()) update logDetailList;

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(responseMessage);
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
            objLogWrapper.logType = IF_DTO.LOG_TYPE.HEROKU_SAP_IN;

            CommonUtilCustomController.setLog(objLogWrapper);
        }
    }
}