/*************************************************************
 * @author : th.kim
 * @description : 커미션 내역, 커미션 관리 생성 및 삭제 컨트롤러
 * @target : VehicleStock_tr, PaymentTracker_tr, CreateStipendCommission_ba
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-04-01      th.kim          Created
**************************************************************/
public with sharing class CommissionManagementController {

    /**
     * @author th.kim
     * @description 커미션 내역 생성
     * @param opportunityIdSet 기회 Id Set
     * @param IsVATDeferred 부가세 후취 레코드 생성 여부
     */
    @Future
    public static void createCommissionHistory(Set<Id> opportunityIdSet, Boolean IsVATDeferred) {

        List<Opportunity> opportunityList = [
            SELECT Id, HandoverDate__c, OwnerId, VATDefermentStatus__c
            FROM Opportunity
            WHERE Id IN :opportunityIdSet
        ];

        Integer todayYear = Date.today().year();
        Integer todayMonth = Date.today().month();
        Set<Id> ownerIdSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Integer> monthSet = new Set<Integer>();
        for (Opportunity opportunity : opportunityList) {
            // 차량에 연결된 기회 맵
            ownerIdSet.add(opportunity.OwnerId);
            if (!IsVATDeferred) {
                if (opportunity.HandoverDate__c == null) continue;
                yearSet.add(opportunity.HandoverDate__c.year());
                monthSet.add(opportunity.HandoverDate__c.month());
            } else {
                yearSet.add(todayYear);
                monthSet.add(todayMonth);
            }
        }

        // 영업사원, 날짜 기준 커미션 관리 가져오기
        List<CommissionManagement__c> commissionManagementList = [
            SELECT Id, Period__c, OwnerId
            FROM CommissionManagement__c
            WHERE OwnerId IN :ownerIdSet
            AND CALENDAR_YEAR(Period__c) IN :yearSet
            AND CALENDAR_MONTH(Period__c) IN :monthSet
        ];

        // 기존 커미션 관리 맵
        Map<String, CommissionManagement__c> commissionManagementMap = getCommissionManagementMap(commissionManagementList);

        Map<String, CommissionManagement__c> insertManagementMap = new Map<String, CommissionManagement__c>();
        for (Opportunity opportunity : opportunityList) {
            if (!IsVATDeferred) {
                // 출고일 예외 체크
                if (opportunity.HandoverDate__c == null) continue;
            }
            Integer handoverYear = IsVATDeferred ? todayYear : opportunity.HandoverDate__c.year();
            Integer handoverMonth = IsVATDeferred ? todayMonth : opportunity.HandoverDate__c.month();
            String key = opportunity.OwnerId + String.valueOf(handoverYear) + String.valueOf(handoverMonth);

            // 커미션 관리 존재하지 않을 시 커미션 관리 생성
            if (!commissionManagementMap.containsKey(key)) {
                if (insertManagementMap.containsKey(key)) continue;
                insertManagementMap.put(key, new CommissionManagement__c(
                    OwnerId = opportunity.OwnerId,
                    Period__c = Date.newInstance(handoverYear, handoverMonth, 1)
                ));
            }
        }

        // 새 커미션 관리 생성 및 맵 가져오기
        commissionManagementMap = doInsertAndGetCommissionManagementMap(insertManagementMap, commissionManagementMap);

        List<CommissionHistory__c> commissionHistoryList = new List<CommissionHistory__c>();
        for (Opportunity opportunity : opportunityList) {

            if (!IsVATDeferred) {
                // 출고일 예외 체크
                if (opportunity.HandoverDate__c == null) continue;
            }

            String handoverYear = String.valueOf(IsVATDeferred ? todayYear : opportunity.HandoverDate__c.year());
            String handoverMonth = String.valueOf(IsVATDeferred ? todayMonth : opportunity.HandoverDate__c.month());

            commissionHistoryList.add(new CommissionHistory__c(
                ExternalKey__c = opportunity.OwnerId + handoverYear + handoverMonth + opportunity.Id + (IsVATDeferred ? 'FinishedDefermentVAT' : opportunity.VATDefermentStatus__c == '승인됨' ? 'DefermentVAT' : 'Complete'),
                CommissionManagement__c = commissionManagementMap.get(opportunity.OwnerId + handoverYear + handoverMonth).Id,
                Opportunity__c = opportunity.Id,
                Type__c = IsVATDeferred ? 'FinishedDefermentVAT' : null
            ));
        }

        upsert commissionHistoryList ExternalKey__c;
    }

    /**
     * @author th.kim
     * @description 기존 커미션 관리 Map 데이터로 가져오기
     * @param commissionManagementList 커미션관리 리스트
     *
     * @return 커미션 관리 키 맵
     */
    public static Map<String, CommissionManagement__c> getCommissionManagementMap(List<CommissionManagement__c> commissionManagementList) {

        Map<String, CommissionManagement__c> commissionManagementMap = new Map<String, CommissionManagement__c>();
        for (CommissionManagement__c commissionManagement : commissionManagementList) {
            // 영업사원, 날짜별 커미션 관리 put
            commissionManagementMap.put(
                commissionManagement.OwnerId + String.valueOf(commissionManagement.Period__c.year()) + String.valueOf(commissionManagement.Period__c.month()),
                commissionManagement
            );
        }

        return commissionManagementMap;
    }

    /**
     * @author th.kim
     * @description 1. 커미션 관리 기존에 존재하지 않을 시 커미션 관리 생성
     *              2. 생성 후 커미션 관리 맵에 넣어주기
     * @param insertManagementMap 생성할 커미션 관리
     * @param commissionManagementMap 리턴할 커미션 관리
     *
     * @return 커미션 관리 키 맵
     */
    public static Map<String, CommissionManagement__c> doInsertAndGetCommissionManagementMap(Map<String, CommissionManagement__c> insertManagementMap, Map<String, CommissionManagement__c> commissionManagementMap) {

        if (!insertManagementMap.isEmpty()) {
            insert insertManagementMap.values();
            for (CommissionManagement__c commissionManagement : insertManagementMap.values()) {
                // 새로 생성된 영업사원, 날짜별 커미션 관리 put
                commissionManagementMap.put(
                    commissionManagement.OwnerId + String.valueOf(commissionManagement.Period__c.year()) + String.valueOf(commissionManagement.Period__c.month()),
                    commissionManagement
                );
            }
        }
        return commissionManagementMap;
    }

    /**
     * @author th.kim
     * @description 커미션 내역 삭제
     * @param opportunityIdSet 삭제할 Opportunity Id
     */
    public static void deleteCommissionHistory(Set<Id> opportunityIdSet) {

        List<CommissionHistory__c> deleteHistoryList = [
            SELECT Id
            FROM CommissionHistory__c
            WHERE Opportunity__c IN :opportunityIdSet
        ];

        delete deleteHistoryList;
    }
}