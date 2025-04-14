/**
* @Author            : payo03@solomontech.net
* @Description 		 : CustomConfig화면을 통한 SalesCondition 생성 Batch
* @Target            : CustomConfigDetail__c
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-03      payo03@solomontech.net           Created
  1.1      2025-04-14      payo03@solomontech.net           판매조건 Key값 변경
*/
public without sharing class SalesCondition_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    public Date basisDate;

    private final static String RECORDTYPE_SALES_CONDITION = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('SALES_CONDITION').getRecordTypeId();
    private final static Map<String, String> SEGMENT2_MAP = CommonUtilController.getPickListMap('Product2', 'Segment2__c');
    private final static Map<String, String> EMISSION_LEVEL_MAP = CommonUtilController.getPickListMap('Product2', 'EmissionLevel__c');

    public SalesCondition_ba(String paramDate) {
        if(paramDate != null) this.basisDate = Date.valueOf(paramDate);
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String selectFields =       getFields();
        String fromObject =         'ConfigDetail__c';
        String whereConditions =    'ConfigMaster__r.RecordTypeId = \'' + RECORDTYPE_SALES_CONDITION + '\'';

        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, whereConditions);
        return Database.getQueryLocator(buildQuery);
    }

    public void execute(SchedulableContext context) {
        String paramDate = String.valueOf(Date.today());
        if(basisDate != null) paramDate = String.valueOf(basisDate);

        Database.executeBatch(new SalesCondition_ba(paramDate), 100);
    }

    /*
        SalesCondition_ba의 Logic [Copy & Paste할경우 전체 삭제 후 Insert]
            1. CustomConfig Row > SalesCondition Update, Insert
                1-1. 기존에 존재하는 SalesConditionMaster일경우 Update, 신규 Insert
                1-2. Start-End 사이의 데이터 Update
            2. 해당 Model에 대한 Product2 Lookup
    */
    public void execute(Database.BatchableContext context, List<SObject> records) {
        // Batch 날짜를 직접 지정하는경우(관리자용)
        Date basisDate = basisDate != null ? basisDate : Date.today();

        Map<String, ConfigDetail__c> deleteMap = new Map<String, ConfigDetail__c>();   // 같은데이터 Truncate & Insert할경우, Report데이터를 위해 삭제처리
        Map<String, ConfigDetail__c> detailMap = new Map<String, ConfigDetail__c>();
        for(SObject record : records) {
            ConfigDetail__c obj = (ConfigDetail__c) record;

            String segmentValue = SEGMENT2_MAP.get(obj.Attribute2__c);
            String emissionLevelValue = EMISSION_LEVEL_MAP.get(obj.Attribute5__c);
            String listPrice = String.valueOf(Integer.valueOf(obj.Attribute6__c.trim().replaceAll('[.,]', '')));
            String discount = String.valueOf(Integer.valueOf(obj.Attribute7__c.trim().replaceAll('[.,%]', '')));
            String ym = obj.Attribute10__c != null ? obj.Attribute10__c.replace('-', '') : '';

            String key = obj.Name.trim() +
                    obj.Attribute1__c +
                    segmentValue +
                    obj.Attribute3__c +
                    obj.Attribute4__c +
                    emissionLevelValue +
                    listPrice +
                    discount +
                    obj.Attribute8__c +
                    obj.Attribute9__c +
                    ym;

            deleteMap.put(key.toUpperCase(), obj);
            detailMap.put(obj.Id, obj);
        }

        // 1. SalesCondition StartDate-EndDate 사이의 Condition IsActive Update
        Map<Id, SalesConditionMaster__c> masterDetailMap = new Map<Id, SalesConditionMaster__c>();
        List<SalesConditionMaster__c> deleteConditionList = new List<SalesConditionMaster__c>();
        for(SalesConditionMaster__c obj : [
                SELECT Id, ConfigDetail__c,
                        Model__c, Generation__c, Segment2__c, LocalYear__c, ModelYear__c, EmissionLevel__c, ListPrice__c, Discount__c,
                        StartDate__c, EndDate__c, YearMonth__c, IsActive__c
                FROM SalesConditionMaster__c
                WHERE IsActive__c = TRUE
        ]) {
            Integer listPrice = Integer.valueOf(obj.ListPrice__c);
            Integer discount = Integer.valueOf(String.valueOf(obj.Discount__c).replaceAll('[.,%]', ''));
            String ym = obj.YearMonth__c != null ? obj.YearMonth__c.replace('-', '') : '';

            String key = obj.Model__c.trim() +
                    obj.Generation__c +
                    obj.Segment2__c +
                    obj.LocalYear__c +
                    obj.ModelYear__c +
                    obj.EmissionLevel__c +
                    listPrice +
                    discount +
                    String.valueOf(obj.StartDate__c) +
                    String.valueOf(obj.EndDate__c) +
                    ym;

            if(deleteMap.get(key.toUpperCase()) != null) {
                // 동일한 데이터는 삭제처리(예약 혹은 특정row 변경을 할때 같이 올림. Report데이터를 위해 삭제처리)
                deleteConditionList.add(obj);
            } else {
                // 신규데이터 Insert
                masterDetailMap.put(obj.ConfigDetail__c, obj);
            }
        }
        if(!deleteConditionList.isEmpty()) delete deleteConditionList;

        Set<String> p2KeySet = new Set<String>();
        Map<String, SalesConditionMaster__c> keyMap = new Map<String, SalesConditionMaster__c>();
        for(String id : detailMap.keySet()) {
            ConfigDetail__c detail = detailMap.get(id);

            SalesConditionMaster__c master = masterDetailMap.containsKey(id) ? masterDetailMap.get(id) : new SalesConditionMaster__c();
            String ym = detail.Attribute10__c != null ? detail.Attribute10__c.replace('-', '') : '';

            master.Model__c = detail.Name;
            master.Generation__c = detail.Attribute1__c;
            master.LocalYear__c = detail.Attribute3__c;
            master.ModelYear__c = detail.Attribute4__c;

            master.Segment2__c = SEGMENT2_MAP.get(detail.Attribute2__c);
            master.EmissionLevel__c = EMISSION_LEVEL_MAP.get(detail.Attribute5__c.toUpperCase());

            master.ListPrice__c = Decimal.valueOf(detail.Attribute6__c.replaceAll('[.,]', ''));
            master.Discount__c = Decimal.valueOf(detail.Attribute7__c.replace(',', '.').replace('%', ''));
            master.StartDate__c = Date.valueOf(detail.Attribute8__c);
            master.EndDate__c = Date.valueOf(detail.Attribute9__c);
            master.YearMonth__c = ym;

            // 유효한 데이터 Lookup
            master.IsActive__c = true;
            master.ConfigDetail__c = id;

            // 유효하지 않은 데이터 비활성화 처리(일 배치. 혹은 관리자 지정날짜 기준)
            if(!(master.StartDate__c <= basisDate && master.EndDate__c >= basisDate)) master.IsActive__c = false;

            String key = master.Model__c.trim() +
                    master.Generation__c +
                    master.Segment2__c +
                    master.LocalYear__c +
                    master.ModelYear__c +
                    master.EmissionLevel__c;

            // ver1.1 판매조건 Key값 변경
            Integer lastIndex = master.Model__c.lastIndexOf(' ');
            Integer sLastIndex = master.Model__c.lastIndexOf(' ', lastIndex - 1);

            String model1 = master.Model__c.substring(0, sLastIndex);                   // "TGX 28.510 6x2=2 LL SA"
            String model2 = master.Model__c.substring(sLastIndex + 1, lastIndex);       // "GX"
            String model3 = master.Model__c.substring(lastIndex + 1);                   // "3300"
            String p2Key = model1 + '^' + model2 + '^' + model3;

            p2KeySet.add(p2Key);
            keyMap.put(key.toUpperCase(), master);

            System.debug(p2Key);
            System.debug(key.toUpperCase());
        }
        upsert keyMap.values();

        // 2. 해당 Model에 대한 Product2 Lookup
        /*
        List<Product2> productList = [
                SELECT Id, SalesConditionMaster__c, SpecShort__c, CabMark__c, WheelBase__c, Generation__c,
                        Segment2__c, LocalYear__c, ModelYear__c, EmissionLevel__c
                FROM Product2
                WHERE SpecShort__c IN :p2KeySet
        ];
        */
        // ver1.1 판매조건 Key값 변경
        String selectFields     = 'Id, SalesConditionMaster__c, SpecShort__c, CabMark__c, WheelBase__c, Generation__c, Segment2__c, LocalYear__c, ModelYear__c, EmissionLevel__c';
        String fromObject       = 'Product2';
        String whereConditions  = '';
        for(String key : p2KeySet) {
            List<String> keyFields = key.split('\\^');

            whereConditions += '(SpecShort__c = \'' + keyFields.get(0) + '\' AND toLabel(CabMark__c) = \'' + keyFields.get(1) + '\' AND toLabel(WheelBase__c) = \'' + keyFields.get(2) + '\') OR ';
        }
        whereConditions = whereConditions.substring(0, whereConditions.length() - 3);

        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, whereConditions);
        List<Product2> productList = Database.query(buildQuery);

        for(Product2 obj : productList) {
            // Product2-SalesConditionMaster Lookup 유효한 데이터만 Mapping (Id or NULL)
            // ver1.1 판매조건 Key값 변경
            String cabMark = CommonUtilController.getPicklistLabelForLabel('Product2', 'CabMark__c', obj.CabMark__c);
            String wheelBase = CommonUtilController.getPicklistLabelForLabel('Product2', 'WheelBase__c', obj.WheelBase__c);
            List<String> modelKeyList = new List<String>{
                    obj.SpecShort__c.trim(), cabMark, wheelBase
            };

            String key = String.join(modelKeyList, ' ') +
                    obj.Generation__c +
                    obj.Segment2__c +
                    obj.LocalYear__c +
                    obj.ModelYear__c +
                    obj.EmissionLevel__c;

            System.debug(key.toUpperCase());
            SalesConditionMaster__c master = keyMap.get(key.toUpperCase());
            obj.SalesConditionMaster__c = (master != null && master.IsActive__c) ? master.Id : null;
        }
        update productList;
    }

    public void finish(Database.BatchableContext context) {

        System.debug('########## SalesCondition_ba Finish ##########');
        System.debug('Date : ' + basisDate);
    }

    public static String getFields() {
        return 'Id, Name, ' +
                'Attribute1__c, Attribute2__c, Attribute3__c, Attribute4__c, Attribute5__c, ' +
                'Attribute6__c, Attribute7__c, Attribute8__c, Attribute9__c, Attribute10__c ';
    }
}