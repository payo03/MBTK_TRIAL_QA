/*************************************************************
 * @author : San.Kang
 * @date : 2025-01-15
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-01-15        San.Kang           Created
**************************************************************/
@IsTest
private class Contract_tr_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder.createObjects();
    }
    @IsTest
    static void testBehavior() {
        Test.startTest();
        Opportunity opportunityObj = [SELECT Id FROM Opportunity LIMIT 1];
        Account accountObj = [SELECT Id FROM Account LIMIT 1];
        Quote quoteObj = [SELECT Id FROM Quote LIMIT 1];
        Contract contractObj = new Contract();
            contractObj.Opportunity__c = opportunityObj.Id;
            contractObj.AccountId = accountObj.Id;
            contractObj.Quote__c = quoteObj.Id;
            contractObj.ApprovalStatus__c = '제출됨';
            contractObj.ConStatus__c = '승인 단계';
        insert contractObj;

        quoteObj.ContractId = contractObj.Id;
        update quoteObj;

        contractObj.ApprovalStatus__c = '반려됨';
        contractObj.ConStatus__c = '계약 취소';
        update contractObj;

        Contract contractObj2 = new Contract();
            contractObj2.Opportunity__c = opportunityObj.Id;
            contractObj2.AccountId = accountObj.Id;
            contractObj2.Quote__c = quoteObj.Id;
            contractObj2.ApprovalStatus__c = '제출됨';
            contractObj2.ConStatus__c = '승인 단계';
        insert contractObj2;

        quoteObj.ContractId = contractObj2.Id;
        update quoteObj;

        opportunityObj.ContractId = contractObj2.Id;
        update opportunityObj;

        contractObj2.ApprovalStatus__c = '승인됨';
        update contractObj2;

        Test.stopTest();
    }
}