/*************************************************************
 * @author : th.kim
 * @description : 
 * @target : 
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-04-08      th.kim          Created
**************************************************************/
@IsTest
private class IncentiveHistory_tr_test {

    static final IncentiveHistory__c INCENTIVE_HISTORY;
    static {
        TestObjectBuilder2.createContractBundle();
        INCENTIVE_HISTORY = TestObjectBuilder2.createIncentiveHistory();
    }

    @IsTest
    static void doTest() {
        Test.startTest();
        insert INCENTIVE_HISTORY;
        Test.stopTest();
    }
}