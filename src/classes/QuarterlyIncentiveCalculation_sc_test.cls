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
private class QuarterlyIncentiveCalculation_sc_test {

    @IsTest
    static void doTest() {
        Test.startTest();
        String cronExpression = '0 0 1 1 1,4,7,10 ?';

        // 스케줄러 등록
        String jobName = 'Quarterly Incentive Calculation Test';
        System.schedule(jobName, cronExpression, new QuarterlyIncentiveCalculation_sc());
        Test.stopTest();
    }
}