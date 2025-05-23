/**
* @Author            : payo03@solomontech.net
* @Description 		 : 승인 프로세스 요청
* @Target            : vatDeferralRequest
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-07      payo03@solomontech.net           Created
*/
public with sharing class FinancialDefermentRequest {

    @AuraEnabled
    public static Opportunity screenInit(String recordId) {
        return fetchOpportunity(recordId);
    }

    @AuraEnabled
    public static Map<String, Object> requestDeferred(Map<String, String> paramMap) {
        Map<String, Object> resultMap = new Map<String, Object>();

        String recordId = paramMap.get('recordId');
        String apiName = paramMap.get('apiName');
        String updateField = paramMap.get('updateField');
        String deferredAmount = paramMap.get('deferredAmount');
        String contractAmount = paramMap.get('contractAmount');
        String comment = paramMap.get('comment');

        Opportunity opportunity = fetchOpportunity(recordId);
        /* TODO : 필요여부 확인
        Boolean isEqualUser = opportunity.OwnerId.equals(UserInfo.getUserId());
        resultMap.put('isEqualUser', isEqualUser);
        */
        paramMap.put('opportunityName', opportunity.Name);

        Savepoint sp = Database.setSavepoint();
        try {
            opportunity.ContractAmount__c = Decimal.valueOf(contractAmount);
            opportunity.VATRequestDays__c = paramMap.containsKey('requestDays') ?
                    Decimal.valueOf(paramMap.get('requestDays'))
                    : null;
            opportunity.put(updateField, Decimal.valueOf(deferredAmount));
            update opportunity;

            /*
                2025-01-15 김현아책임 요청.
                Q. 찬영님 부가세 후취 요청 버튼 눌렀을 때 제가 기회에 안보이는 필드로 [요청 금액] 필드 넣어두면 그쪽에 이 금액을 업데이트해주실 수 있나요?
                    승인프로세스 호출하기 전에요
                A. 1. 버튼 클릭
                   2. 필드값 Update
                   이렇게 말씀하시는거죠??
                Q. 정확히는 요청 버튼 눌렀을때 필드값 업데이트 > 승인프로세스 호출 이렇게요
                    요청하기전엔 안되어도 됩니다
            */
            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();

            request.setObjectId(recordId);
            request.setSubmitterId(UserInfo.getUserId());
            request.setProcessDefinitionNameOrId(apiName);
            request.setComments(comment);

            Approval.ProcessResult result = Approval.process(request);
            resultMap.put('isSuccess', result.success);

            DefermentRequest__c defermentRequest = createDefermentRequest(paramMap);
            insert defermentRequest;
        } catch (Exception e) {
            Database.rollback(sp);
            String message = e.getMessage();
            message = message.substring(message.indexOf(';') + 1);
            if(message.contains('ALREADY_IN_PROCESS')) message = '기 승인요청 Process가 존재합니다';

            resultMap.put('isSuccess', false);
            resultMap.put('message', message);
        }

        return resultMap;
    }

    public static DefermentRequest__c createDefermentRequest(Map<String, String> paramMap) {
        DefermentRequest__c request = new DefermentRequest__c();

        String recordId = paramMap.get('recordId');
        String quoteId = paramMap.get('quoteId');
        String apiName = paramMap.get('apiName');
        String opportunityName = paramMap.get('opportunityName');

        Boolean isCheck = Boolean.valueOf(paramMap.get('isCheck'));
        Decimal deferredAmount = Decimal.valueOf(paramMap.get('deferredAmount'));
        Integer requestDays = paramMap.containsKey('requestDays') ? Integer.valueOf(paramMap.get('requestDays')) : null;
        Date requestDueDate = paramMap.containsKey('requestDueDate') ? Date.valueOf(paramMap.get('requestDueDate')) : null;

        request.Opportunity__c = recordId;
        request.Quote__c = quoteId;
        request.Name = opportunityName;
        request.Type__c = apiName;
        request.DeferredAmount__c = deferredAmount;
        request.RequestDate__c = Date.today();
        request.Status__c = 'IN_PROGRESS';
        request.isCheck__c = isCheck;

        request.RequestDueDate__c = requestDueDate;
        request.RequestDays__c = requestDays;

        return request;
    }

    private static Opportunity fetchOpportunity(String recordId) {
        return [
            SELECT Id, OwnerId, Name, ContractAmount__c, TaxDeferredAmount__c, PaymentDeferredAmount__c,
            (
                SELECT Id, Name, Status, fm_DeliveryPrice__c,
                        fm_TotalRealAndSpecialPrice__c, fm_RealSellAmt__c, fm_MAXTaxDeferredAmount__c,
                        Product__r.Name, toLabel(Product__r.Segment2__c)
                FROM Quotes
                WHERE Status != 'Canceled'
                ORDER BY LastModifiedDate DESC
            ),(
                SELECT Id, Type__c, Quote__c
                FROM DefermentRequest__r
                WHERE Status__c = 'COMPLETED'
            )
            FROM Opportunity
            WHERE Id =: recordId
        ];
    }
}