/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-03
 * @description : 사전배정 & Deposit 요청시 필요한 레코드 정보 가져오기
 * @target : preAllocation.js, depositInvoice.js
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-03      chaebeom.do     Created
 * 2.0          2025-03-14      chaebeom.do     사전배정 프로세스 삭제로 인한 이름 변경
**************************************************************/
public with sharing class CreateAssignRequestController {
    public class depositWrap {
        @AuraEnabled public String accName;
        @AuraEnabled public String accPhone;
        @AuraEnabled public String vehicleName;
        @AuraEnabled public String opportunity;
        @AuraEnabled public String vehicleId;
        @AuraEnabled public String bpCode;
        @AuraEnabled public String businessName;
        @AuraEnabled public String businessNumber;

        public depositWrap(String accName, String accPhone, String vehicleName, String opportunity, String vehicleId, String bpCode, String businessName, String businessNumber) {
            this.accName = accName;
            this.accPhone = accPhone;
            this.vehicleName = vehicleName;
            this.opportunity = opportunity;
            this.vehicleId = vehicleId;
            this.bpCode = bpCode;
            this.businessName = businessName;
            this.businessNumber = businessNumber;
        }
    }

    @AuraEnabled
    public static List<depositWrap> getAcc(String recordId) {
        String selectFields = 'Id, Opportunity__c, Account.Name, Account.PersonMobilePhone, VehicleStock__r.Product__r.Name, VehicleStock__c, Account.BPCode__c, Account.BusinessName__c, Account.BusinessNumber__c';
        String whereConditions = 'Id = \'' + recordId + '\'';
        String query = CommonUtilController.buildQuery(selectFields, 'Contract', whereConditions);

        List<Contract> contractList = Database.query(query);

        System.debug('recordId::: ' + recordId);
        System.debug('contractList::: ' + contractList);

        List<depositWrap> preAlloWrapList = new List<depositWrap>();
        for(Contract contract : contractList) { 
                depositWrap preAlloWrap = new depositWrap(
                contract.Account.Name,
                contract.Account.PersonMobilePhone,
                contract.VehicleStock__r.Product__r.Name,
                contract.Opportunity__c,
                contract.VehicleStock__c,
                contract.Account.BPCode__c,
                contract.Account.BusinessName__c,
                contract.Account.BusinessNumber__c
                );
            preAlloWrapList.add(preAlloWrap);
        }
        return preAlloWrapList;
    }

    @AuraEnabled
    public static List<Quote> getQuote(String recordId) {
        String selectFields = 'Id, OpportunityId, AccountId, Product__c, VehicleStock__c';
        String whereConditions = 'Id = \'' + recordId + '\'';
        String query = CommonUtilController.buildQuery(selectFields, 'Quote', whereConditions);

        List<Quote> quoteList = Database.query(query);
    
        return quoteList;
    }

    // //진행중인 승인 프로세스 있는지 확인
    // @AuraEnabled
    // public static Boolean getPreAllocationStatus(String recordId) {
    //     List<Quote> q = getQuote(recordId);
    //     String selectFields = 'Id, PreAllocationHistory__c';
    //     String whereConditions = 'Id = \'' + q[0].OpportunityId + '\'';
    //     String query = CommonUtilController.buildQuery(selectFields, 'Opportunity', whereConditions);

    //     List<Opportunity> approvalList = Database.query(query);

    //     if (approvalList[0].PreAllocationHistory__c == '제출됨' || approvalList[0].PreAllocationHistory__c == '배정됨') {
    //         return true;
    //     } else {
    //         return false;
    //     }
    // }

    // //승인 프로세스 생성 및 사전배정요청 레코드 생성
    // @AuraEnabled
    // public static String createApprovalProcess(Map<String, String> inputMap) {
    //     createAssignRequest(inputMap);

    //     // Create an approval request for the account
    //     Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
    //     req1.setComments(inputMap.get('comment'));
    //     req1.setObjectId(inputMap.get('recordId'));
    //     // Submit the record to the existing process named PTO_Reqwuest_Process
    //     req1.setProcessDefinitionNameOrId('Pre_Allocation');
    //     // Submit the approval request for the account
    //     Approval.ProcessResult result = Approval.process(req1);
    //     return '승인 요청이 완료되었습니다.';
    // }

    @AuraEnabled
    public static void createAssignRequest(Map<String, String> inputMap) {
        String type = inputMap.get('type');
        String recordId = inputMap.get('recordId');
        Id userId = UserInfo.getUserId();

        AssignRequest__c par = new AssignRequest__c();
        // VehicleStock__c vs = new VehicleStock__c();
            
        if (type == 'deposit') {
            par.Opportunity__c = recordId;
            par.VehicleStock__c = inputMap.get('stockId');
            par.Type__c = '일반배정';
            par.Status__c = '승인';
            par.Submitter__c = userId;
            par.RequestDate__c = date.today();
            par.Payment__c = Decimal.valueOf(inputMap.get('deposit'));

            // vs.Id = inputMap.get('stockId');
            // vs.AssignmentStatus__c = '배정 요청중';

            Contract c = new Contract();
            c.Id = inputMap.get('contractId');
            c.Deposit__c = Decimal.valueOf(inputMap.get('deposit'));
            update c;
        }
        // } else if (type == 'preAllocation') {
        //     List<Quote> q = getQuote(inputMap.get('recordId'));
        //     // QuoteLineItem ql = [SELECT Product2Id FROM QuoteLineItem WHERE QuoteId = :recordId];
        //     // String stockId = getVehicleStock(q[0].Product__c);

        //     par.Opportunity__c = q[0].OpportunityId;
        //     par.VehicleStock__c = q[0].VehicleStock__c;
        //     // par.VehicleStock__c = stockId;
        //     par.Type__c = '사전배정';
        //     par.Status__c = '제출';
        //     par.Submitter__c = userId;
        //     par.RequestDate__c = date.today();
        //     par.Payment__c = Decimal.valueOf(inputMap.get('deposit'));

        //     vs.Id = q[0].VehicleStock__c;
        //     // vs.Id = stockId;
        //     vs.AssignmentStatus__c = '배정 요청중';

        //     Opportunity opp = new Opportunity();
        //     opp.Id = q[0].OpportunityId;
        //     opp.PreAllocationHistory__c = '제출됨';
        //     update opp;
        // }
        insert par;
        // update vs;
    }
}