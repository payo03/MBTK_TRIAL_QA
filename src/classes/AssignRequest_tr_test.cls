/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-23
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-23      chaebeom.do     Created
 * 2.0          2025-03-14      chaebeom.do     사전배정 프로세스 삭제로 인한 이름 변경
**************************************************************/
@isTest
private class AssignRequest_tr_test {
    
    static final Opportunity Opportunity;
    static final Contract Contract;
    static final VehicleStock__c Stock;
    static final VirtualAccountMaster__c VaccMs;
    static final VirtualAccount__c virtualAccount;

    static {
        TestObjectBuilder.createObjects();
        Contract = TestObjectBuilder.contract;
        Opportunity = TestObjectBuilder.opportunity;
        Stock = TestObjectBuilder.vehicleStock;
        VaccMs = TestObjectBuilder.virtualAccountMaster;
        virtualAccount = TestObjectBuilder.virtualAccount;
    }


    @isTest
    static void depositTest() {
        Test.startTest();
        Opportunity.ContractId = Contract.Id;
        update Opportunity;
        AssignRequest__c depositReq = new AssignRequest__c();
            depositReq.Opportunity__c = Opportunity.Id;
            depositReq.VehicleStock__c = Stock.Id;
            depositReq.Type__c = '일반배정';
            depositReq.Status__c = '승인';
            depositReq.RequestDate__c = date.today();
            depositReq.Payment__c = 1000000;
        insert depositReq;
        Test.stopTest();
    }

    @isTest
    static void depositTest2() {
        Test.startTest();
        Opportunity.ContractId = Contract.Id;
        update Opportunity;
        virtualAccount.Opportunity__c = Opportunity.Id;
        virtualAccount.IsValid__c = true;
        update virtualAccount;
        AssignRequest__c depositReq = new AssignRequest__c();
            depositReq.Opportunity__c = Opportunity.Id;
            depositReq.VehicleStock__c = Stock.Id;
            depositReq.Type__c = '일반배정';
            depositReq.Status__c = '승인';
            depositReq.RequestDate__c = date.today();
            depositReq.Payment__c = 1000000;
        insert depositReq;
        Test.stopTest();
    }

    // @isTest
    // static void preAssignTest() {
    //     Test.startTest();
    //     AssignRequest__c preAssignReq = new AssignRequest__c();
    //         preAssignReq.Opportunity__c = Opportunity.Id;
    //         preAssignReq.VehicleStock__c = Stock.Id;
    //         preAssignReq.Type__c = '사전배정';
    //         preAssignReq.Status__c = '제출';
    //         preAssignReq.RequestDate__c = date.today();
    //         preAssignReq.Payment__c = 1000000;
    //     insert preAssignReq;

    //     preAssignReq.Status__c = '승인';
    //     update preAssignReq;
    //     Test.stopTest();
    // }
}