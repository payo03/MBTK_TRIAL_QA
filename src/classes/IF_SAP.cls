/**
* @Author            : payo03@solomontech.net
* @Description 		 : SAP > Heroku > SFDC Interface
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-08      payo03@solomontech.net           Created
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

        switch on pathCase {
            // 재고이동 결과조회. 현재 미사용
            when 'sms005' { stockResult(); }
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

    private static void stockResult() {
        response.addHeader('Content-Type', 'application/json');
        String requestBody = request.requestBody.toString();
        System.debug(requestBody);

        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        String responseMessage;
        try {
            status = 'SUCCESS';
            responseTime = Datetime.now();
            responseMessage = JSON.serialize(requestMap);

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

    // 금액 Update. 수신이 아닌 송신 Response로 진행해야함
    private static void updateAmount() {
        final String LOAN_KEY = '99_LOAN';
        final String SUBVENTION_KEY = '99_SUBVENTION';
        final String CAMPAIGN_KEY = '99_CAMPAIGN';
        final Set<String> PASS_KEY_SET = new Set<String>{LOAN_KEY, SUBVENTION_KEY, CAMPAIGN_KEY};
        
        response.addHeader('Content-Type', 'application/json');
        String requestBody = request.requestBody.toString();
        System.debug(requestBody);

        IF_DTO.PaymentDetailInfo info = (IF_DTO.PaymentDetailInfo) JSON.deserialize(requestBody, IF_DTO.PaymentDetailInfo.class);
        Integer loanAmount = 0;
        String responseMessage;
        String paymentTrackerId;
        String contractId;

        PaymentLog__c paymentLog = new PaymentLog__c();
        try {
            status = 'SUCCESS';
            responseTime = Datetime.now();
            responseMessage = JSON.serialize(info);

            String virtualAccountNumber = info.acc_no;
            String documentId = info.doc_num;
            String bpCode = info.card_cd;
            Integer depositAmount = Integer.valueOf(info.doc_total);

            // log는 무조건 Insert
            paymentLog.Name = CommonUtilController.formatDate(Datetime.now(), 'C') + '_' + virtualAccountNumber;
            paymentLog.Amount__c = depositAmount;
            paymentLog.InternalDocumentId__c = documentId;
            paymentLog.PaymentTracker__c = TRACKER_ID;   // Dummy용 데이터. 오류없을시 finally에서 실데이터로 매핑

            // 1. Update될 PaymentType조회
            VirtualAccount__c vAccount = [
                    SELECT Id, fm_VirtualAccount__c, Opportunity__c, Account__c
                    FROM VirtualAccount__c
                    WHERE fm_VirtualAccount__c = :virtualAccountNumber
                    AND Account__r.BPCode__c = :bpCode
            ];

            Map<String, PaymentType__c> keyMap = new Map<String, PaymentType__c>();
            for(PaymentType__c objType : [
                    SELECT Id, Type__c, RequestAmount__c, DepositAmount__c, UpdateStage__c, fm_LeftAmount__c,
                            PaymentTracker__c, PaymentTracker__r.Opportunity__r.ContractId
                    FROM PaymentType__c
                    WHERE PaymentTracker__r.Opportunity__c = :vAccount.Opportunity__c
                    AND PaymentTracker__r.IsValid__c = TRUE
                    AND fm_LeftAmount__c != 0
                    ORDER BY Type__c
            ]) {
                if(paymentTrackerId == null) paymentTrackerId = objType.PaymentTracker__c;
                if(contractId == null) contractId = objType.PaymentTracker__r.Opportunity__r.ContractId;
                if(objType.Type__c.equals(LOAN_KEY)) loanAmount = Integer.valueOf(objType.RequestAmount__c);

                keyMap.put(objType.Type__c, objType);
            }

            // 2. 입금금액에 맞게 Payment Type 계정별 Update
            List<PaymentType__c> updateList = new List<PaymentType__c>();
            Boolean updateFlag = false;                 // 계약금 입금완료시
            String adjustStatus;                        // 최종반영 Status
            Integer adjustAmount = depositAmount;       // 입금금액 Start

            // 대출계정 처리
            for(String key : PASS_KEY_SET) {
                // 대출금 Case. 입금금액 = 대출금액
                // Capital에서 입금해준 금액으로 매핑이 아닌. 입금한 사람의 정보를 가지고 로직 필요하지 않나... 100분의 1의 확률로 사용자가 Capital의 금액을 입금하면 어떡하지

                if(key.equals(LOAN_KEY) && adjustAmount.equals(loanAmount)) {
                    PaymentType__c obj = keyMap.get(key);
                    obj.DepositAmount__c = adjustAmount;
                    updateList.add(obj);

                    // 잔여금액 끝
                    adjustAmount = 0;
                }
                keyMap.remove(key);
            }

            // 대출계정 외 처리
            for(String key : keyMap.keySet()) {
                // 입금금액 소진시 End.
                if(adjustAmount <= 0) break;

                PaymentType__c obj = keyMap.get(key);
                System.debug('잔여금액 : ' + adjustAmount);

                // 계정별 금액 할당 Process
                Integer leftAmount = Integer.valueOf(obj.fm_LeftAmount__c);
                Integer assignAmount = Math.min(leftAmount, adjustAmount);
                obj.DepositAmount__c += assignAmount;
                updateList.add(obj);

                // 잔여금액 반영(다음 Loop에서 사용)
                adjustAmount -= assignAmount;

                // 납부금에 따른 Logic
                if('5_OVER_PAID'.equals(key)) adjustStatus = 'OVER_PAID';                       // 초과금 납부 시작시
                if(leftAmount.equals(assignAmount)) adjustStatus = obj.UpdateStage__c;          // 계정별 납입금 완료시
                if(adjustStatus != null && 'DEPOSIT'.equals(adjustStatus)) updateFlag = true;   // 계약금 완료시
            }
            paymentLog.PaymentTracker__c = paymentTrackerId;

            if(!updateList.isEmpty()) update updateList;    // PaymentType Update
            if(adjustStatus != null) update new PaymentTracker__c(Id = paymentTrackerId, Status__c = adjustStatus); // PaymentTracker Update
            if(updateFlag) StageUpdateCommonController.doUpdateOpportunity(contractId); // 계약 및 입금완료 확인. Opportunity Update

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
        response.addHeader('Content-Type', 'application/json');
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
        response.addHeader('Content-Type', 'application/json');
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
        response.addHeader('Content-Type', 'application/json');
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