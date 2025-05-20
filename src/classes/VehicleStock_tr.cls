/*********************************************************************************************************
 * @author : th.kim
 * @date : 2024-11-18
 * @description :
 * @target :
==========================================================================================================
 * Ver          Date            Author                          Modification
 * 1.0          2024-11-18      th.kim                          Created
 * 1.1          2024-12-06      th.kim, payo03@solomontech.net  재고 증감로직 구현
 * 1.2          2025-02-17      payo03@solomontech.net          사전배정 관련프로세스 삭제
 * 1.3          2025-03-10      th.kim                          createCommissionHistory() 추가
 * 1.4          2025-04-29      th.kim                          재고 증감 로직 수정 및 리팩토링 (특정 조건에서만 수량 차감 -> 상태 변경시 기존 상태 수량 차감)
*********************************************************************************************************/
public without sharing class VehicleStock_tr extends TriggerHandler {

    /** TriggerHandler */
    private final List<VehicleStock__c> newList { get; set; }
    private final List<VehicleStock__c> oldList { get; set; }
    private final Map<Id, VehicleStock__c> oldMap { get; set; }
    private final Map<Id, VehicleStock__c> newMap { get; set; }

    public VehicleStock_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        oldMap = (Map<Id, VehicleStock__c>) Trigger.oldMap;
        newMap = (Map<Id, VehicleStock__c>) Trigger.newMap;
    }

    public override void beforeUpdate() {
//        updateHandover();
        syncNoShowStatus();
    }

    public override void afterInsert() {
        adjustStock();
//        createSpecialProduct();
    }

    public override void afterUpdate() {
        adjustStock();
        updateHandover();
        processCommissionHistory();
//        createSpecialProduct();
    }

    /**
     * @author th.kim
     * @description Product, VehicleCategory 재고 수량 조정 필드 업데이트
     *              - Product 변경, Record 삭제 : 수량 빼기(-)
     *              - Record Insert, Record Status변경시 : Case별 수량 적용
     *              1. Product 수량 적용                  | [if (!productList.isEmpty()) update productList;]
     *              2. VehicleCategory 수량적용            | [if (!categoryList.isEmpty()) update categoryList;]
     */
    private void adjustStock() {
        // AFTER_INSERT, AFTER_UPDATE

        // Product Id별 -> Field별, 관련 Stock 수를 집계하는 Map
        // Key : Product / Value : Map<String, Integer>
        //                      - Key : Field / Value : Qty
        Map<Id, Map<String, Integer>> productMap = new Map<Id, Map<String, Integer>>();
        for (VehicleStock__c newStock : newList) {
            String productId = newStock.Product__c;
            VehicleStock__c oldStock = new VehicleStock__c();
            if (oldMap != null) oldStock = oldMap.get(newStock.Id);

            // 상태의 수량 필드 맵
            Map<String, String> statusFieldMap = new Map<String, String>{
                '재고 미노출(임시)' => 'StockNoShowQty__c',
                '재고 노출' => 'Quantity__c',
                '30일 재고' => 'After30DaysQty__c',
                '60일 재고' => 'After60DaysQty__c'
            };

            /* ver 1.4 재고 증감 로직 수정 및 리팩토링
            String noShowField = 'StockNoShowQty__c';
            String quantityField = 'Quantity__c';
            String after30Field = 'After30DaysQty__c';
            String after60Field = 'After60DaysQty__c';
            String preAssignField = 'PreAssignQty__c';
            String waitingListField = 'WaitingListQty__c';
            */

            Map<String, Integer> fieldQuantityMap = new Map<String, Integer>();
            if (productMap.get(productId) != null) fieldQuantityMap = productMap.get(productId);

            Boolean isStatusChange = Trigger.isUpdate && oldStock.Status__c != newStock.Status__c;

            // Product 변경, Record 삭제
            Boolean isOldChange = Trigger.isDelete || (Trigger.isUpdate && oldStock.Product__c != newStock.Product__c) || isStatusChange;
            if (isOldChange) {

            /* ver 1.4 재고 증감 로직 수정 및 리팩토링
                String varField = null;
                switch on oldStock.Status__c {
                    when '재고 미노출(임시)' {
                        varField = noShowField;
                    }
                    when '재고 노출' {
                        varField = quantityField;
                    }
                    when '30일 재고' {
                        varField = after30Field;
                    }
                    when '60일 재고' {
                        varField = after60Field;
                    }
                }*/

                String statusField = statusFieldMap.get(oldStock.Status__c);
                if (statusField != null) productMap.put(oldStock.Product__c, adjustQuantity(fieldQuantityMap, statusField, false));
            }

            // Record Insert, Record Status변경시
            Boolean isNewChange = Trigger.isInsert || isStatusChange;
            if (isNewChange) {
                String statusField = statusFieldMap.get(newStock.Status__c);
                if (statusField != null) productMap.put(newStock.Product__c, adjustQuantity(fieldQuantityMap, statusField, true));

                /* ver 1.4 재고 증감 로직 수정 및 리팩토링
                switch on newStock.Status__c {
                    when '재고 미노출(임시)' {
                        productMap.put(productId, adjustQuantity(fieldQuantityMap, noShowField, true));

                        // Case 기 존재데이터일경우
                        if (oldMap != null) {
                            if (oldStock.Status__c == '재고 노출') {
                                productMap.put(productId, adjustQuantity(fieldQuantityMap, quantityField, false));
                            } else if (oldStock.Status__c == '30일 재고') {
                                productMap.put(productId, adjustQuantity(fieldQuantityMap, after30Field, false));
                            }
                        }
                    }
                    when '재고 노출' {
                        productMap.put(productId, adjustQuantity(fieldQuantityMap, quantityField, true));

                        // Case 기 존재데이터일경우
                        if (oldMap != null) {
                            if (oldStock.Status__c == '재고 미노출(임시)') {
                                productMap.put(productId, adjustQuantity(fieldQuantityMap, noShowField, false));
                            } else if (oldStock.Status__c == '30일 재고') {
                                productMap.put(productId, adjustQuantity(fieldQuantityMap, after30Field, false));
                            }
                        }
                    }
                    when '30일 재고' {
                        productMap.put(productId, adjustQuantity(fieldQuantityMap, after30Field, true));

                        // Case 60일 재고에서 변경된 경우
                        if (oldMap != null && oldStock.Status__c == '60일 재고') {
                            productMap.put(productId, adjustQuantity(fieldQuantityMap, after60Field, false));
                        }
                    }
                    when '60일 재고' {
                        productMap.put(productId, adjustQuantity(fieldQuantityMap, after60Field, true));

                        // Case 30일 재고에서 변경된 경우
                        if (oldMap != null && oldStock.Status__c == '30일 재고') {
                            productMap.put(productId, adjustQuantity(fieldQuantityMap, after30Field, false));
                        }
                    }
                    when '판매완료' {
                        productMap.put(productId, adjustQuantity(fieldQuantityMap, quantityField, false));

                        *//* ver1.2 사전배정 관련프로세스 삭제
                        // Case 기 존재데이터일경우
                        if (oldMap != null && newStock.PreAssigned__c) {
                            productMap.put(productId, adjustQuantity(fieldQuantityMap, preAssignField, false));
                        }
                        *//*
                    }
                }*/
            }

            // TODO :: 배정상태로 변경 필요
            // 사전배정 재고 할당되었을 때
            /* ver1.2 사전배정 관련프로세스 삭제
            if(
                    (Trigger.isInsert && newStock.PreAssigned__c) ||
                    (oldMap != null && !oldStock.PreAssigned__c && newStock.PreAssigned__c)
            ) {
                // 1. 신규생성 동시 사전배정 할당 +
                // 2. 기존재고 있으면서 할당 +
                productMap.put(productId, adjustQuantity(fieldQuantityMap, preAssignField, true));

                // 사전배정재고 할당시, 대기수요 수량 -
                if(oldMap != null && newStock.PreAssigned__c) {
                    productMap.put(productId, adjustQuantity(fieldQuantityMap, waitingListField, false));

                }
            } else if(oldMap != null && oldStock.PreAssigned__c && !newStock.PreAssigned__c) {
                // 기존재고 존재시, 할당 -
                productMap.put(productId, adjustQuantity(fieldQuantityMap, preAssignField, false));
            }
            */
        }

        // VehicleCategory Id별 -> Field별, 관련 Stock 수를 집계하는 Map
        // Key : VehicleCategory / Value : Map<String, Integer>
        //                      - Key : Field / Value : Qty
        Map<Id, Map<String, Integer>> vehicleMap = new Map<Id, Map<String, Integer>>();
        List<Product2> productList = [SELECT Id, AdjustField__c, VehicleCategory__c FROM Product2 WHERE Id IN :productMap.keySet()];
        for (Product2 product : productList) {
            // Product. Field별 Map
            Map<String, Integer> productQuantityMap = productMap.get(product.Id);

            Map<String, Decimal> updateMap = new Map<String, Decimal>();
            for (String field : productQuantityMap.keySet()) {
                // Product에도 ETA 필드 추가로 주석 처리 - (th.kim, 24-12-23)
//                if(field == 'Quantity__c' || field == 'PreAssignQty__c') {
                updateMap.put(field, productQuantityMap.get(field));
//                }
            }
            product.AdjustField__c = JSON.serialize(updateMap);

            // VehicleCategory. Field별 Map
            String key = product.VehicleCategory__c;
            Map<String, Integer> vehicleQuantityMap = new Map<String, Integer>();
            if (vehicleMap.get(key) != null) vehicleQuantityMap = vehicleMap.get(key);
            for (String field : productQuantityMap.keySet()) {
                vehicleQuantityMap.put(field, productQuantityMap.get(field));
            }
            vehicleMap.put(key, vehicleQuantityMap);
        }
        if (!productList.isEmpty()) update productList;

        List<VehicleCategory__c> categoryList = [SELECT Id, AdjustField__c FROM VehicleCategory__c WHERE Id IN :vehicleMap.keySet()];
        for (VehicleCategory__c category : categoryList) {
            // VehicleCategory. Field별 Map
            Map<String, Integer> productQuantityMap = vehicleMap.get(category.Id);

            Map<String, Decimal> updateMap = new Map<String, Decimal>();
            for (String field : productQuantityMap.keySet()) {
                updateMap.put(field, productQuantityMap.get(field));
            }

            category.AdjustField__c = JSON.serialize(updateMap);
        }
        if (!categoryList.isEmpty()) update categoryList;
    }

    /**
     * @param fieldQuantityMap      Key : Field, Value : Quantity | 수량필드에 대한 증감수량
     * @param field                 Update할 필드 명
     * @param isIncrease            TRUE : +, FALSE : -
     * @description                 ver1.1 재고 증감로직 구현
     * @return                      Map<String, Integer> value
     */
    private static Map<String, Integer> adjustQuantity(Map<String, Integer> fieldQuantityMap, String field, Boolean isIncrease) {
        Integer adjustQty = 0;
        if (fieldQuantityMap.get(field) != null) adjustQty = fieldQuantityMap.get(field);

        adjustQty = isIncrease ? ++adjustQty : --adjustQty;
        fieldQuantityMap.put(field, adjustQty);

        return fieldQuantityMap;
    }

    /**
     * @author th.kim
     * @description 차량 데이터 업데이트 시 핸드오버도 트리거 태워주기 위한 메서드
     */
    private void updateHandover() {

        List<Handover__c> handoverList = [SELECT Id FROM Handover__c WHERE Opportunity__r.VehicleStock__c IN :newMap.keySet()];
        update handoverList;
    }

    /**
     * @author th.kim
     * @description case. 출고 처리
                        1. 출고 처리 차량 기회의 (영업사원별 출고일 연월) 기준으로 커미션 관리 조회
                        2. 커미션 관리 없을 시 커미션 관리 생성
                        3. 기회의 (영업사원별 출고일 연월) 기준으로 커미션 관리 맵핑 후 커미션 내역 생성
                    case. 출고 취소
                        1. 출고 취소 차량의 기회 조회
                        2. 해당 기회의 커미션 내역 삭제
     */
    private void processCommissionHistory() {

        Set<Id> activeStockIdSet = new Set<Id>();
        Set<Id> inactiveStockIdSet = new Set<Id>();
        for (VehicleStock__c newStock : newList) {
            VehicleStock__c oldStock = oldMap.get(newStock.Id);

            // 출고 처리
            if (oldStock.VehicleStatus__c != '출고됨' && newStock.VehicleStatus__c == '출고됨') {
                activeStockIdSet.add(newStock.Id);
            }
            // 출고 취소
            else if (oldStock.VehicleStatus__c == '출고됨' && newStock.VehicleStatus__c != '출고됨') {
                inactiveStockIdSet.add(newStock.Id);
            }
        }

        // 출고 처리 차량 존재
        if (!activeStockIdSet.isEmpty()) {

            // 출고된 차량에 연결된 기회 get
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
                SELECT Id
                FROM Opportunity
                WHERE VehicleStock__c IN :activeStockIdSet
                AND VehicleStock__c != NULL
            ]);
            System.debug('opportunityList active :: ' + opportunityMap);

            CommissionManagementController.createCommissionHistory(opportunityMap.keySet(), false);
        }
        // 출고 취소 차량 존재
        else if (!inactiveStockIdSet.isEmpty()) {
            // 출고 취소된 차량에 연결된 기회 get
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
                SELECT Id
                FROM Opportunity
                WHERE VehicleStock__c IN :inactiveStockIdSet
            ]);
            CommissionManagementController.deleteCommissionHistory(opportunityMap.keySet());
        }
    }

    /**
     * @author th.kim
     * @description 재고 미노출, 재고 상태 필드 값 연동
     */
    private void syncNoShowStatus() {

        for (VehicleStock__c newStock : newList) {
            VehicleStock__c oldStock = oldMap.get(newStock.Id);
            // 재고 상태 변경 시
            if (oldStock.Status__c != newStock.Status__c) {
                newStock.StockNoShow__c = newStock.Status__c == '재고 미노출(임시)';
            }
            // 재고 미노출 필드 업데이트 시
            else if (oldStock.StockNoShow__c != newStock.StockNoShow__c) {
                // 재고 미노출로 변경
                if (newStock.StockNoShow__c) {
                    newStock.Status__c = '재고 미노출(임시)';
                }
                // 재고 노출로 변경, 기존 재고 상태 재고 미노출일 시
                else if (newStock.Status__c == '재고 미노출(임시)') {
                    newStock.Status__c = '재고 노출';
                }
            }
        }
    }

//    /**
//     * @author th.kim
//     * @description 커미션 내역 생성
//     * @param opportunityList 기회 리스트
//     * @param IsVATDeferred 부가세 후취 레코드 생성 여부
//     */
//    public static void createCommissionHistory(List<Opportunity> opportunityList, Boolean IsVATDeferred) {
//
//        Integer todayYear = Date.today().year();
//        Integer todayMonth = Date.today().month();
//        Set<Id> ownerIdSet = new Set<Id>();
//        Set<Integer> yearSet = new Set<Integer>();
//        Set<Integer> monthSet = new Set<Integer>();
//        for (Opportunity opportunity : opportunityList) {
//            // 차량에 연결된 기회 맵
//            ownerIdSet.add(opportunity.OwnerId);
//            if (!IsVATDeferred) {
//                yearSet.add(opportunity.HandoverDate__c.year());
//                monthSet.add(opportunity.HandoverDate__c.month());
//            } else {
//                yearSet.add(todayYear);
//                monthSet.add(todayMonth);
//            }
//        }
//
//        // 영업사원, 날짜 기준 커미션 관리 가져오기
//        List<CommissionManagement__c> commissionManagementList = [
//            SELECT Id, Period__c, OwnerId
//            FROM CommissionManagement__c
//            WHERE OwnerId IN :ownerIdSet
//            AND CALENDAR_YEAR(Period__c) IN :yearSet
//            AND CALENDAR_MONTH(Period__c) IN :monthSet
//        ];
//        System.debug('commissionManagementList :: ' + commissionManagementList);
//        Map<String, CommissionManagement__c> commissionManagementMap = new Map<String, CommissionManagement__c>();
//        for (CommissionManagement__c commissionManagement : commissionManagementList) {
//            // 영업사원, 날짜별 커미션 관리 put
//            commissionManagementMap.put(
//                commissionManagement.OwnerId + String.valueOf(commissionManagement.Period__c.year()) + String.valueOf(commissionManagement.Period__c.month()),
//                commissionManagement
//            );
//        }
//        System.debug('commissionManagementMap before :: ' + commissionManagementMap);
//
//        Map<String, CommissionManagement__c> insertManagementMap = new Map<String, CommissionManagement__c>();
//        for (Opportunity opportunity : opportunityList) {
//            if (!IsVATDeferred) {
//                // 출고일 예외 체크
//                if (opportunity.HandoverDate__c == null) {
//                    System.debug('기회의 출고일이 존재하지 않음 - ' + opportunity.Id);
//                    continue;
//                }
//            }
//            Integer handoverYear = IsVATDeferred ? todayYear : opportunity.HandoverDate__c.year();
//            Integer handoverMonth = IsVATDeferred ? todayMonth : opportunity.HandoverDate__c.month();
//            String key = opportunity.OwnerId + String.valueOf(handoverYear) + String.valueOf(handoverMonth);
//
//            // 커미션 관리 존재하지 않을 시 커미션 관리 생성
//            if (!commissionManagementMap.containsKey(key)) {
//                if (insertManagementMap.containsKey(key)) continue;
//                insertManagementMap.put(key, new CommissionManagement__c(
//                    OwnerId = opportunity.OwnerId,
//                    Period__c = Date.newInstance(handoverYear, handoverMonth, 1)
//                ));
//            }
//        }
//
//        if (!insertManagementMap.isEmpty()) {
//            insert insertManagementMap.values();
//            System.debug('insertManagementMap :: ' + insertManagementMap);
//            for (CommissionManagement__c commissionManagement : insertManagementMap.values()) {
//                // 새로 생성된 영업사원, 날짜별 커미션 관리 put
//                commissionManagementMap.put(
//                    commissionManagement.OwnerId + String.valueOf(commissionManagement.Period__c.year()) + String.valueOf(commissionManagement.Period__c.month()),
//                    commissionManagement
//                );
//            }
//            System.debug('commissionManagementMap after :: ' + commissionManagementMap);
//        }
//
//        List<CommissionHistory__c> commissionHistoryList = new List<CommissionHistory__c>();
//        for (Opportunity opportunity : opportunityList) {
//
//            if (!IsVATDeferred) {
//                // 출고일 예외 체크
//                if (opportunity.HandoverDate__c == null) {
//                    System.debug('기회의 출고일이 존재하지 않음 - ' + opportunity.Id);
//                    continue;
//                }
//            }
//
//            String handoverYear = String.valueOf(IsVATDeferred ? todayYear : opportunity.HandoverDate__c.year());
//            String handoverMonth = String.valueOf(IsVATDeferred ? todayMonth : opportunity.HandoverDate__c.month());
//
//            commissionHistoryList.add(new CommissionHistory__c(
//                ExternalKey__c = opportunity.OwnerId + handoverYear + handoverMonth + opportunity.Id + (IsVATDeferred ? 'DefermentVAT' : ''),
//                CommissionManagement__c = commissionManagementMap.get(opportunity.OwnerId + handoverYear + handoverMonth).Id,
//                Opportunity__c = opportunity.Id,
//                Type__c = IsVATDeferred ? 'DefermentVAT' : null
//            ));
//        }
//        System.debug('commissionHistoryList :: ' + commissionHistoryList);
//        upsert commissionHistoryList ExternalKey__c;
//    }
//
//    /**
//     * @author th.kim
//     * @description 커미션 내역 삭제
//     * @param opportunityIdSet 삭제할 Opportunity Id
//     */
//    public static void deleteCommissionHistory(Set<Id> opportunityIdSet) {
//
//        List<CommissionHistory__c> deleteHistoryList = [
//            SELECT Id
//            FROM CommissionHistory__c
//            WHERE Opportunity__c IN :opportunityIdSet
//        ];
//        System.debug('deleteHistoryList :: ' + deleteHistoryList);
//        delete deleteHistoryList;
//    }
}