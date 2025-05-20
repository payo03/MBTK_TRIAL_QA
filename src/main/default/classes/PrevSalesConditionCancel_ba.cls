/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : PrevSalesConditionCancel_test
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-05-14      jh.jung           Created
*/

public with sharing class PrevSalesConditionCancel_ba implements Database.Batchable<SObject>, Database.Stateful {

    public Integer successCount = 0;
    public Integer failCount = 0;

    public Set<Id> contractIdSet = new Set<Id>();

    // start: 배치 대상 레코드 조회 (Quote)
    public Database.QueryLocator start(Database.BatchableContext bc) {

        // 조건: 세금계산서 날짜 없음, Closed Won 아님, Canceled 아님
        return Database.getQueryLocator([
            SELECT Id, OpportunityId, Status, ContractId
            FROM Quote
            WHERE Opportunity.TaxInvoiceDate__c = null
            AND Opportunity.StageName != 'Closed Won'
            AND Status != 'Canceled'
            ORDER BY CreatedDate ASC
        ]);
    }

    // execute: 배치 처리 로직 (Scope 단위 실행)
    public void execute(Database.BatchableContext bc, List<Quote> scope) {

        List<Quote> publishQuoteList = new List<Quote>();
        List<Quote> otherQuoteList = new List<Quote>();
        Set<Id> publishOpptyIdSet = new Set<Id>();

        for (Quote quoteObj : scope) {
            if (quoteObj.Status == 'Published') {
                // 받은 Quote 중 "Published" 상태인 것만 따로 모음
                publishQuoteList.add(quoteObj);
                publishOpptyIdSet.add(quoteObj.OpportunityId);
            } else {
                // 그 외 Quote는 상태를 "Canceled"로 바꿈
                quoteObj.Status = 'Canceled';
                otherQuoteList.add(quoteObj);
            }
        }

        Savepoint sp = Database.setSavepoint();

        try {
            // Published 견적 → Oppty 기준 재협상 처리
            if (!publishOpptyIdSet.isEmpty()) {
                List<Map<String, Object>> paramList = new List<Map<String, Object>>();
                for (Id opptyId : publishOpptyIdSet) {
                    Map<String, Object> paramMap = new Map<String, Object>();
                    paramMap.put('type', 'Renegotiation');
                    paramMap.put('opptyId', opptyId);
                    paramMap.put('selectedValues', null);
                    paramList.add(paramMap);
                }
                // 외부 로직 호출: Contract 취소 및 재협상 처리
                ContractCancelController.cancelByCaseList(paramList, true);
            }

            // 나머지 Quote → Canceled 상태로 업데이트
            if (!otherQuoteList.isEmpty()) {
                update otherQuoteList;
            }

            // 성공했다면 Cancel할 contract 목록에 추가
            for(Quote publishQuote : publishQuoteList) {
                contractIdSet.add(publishQuote.ContractId);
            }
            successCount++;
        } catch (Exception e) {
            Database.rollback(sp); // 롤백 수행
            System.debug('Rollback due to error: ' + e.getMessage());
            failCount++;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('PrevSalesConditionCancel_ba is finished');
        System.debug('successCount ::: ' + successCount);
        System.debug('failCount ::: ' + failCount);


        resultSendEmail();
        if(!contractIdSet.isEmpty())    moduSignCancelBatch();
    }

    // 취소 성공한 Publish Quote의 계약 캔슬
    private void moduSignCancelBatch() {
        String moduSignCondition = '' +
            'AND (Status__c != \'ABORTED\' OR Status__c != \'COMPLETED\') ' +
            'AND Contract__c IN ' + CommonUtilController.joinedString(contractIdSet);

        Database.executeBatch(new CancelRequestModuSign_ba(moduSignCondition), 4);
    }

    // 성공 및 실패시 프로젝트 팀 메일, 플래닝팀(OrderAdmin), 매니지먼트팀(MgmtAdmin)에 메일 전송
    private void resultSendEmail() {

        String subject;
        String emailBody;

        String SUCCESS_SUBJECT = '이전 판매조건으로 만들어진 견적 및 계약이 모두 취소 처리 되었습니다.';
        String FAIL_SUBJECT = '이전 판매조건으로 만들어진 견적 및 계약 취소가 일부 실패했습니다.';

        String SUCCESS_BODY =
            '안녕하세요,\n\n' +
                '이전 판매조건을 기준으로 생성된 견적 및 계약 건에 대해 시스템에서 모두 정상적으로 취소 처리가 완료되었습니다.\n\n' +
                '감사합니다.';

        String FAIL_BODY =
            '안녕하세요,\n\n' +
                '진행중인 견적/계약 자동취소 시스템에 오류가 발생했습니다.\n' +
                '이로 인해 취소되지 않은 견적/계약이 있습니다.\n\n' +
                '자세한 사항은 시스템관리자에게 문의 부탁드립니다.\n' +
                '감사합니다.';

        // 전부 성공
        if(failCount == 0) {
            subject = SUCCESS_SUBJECT;
            emailBody = SUCCESS_BODY;
        } else {
            subject = FAIL_SUBJECT;
            emailBody = FAIL_BODY;
        }

        List<PermissionSetAssignment> permissionSetAssignments = [
            SELECT Assignee.Id, Assignee.Name, Assignee.Email
            FROM PermissionSetAssignment
            WHERE (PermissionSet.Name = 'OrderAdmin' OR PermissionSet.Name = 'MgmtAdmin')
            AND Assignee.IsActive = true
        ];

        Set<String> userEmailSet = new Set<String>();

        // 팀메일은 고정으로 전달 받음
        userEmailSet.add('mtbk-sf@solomontech.net');

        for(PermissionSetAssignment psaObj : permissionSetAssignments) {
            userEmailSet.add(psaObj.Assignee.Email);
        }

        List<Map<String, Object>> mailInfoList = new List<Map<String, Object>>();

        Map<String, Object> mailInfo = new Map<String, Object>();
        mailInfo.put('subject', subject);
        mailInfo.put('body', emailBody);
        mailInfo.put('to', new List<String>(userEmailSet));

        mailInfoList.add(mailInfo);

        EmailConfigController.sendEmail(mailInfoList);
    }
}