/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-18      payo03@solomontech.net           Created
  1.1      2025-03-18      payo03@solomontech.net           Naming Rule 적용
  1.2      2025-04-01      payo03@solomontech.net           신규 Product생성시 기존재 Option 복제
*/
public without sharing class Product2_tr extends TriggerHandler {
    
    private List<Product2>    newList { get; set; } // Test13
    private List<Product2>    oldList { get; set; }
    private Map<Id, Product2> newMap  { get; set; }
    private Map<Id, Product2> oldMap  { get; set; }

    public static final Map<String, String> CAB_MARK_MAP = CommonUtilController.getPickListMap('Product2', 'CabMark__c');
    public static final Map<String, String> WHEEL_BASE_MAP = CommonUtilController.getPickListMap('Product2', 'WheelBase__c');

    public Product2_tr() {
        newList = (List<Product2>)    Trigger.new;
        oldList = (List<Product2>)    Trigger.old;
        newMap  = (Map<Id, Product2>) Trigger.newMap;
        oldMap  = (Map<Id, Product2>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        setName();
    }

    public override void beforeUpdate() {
        setName();
        setDefaultValues();
    }

    public override void afterInsert() {
         makeOptionJunction();
    }

    private void setDefaultValues() {

        for(Product2 newOne : newList) {
            Product2 oldOne = oldMap.get(newOne.Id);

            // Product2 수량 직접 Update 방지
            if(oldOne != null &&
                (
                    (oldOne.Quantity__c != newOne.Quantity__c)/* ||
                    (oldOne.StockV01__c != newOne.StockV01__c) ||
                    (oldOne.StockH01__c != newOne.StockH01__c)*/
                )
            ) {
                throw new TriggerHandlerException('Update Number Field Direct Error. Use AdjustField__c');
            }

            /*
                # 수량 Update A to Z
                - 재고수량은 사용자의 동시성 제어가 불가능함. 예를들어 같은 시각에 2명이상의 사용자가 수량을 같이 Update한다면... SELECT 시점의 수량에 Update하게 됨
                    따라서 재고수량의 필드는 AdjustField__c를 통해 Trigger호출하여 수량 Update

                1. Map<String, Decimal> quantityMap = new Map<String, Decimal>();
                2. quantityMap.put('Quantity__c', 3);
                3. quantityMap.put('StockV01__c', -2);
                4. productObj.AdjustField__c = JSON.serialize(quantityMap);
                5. update productObj;
            */
            if(newOne.AdjustField__c != null) {
                Map<String, Decimal> mapQuantity = (Map<String, Decimal>)JSON.deserialize(newOne.AdjustField__c, Map<String, Decimal>.class);
                for(String fieldName : mapQuantity.keySet()) {
                    newOne.put(fieldName, Decimal.valueOf(String.valueOf(oldOne.get(fieldName))) + mapQuantity.get(fieldName));
                    if(Integer.valueOf(newOne.get(fieldName)) < 0) newOne.put(fieldName, 0);
                }

                // 값 저장 후 초기화
                newOne.AdjustField__c = null;
            }
        }
    }

    // ver1.1 Naming Rule 적용
    /*  25-03-18. 전도형 책임님 메신저 내용 참조
        Specshort + CabMark + WheelBase
        Option(Sopiler LNS Premium OTV)
        LMY 까지만..

        이렇게 되면 카모델 가격이 다르면 이름도 다르게 구분되서 보여줄수 잇을것같내요
    */
    private void setName() {

        for(Product2 newObj : newList) {

            if(Trigger.isUpdate) {
                Product2 oldObj = oldMap.get(newObj.Id);
                // 데이터 변경 없을 시 패스
                if (
                        oldObj.SpecShort__c == newObj.SpecShort__c &&
                        oldObj.CabMark__c == newObj.CabMark__c &&
                        oldObj.WheelBase__c == newObj.WheelBase__c &&

                        oldObj.IsSpoiler__c == newObj.IsSpoiler__c &&
                        oldObj.IsLNS__c == newObj.IsLNS__c &&
                        oldObj.TrimLevel__c == newObj.TrimLevel__c &&
                        oldObj.IsOTV__c == newObj.IsOTV__c &&
                        oldObj.LocalYear__c == newObj.LocalYear__c
                ) {
//                    continue;
                }
            }

            String cabMark = CommonUtilController.getPicklistLabelForLabel('Product2', 'CabMark__c', newObj.CabMark__c);
            String wheelBase = CommonUtilController.getPicklistLabelForLabel('Product2', 'WheelBase__c', newObj.WheelBase__c);
            String trimLevel = CommonUtilController.getPicklistLabelForLabel('Product2', 'TrimLevel__c', newObj.TrimLevel__c);

            List<String> defaultList = new List<String>();
            defaultList.add(newObj.SpecShort__c);
            if(String.isNotBlank(cabMark) && newObj.CabMark__c != '0') defaultList.add(cabMark);
            if(String.isNotBlank(wheelBase)) defaultList.add(wheelBase);

            List<String> additionalList = new List<String>();
            if(String.isNotBlank(newObj.LocalYear__c)) additionalList.add(newObj.LocalYear__c);
            if(newObj.IsSpoiler__c) additionalList.add('SPOILER');
            if(newObj.IsLNS__c) additionalList.add('LNS');
            if(String.isNotBlank(trimLevel)) additionalList.add(trimLevel.toUpperCase());
            if(newObj.IsOTV__c) additionalList.add('OTV');

            newObj.Name = String.join(defaultList, ' ') + ' ' + String.join(additionalList, '_');
        }
    }

    // ver1.2 신규 Product생성시 기존재 Option 복제
    private void makeOptionJunction() {
        List<String> labelList = new List<String>{'SpecShort__c', 'CabMark__c', 'WheelBase__c'};

        Map<String, List<SObject>> keyMap = CommonUtilController.getObjectMapJoin(newList, labelList, '^');
        String selectFields     = 'Id, Product__c, VehicleOptionMaster__c, Product__r.SpecShort__c, Product__r.CabMark__c, Product__r.WheelBase__c';
        String fromObject       = 'ProductOption__c';
        String whereConditions  = '';
        for(String key : keyMap.keySet()) {
            List<String> keyFields = key.split('\\^');

            whereConditions += '(Product__r.SpecShort__c = \'' + keyFields.get(0) + '\' AND Product__r.CabMark__c = \'' + keyFields.get(1) + '\' AND Product__r.WheelBase__c = \'' + keyFields.get(2) + '\') OR ';
        }
        whereConditions = whereConditions.substring(0, whereConditions.length() - 3);

        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, whereConditions);
        List<ProductOption__c> objList = Database.query(buildQuery);

        List<ProductOption__c> optionList = new List<ProductOption__c>();
        for(ProductOption__c obj : objList) {
            String key = obj.Product__r.SpecShort__c + '^' + obj.Product__r.CabMark__c + '^' + obj.Product__r.WheelBase__c;

            // Key별 ProductList
            for(SObject SObj : keyMap.get(key)) {
                ProductOption__c option = new ProductOption__c();

                option.Product__c = SObj.Id;
                option.VehicleOptionMaster__c = obj.VehicleOptionMaster__c;
                optionList.add(option);
            }
        }
        if(!optionList.isEmpty()) insert optionList;
    }
}