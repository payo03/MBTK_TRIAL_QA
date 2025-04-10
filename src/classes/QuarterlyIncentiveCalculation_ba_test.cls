/*************************************************************
 * @author : th.kim
 * @description : 
 * @target : 
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-26      th.kim          Created
**************************************************************/
@IsTest
private class QuarterlyIncentiveCalculation_ba_test {

    static {
        insert TestObjectBuilder.createOpportunity();
        insert TestObjectBuilder.createIncentiveTargetMaster();
    }

    @IsTest
    static void doTest() {
        Test.startTest();
        Database.executeBatch(new QuarterlyIncentiveCalculation_ba(Date.today()));
        Test.stopTest();
    }
}