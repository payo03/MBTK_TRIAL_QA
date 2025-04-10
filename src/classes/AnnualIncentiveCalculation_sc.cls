/*************************************************************
 * @author : th.kim
 * @description : 매년 초에 이전 년도의 영업사원별 인센티브 계산 배치 실행 스케줄러
                String cronExpression = '0 0 1 1 1 ? *;

                // 스케줄러 등록
                String jobName = 'Annual Incentive Calculation';
                System.schedule(jobName, cronExpression, new AnnualIncentiveCalculation_sc());
 * @target : 매년 초 (1월 1일 오전 1:00)
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-13      th.kim          Created
**************************************************************/
public with sharing class AnnualIncentiveCalculation_sc implements Schedulable {

    public void execute(SchedulableContext sc) {

        // 매년 초 이전 년도 계산하기 위해 전년도 가져오기
        AnnualIncentiveCalculation_ba batch = new AnnualIncentiveCalculation_ba(Date.today().addYears(-1));
        Database.executeBatch(batch);
    }
}