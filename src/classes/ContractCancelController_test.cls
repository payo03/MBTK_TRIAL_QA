/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-03-28
 * @description : ContractCancelController의 test class
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-28      chaebeom.do     Created
**************************************************************/
@isTest
private class ContractCancelController_test {
    static final Opportunity opportunity;
    static final Contract contract;
    static final List<PDIStep__c> pdiStepList;

    static {
        TestObjectBuilder.createObjects();
        opportunity = TestObjectBuilder.opportunity;
        contract = TestObjectBuilder.contract;
        pdiStepList = TestObjectBuilder.pdiStepList;
    }

    @isTest
    static void testInit() {
        Test.startTest();
        ContractCancelController.init(opportunity.Id);
        Test.stopTest();
    }

    @isTest
    static void testCancelByCase1() {
        opportunity.ContractId = contract.Id;
        update opportunity;

        Test.startTest();
        ContractCancelController.cancelByCase('Renegotiation', opportunity.Id);
        Test.stopTest();
    }

    @isTest
    static void testCancelByCase2() {
        opportunity.ContractId = contract.Id;
        update opportunity;

        Test.startTest();
        ContractCancelController.cancelByCase('closedLost', opportunity.Id);
        Test.stopTest();
    }

    @isTest
    static void testCancelByCase3() {
        opportunity.ContractId = contract.Id;
        update opportunity;

        Test.startTest();
        ContractCancelController.cancelByCase('returnVehicle', opportunity.Id);
        Test.stopTest();
    }
}