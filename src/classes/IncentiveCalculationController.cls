/*************************************************************
 * @author : th.kim
 * @description : 영업사원별 달성 인센티브 목표에 따른 금액 계산 컨트롤러
 * @target : QuarterlyIncentiveCalculation_ba, AnnualIncentiveCalculation_ba
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-13      th.kim          Created
**************************************************************/
public with sharing class IncentiveCalculationController {

    /**
     * @author th.kim
     * @description 인센티브 계산 전 기존 인센티브 데이터 초기화 (연월 외에 조건을 주면 조건에 해당되지 않으면 계산 안되므로 해당 연월 전부 재계산)
     * @param initOpportunityList 초기화할 대상 기회 리스트
     */
    public static void initData(List<Opportunity> initOpportunityList) {
        Set<Id> historyIdSet = new Set<Id>();
        for (Opportunity opportunity : initOpportunityList) {
            historyIdSet.add(opportunity.IncentiveHistoryQuarterly__c);
            historyIdSet.add(opportunity.IncentiveHistoryAnnual__c);
            opportunity.IncentiveHistoryQuarterly__c = null;
            opportunity.IncentiveHistoryAnnual__c = null;
        }
        update initOpportunityList;

        List<IncentiveHistory__c> initIncentiveHistoryList = [SELECT Id, SalesCount__c FROM IncentiveHistory__c WHERE Id IN :historyIdSet];
        for (IncentiveHistory__c history : initIncentiveHistoryList) {
            history.SalesCount__c = 0;
        }
        update initIncentiveHistoryList;
    }

    /**
     * @author th.kim
     * @description 소유자별 기회 개수 맵 생성
     * @param ownerOpportunityIdCountMap 소유자별 기회 개수 맵
     * @param opportunity 기회 객체 데이터
     *
     * @return 소유자별 기회 개수 맵
     */
    public static Map<Id, Set<Id>> setOwnerOpportunityIdCountMap(Map<Id, Set<Id>> ownerOpportunityIdCountMap, Opportunity opportunity) {

        if (ownerOpportunityIdCountMap.get(opportunity.OwnerId) == null) {
            ownerOpportunityIdCountMap.put(opportunity.OwnerId, new Set<Id>());
        }
        ownerOpportunityIdCountMap.get(opportunity.OwnerId).add(opportunity.Id);

        return ownerOpportunityIdCountMap;
    }

    /**
     * @author th.kim
     * @description 영업사원별 달성 인센티브 목표에 따른 금액 계산
     * @param ownerOpportunityIdCountMap 유저별 Opportunity 개수 저장 맵
     * @param targetMasterList 인센티브 타겟 마스터 리스트
     */
    public static void execute(Map<Id, Set<Id>> ownerOpportunityIdCountMap, List<IncentiveTargetMaster__c> targetMasterList) {

        Map<Id, IncentiveTargetMaster__c> ownerTargetMap = new Map<Id, IncentiveTargetMaster__c>();

        // 각 목표 레코드에 대해 OwnerId별 목표 달성 여부 확인
        for (Id ownerId : ownerOpportunityIdCountMap.keySet()) {
            for (IncentiveTargetMaster__c targetMaster : targetMasterList) {
                Integer targetCount = ownerOpportunityIdCountMap.get(ownerId).size();

                // 목표 범위 이상 달성 시
                if (targetCount >= targetMaster.MinSalesTarget__c) {
                    ownerTargetMap.put(ownerId, targetMaster);
                    break;
                }
            }
        }

        if (!ownerTargetMap.isEmpty()) {
            List<IncentiveHistory__c> incentiveHistoryList = new List<IncentiveHistory__c>();

            for (Id ownerId : ownerTargetMap.keySet()) {
                IncentiveTargetMaster__c targetMaster = ownerTargetMap.get(ownerId);
                // 1개의 목표에 1명의 영업사원이 중복으로 생기지 않도록 외부 키 값 추가
                incentiveHistoryList.add(new IncentiveHistory__c(
                    ExternalKey__c = ownerId + targetMaster.Year__c + targetMaster.TargetType__c + targetMaster.Quarter__c,
                    IncentiveTargetMaster__c = targetMaster.Id,
                    OwnerId = ownerId,
                    SalesCount__c = ownerOpportunityIdCountMap.get(ownerId).size()
                ));
            }

            upsert incentiveHistoryList ExternalKey__c;

            List<Opportunity> opportunityList = new List<Opportunity>();
            for (IncentiveHistory__c history : incentiveHistoryList) {
                IncentiveTargetMaster__c targetMaster = ownerTargetMap.get(history.OwnerId);
                for (Id opportunityId : ownerOpportunityIdCountMap.get(history.OwnerId)) {
                    Opportunity opportunity = new Opportunity(Id = opportunityId);
                    Id historyId = history.Id;
                    if (targetMaster.TargetType__c == 'Annual') {
                        opportunity.IncentiveHistoryAnnual__c = historyId;
                    } else if (targetMaster.TargetType__c == 'Quarterly') {
                        opportunity.IncentiveHistoryQuarterly__c = historyId;
                    }
                    opportunityList.add(opportunity);
                }
            }

            update opportunityList;
        }
    }
}