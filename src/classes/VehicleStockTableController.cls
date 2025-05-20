/*************************************************************
 * @author : th.kim
 * @date : 2024-11-12
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-12      th.kim          Created
 * 2.0          2025-02-06      san.kang        Updated
**************************************************************/
public without sharing class VehicleStockTableController {
    public class MasterWrap {
        @AuraEnabled public String key;
        @AuraEnabled public String segment;
        @AuraEnabled public String name;
        @AuraEnabled public String styling;
        @AuraEnabled public Decimal carAmt;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Integer quantity;
        @AuraEnabled public Integer waitingListQty;
        @AuraEnabled public Integer stockNoShowQty;
        @AuraEnabled public Integer preAssignQty;
        @AuraEnabled public Integer after30DaysQty;
        @AuraEnabled public Integer after60DaysQty;
        @AuraEnabled public Integer eta;
        @AuraEnabled public List<ProductWrap> children;

        public MasterWrap(String key, String segment, String name ,String styling, Decimal carAmt, Decimal price, Integer quantity, Integer waitingListQty, Integer stockNoShowQty, Integer after30DaysQty, Integer after60DaysQty, Integer eta) {
            this.key = key;
            this.segment = segment;
            this.name = name;
            this.styling = styling;
            this.carAmt = carAmt;
            this.price = price;
            this.quantity = quantity;
            this.waitingListQty = waitingListQty;
            this.stockNoShowQty = stockNoShowQty;
            this.preAssignQty = preAssignQty;
            this.after30DaysQty = after30DaysQty;
            this.after60DaysQty = after60DaysQty;
            this.eta = eta;
        }
    }

    public class ProductWrap {
        @AuraEnabled public String id;
        @AuraEnabled public String LMY;
        @AuraEnabled public String VMY;
        @AuraEnabled public String colour;
        @AuraEnabled public Decimal DC;
        @AuraEnabled public Decimal totalPrice;
        @AuraEnabled public String deviation;
        @AuraEnabled public String remarks;
        @AuraEnabled public Integer modelQuantity;
        @AuraEnabled public List<VehicleDetailWrap> children;

        public ProductWrap(String id, String LMY, String VMY, String colour, Decimal DC, Decimal totalPrice, String deviation, String remarks, Integer modelQuantity) {
            this.id = id;
            this.LMY = LMY;
            this.VMY = VMY;
            this.colour = colour;
            this.DC = DC;
            this.totalPrice = totalPrice;
            this.deviation = deviation;
            this.remarks = remarks;
            this.modelQuantity = modelQuantity;
            this.children = new List<VehicleDetailWrap>();
        }
    }

    public class VehicleDetailWrap {
        @AuraEnabled public String id;
        @AuraEnabled public Decimal longTermDiscountRate;
        @AuraEnabled public String modelName;
        @AuraEnabled public String modelYear;
        @AuraEnabled public String localYear;
        @AuraEnabled public String vehicleNo;
        @AuraEnabled public String productionSite;
        @AuraEnabled public String color;
        @AuraEnabled public String stockStatus;
        @AuraEnabled public Boolean stockNoShow;
        @AuraEnabled public String vehicleUrl;
//        @AuraEnabled public Decimal totalDC;
//        @AuraEnabled public Decimal partsDC;
//        @AuraEnabled public Decimal specialDC;
//        @AuraEnabled public Decimal discountedPrice;
        @AuraEnabled public String remarks;
        @AuraEnabled public String deviation;
//        @AuraEnabled public Integer amount;

        public VehicleDetailWrap(String id, String modelName, Decimal longTermDiscountRate, String localYear, String modelYear, String vehicleNo, /*String vin,*/ String productionSite, String color,/*String arrivalDate,*/ String stockStatus /*String actionLabel*/, Boolean stockNoShow, String remarks, String deviation) {
            this.id = id;
            this.modelName = modelName;
            this.longTermDiscountRate = longTermDiscountRate;
            this.modelYear = modelYear;
            this.localYear = localYear;
            this.vehicleNo = vehicleNo;
            this.productionSite = productionSite;
            this.color = color;
            this.stockStatus = stockStatus;
            this.stockNoShow = stockNoShow;
            this.vehicleUrl = '/lightning/r/VehicleStock__c/' + id + '/view';
//            this.totalDC = totalDC;
//            this.partsDC = partsDC;
//            this.specialDC = specialDC;
//            this.discountedPrice = discountedPrice;
            this.remarks = remarks;
            this.deviation = deviation;
//            this.amount = amount;
        }
    }
    public class DetailAdditionalWrap {
        @AuraEnabled public String id;                   // Id
        @AuraEnabled public String productId;                   // Id
        @AuraEnabled public String localYear;                   // LMY
        @AuraEnabled public String modelYear;                   // VMY
        @AuraEnabled public String color;                       // 색상
        @AuraEnabled public Decimal totalDC;                    // 총 할인
        @AuraEnabled public Decimal longTermDiscountRate;       // 장기재고할인율
        @AuraEnabled public Decimal partsDC;                    // 파츠 할인율
        @AuraEnabled public Decimal specialDC;                  // 스페셜 할인율
        @AuraEnabled public Decimal discountedPrice;            // 할인가
        @AuraEnabled public String deviation;                   // 결함
        @AuraEnabled public String remarks;                     // 비고
        @AuraEnabled public Integer amount;                     // 수량

        public DetailAdditionalWrap(String id,String productId, String localYear, String modelYear, String color, Decimal totalDC, Decimal longTermDiscountRate, Decimal partsDC, Decimal specialDC, Decimal discountedPrice, String deviation, String remarks, Integer amount) {
            this.id = id;
            this.productId = productId;
            this.localYear = localYear;
            this.modelYear = modelYear;
            this.color = color;
            this.totalDC = totalDC;
            this.longTermDiscountRate = longTermDiscountRate;
            this.partsDC = partsDC;
            this.specialDC = specialDC;
            this.discountedPrice = discountedPrice;
            this.deviation = deviation;
            this.remarks = remarks;
            this.amount = amount;
        }
    }

    private class InsertDataWrap {
        public String id;
        public String oppId;
        public String accountId;
//        public String type;
    }

    /**
     * @author th.kim
     * @description 재고 Oneview 화면
     * @param recordId VehicleStock recordId
     *
     * @return
     */
//    @AuraEnabled
//    public static List<MasterWrap> getVehicleStock(String recordId) {
//
//        VehicleStock__c currentStock = [SELECT Product__r.VehicleCategory__c FROM VehicleStock__c WHERE Id = :recordId];
//        List<VehicleStock__c> vehicleStockList = getVehicleStockList(currentStock.Product__r.VehicleCategory__c);
//
//        if (!vehicleStockList.isEmpty()) {
//
//            List<ProductWrap> MasterWrapList = new List<ProductWrap>();
//            Map<String, ProductWrap> MasterWrapMap = new Map<String, ProductWrap>();
//
//            List<MasterWrap> MasterWrapList = new List<MasterWrap>();
//            Map<String, MasterWrap> MasterWrapMap = new Map<String, MasterWrap>();
//
//            for (VehicleStock__c stock : vehicleStockList) {
//
//                String actionLabel = stock.PreAssigned__c ? '대기안건' : '요청생성';
//                VehicleDetailWrap vehicleDetailWrap = new VehicleDetailWrap(
//                    stock.Id,
//                    stock.Product__r.Name,
//                    stock.ModelYear__c,
//                    stock.VehicleNo__c,
//                    stock.Name,
//                    'test',
//                    stock.CarColor__c,
//                    String.valueOf(stock.get('arrivalDate')),
//                    stock.PreAssigned__c,
//                    stock.StockStatusDesc__c,
//                    actionLabel
//                );
//
//                Product2 product = stock.Product__r;
//                ProductWrap MasterWrap = MasterWrapMap.get(product.Id);
//                if (MasterWrap == null) {
//                    MasterWrap = new ProductWrap(
//                        product.Id,
//                        product.Name
//                    );
//                    MasterWrapMap.put(product.Id, MasterWrap);
//                    MasterWrapList.add(MasterWrap);
//
//                    VehicleCategory__c vehicleCategory = stock.Product__r.VehicleCategory__r;
//                    MasterWrap MasterWrap = MasterWrapMap.get(vehicleCategory.Id);
//                    if (MasterWrapMap.get(stock.Product__r.VehicleCategory__c) == null) {
//                        MasterWrap = new MasterWrap(vehicleCategory.Id, 'TPP', 'TGS_37.460_8X4_BB', 'M', '2990');
//                        MasterWrapMap.put(vehicleCategory.Id, MasterWrap);
//                        MasterWrapList.add(MasterWrap);
//                    }
//                    MasterWrap.children.add(MasterWrap);
//                }
//                MasterWrap.children.add(vehicleDetailWrap);
//            }
//
//            for(MasterWrap MasterWrap : MasterWrapList) {
//                Integer modelQty = 0;
//                for(ProductWrap MasterWrap : MasterWrapList) {
//                    modelQty = MasterWrap.children.size();
//                    MasterWrap.modelQuantity = modelQty;
//                }
//                MasterWrap.quantity += modelQty;
//            }
//
//            return MasterWrapList;
//        }
//        return null;
//    }

    /**
     * @author th.kim
     * @description Category 데이터 및 필터 Picklist 가져오기
     * @param stockId 현재 Stock Id
     *
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> getInitData(String stockId) {

        List<VehicleStock__c> vehicleStockList = new List<VehicleStock__c>();
        if (String.isNotBlank(stockId)) {
            vehicleStockList = [SELECT Id, Product__r.VehicleCategory__c FROM VehicleStock__c WHERE Id = :stockId];
        }

        return new Map<String, Object>{
                'categoryList' => getDynamicVehicleCategoryList(''),
                'segment' => CommonUtilController.getPickList('VehicleCategory__c', 'Segment2__c'),
                'styling' => CommonUtilController.getPickList('Product2', 'Styling__c'),
                'wheelbase' => CommonUtilController.getPickList('VehicleCategory__c', 'Wheelbase__c'),
                'axle' => CommonUtilController.getPickList('VehicleCategory__c', 'AxleConfiguration__c'),
//            'trimLevel' => CommonUtilController.getPickList('Product2', 'TrimLevel__c'),
                'saPermission' => checkSAPermissionSet(),
                'currentCategoryId' => !vehicleStockList.isEmpty() ? vehicleStockList[0]?.Product__r?.VehicleCategory__c : null,
                'stockId' => CommonUtilController.convert15to18DigitId(stockId)
        };
    }

    /*
    * quoteCreator일 때, key값 가져오기
    * */
    @AuraEnabled
    public static String quoteCreatorData(String productId) {
        String categoryKey = '';
        if (String.isNotBlank(productId)) {
            Product2 product2 = [SELECT Id, Name, Styling__c, VehicleCategory__r.Name FROM Product2 WHERE Id =:productId];
            categoryKey = product2.VehicleCategory__r.Name + ',' + product2.Styling__c;
        }

        return categoryKey;
    }
    /**
     * @author th.kim
     * @description 2분할 Master 데이터 가져오기
     * @return MasterWrap 마스터 리스트
     */
//    @AuraEnabled
//    public static List<MasterWrap> getVehicleCategory() {
//
//        return getVehicleCategoryList('');
//    }

    /**
     * @author th.kim
     * @description 2분할 디테일 데이터 가져오기
     * @param categoryId 선택한 마스터 Category Id
     * @param tab 선택한 Tab
     *
     * @return ProductWrap 디테일 리스트
     */
    @AuraEnabled
    public static Map<String, Object> getProductWrap(String categoryKey, String tab) {
        List<String> keyList = new List<String>();
        for (String key : categoryKey.split(',')) {
            if(key.trim() == 'null' || key.trim() == null) {
                key = null;
            }else{
                key =  '\'' + key.trim() + '\'';
            }
            keyList.add(key);
        }
        if (!keyList.isEmpty()) {
            String whereConditions = '';
            if (tab == 'sa') {
                whereConditions += ' StockNoShow__c = false AND Status__c = \'재고 노출\'' +
                        ' AND VehicleStatus__c != \'출고됨\' AND ' ;
            }
            whereConditions += ' Product__r.VehicleCategory__r.Name = ' + keyList[0] ;
            whereConditions += keyList[1] != null ? ' AND ' + ' Product__r.Styling__c = ' + keyList[1] : '';
            return getDynamicProductWrapList(whereConditions, tab);
        } else {
            return null;
        }
    }

    /**
     * @author th.kim
     * @description 필터 Picklist 데이터 가져오기
     * @return {segment: Array(6), wheelbase: Array(31)}
     */
//    @AuraEnabled
//    public static Map<String, List<Map<String, String>>> getFilterPicklist() {
//
//        System.debug('getPickList :: ' + CommonUtilController.getPickList('Product2', 'Segment2__c'));
//        return new Map<String, List<Map<String, String>>>{
//            'segment' => CommonUtilController.getPickList('VehicleCategory__c', 'Segment2__c'),
//            'wheelbase' => CommonUtilController.getPickList('VehicleCategory__c', 'Wheelbase__c')
//        };
//    }

    /**
     * @author th.kim
     * @description 필터링하여 검색한 VehicleCategory 리스트
     * @param filterMap 필터링할 데이터
     *
     * @return 필터링된 VehicleCategory 리스트
     */
    @AuraEnabled
    public static List<MasterWrap> getFilteredCategoryList(Map<String, String> filterMap) {
        Map<String, String> modifiedMap = new Map<String, String>();
        for (String key : filterMap.keySet()) {
            String newKey = (key == 'Styling__c') ? key : 'VehicleCategory__r.' + key;
            modifiedMap.put(newKey, filterMap.get(key));
        }
        String whereConditions = CommonUtilController.buildWhereConditions(modifiedMap);
        return getDynamicVehicleCategoryList(whereConditions);
    }

    /**
     * @author th.kim
     * @description 필터링하여 검색한 Product 디테일 리스트
     * @param filterMap 필터링할 데이터
     * @param tab 현재 탭
     *
     * @return 필터링된 Product 디테일 리스트
     */
//    @AuraEnabled
//    public static List<ProductWrap> getFilteredProductWrapList(Map<String, Object> filterMap, String tab) {
//        System.debug(filterMap);
//        if (tab == 'sa') {
//            filterMap.put('StockNoShow__c', false);
//        }
//        String whereConditions = CommonUtilController.buildWhereConditions(filterMap);
//        return getDynamicProductWrapList(whereConditions);
//    }

    /**
     * @author th.kim
     * @description 재고 노출/미노출 업데이트
     * @param stockIdList 업데이트할 stock id 리스트
     * @param isStockNoShow 미노출/노출 여부
     */
    @AuraEnabled
    public static void updateStockShow(List<String> stockIdList, Boolean isStockNoShow) {

        List<VehicleStock__c> stockList = [SELECT Id, StockNoShow__c, Status__c FROM VehicleStock__c WHERE Id IN :stockIdList];
        Map<Boolean, String> stockNoShowMap = new Map<Boolean, String>{
                true => '재고 미노출(임시)',
                false => '재고 노출'
        };
        for (VehicleStock__c stock : stockList) {
            stock.StockNoShow__c = isStockNoShow;
            stock.Status__c = stockNoShowMap.get(isStockNoShow);
        }

        update stockList;
    }

    // /**
    //  * @author th.kim
    //  * @description 사전배정요청 생성
    //  * @param paramMap 선택한 데이터 리스트 맵
    //  */
    // @AuraEnabled
    // public static void createPreAssignRequest(Map<String, String> paramMap) {
    //     Savepoint savepoint = Database.setSavepoint();
    //     try {
    //         List<InsertDataWrap> insertDataWrapList = (List<InsertDataWrap>) JSON.deserialize(paramMap.get('selectedData'), List<InsertDataWrap>.class);

    //         Set<Id> productIdSet = new Set<Id>();
    //         for (InsertDataWrap data : insertDataWrapList) {
    //             productIdSet.add(data.id);
    //         }
    //         Map<Id, Product2> productMap = new Map<Id, Product2>([
    //                 SELECT Id, Quantity__c, (SELECT Id FROM VehicleStock__r ORDER BY CreatedDate ASC LIMIT 1)
    //                 FROM Product2
    //         ]);

    //         String type = paramMap.get('type');
    //         List<PreAssignRequest__c> preAssignRequestList = new List<PreAssignRequest__c>();
    //         for (InsertDataWrap data : insertDataWrapList) {

    //             PreAssignRequest__c preAssignRequest = new PreAssignRequest__c(
    //                     Opportunity__c = data.oppId,
    //                     Type__c = type,
    //                     Submitter__c = UserInfo.getUserId(),
    //                     Status__c = '제출'
    //             );
    //             if (type == '사전배정') {
    //                 preAssignRequest.VehicleStock__c = productMap.get(data.id).VehicleStock__r[0].Id;
    //             } else if (type == '대기리스트') {
    //                 preAssignRequest.VehicleCategory__c = data.id;
    //             }
    //             preAssignRequestList.add(preAssignRequest);
    //         }

    //         insert preAssignRequestList;

    //         List<Approval.ProcessSubmitRequest> approvalList = new List<Approval.ProcessSubmitRequest>();

    //         for (PreAssignRequest__c request : preAssignRequestList) {
    //             Approval.ProcessSubmitRequest approval = new Approval.ProcessSubmitRequest();
    //             approval.setObjectId(request.Id); // 레코드 ID 설정
    //             approval.setSubmitterId(request.Submitter__c); // 제출자 설정 (현재 사용자)
    //             approval.setComments('Submit Comments');

    //             // 승인 요청을 리스트에 추가
    //             approvalList.add(approval);
    //         }

    //         // 여러 레코드를 한 번에 제출
    //         if (!approvalList.isEmpty()) {
    //             List<Approval.ProcessResult> resultList = Approval.process(approvalList);

    //             // 제출 결과 출력
    //             for (Approval.ProcessResult result : resultList) {
    //             }
    //         }
    //     } catch (Exception e) {
    //         System.debug('err :: ' + e.getMessage() + ', track :: ' + e.getStackTraceString());
    //         Database.rollback(savepoint);
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    /**
     * @author th.kim
     * @description 기회 생성
     * @param selectedData JSON 타입 선택한 데이터 리스트
     */
//    @AuraEnabled
//    public static void createOpp(String selectedData) {
//        Savepoint savepoint = Database.setSavepoint();
//        try {
//            List<InsertDataWrap> insertDataWrapList = (List<InsertDataWrap>) JSON.deserialize(selectedData, List<InsertDataWrap>.class);
//
//            // Product2 데이터 수집
//            Set<Id> productIdSet = new Set<Id>();
//            Set<Id> accountIdSet = new Set<Id>();
//            for (InsertDataWrap data : insertDataWrapList) {
//                if (String.isNotBlank(data.id)) {
//                    productIdSet.add(data.id);
//                    accountIdSet.add(data.accountId);
//                }
//            }
//
//            // Product2 데이터 가져오기
//            Map<Id, Product2> productMap = new Map<Id, Product2>(
//                    [SELECT Id, Name, CarAmt__c, VehicleCategory__r.Name FROM Product2 WHERE Id IN :productIdSet]
//            );
//            // Account 데이터 가져오기
//            Map<Id, Account> accountMap = new Map<Id, Account>(
//                    [SELECT Id, Name FROM Account WHERE Id IN :accountIdSet]
//            );
//
//            // Standard Pricebook 및 PricebookEntry 가져오기
//            Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
//            List<PricebookEntry> pricebookEntryList = [
//                    SELECT Id, Product2Id, UnitPrice
//                    FROM PricebookEntry
//                    WHERE Pricebook2Id = :standardPricebook.Id
//                    AND Product2Id IN :productIdSet
//                    AND IsActive = TRUE
//            ];
//            Map<String, PricebookEntry> productPriceBookEntryMap = new Map<String, PricebookEntry>();
//            for (PricebookEntry entry : pricebookEntryList) {
//                productPriceBookEntryMap.put(entry.Product2Id, entry);
//            }
//
//            // Opportunity 생성
//            List<Opportunity> oppList = new List<Opportunity>();
//            for (InsertDataWrap data : insertDataWrapList) {
//                Opportunity opp = new Opportunity(
//                        Name = accountMap.get(data.accountId).Name + ' ' + productMap.get(data.id).Name,
//                        AccountId = data.accountId,
//                        StageName = 'Qualification',
//                        CloseDate = Date.today().addMonths(1)
//                );
//                oppList.add(opp);
//            }
//            insert oppList;
//
//            // OpportunityLineItem 생성
//            List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
//            for (Integer i = 0; i < insertDataWrapList.size(); i++) {
//                InsertDataWrap data = insertDataWrapList[i];
//                Product2 product = productMap.get(data.id);
//                PricebookEntry pbe = productPriceBookEntryMap.get(data.id);
//                Opportunity opp = oppList[i]; // 순서를 기반으로 Opportunity 매핑
//
//                if (product != null && pbe != null && opp != null) {
//                    OpportunityLineItem item = new OpportunityLineItem(
//                            OpportunityId = opp.Id,
//                            Product2Id = product.Id,
//                            PricebookEntryId = pbe.Id,
//                            Quantity = 1,
//                            UnitPrice = product.CarAmt__c
//                    );
//                    oppLineItemList.add(item);
//                } else {
//                    throw new QueryException('No Pricebook Entry');
//                }
//            }
//            insert oppLineItemList;
//        } catch (Exception e) {
//            System.debug('err :: ' + e.getMessage() + ', track :: ' + e.getStackTraceString());
//            Database.rollback(savepoint);
//            throw new AuraHandledException(e.getMessage());
//        }
//    }

    /**
     * @author th.kim
     * @description 동적으로 VehicleCategory 리스트 가져와서 MasterWrap으로 변환
     * @param whereConditions where 조건
     *
     * @return MasterWrap 리스트
     */
    private static List<MasterWrap> getDynamicVehicleCategoryList(String whereConditions) {

        String selectFields = 'Id, Name, CarAmt__c, Quantity__c, Styling__c, VehicleCategory__r.Segment2__c,CreatedDate, VehicleCategory__r.Name, WaitingListQty__c, StockNoShowQty__c,  After30DaysQty__c, After60DaysQty__c, ' +
                ' VehicleCategory__r.Quantity__c, VehicleCategory__r.WaitingListQty__c, VehicleCategory__r.StockNoShowQty__c, VehicleCategory__r.After30DaysQty__c, VehicleCategory__r.After60DaysQty__c, ' +
                ' ( SELECT VehicleOptionMaster__r.Price__c FROM ProductOption__r WHERE VehicleOptionMaster__r.Division__c =\'필수 옵션\' ) ';

//        String defaultWhereConditions = '(VehicleCategory__r.Quantity__c > 0 OR VehicleCategory__r.StockNoShowQty__c > 0 OR VehicleCategory__r.After30DaysQty__c > 0 OR VehicleCategory__r.After60DaysQty__c > 0)';
        String defaultWhereConditions = '(Quantity__c > 0 OR StockNoShowQty__c > 0 OR After30DaysQty__c > 0 OR After60DaysQty__c > 0)';
        if (String.isNotBlank(whereConditions)) {
            whereConditions += ' AND ' + defaultWhereConditions;
        } else {
            whereConditions = defaultWhereConditions;
        }

        // String query = CommonUtilController.buildQuery(selectFields, 'VehicleCategory__c', whereConditions, '');
        String query = CommonUtilController.buildQuery(selectFields, 'Product2', whereConditions, 'VehicleCategory__r.Quantity__c DESC');
        List<Product2> productList = Database.query(query);
        List<MasterWrap> MasterWrapList = new List<MasterWrap>();
        Map<String, Map<String, Object>> masterWrapMap = new Map<String, Map<String, Object>>();
        for (Product2 product : productList) {
            Decimal price = 0;
            for(ProductOption__c productOptionObj : product.ProductOption__r){
                if (productOptionObj.VehicleOptionMaster__r.Price__c != null) {
                    price += (Decimal)productOptionObj.VehicleOptionMaster__r.Price__c;
                }
            }
            masterWrapMap.put(product.VehicleCategory__r.Name + product.Styling__c,
                    new Map<String, Object>{
                            'Segment2__c' => product.VehicleCategory__r.Segment2__c,
                            'Name' => product.VehicleCategory__r.Name,
                            'Styling__c' => product.Styling__c,
                            'CarAmt__c' => sortCarAmt(masterWrapMap, product),
                            'Price__c' => price,
                            'Quantity__c' => sumMasterField('Quantity__c', masterWrapMap, product),
                            'WaitingListQty__c' => sumMasterField('WaitingListQty__c', masterWrapMap, product),
                            'StockNoShowQty__c'=> sumMasterField('StockNoShowQty__c', masterWrapMap, product),
                            'After30DaysQty__c' => sumMasterField('After30DaysQty__c', masterWrapMap, product),
                            'After60DaysQty__c' => sumMasterField('After60DaysQty__c', masterWrapMap, product),
                            'ETA__c' => sumMasterField('After30DaysQty__c', masterWrapMap, product) + sumMasterField('After60DaysQty__c', masterWrapMap, product)
                    });
        }

        for(String key : masterWrapMap.keySet()){
            MasterWrap MasterWrap = new MasterWrap(
                    masterWrapMap.get(key).get('Name') +','+masterWrapMap.get(key).get('Styling__c'),
                    (String)masterWrapMap.get(key).get('Segment2__c'),
                    (String)masterWrapMap.get(key).get('Name'),
                    (String)masterWrapMap.get(key).get('Styling__c'),
                    (Decimal)masterWrapMap.get(key).get('CarAmt__c'),
                    (Decimal)masterWrapMap.get(key).get('Price__c'),
                    (Integer)masterWrapMap.get(key).get('Quantity__c'),
                    (Integer) masterWrapMap.get(key).get('WaitingListQty__c'),
                    (Integer) masterWrapMap.get(key).get('StockNoShowQty__c'),
                    (Integer) masterWrapMap.get(key).get('After30DaysQty__c'),
                    (Integer) masterWrapMap.get(key).get('After60DaysQty__c'),
                    (Integer) masterWrapMap.get(key).get('ETA__c')
            );

            MasterWrapList.add(MasterWrap);
        }

//        MasterWrap MasterWrap = new MasterWrap(
//                product.Id,
//                product.VehicleCategory__r.Segment2__c,
//                product.VehicleCategory__r.Name,
//                product.Styling__c,
//                Integer.valueOf(product.VehicleCategory__r.Quantity__c),
//                Integer.valueOf(product.VehicleCategory__r.WaitingListQty__c),
//                Integer.valueOf(product.VehicleCategory__r.StockNoShowQty__c),
//                Integer.valueOf(product.VehicleCategory__r.PreAssignQty__c),
//                Integer.valueOf(product.VehicleCategory__r.After30DaysQty__c),
//                Integer.valueOf(product.VehicleCategory__r.After60DaysQty__c)
//        );

        return MasterWrapList;
    }

    /**
     * @author th.kim
     * @description 동적으로 VehicleStock 리스트 가져오기
     * @param whereConditions where 조건문
     *
     * @return VehicleStock__c 리스트
     */
    private static Map<String, Object> getDynamicProductWrapList(String whereConditions, String tab) {

        String selectFields = 'Id, Name, ModelYear__c, VehicleNo__c, CarColor__c, StockStatusDesc__c, ProductionSite__c, LongTermStock__c, IsSpecial__c, IsOptionDiscount__c,  ' +
                ' LongtermDiscountRate__c, StockNoShow__c, OptionDiscountRate__c,SpecialDiscountAmt__c, Remarks__c, Deviation__c, Product__c, Product__r.ProductStyling__c,' +
                ' Product__r.LocalYear__c, Product__r.ModelYear__c, Product__r.Quantity__c, Product__r.Colour__c, Product__r.DiscountKRW__c , Product__r.Deviation__c, Product__r.Remarks__c, ' +
                ' Product__r.VehicleCategory__c, Product__r.VehicleCategory__r.Name, Product__r.CarAmt__c, Product__r.SalesConditionMaster__r.Discount__c, Product__r.fm_DiscountKRW__c, ' +
                ' (SELECT VehicleStock__c FROM Opportunities__r) ';
        String orderBy = 'Product__r.LocalYear__c, Product__r.ModelYear__c';
        String query = CommonUtilController.buildQuery(selectFields, 'VehicleStock__c', whereConditions, orderBy);
        System.debug('query:'+query);
        List<VehicleStock__c> vehicleStockList = Database.query(query);

        List<ProductWrap> productWrapList = new List<ProductWrap>();
        Map<String, ProductWrap> productWrapMap = new Map<String, ProductWrap>();
        Set<Id> productIdSet = new Set<Id>();
        Map<Id, Decimal> optionPriceMap = new Map<Id, Decimal>();
        List<DetailAdditionalWrap> detailAdditionalWrapList = new List<DetailAdditionalWrap>();
        Map<String, Integer> detailAmountMap = new Map<String,Integer>();
        for (VehicleStock__c stock : vehicleStockList) {
            if ((stock.Opportunities__r == null || stock.Opportunities__r.size() == 0) && tab == 'sa') {
                productIdSet.add(stock.Product__c);
                if (stock.LongTermStock__c || stock.IsSpecial__c || stock.IsOptionDiscount__c) {
                    if (detailAmountMap.containsKey(stock.Product__c)) {
                        detailAmountMap.put(stock.Product__c, detailAmountMap.get(stock.Product__c) + 1);
                    } else {
                        detailAmountMap.put(stock.Product__c, 1);
                    }
                    Decimal totalDC = (stock?.OptionDiscountRate__c ?? 0) + (stock?.LongtermDiscountRate__c ?? 0);
                    Decimal totalDCPrice = (decimalNullCheck(stock.Product__r.CarAmt__c) * totalDC) / 100 +
                            (stock.SpecialDiscountAmt__c != null ? stock.SpecialDiscountAmt__c : 0);
                    Decimal discountedPrice = (stock?.Product__r?.CarAmt__c ?? 0) - (totalDCPrice + decimalNullCheck(optionPriceMap.get(stock.Product__c)));
                    detailAdditionalWrapList.add(new DetailAdditionalWrap(
                            stock.Id,
                            stock.Product__c,
                            stock.Product__r.LocalYear__c,            // localYear
                            stock.Product__r.ModelYear__c,            // modelYear
                            stock.Product__r.Colour__c,            // color
                            priceFloor(totalDCPrice),           // totalDC
                            stock.LongtermDiscountRate__c > 0 ? stock.LongtermDiscountRate__c / 100 : 0,              // longTermDiscountRate
                            stock.OptionDiscountRate__c > 0 ? stock.OptionDiscountRate__c / 100 : 0,// partsDC
                            stock.SpecialDiscountAmt__c != null ? stock.SpecialDiscountAmt__c : 0,             // specialDC
                            priceFloor(discountedPrice),          // discountedPrice
                            stock.Deviation__c,   // deviation
                            stock.Remarks__c,        // remarks
                            1                  // amount
                    ));
                }
            } else if (tab == 'admin'){
                productIdSet.add(stock.Product__c);
            }
        }
        List<Product2> productList = [SELECT Id,ProductStyling__c, LocalYear__c, ModelYear__c, Quantity__c, Colour__c, fm_DiscountKRW__c, DiscountKRW__c ,
                Deviation__c, Remarks__c, VehicleCategory__c, VehicleCategory__r.Name, CarAmt__c, SalesConditionMaster__r.Discount__c,
        ( SELECT VehicleOptionMaster__r.Price__c FROM ProductOption__r WHERE VehicleOptionMaster__r.Division__c ='필수 옵션' )
        FROM Product2
        WHERE Id IN:productIdSet];
        for(Product2 product : productList){
            Decimal optionPrice = 0;
            for (ProductOption__c productOptionObj : product.ProductOption__r) {
                optionPrice += productOptionObj.VehicleOptionMaster__r.Price__c != null ? productOptionObj.VehicleOptionMaster__r.Price__c : 0;
            }
            optionPriceMap.put(product.Id,optionPrice);
        }

        for (VehicleStock__c stock : vehicleStockList) {
            // 디테일 생성
            // 디테일 생성
            VehicleDetailWrap vehicleDetailWrap = new VehicleDetailWrap(
                    stock.Id,
                    '',
                    stock.LongtermDiscountRate__c,
                    stock.Product__r.ModelYear__c,
                    stock.Product__r.LocalYear__c,
                    stock.VehicleNo__c,
                    stock.ProductionSite__c,
                    stock.Product__r.Colour__c,
                    stock.StockStatusDesc__c,
                    stock.StockNoShow__c,
                    stock.Remarks__c,
                    stock.Deviation__c
            );
            Product2 product = stock.Product__r;
            Decimal carAmt = product.CarAmt__c != null ? product.CarAmt__c : 0;
            Decimal discountRate = (product.SalesConditionMaster__r != null && product.SalesConditionMaster__r.Discount__c != null)
                    ? product.SalesConditionMaster__r.Discount__c
                    : 0;
            Decimal optionPrice = optionPriceMap.containsKey(product.Id) && optionPriceMap.get(product.Id) != null
                    ? optionPriceMap.get(product.Id)
                    : 0;

            Decimal dcPrice = (carAmt * discountRate) / 100;
            Decimal totalPrice = (carAmt - dcPrice) + optionPrice;

            if (product != null) {
                Integer additionalAmount = 0;
                if(detailAmountMap.containsKey(product.Id)) additionalAmount = detailAmountMap.get(product.Id);
                    ProductWrap productWrap = productWrapMap.get(product.Id);
                    // ProductWrap 없을 시 새로 생성
                if (productWrap == null) {
                    productWrap = new ProductWrap(
                            product.Id,
                            product.LocalYear__c,
                            product.ModelYear__c,
                            product.Colour__c,
                            priceFloor(dcPrice),
                            priceFloor(totalPrice),
                            product.Deviation__c,
                            product.Remarks__c,
                            tab != 'sa' ? Integer.valueOf(product.Quantity__c) :
                                    Integer.valueOf(product.Quantity__c) - additionalAmount < 0 ? 0 : Integer.valueOf(product.Quantity__c) - additionalAmount
                    );
                    productWrapMap.put(product.Id, productWrap);
                    productWrapList.add(productWrap);
                }
                // ProductWrap에 Detail 데이터 넣어주기
                productWrap.children.add(vehicleDetailWrap);
            }
        }
        Map<String, Object> wrapMap = new Map<String,Object>{
                'detailAdditionalWrapList' => detailAdditionalWrapList,
                'productWrapList' => productWrapList
        };
        return wrapMap;
    }

    private static Integer sumMasterField(String fieldName, Map<String,Map<String,Object>> masterMap, Product2 product) {
        Integer fieldValue = Integer.valueOf(product.get(fieldName));
        Integer totalNumber = masterMap.containsKey(product.VehicleCategory__r.Name + product.Styling__c) == false ?
                fieldValue :
                (Integer)masterMap.get(product.VehicleCategory__r.Name + product.Styling__c).get(fieldName) + (Integer)fieldValue;
        return totalNumber;
    }

    private static Decimal sortCarAmt(Map<String,Map<String,Object>> masterMap, Product2 product) {
        Decimal fieldValue = decimalNullCheck((Decimal)product.get('CarAmt__c'));
        Decimal masterMapValue = masterMap.containsKey(product.VehicleCategory__r.Name + product.Styling__c) == false
                ? fieldValue : String.valueOf(masterMap.get(product.VehicleCategory__r.Name + product.Styling__c).get('CarAmt__c')).contains(',')
                        ? Decimal.valueOf(String.valueOf(masterMap.get(product.VehicleCategory__r.Name + product.Styling__c).get('CarAmt__c')).replace(',',''))
                        :  Decimal.valueOf(String.valueOf(masterMap.get(product.VehicleCategory__r.Name + product.Styling__c).get('CarAmt__c')));
        Decimal carAmt = fieldValue > masterMapValue ? fieldValue : masterMapValue;

        return carAmt;
    }
//
//    private static Object formatCurrency(Decimal value) {
//        String formatted = value != null ? value.setScale(0, System.RoundingMode.FLOOR).format() : '0';
//        return formatted;
//    }

    private static Decimal decimalNullCheck(Decimal value) {
        Decimal returnValue = value != null ? value : 0;
        return returnValue;
    }

    @AuraEnabled
    public static Boolean checkSAPermissionSet() {
        Id userId = UserInfo.getUserId();
        List<PermissionSetAssignment> permissionSets = [SELECT Id, PermissionSet.Name, PermissionSet.Label FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSet.Name = 'SA'];

        return !permissionSets.isEmpty();
    }

    public static Decimal priceFloor(Decimal price){
        return Math.floor(price/100000) * 100000;
    }
}