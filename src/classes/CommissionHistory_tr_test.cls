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
private class CommissionHistory_tr_test {

    static final Contract contract;
    static final Opportunity opportunity;
    static final CommissionHistory__c history;

    static {
        contract = TestObjectBuilder.createContract();
        insert contract;
        opportunity = TestObjectBuilder.createOpportunity();
        opportunity.ContractId = contract.Id;
        update opportunity;
        history = TestObjectBuilder.createCommissionHistory();
    }

    @IsTest
    static void doTest() {
        Test.startTest();
        insert history;
        delete history;
        Test.stopTest();
    }
}