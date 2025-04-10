/*************************************************************
 * @author : th.kim
 * @description : 매 분기에 분기별 인센티브 계산 배치 실행 스케줄러
                String cronExpression = '0 0 1 1 1,4,7,10 ?';

                // 스케줄러 등록
                String jobName = 'Quarterly Incentive Calculation';
                System.schedule(jobName, cronExpression, new QuarterlyIncentiveCalculation_sc());

 * @target : 매 분기 (1월, 4월, 7월, 10월, 1일, 오전 1:00)
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-12      th.kim          Created
**************************************************************/
public with sharing class QuarterlyIncentiveCalculation_sc implements Schedulable {

    public void execute(SchedulableContext sc) {

        // 분기 종료 후 다음 달 1일에 실행하기 때문에 이전달 분기 기준으로 가져오기 위해 이전달 가져오기
        QuarterlyIncentiveCalculation_ba batch = new QuarterlyIncentiveCalculation_ba(Date.today().addMonths(-1));
        Database.executeBatch(batch);
    }
}