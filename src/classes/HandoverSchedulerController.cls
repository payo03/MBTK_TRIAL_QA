/*************************************************************
 * @author : th.kim
 * @date : 2025-01-23
 * @description : 핸드오버 스케줄러 Controller
 * @target : handoverScheduler
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-23      th.kim          Created
**************************************************************/
public without sharing class HandoverSchedulerController {

    /**
     * @author th.kim
     * @description 필터링된 핸드오버 리스트 가져오기
     * @param filterMap 필터맵
     *
     * @return HandoverWrap 리스트
     */
    @AuraEnabled
    public static List<SchedulerMainController.HandoverWrap> getFilteredHandoverList(Map<String, Object> filterMap) {

        String whereCondition = filterMap != null ? CommonUtilController.buildWhereConditions(filterMap) : 'Opportunity__r.HandoverDate__c = THIS_MONTH';

        return SchedulerMainController.getHandoverData(whereCondition);
    }

    /**
     * @author th.kim
     * @description 선택된 핸드오버 리스트 업데이트 확인 처리
     * @param handoverIdList 선택된 핸드오버 Id 리스트
     */
    @AuraEnabled
    public static void updateCheckHandoverList(List<String> handoverIdList) {

        List<Handover__c> handoverList = new List<Handover__c>();
        for (String handoverId : handoverIdList) {
            handoverList.add(new Handover__c(
                Id = handoverId,
                IsNeedToCheckUpdate__c = false
            ));
        }
        update handoverList;
    }

    /**
     * @author th.kim
     * @description 선택된 핸드오버 리스트의 차량 출고 처리
     * @param completeList 출고할 차량, 기회 Id 리스트
     */
    @AuraEnabled
    public static void doCompleteHandover(List<Map<String, String>> completeList) {

        List<SObject> updateList = new List<SObject>();
        for (Map<String, String> dataMap : completeList) {
            updateList.add(new VehicleStock__c(
                Id = dataMap.get('stockId'),
                VehicleStatus__c = '출고됨',
                Status__c = '판매완료'
            ));
            updateList.add(new Opportunity(
                Id = dataMap.get('opportunityId'),
                StageName = 'Closed Won'
            ));
        }
        if (!updateList.isEmpty()) update updateList;
    }

    /**
     * @author th.kim
     * @description 선택한 핸드오버 리스트의 차량 변경해주기
     * @param dataList 핸드오버 데이터 리스트
     */
    @AuraEnabled
    public static void updateHandoverStockList(List<Map<String, String>> dataList) {

        try {
            List<SObject> updateList = new List<SObject>();
            for (Map<String, String> data : dataList) {
                String stockId = data.get('stockId');
                String opportunityId = data.get('opportunityId');
                if (String.isNotBlank(opportunityId)) {
                    // 기회 차량 업데이트
                    Opportunity updateOpportunity = new Opportunity(
                        Id = opportunityId,
                        VehicleStock__c = stockId
                    );
                    updateList.add(updateOpportunity);
                }

                String contractId = data.get('contractId');
                if (String.isNotBlank(contractId)) {
                    // 계약 차량 업데이트
                    Contract contract = new Contract(
                        Id = contractId,
                        VehicleStock__c = stockId
                    );
                    updateList.add(contract);
                }
            }

            // 한 번의 DML로 업데이트
            if (!updateList.isEmpty()) {
                update updateList;

                CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Custom' LIMIT 1];

                Set<String> userOrGroupIdSet = new Set<String>();

                // 핸드오버 차량 변경 알림 대상 공유 그룹
                List<Group> groupList = [SELECT Id FROM Group WHERE DeveloperName = 'HandoverStockChangeGroup' LIMIT 1];

                if (groupList.isEmpty()) throw new QueryException('알림 변경 대상 그룹이 존재하지 않습니다.');

                userOrGroupIdSet.add(groupList[0].Id);

                for (Map<String, String> data : dataList) {
                    userOrGroupIdSet.add(data.get('ownerId'));

                    // 알림 발송
                    CommonUtilController.sendNotification(new CommonUtilController.NotificationWrap(
                        '[핸드오버 차량 변경됨] - [' + data.get('oppName') + ']',
                        '[' + data.get('previousVIN') + '] -> ' + '[' + data.get('currentVIN') + '] 으로 변경됨',
                        notificationType.Id,
                        UserInfo.getUserId(),
                        data.get('opportunityId'),
                        userOrGroupIdSet
                    ));
                }
            }
        } catch (Exception e) {
            System.debug('err :: ' + e.getMessage() + '\nTrack :: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @author th.kim
     * @description 필터링된 해당 핸드오버의 차량 재고 리스트 가져오기
     * @param filterMap 필터링 조건
     *
     * @return 해당 핸드오버의 차량 리스트
     */
    @AuraEnabled
    public static List<VehicleStock__c> getVehicleStockList(Map<String, String> filterMap) {

        String selectFields = 'Id, Name, FORMAT(RealArrivalDate__c) realArrivalDate, Product__r.Name, VehicleNo__c, IsIntarder__c, '
            + 'IsPTO__c, IsHypoid__c, Cab_Color__c, VehicleStatus__c, fm_PdiNextStep__c, PDIEntryDate__c ';
        List<String> whereConditionList = new List<String>{
            'Product__c = \'' + filterMap.get('Product__c') + '\'',
            'Status__c = \'재고 노출\'',
            'VehicleStatus__c != \'출고불가\''
        };

        if (String.isNotBlank(filterMap.get('Name'))) {
            whereConditionList.add('Name LIKE \'%' + filterMap.get('Name') + '%\'');
        }
        if (String.isNotBlank(filterMap.get('VehicleNo__c'))) {
            whereConditionList.add('VehicleNo__c LIKE \'%' + filterMap.get('VehicleNo__c') + '%\'');
        }
        String query = CommonUtilController.buildQuery(selectFields, 'VehicleStock__c', String.join(whereConditionList, ' AND '));

        List<VehicleStock__c> stockList = Database.query(query);
        Map<Id, VehicleStock__c> stockMap = new Map<Id, VehicleStock__c>(stockList);

        List<Opportunity> opportunityList = [SELECT Id, VehicleStock__c FROM Opportunity WHERE VehicleStock__c IN :stockMap.keySet()];
        Set<Id> opportunityStockIdSet = new Set<Id>();
        for (Opportunity opportunity : opportunityList) {
            opportunityStockIdSet.add(opportunity.VehicleStock__c);
        }
        List<VehicleStock__c> returnStockList = new List<VehicleStock__c>();
        for (Id stockId : stockMap.keySet()) {
            if (opportunityStockIdSet.contains(stockId)) continue;
            returnStockList.add(stockMap.get(stockId));
        }

        return returnStockList;
    }
}