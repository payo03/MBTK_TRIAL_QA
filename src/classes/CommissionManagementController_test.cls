/*************************************************************
 * @author : th.kim
 * @description : 
 * @target : 
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-04-01      th.kim          Created
**************************************************************/
@IsTest
private class CommissionManagementController_test {
    static final Opportunity opportunity;
    static final Quote quote;
    static final Contract contract;
    static final CommissionHistory__c history;
    static {
        contract = TestObjectBuilder.createContract();
        insert contract;
        opportunity = TestObjectBuilder.createOpportunity();
        opportunity.ContractId = contract.Id;
        update opportunity;
        quote = TestObjectBuilder.createQuote();
        history = TestObjectBuilder.createCommissionHistory();
    }

    @IsTest
    static void testCreateCommissionHistory() {
        Test.startTest();
        Set<Id> opportunityIdSet = new Set<Id>{opportunity.Id};
        CommissionManagementController.createCommissionHistory(opportunityIdSet, false);
        CommissionManagementController.createCommissionHistory(opportunityIdSet, true);
        CommissionManagementController.deleteCommissionHistory(opportunityIdSet);
        Test.stopTest();
    }
}