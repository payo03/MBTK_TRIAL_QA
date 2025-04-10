/*************************************************************
 * @author : th.kim
 * @description : 매월 영업사원별 Stipend 생성 배치
 * @target : CreateStipendCommission_sc
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-04-01      th.kim          Created
**************************************************************/
public with sharing class CreateStipendCommission_ba implements Database.Batchable<SObject>, Database.Stateful {

    private static final Integer todayYear = Date.today().year();
    private static final Integer todayMonth = Date.today().month();
    private static final String todayYearStr = String.valueOf(todayYear);
    private static final String todayMonthStr = String.valueOf(todayMonth);

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id, Agency__c, fm_StipendAmount__c
            FROM User
            WHERE Profile.Name = 'MTBK Agent'
        ]);
    }

    public void execute(Database.BatchableContext bc, List<User> userList) {

        Set<Id> userIdSet = new Set<Id>();
        for (User user : userList) {
            userIdSet.add(user.Id);
        }

        // 영업사원, 날짜 기준 커미션 관리 가져오기
        List<CommissionManagement__c> commissionManagementList = [
            SELECT Id, Period__c, OwnerId
            FROM CommissionManagement__c
            WHERE OwnerId IN :userIdSet
            AND CALENDAR_YEAR(Period__c) = :todayYear
            AND CALENDAR_MONTH(Period__c) = :todayMonth
        ];

        Map<String, CommissionManagement__c> commissionManagementMap = CommissionManagementController.getCommissionManagementMap(commissionManagementList);

        Map<String, CommissionManagement__c> insertManagementMap = new Map<String, CommissionManagement__c>();
        for (User user : userList) {
            String key = user.Id + todayYearStr + todayMonthStr;
            // 커미션 관리 존재하지 않을 시 커미션 관리 생성
            if (!commissionManagementMap.containsKey(key)) {
                if (insertManagementMap.containsKey(key)) continue;
                insertManagementMap.put(key, new CommissionManagement__c(
                    OwnerId = user.Id,
                    Period__c = Date.newInstance(todayYear, todayMonth, 1)
                ));
            }
        }

        commissionManagementMap = CommissionManagementController.doInsertAndGetCommissionManagementMap(insertManagementMap, commissionManagementMap);

        List<CommissionHistory__c> commissionHistoryList = new List<CommissionHistory__c>();
        for (User user : userList) {
            commissionHistoryList.add(new CommissionHistory__c(
                ExternalKey__c = user.Id + todayYearStr + todayMonthStr + 'Stipend',
                CommissionManagement__c = commissionManagementMap.get(user.Id + todayYearStr + todayMonthStr).Id,
                Type__c = 'Stipend',
                StipendAmount__c = user.fm_StipendAmount__c
            ));
        }

        upsert commissionHistoryList ExternalKey__c;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('CreateStipendCommission_ba is finished');
    }
}