/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-03-28
 * @description : HalfYearlyGoodWillCalculation_sc의 test class
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-28      chaebeom.do     Created
**************************************************************/
@isTest
private class HalfYearlyGoodWillCalculation_sc_test {

    @IsTest
    static void doTest() {
        Test.startTest();

        String cronExpression = '0 0 1 8 1,7 ?';

        // 스케줄러 등록
        String jobName = 'HalfYearly GoodWill Calculation Test';
        System.schedule(jobName, cronExpression, new HalfYearlyGoodWillCalculation_sc());

        Test.stopTest();
    }
}