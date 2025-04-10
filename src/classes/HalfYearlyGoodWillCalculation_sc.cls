/*************************************************************
 * @author : chaebeom.do
 * @description : 매 반기에 반기별 굿윌 적립 배치 실행 스케줄러
                String cronExpression = '0 0 1 8 1,7 ?';

                // 스케줄러 등록
                String jobName = 'Half Yearly GoodWill Calculation Job';
                System.schedule(jobName, cronExpression, new HalfYearlyGoodWillCalculation_sc());

 * @target : 매 반기 (1월 or 7월, 8일, 오전 1:00)
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-14      chaebeom.do     Created
**************************************************************/
public with sharing class HalfYearlyGoodWillCalculation_sc implements Schedulable {

    public void execute(SchedulableContext sc) {
        HalfYearlyGoodWillCalculation_ba batch = new HalfYearlyGoodWillCalculation_ba(Date.today());
        Database.executeBatch(batch);
    }
}