/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-03-14
 * @description : 영업사원별 반기내 판매 제품수에 따른 굿윌 적립 컨트롤러 
 * @target : HalfYearlyGoodWillCalculation_ba
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-14      chaebeom.do     Created
 * 1.1          2025-04-10      chaebeom.do     계약 취소시 굿윌 금액 차감 고려해서 AvailablePoint__c 업데이트 비활성
**************************************************************/
public with sharing class GoodWillSavingController {
    /**
     * @author chaebeom.do
     * @description 영업사원별 달성 인센티브 목표에 따른 금액 계산
     * @param ownerOpportunityCountMap 유저별 Opportunity 개수 저장 맵
     * @param saUserList SA 유저 리스트
     */
    public static void execute(Map<Id, Integer> ownerOpportunityCountMap, List<User> salesAgentList) {

        Map<Id, Id> ownerTargetMap = new Map<Id, Id>();
        Map<Id, Integer> targetCountMap = new Map<Id, Integer>();

        System.debug('ownerOpportunityCountMap : ' + ownerOpportunityCountMap);
        System.debug('salesAgentList : ' + salesAgentList);
        // 기존 굿윌 마스터 조회
        Map<Id, GoodWillMaster__c> mapExistingGoodWillMaster = new Map<Id, GoodWillMaster__c>();
        for (GoodWillMaster__c master : [
            SELECT Id, User__c 
            FROM GoodWillMaster__c 
            WHERE User__c IN :salesAgentList]
            ) {
                mapExistingGoodWillMaster.put(master.User__c, master);
            }
            
        List<GoodWillMaster__c> insertGoodWillMasterList = new List<GoodWillMaster__c>();
        for (User u : salesAgentList) {
            if (!mapExistingGoodWillMaster.containsKey(u.Id)) {
                GoodWillMaster__c newMaster = new GoodWillMaster__c(
                    User__c = u.Id,
                    OwnerId = u.Id
                    );
                    insertGoodWillMasterList.add(newMaster);
                }
            }
            
        // 신규 굿윌 마스터 생성
        if (!insertGoodWillMasterList.isEmpty()) {
            insert insertGoodWillMasterList;
        }
                
        // 굿윌 마스터 재조회
        List<GoodWillMaster__c> goodWillMasterList = [
            SELECT Id, User__c, fm_TargetYear__c, fm_TargetHalfYear__c
            FROM GoodWillMaster__c
            WHERE User__c IN :salesAgentList
            ];

        List<GoodWillSaving__c> goodWillSavingList = new List<GoodWillSaving__c>();
        System.debug('goodWillMasterList : ' + goodWillMasterList);

        for (GoodWillMaster__c gm : goodWillMasterList) {
            goodWillSavingList.add(new GoodWillSaving__c(
                // 250328 - 계약 취소시 적립 금액 업데이트를 위한 중복 방지용 external key 추가 (영업사원 + 연도 + 반기) 
                ExternalKey__c = gm.User__c + String.valueOf(gm.fm_TargetYear__c) + gm.fm_TargetHalfYear__c,
                GoodWillMaster__c = gm.Id,
                SavingPoints__c = ownerOpportunityCountMap.get(gm.User__c) != null ? ownerOpportunityCountMap.get(gm.User__c) * 500000 : 0
                // ver 1.1
                // AvailablePoint__c = ownerOpportunityCountMap.get(gm.User__c) != null ? ownerOpportunityCountMap.get(gm.User__c) * 500000 : 0
            ));
        }

        // insert goodWillSavingList;
        upsert goodWillSavingList ExternalKey__c;

        // 기존 굿윌 적립 만료일이 지났으면 만료됨 체크
        List<GoodWillSaving__c> expireGoodWillSavingList = new List<GoodWillSaving__c>(); 
        List<GoodWillSaving__c> curGoodWillSavingList = [
            SELECT Id, fm_ExpireDate__c, IsValid__c
            FROM GoodWillSaving__c
            WHERE IsValid__c = false
            ];
        
        for (GoodWillSaving__c gws : curGoodWillSavingList) {
            if (gws.fm_ExpireDate__c < System.today()) {
                gws.IsValid__c = true;
                expireGoodWillSavingList.add(gws);
            }
        }
        update expireGoodWillSavingList;
    }
}