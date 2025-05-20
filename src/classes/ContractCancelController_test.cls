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
    static final Map<String, List<String>> selectedValue = new Map<String, List<String>>();

    static {
        TestObjectBuilder2.createContractBundle2();
        insert TestObjectBuilder2.createPaymentTracker();
        insert TestObjectBuilder2.createPaymentTypeList();
        insert TestObjectBuilder2.createPaymentLog();
        insert TestObjectBuilder2.createPDIStep();
        insert TestObjectBuilder2.createHandover();
        opportunity = TestObjectBuilder2.opportunity;
        contract = TestObjectBuilder2.contract;
        pdiStepList = TestObjectBuilder2.pdiStepList;
        List<String> value1 = new List<String>();
        value1.add('볼보 Volvo');
        List<String> value2 = new List<String>();
        value2.add('차량가격 Price');
        List<String> value3 = new List<String>();
        value3.add('브랜드 인지도 Brand Loyalty');
        List<String> value4 = new List<String>();
        value4.add('차량 스펙 Vehicle Specification');
        selectedValue.put('CompetitorSelection__c', value1);
        selectedValue.put('EconomicReasons__c', value2);
        selectedValue.put('PersonalReasons__c', value3);
        selectedValue.put('TechnicalReasons__c', value4);
        // selectedValue.put('LostReasonType__c', value4);
        // selectedValue.put('LostReasonText__c', value4);
    }

    @isTest
    static void testInit() {
        Test.startTest();
        ContractCancelController.init(opportunity.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetPicklistValues() {
        List<String> fieldNames = new List<String>();
        fieldNames.add('CompetitorSelection__c');
        fieldNames.add('EconomicReasons__c');
        fieldNames.add('PersonalReasons__c');
        fieldNames.add('TechnicalReasons__c');

        Test.startTest();
        ContractCancelController.getPicklistValues('Opportunity', fieldNames);
        Test.stopTest();
    }

    @isTest
    static void testCancelByCase1() {
        opportunity.ContractId = contract.Id;
        update opportunity;

        Test.startTest();
        ContractCancelController.cancelByCase('Renegotiation', opportunity.Id, selectedValue);
        Test.stopTest();
    }

    @isTest
    static void testCancelByCase2() {
        opportunity.ContractId = contract.Id;
        update opportunity;

        Test.startTest();
        ContractCancelController.cancelByCase('closedLost', opportunity.Id, selectedValue);
        Test.stopTest();
    }

    @isTest
    static void testCancelByCase3() {
        opportunity.ContractId = contract.Id;
        update opportunity;

        Test.startTest();
        ContractCancelController.cancelByCase('returnVehicle', opportunity.Id, selectedValue);
        Test.stopTest();
    }
}