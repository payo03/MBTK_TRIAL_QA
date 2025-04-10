/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-10
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-10        San.Kang           Created
**************************************************************/
public without sharing class CreatedMngController {

    public class SpecTypeNoWrapper {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String form {get; set;}
        @AuraEnabled public String mngNo {get; set;}
        @AuraEnabled public Date typeDateTractor {get; set;}
        @AuraEnabled public String vehicleName {get; set;}
        @AuraEnabled public String stdLoad {get; set;}
        @AuraEnabled public String typeNo {get; set;}
        @AuraEnabled public Date typeDate {get; set;}
        @AuraEnabled public String capSize {get; set;}
        @AuraEnabled public String modelYear {get; set;}
        @AuraEnabled public String totalWeight {get; set;}
        @AuraEnabled public String maxLoad {get; set;}
        @AuraEnabled public String color {get; set;}
        @AuraEnabled public String engineType {get; set;}
        @AuraEnabled public String remark {get; set;}
        @AuraEnabled public String remark2 {get; set;}
        @AuraEnabled public String remark3 {get; set;}
        @AuraEnabled public String type {get; set;}

        public SpecTypeNoWrapper() {}

        public SpecTypeNoWrapper(String id, String form, String mngNo, Date typeDateTractor, String vehicleName, String stdLoad, String typeNo, date typeDate,
                String capSize, String modelYear, String totalWeight, String maxLoad, String color, String engineType,
                String remark, String remark2, String remark3, String type) {
            this.id = id;
            this.form = form;
            this.mngNo = mngNo;
            this.typeDateTractor = typeDateTractor;
            this.vehicleName = vehicleName;
            this.stdLoad = stdLoad;
            this.typeNo = typeNo;
            this.typeDate = typeDate;
            this.capSize = capSize;
            this.modelYear = modelYear;
            this.totalWeight = totalWeight;
            this.maxLoad = maxLoad;
            this.color = color;
            this.engineType = engineType;
            this.remark = remark;
            this.remark2 = remark2;
            this.remark3 = remark3;
            this.type = type;
        }
    }

    @AuraEnabled
    public static Map<String, Object> getInitData(String vehicleStockId) {
        VehicleStock__c vehicleStock = [SELECT Id, Product__r.Segment2__c, SpecShort__c FROM VehicleStock__c WHERE Id =:vehicleStockId];
        String type = vehicleStock?.Product__r?.Segment2__c != 'TPP' ? '제원관리번호': '형식승인번호';
        String whereConditions = 'Form__c LIKE \'%' + vehicleStock.SpecShort__c + '%\'';

        List<Map<String, String>> options = new List<Map<String, String>>();
        List<AggregateResult> groupedYears = [
                SELECT ModelYear__c
                FROM SpecTypeNo__c
                WHERE ModelYear__c != null
                AND Form__c LIKE :('%' + vehicleStock.SpecShort__c + '%')
                GROUP BY ModelYear__c
                ORDER BY ModelYear__c DESC
        ];
        for (AggregateResult ar : groupedYears) {
            String year = (String) ar.get('ModelYear__c');
            options.add(new Map<String, String>{
                    'label' => year,
                    'value' => year
            });
        }
        return new Map<String, Object>{
            'specTypeNoList' => getSpecTypeNoList(type, whereConditions),
            'modelYear' => options
        };
    }

    @AuraEnabled
    public static List<SpecTypeNoWrapper> searchSpecTypeNo(String type, String vehicleStockId, Map<String, String> filterMap) {
        System.debug('filterMap'+filterMap);
        VehicleStock__c vehicleStock = [SELECT Id, Product__r.Segment2__c, SpecShort__c FROM VehicleStock__c WHERE Id =:vehicleStockId];
        List<String> filters = new List<String>();
        String whereConditions = 'Form__c LIKE \'%' + vehicleStock.SpecShort__c + '%\' AND ';
        for (String key : filterMap.keySet()) {
            String value = filterMap.get(key) != null ?  filterMap.get(key) : null ;
            if (value != null) {
                filters.add(key + ' LIKE \'%' + String.escapeSingleQuotes(value) + '%\'');
            }
        }
        // 동적 필터 추가
        if (!filters.isEmpty()) {
            whereConditions += String.join(filters, ' AND ');
        }

        return getSpecTypeNoList(type, whereConditions);
    }

    public static List<SpecTypeNoWrapper> getSpecTypeNoList(String type, String whereConditions) {

        String selectFields = getField(Schema.SObjectType.SpecTypeNo__c.fields.getMap());
        whereConditions += whereConditions != '' ? ' AND Type__c = \''+ type +'\'' : ' Type__c = \''+ type +'\'';
        String query = CommonUtilController.buildQuery(selectFields, 'SpecTypeNo__c', whereConditions, 'ModelYear__c');
        System.debug('specTypeNos'+query);
        List<SpecTypeNo__c> specTypeNos = Database.query(query);
        System.debug('specTypeNos'+specTypeNos);
        List<SpecTypeNoWrapper> SpecTypeNoWrappers = new List<SpecTypeNoWrapper>();

        for(SpecTypeNo__c specTypeNo : specTypeNos){

            SpecTypeNoWrapper SpecTypeNoWrapper = new SpecTypeNoWrapper(
                specTypeNo.Id,
                specTypeNo.Form__c,
                specTypeNo.MngNo__c,
                specTypeNo.TypeDateTractor__c,
                specTypeNo.VehicleName__c,
                specTypeNo.StdLoad__c,
                specTypeNo.TypeNo__c,
                specTypeNo.TypeDate__c,
                specTypeNo.CapSize__c,
                specTypeNo.ModelYear__c,
                specTypeNo.TotalWeight__c,
                specTypeNo.MaxLoad__c,
                specTypeNo.Color__c,
                specTypeNo.EngineType__c,
                specTypeNo.Remark__c,
                specTypeNo.Remark2__c,
                specTypeNo.Remark3__c,
                specTypeNo.Type__c
            );
            SpecTypeNoWrappers.add(SpecTypeNoWrapper);
        }
        System.debug('test');
        return SpecTypeNoWrappers;
    }

    public static String getField(Map<String, Schema.SObjectField> ObjMap){
        List<String> accessibleFields = new List<String>();

        for (String fieldName : ObjMap.keySet()) {
            Schema.DescribeFieldResult fieldDesc = ObjMap.get(fieldName).getDescribe();
            // 접근 가능한 필드만 추가
            if (fieldDesc.isAccessible()) {
                accessibleFields.add(fieldName);
            }
        }
        return String.join(accessibleFields, ', ');
    }

    @AuraEnabled
    public static void saveSpecTypeNo(String specTypeNoId, String vehicleStockId){
        try{
            VehicleStock__c vehicleStock = [SELECT Id FROM VehicleStock__c WHERE Id = :vehicleStockId];

            if(vehicleStock != null){
                vehicleStock.SpecTypeNo__c = specTypeNoId;
                update vehicleStock;
            }
        }catch (Exception e){
            System.debug('Error' + e);
        }

    }

}