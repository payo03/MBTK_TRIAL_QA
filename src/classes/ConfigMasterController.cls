/**
* @Author            : payo03@solomontech.net
* @Description 		 : Config 설정화면
* @Target            : configView LWC
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-11      payo03@solomontech.net           Created
  1.0      2025-03-17      blacktick@solomontech.net        upsertConfigMaster PL_CAL_INFO 인 경우
*/
public without sharing class ConfigMasterController {

    private final static String RECORDTYPE_SALES_CONDITION = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('SALES_CONDITION').getRecordTypeId();
    private final static String RECORDTYPE_PL_CAL_INFO = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('PL_CAL_INFO').getRecordTypeId();

    @AuraEnabled
    public static Map<String, Object> selectConfigMaster(String configCode) {
        Map<String, Object> returnMap = new Map<String, Object>();
        List<HierarchyStructure> hierarchyList = new List<HierarchyStructure>();

        String fields = 'Id, Name, Value__c, Description__c, Parent__c, Parent__r.Name, RecordType.DeveloperName';
        String fromObject = 'ConfigMaster__c';
        String whereCondition = configCode != '' ? 'Name = \'' + configCode + '\'' : '';
        String orderBy = 'Name';
        String query = CommonUtilController.buildQuery(fields, fromObject, whereCondition, orderBy);

        List<ConfigMaster__c> masterList = Database.query(query);
        returnMap.put('List', masterList);

        List<HierarchyStructure> structureList = new List<HierarchyStructure>();
        Map<String, HierarchyStructure> structureMap = new Map<String, HierarchyStructure>();
        for(ConfigMaster__c master : masterList) {
            String id = master.Id;
            String code = master.Name;
            String value = master.Value__c;
            String pCode = master.Parent__r.Name;

            HierarchyStructure structure = new HierarchyStructure(id, code, value, pCode);
            structureList.add(structure);
            structureMap.put(code, structure);
        }

        for(HierarchyStructure structure : structureList) {
            if(structure.pCode != null) {
                if(structureMap.containsKey(structure.pCode)) {
                    structureMap.get(structure.pCode).children.add(structure);
                } else {
                    hierarchyList.add(structure);
                }
            } else {
                hierarchyList.add(structure);
            }
        }
        returnMap.put('Hierarchy', hierarchyList);

        return returnMap;
    }

    @AuraEnabled
    public static List<ConfigDetail__c> selectConfigDetailById(Id paramId) {
        List<ConfigDetail__c> detailList = [
                SELECT Id, Name,
                        Attribute1__c, Attribute2__c, Attribute3__c, Attribute4__c, Attribute5__c, Attribute6__c, Attribute7__c, Attribute8__c, Attribute9__c, Attribute10__c,
                        Attribute11__c, Attribute12__c, Attribute13__c, Attribute14__c, Attribute15__c, Attribute16__c, Attribute17__c, Attribute18__c, Attribute19__c, Attribute20__c,
                        ConfigMaster__c, ConfigMaster__r.Name
                FROM ConfigDetail__c
                WHERE ConfigMaster__c = :paramId
        ];

        return detailList;
    }

    @AuraEnabled
    public static void upsertConfigMaster(List<Map<String, Object>> paramMList) {
        Map<String, Id> masterMap = new Map<String, Id>();
        for(ConfigMaster__c master : [
            SELECT Id, Name
            FROM ConfigMaster__c
        ]) {
            masterMap.put(master.Name, master.Id);
        }

        List<ConfigMaster__c> upsertList = new List<ConfigMaster__c>();
        for(Map<String, Object> paramM : paramMList) {
            System.debug(paramM);
            String id = String.valueOf(paramM.get('Id'));
            String name = String.valueOf(paramM.get('Name'));
            String value = String.valueOf(paramM.get('Value__c'));
            String description = String.valueOf(paramM.get('Description__c'));
            String parentCode = String.valueOf(paramM.get('parentName'));

            // Case. id가 != null, UPDATE, id == null, INSERT
            ConfigMaster__c master = new ConfigMaster__c();
            if(id != null) master.Id = id;

            master.Name = name.toUpperCase();
            master.Value__c = value.toUpperCase();
            master.Description__c = description;

            master.Parent__c = null;
            if(parentCode != null && parentCode != '') master.Parent__c = masterMap.get(parentCode.toUpperCase());

            upsertList.add(master);
        }
        System.debug(upsertList);

        upsert upsertList;
    }
    
    @AuraEnabled
    public static void upsertConfigDetail(List<ConfigDetail__c> paramDList) {

        ConfigMaster__c master = [
                SELECT Id, RecordTypeId, (SELECT Id, Name FROM ConfigDetails__r)
                FROM ConfigMaster__c
                WHERE Id = :paramDList.get(0).ConfigMaster__c
        ];

        if (master.RecordTypeId.equals(RECORDTYPE_PL_CAL_INFO)) {
            // Config Code값이 PL_CAL_INFO일 경우, Name이 있으면 업데이트, 없으면 추가
            List<ConfigDetail__c> insertDetailList = new List<ConfigDetail__c>();
            List<ConfigDetail__c> updateDetailList = new List<ConfigDetail__c>();

            List<AvgLocalCost__c> upsertLocalCostList = new List<AvgLocalCost__c>();

            Map<String, ConfigDetail__c> detailMap = new Map<String, ConfigDetail__c>();
            for(ConfigDetail__c detail : master.ConfigDetails__r) {
                  detailMap.put(detail.Name, detail);
            }
            for(ConfigDetail__c detail : paramDList) {
                if(detailMap.get(detail.Name) != null) {
                    detail.Id = detailMap.get(detail.Name).Id;
                    updateDetailList.add(detail);
                } else {
                    insertDetailList.add(detail);
                }
                AvgLocalCost__c avgLocalCost = new AvgLocalCost__c();
                avgLocalCost.ReportSpec__c = detail.Name;
                avgLocalCost.LocalCostAvg__c = Decimal.valueOf(detail.Attribute1__c.trim().replaceAll('[.,]', ''));
                avgLocalCost.PdiCostAvg__c = Decimal.valueOf(detail.Attribute2__c.trim().replaceAll('[.,]', ''));
                avgLocalCost.OtherCostAvg__c = Decimal.valueOf(detail.Attribute3__c.trim().replaceAll('[.,]', ''));
                avgLocalCost.Active__c = 'true'.equals(detail.Attribute4__c.toLowerCase());
                upsertLocalCostList.add(avgLocalCost);
            }
            // CustomDetail 반영
            if(!updateDetailList.isEmpty()) update updateDetailList;
            if(!insertDetailList.isEmpty()) insert insertDetailList;

            // AvgLocalCost 반영
            if(!upsertLocalCostList.isEmpty()) upsert upsertLocalCostList ReportSpec__c;

            // 모든 카테고리에 평균 로컬 비용 연결
            List<VehicleCategory__c> updateVehicleCategoryList = new List<VehicleCategory__c>();
            Map<String, AvgLocalCost__c> avgReportSpecMap = new Map<String, AvgLocalCost__c>();
            for(AvgLocalCost__c tempALC : upsertLocalCostList) {
                avgReportSpecMap.put(tempALC.ReportSpec__c, tempALC);
            }
            List<VehicleCategory__c> vehicleCategoryList = [
                    SELECT Id, Name
                    FROM VehicleCategory__c
//                    WHERE Report_Spec__c IN :avgReportSpecMap.keySet()
            ];
            for(VehicleCategory__c vehicleCategory : vehicleCategoryList) {
                if(avgReportSpecMap.get(vehicleCategory.Name) == null) {
                    vehicleCategory.AvgLocalCost__c = null;
                } else {
                    vehicleCategory.AvgLocalCost__c = avgReportSpecMap.get(vehicleCategory.Name).Id;
                }
                updateVehicleCategoryList.add(vehicleCategory);
            }
            System.debug(updateVehicleCategoryList);
            update updateVehicleCategoryList;
        } else {
            upsert paramDList;

            // Config Code값이 SalesCondition일경우
            if (master.RecordTypeId.equals(RECORDTYPE_SALES_CONDITION)) Database.executeBatch(new SalesCondition_ba(String.valueOf(Date.today())));
        }
    }

    @AuraEnabled
    public static void deleteConfigDetail(List<Id> idList) {
        List<ConfigDetail__c> deleteList = [
                SELECT Id
                FROM ConfigDetail__c
                WHERE Id IN :idList
        ];

        delete deleteList;
    }

    public class HierarchyStructure {
        @AuraEnabled public String id;
        @AuraEnabled public String code;
        @AuraEnabled public String value;
        @AuraEnabled public String pCode;
        @AuraEnabled public List<HierarchyStructure> children;
    
        public HierarchyStructure(String id, String code, String value, String pCode) {
            this.id = id;
            this.code = code;
            this.value = value;
            this.pCode = pCode;
            this.children = new List<HierarchyStructure>();
        }
    }
}