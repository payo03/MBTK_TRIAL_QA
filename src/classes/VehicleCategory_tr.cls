/*************************************************************
 * @author : th.kim
 * @date : 2024-11-20
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author                  Modification
 * 1.0          2024-11-20      th.kim                  Created
 * 1.1          2025-02-26      payo03@solomontech.net  ERP Code I/F로직 추가
 * 1.2          2025-02-26      jh.jung                 setAvgLocalCost 추가
**************************************************************/
public without sharing class VehicleCategory_tr extends TriggerHandler {

    /** TriggerHandler */
    private final List<VehicleCategory__c> newList { get; set; }
    private final List<VehicleCategory__c> oldList { get; set; }
    private final Map<Id, VehicleCategory__c> oldMap { get; set; }
    private final Map<Id, VehicleCategory__c> newMap { get; set; }

    private final static String MAN_CODE = 'MAN5000';
    private final static String TRP_CODE = 'MAN5001';
    private final static String LOG_TYPE = 'ERP_MODEL';
    private final static String IF_ID = InterfaceSAP.IF_SMS009;

    public VehicleCategory_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        oldMap = (Map<Id, VehicleCategory__c>) Trigger.oldMap;
        newMap = (Map<Id, VehicleCategory__c>) Trigger.newMap;
    }

    public override void beforeInsert() {
        setName();
        setAvgLocalCost();
    }

    public override void beforeUpdate() {
        setDefaultValues();
        setName();
        setAvgLocalCost();
    }

    public override void afterInsert() {

    }

    public override void afterUpdate() {

    }

    private void setDefaultValues() {

        for (VehicleCategory__c newOne : newList) {
            VehicleCategory__c oldOne = oldMap.get(newOne.Id);

            // VehicleCategory 수량 직접 Update 방지
            if (oldOne != null && (oldOne.Quantity__c != newOne.Quantity__c)) throw new TriggerHandlerException('Update Number Field Direct Error. Use AdjustField__c');

            /*
                # 수량 Update A to Z
                - 재고수량은 사용자의 동시성 제어가 불가능함. 예를들어 같은 시각에 2명이상의 사용자가 수량을 같이 Update한다면... SELECT 시점의 수량에 Update하게 됨
                    따라서 재고수량의 필드는 AdjustField__c를 통해 Trigger호출하여 수량 Update

                1. Map<String, Decimal> quantityMap = new Map<String, Decimal>();
                2. quantityMap.put('Quantity__c', 3);
                3. quantityMap.put('StockNoShowQty__c', -2);
                4. productObj.AdjustField__c = JSON.serialize(quantityMap);
                5. update productObj;
            */
            if (newOne.AdjustField__c != null) {
                Map<String, Decimal> mapQuantity = (Map<String, Decimal>) JSON.deserialize(newOne.AdjustField__c, Map<String, Decimal>.class);
                for (String fieldName : mapQuantity.keySet()) {
                    newOne.put(fieldName, Decimal.valueOf(String.valueOf(oldOne.get(fieldName))) + mapQuantity.get(fieldName));
                    if(Integer.valueOf(newOne.get(fieldName)) < 0) newOne.put(fieldName, 0);
                }

                // 값 저장 후 초기화
                newOne.AdjustField__c = null;
            }
        }
    }

    /**
     * @author jh.jung
     * @description AvgLocalCost 지정
     */
    private void setAvgLocalCost() {

        Map<String, AvgLocalCost__c> avgLocalCostMap = new Map<String, AvgLocalCost__c>();
        List<AvgLocalCost__c> avgLocalCostList = [
                SELECT Id, ReportSpec__c
                FROM AvgLocalCost__c
        ];

        for(AvgLocalCost__c tempObj : avgLocalCostList) {
            avgLocalCostMap.put(tempObj.ReportSpec__c, tempObj);
        }

        for(VehicleCategory__c categoryNew : newList) {
            if(Trigger.isUpdate) {
                VehicleCategory__c categoryOld = oldMap.get(categoryNew.Id);
                // 데이터 변경 없을 시 패스
                if (categoryOld.Name == categoryNew.Name) {
                    continue;
                }
            }

            System.debug('categoryNew.Name ::: ' + categoryNew.Name);
            categoryNew.AvgLocalCost__c = avgLocalCostMap.get(categoryNew.Name)?.Id;
        }
    }

    /**
     * @author th.kim
     * @description Naming Rule 설정
     *              (모델타입-WeightCapacity__c-마력-Axle-서스펜션-캡-휠베이스)
     */
    private void setName() {

        for(VehicleCategory__c categoryNew : newList) {

            if(Trigger.isUpdate) {
                VehicleCategory__c categoryOld = oldMap.get(categoryNew.Id);
                // 데이터 변경 없을 시 패스
                if (categoryOld.ModelType__c == categoryNew.ModelType__c
                    && categoryOld.WeightCapacity__c == categoryNew.WeightCapacity__c
                    && categoryOld.HorsePower__c == categoryNew.HorsePower__c
                    && categoryOld.AxleConfiguration__c == categoryNew.AxleConfiguration__c
                    && categoryOld.Suspension__c == categoryNew.Suspension__c
                    && categoryOld.CabMark__c == categoryNew.CabMark__c
                    && categoryOld.WheelBase__c == categoryNew.WheelBase__c) {
                    continue;
                }
            }

            String cabMark = CommonUtilController.getPicklistLabelForLabel('VehicleCategory__c', 'CabMark__c',categoryNew.CabMark__c);
            String wheelbase = CommonUtilController.getPicklistLabelForLabel('VehicleCategory__c', 'WheelBase__c',categoryNew.WheelBase__c);

            List<String> nameList = new List<String>();
            if(String.isNotBlank(categoryNew.ModelType__c)) nameList.add(categoryNew.ModelType__c);
            if(String.isNotBlank(categoryNew.HorsePower__c)) {
                if(String.isNotBlank(categoryNew.WeightCapacity__c)) {
                    nameList.add(categoryNew.WeightCapacity__c + '.' + categoryNew.HorsePower__c);
                } else {
                    nameList.add(categoryNew.HorsePower__c);
                }
            }
            if(String.isNotBlank(categoryNew.AxleConfiguration__c)) nameList.add(categoryNew.AxleConfiguration__c);
            if(String.isNotBlank(categoryNew.Suspension__c)) nameList.add(categoryNew.Suspension__c);
//            if(String.isNotBlank(categoryNew.Kind__c)) nameList.add(categoryNew.Kind__c);
            if(String.isNotBlank(cabMark) && categoryNew.CabMark__c != '0') nameList.add(cabMark);
            if(String.isNotBlank(wheelbase)) nameList.add(wheelbase);

            categoryNew.Name = String.join(nameList, ' ');
        }
    }
}