/*************************************************************
 * @author : th.kim
 * @description : 매월 1일 오전 1시에 Stipend 커미션 생성 배치 실행 스케줄러
 *              String cron = '0 0 1 1 * ? *';
 *              System.schedule('Create Stipend Commission', cron, new CreateStipendCommission_sc());
 * @target : 매월 1일 오전 1시
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-04-01      th.kim          Created
**************************************************************/
public with sharing class CreateStipendCommission_sc implements Schedulable {

    public void execute(SchedulableContext sc) {

        CreateStipendCommission_ba batch = new CreateStipendCommission_ba();
        Database.executeBatch(batch);
    }
}