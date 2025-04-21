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
        @AuraEnabled public String idNumber;

        public depositWrap(String accName, String accPhone, String vehicleName, String opportunity, String vehicleId, String bpCode, String businessName, String businessNumber, String idNumber) {
            this.accName = accName;
            this.accPhone = accPhone;
            this.vehicleName = vehicleName;
            this.opportunity = opportunity;
            this.vehicleId = vehicleId;
            this.bpCode = bpCode;
            this.businessName = businessName;
            this.businessNumber = businessNumber;
            this.idNumber = idNumber;
        }
    }

    @AuraEnabled
    public static List<depositWrap> getAcc(String recordId) {
        String selectFields = 'Id, Opportunity__c, Account.Name, Account.PersonMobilePhone, VehicleStock__r.Product__r.Name, VehicleStock__c, Account.BPCode__c, Account.BusinessName__c, Account.BusinessNumber__c, Account.IDNumber__pc';
        String whereConditions = 'Id = \'' + recordId + '\'';
        String query = CommonUtilController.buildQuery(selectFields, 'Contract', whereConditions);

        List<Contract> contractList = Database.query(query);

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
                contract.Account.BusinessNumber__c,
                contract.Account.IDNumber__pc
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

    @AuraEnabled
    public static void createAssignRequest(Map<String, String> inputMap) {
        String type = inputMap.get('type');
        String recordId = inputMap.get('recordId');
        Id userId = UserInfo.getUserId();

        AssignRequest__c par = new AssignRequest__c();
            
        if (type == 'deposit') {
            par.Opportunity__c = recordId;
            par.VehicleStock__c = inputMap.get('stockId');
            par.Type__c = '일반배정';
            par.Status__c = '승인';
            par.Submitter__c = userId;
            par.RequestDate__c = date.today();
            par.Payment__c = Decimal.valueOf(inputMap.get('deposit'));

            Contract c = new Contract();
            c.Id = inputMap.get('contractId');
            c.Deposit__c = Decimal.valueOf(inputMap.get('deposit'));
            update c;
        }
        
        insert par;
    }
}