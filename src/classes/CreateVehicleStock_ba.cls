/**
* @Author            : payo03@solomontech.net
* @Description 		 : BF1버튼을 통한 VehicleStock 생성 batch
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-22      payo03@solomontech.net           Created
  1.1      2024-12-04      payo03@solomontech.net           InvoiceNumber 존재시 VehicleStock Mig 조건제어, VehicleCategory-Product 관계도 정리
  1.2      2024-12-16      payo03@solomontech.net           SAP Interface 자동화
  1.3      2025-01-13      payo03@solomontech.net           ERPCode값이 NULL일경우 Insert PASS
  1.4      2025-02-19      payo03@solomontech.net           Spoiler장착된 차량Case 적용
  2.0      2025-04-10      payo03@solomontech.net           Product Key : IsSpoiler여부 제거. Stock Status Update조건 IsCompleted 제거, IF 분리, Product2 금액 복제
  2.1      2025-04-25      payo03@solomontech.net           PDI Step INIT추가
*/
public without sharing class CreateVehicleStock_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    private final static String MAN_CODE = 'MAN5000';
    private final static String TRP_CODE = 'MAN5001';
    private final static String LOG_TYPE = 'ERP_MODEL';
    private final static String IF_ID = InterfaceSAP.IF_SMS009;

    public Map<String, Object> infoMap;              // Update Param
    public String dynamicCondition;                  // 특정조건으로만 Batch 실행
    public List<VehicleCategory__c> newCategoryList = new List<VehicleCategory__c>();   // FINISH 함수에서 사용할 Batch 변수(Stateful)

    private final static Map<String, String> SEGMENT1_MAP = CommonUtilController.getPickListMap('Product2', 'Segment1__c');
    private final static Map<String, String> SEGMENT2_MAP = CommonUtilController.getPickListMap('Product2', 'Segment2__c');
    private final static Map<String, String> CAB_MARK_MAP = CommonUtilController.getPickListMap('Product2', 'CabMark__c');
    private final static Map<String, String> INTARDER_MAP = CommonUtilController.getPickListMap('Product2', 'Intarder__c');
    private final static Map<String, String> WHEEL_BASE_MAP = CommonUtilController.getPickListMap('Product2', 'WheelBase__c');
    private final static Map<String, String> TRIM_LEVEL_MAP = CommonUtilController.getPickListMap('Product2', 'TrimLevel__c');
    private final static Map<String, String> EMISSION_LEVEL_MAP = CommonUtilController.getPickListMap('Product2', 'EmissionLevel__c');
    private final static Map<String, String> CAR_COLOR_MAP = CommonUtilController.getPickListMap('VehicleStock__c', 'CarColor__c');

    public CreateVehicleStock_ba(Map<String, Object> infoMap, String dynamicCondition) {
        if(infoMap != null) this.infoMap = infoMap;
        if(dynamicCondition != null) this.dynamicCondition = dynamicCondition;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String selectFields =       getFields();
        String fromObject =         'AvisOrderInfo__c ';

        // SAP Interface 시점 이후로 VehicleStock Update 하지않음.
        String whereConditions =    'Id != NULL ';
        if(this.dynamicCondition != null) whereConditions = this.dynamicCondition;

        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, whereConditions);
        System.debug(buildQuery);
        return Database.getQueryLocator(buildQuery);
    }

    /*
        AvisOrderInfo기준. VehicleStock 생성시 Process
        1. AvisOrderInfo - VehicleStock 필드 매핑
        2. Product2, VehicleCategory 미존재시 데이터 자동생성, Product - VehicleCategory Lookup
        3. VehicleStock - Product2 Lookup & Insert
        4. Email 전송(AvisOrderInfo Trigger에서 수행)
    */
    public void execute(Database.BatchableContext context, List<SObject> records) {
        // 관리자 Batch 실행을 위한 infoMap 사용 / Update
        Map<String, Object> infoMap = (this.infoMap == null || this.infoMap.isEmpty())
                ? new Map<String, Object>()
                : this.infoMap;

        Set<String> vinNumberSet = new Set<String>();
        List<AvisOrderInfo__c> infoList = new List<AvisOrderInfo__c>();
//        List<String> orderConfirmList = new List<String>();
        for(SObject record : records) {
            AvisOrderInfo__c info = (AvisOrderInfo__c) record;

            // ver1.3 ERPCode값이 NULL일경우 Insert PASS
            String ERPCode = CommonUtilCustomController.parseCarCode(
                    info.fm_Segment1__c,
                    info.fm_SpecShort__c,
                    info.CabMark__c,
                    info.IntarderOption__c,
                    info.WheelBase__c,
                    info.TrimLevel__c,
                    info.EmissionLevelEu__c
            );
            if(ERPCode == null) continue;

            vinNumberSet.add(info.ChassisFrameNo__c);
            infoList.add(info);

            /* ver2.0 IF 분리
            // ver1.2 SAP Interface 자동화
            if(info.fm_OrderConfirmSAP__c) orderConfirmList.add(info.Id);
            */
        }
//        if(!orderConfirmList.isEmpty()) System.enqueueJob(new AsyncOrderConfirm(orderConfirmList, infoMap), 1);

        Map<String, VehicleStock__c> stockMap = new Map<String, VehicleStock__c>();
        for(VehicleStock__c stock : [
                SELECT Id, Name, Status__c
                FROM VehicleStock__c
                WHERE Name IN :vinNumberSet
        ]) {
            stockMap.put(stock.Name, stock);
        }
        updateStockStatus(infoList, stockMap);    // ver2.0 Stock Status Update조건 IsCompleted 제거

        // 1. AvisOrderInfo - VehicleStock 필드 매핑
        List<VehicleStock__c> stockList = new List<VehicleStock__c>();                          // Insert VehicleStock
        List<AvisOrderInfo__c> updateInfoList = new List<AvisOrderInfo__c>();                   // Update AvisOrderInfo
        Map<String, AvisOrderInfo__c> ERPCodeInfoMap = new Map<String, AvisOrderInfo__c>();     // Mapping VehicleCategory
        Map<String, AvisOrderInfo__c> keyMap = new Map<String, AvisOrderInfo__c>();             // Mapping Product2
        Map<String, AvisOrderInfo__c> vehicleNoMap = new Map<String, AvisOrderInfo__c>();       // Mapping VehicleStock

        Map<String, SpoilerPart__c> spoilerMap = SAPCommon.fetchSpoilerMap(infoList);           // ver1.4 Spoiler장착된 차량Case 적용
        System.debug(infoList);
        for(AvisOrderInfo__c info : infoList) {
            Boolean isCompleted = infoMap.containsKey('isCompleted') ? Boolean.valueOf(infoMap.get('isCompleted')) : info.IsCompleted__c;
            if(isCompleted) continue;   // ver1.1 InvoiceNumber 존재시 VehicleStock Mig 조건제어

            String vinKey = info.ChassisFrameNo__c;
            VehicleStock__c stock = stockMap.containsKey(vinKey) ? stockMap.get(vinKey) : new VehicleStock__c();

            String ERPCode = CommonUtilCustomController.parseCarCode(
                    info.fm_Segment1__c,
                    info.fm_SpecShort__c,
                    info.CabMark__c,
                    info.IntarderOption__c,
                    info.WheelBase__c,
                    info.TrimLevel__c,
                    info.EmissionLevelEu__c
            );

            String isDeck = '00';
            if(info.fm_IsDeck__c) isDeck = '01';
            ERPCode += isDeck;

            ERPCodeInfoMap.put(ERPCode, info);

            stock.AvisOrderInfo__c = info.Id;
            stock.ERPCode__c = ERPCode;
            stock.CarColor__c = CAR_COLOR_MAP.get(info.CarColor__c);

            stock.IsSpoiler__c = info.IsSpoiler__c > 0;
            stock.IsHypoid__c = info.IsHypoid__c > 0;
            stock.IsPTO__c = info.IsPTO__c > 0;

            stock.Name = info.ChassisFrameNo__c;
            stock.Destination__c = info.Destination__c;
            stock.DriveConcept__c = info.DriveConcept__c;
            stock.EngineNumber__c = info.EngineNumber__c;
            stock.EngineRange__c = info.EngineRange__c;
            stock.EngineType__c = info.EngineType__c;
            stock.FassungDate__c = info.FassungDate__c;
            stock.Harbour__c = info.Harbour__c;
            stock.KblColumn__c = info.KblColumn__c;
            stock.NameReceiver__c = info.NameReceiver__c;
            stock.OrderIntakeNo__c = info.OrderIntakeNo__c;
            stock.Overhang__c = info.Overhang__c;
            stock.Ship__c = info.Ship__c;
            stock.SpecShort__c = info.fm_SpecShort__c;
            stock.SubsideryName__c = info.SubsideryName__c;
            stock.Typ__c = info.Typ__c;
            stock.TypFamily__c = info.TypFamily__c;
            stock.TypPrefix__c = info.TypPrefix__c;
            stock.VehicleNo__c = info.VehicleNo__c;
            stock.WeightKg__c = info.WeightKg__c;
            stock.ProducedDate__c = info.EopDate__c;
            stock.KblColumn__c = info.KblColumn__c;
            stock.NameReceiver__c = info.NameReceiver__c;
            stock.OrderBurden__c = info.OrderBurden__c;
            stock.OrderIntakeNo__c = info.OrderIntakeNo__c;
            stock.Overhang__c = info.Overhang__c;
            stock.BasicVehicle__c = info.BasicVehicle__c;
            stock.DeliveryRelease__c = info.DeliveryRelease__c;
            stock.DepartureHarbor__c = info.DepartureHarbor__c;
            stock.HorsePower__c = info.HorsePower__c;
            stock.LeadingAxle__c = info.Leading_Axle__c;
            stock.EopMonth__c = info.EopMonth__c;
            stock.EopPlanMonth__c = info.EopPlanMonth__c;
            stock.ETAMonth__c = info.ETAMonth__c;
            stock.OrderMonth__c = info.OrderMonth__c;
            stock.SopMonth__c = info.SopMonth__c;
            stock.SopPlanMonth__c = info.SopPlanMonth__c;
            stock.EopDate__c = info.EopDate__c;
            stock.ETA__c = info.ETA__c;
            stock.Etd__c = info.Etd__c;
            stock.EtdMonth__c = info.EtdMonth__c;
            stock.Exworks__c = info.Exworks__c;
            stock.HarbourShort__c = info.HarbourShort__c;
            stock.HorsePowerMax__c = info.HorsePowerMax__c;
            stock.InvoiceDateBefore__c = info.InvoiceDateBefore__c;
            stock.InvoiceDateLast__c = info.InvoiceDateLast__c;
            stock.KswDoneMark__c = info.KswDoneMark__c;
            stock.KswInside__c = info.KswInside__c;
            stock.KswOutOfSe__c = info.KswOutOfSe__c;
            stock.OrderDate__c = info.OrderDate__c;
            stock.Ordered__c = info.Ordered__c;
            stock.Pickup__c = info.Pickup__c;
            stock.ProductionMonth__c = info.ProductionMonth__c;
            stock.ReadyForDelievery__c = info.ReadyForDelievery__c;
            stock.SopDate__c = info.SopDate__c;
            stock.SopPlan__c = info.SopPlan__c;
            stock.TargetMonthArrival__c = info.TargetMonthArrival__c;
            stock.TargetRegion__c = info.TargetRegion__c;
            stock.SendTo__c = info.SendTo__c;
            stock.Cab_Color__c = info.Cab_Color__c;
            stock.RAL_Code__c = info.RAL_Code__c;
            stock.InvoiceNumber__c = info.InvoiceNumber__c;
            stock.ProductionSite__c = info.fm_ProductionSite__c;

            // ver1.4 Spoiler장착된 차량Case 적용
            String spoilerKey = CommonUtilCustomController.getSpoilerKey(info);
            SpoilerPart__c spoiler = spoilerMap.get(spoilerKey);
//            if(info.IsSpoiler__c > 0 && spoiler != null) stock.SpoilerPart__c = spoiler.Id;
            if(spoiler != null) stock.SpoilerPart__c = spoiler.Id;

            // ver2.0 Stock Status Update조건 IsCompleted 제거
            /*
            if(info.ETA__c != null) {
                if (info.ETA__c <= Date.today() && stock.Status__c != '재고 노출') {
                    // Case. ETA 날짜 <= 현재날짜 && 상태값 '재고 노출'이 아닐때
                    stock.Status__c = '재고 미노출(임시)';
                    stock.StockNoShow__c = true;
                } else {
                    stock.Status__c = '30일 재고';

                    if (info.ETA__c > Date.today().addMonths(2)) stock.Status__c = '60일 재고';
                }
            }
            */

            // ver1.1 InvoiceNumber 존재시 VehicleStock Mig 조건제어
            // ver1.3 ERPCode값이 NULL일경우 Insert PASS
            if(stock.InvoiceNumber__c != null && !ERPCode.contains('null')) {
                info.IsCompleted__c = true;

                updateInfoList.add(info);
            }
            stockList.add(stock);
            vehicleNoMap.put(stock.Name, info);

            String key = info.fm_SpecShort__c +
                    SEGMENT1_MAP.get(info.fm_Segment1__c) +
                    SEGMENT2_MAP.get(info.fm_Segment2__c) +
                    CAB_MARK_MAP.get(info.CabMark__c) +
                    WHEEL_BASE_MAP.get(info.WheelBase__c) +
                    TRIM_LEVEL_MAP.get(info.TrimLevel__c) +
                    Boolean.valueOf(info.Optiview__c > 0) +
                    Boolean.valueOf(info.LION_S__c > 0) +
                    Boolean.valueOf(info.IsPTO__c > 0) +
//                    Boolean.valueOf(info.IsSpoiler__c > 0) +  // ver2.0 Product Key : IsSpoiler여부 제거
                    info.ModelYear__c +
                    info.LocalYear__c +
                    info.fm_Generation__c;
            keyMap.put(key, info);
        }
        // ver1.1 InvoiceNumber 존재시 VehicleStock Mig 조건제어
        if(!updateInfoList.isEmpty()) update updateInfoList;

        // 2. Product2 미존재시 데이터 자동생성, Product - VehicleCategory Lookup
        Map<String, VehicleCategory__c> vehicleKeyMap = new Map<String, VehicleCategory__c>();
        for(VehicleCategory__c obj : [
                SELECT Id, ERPCode__c
                FROM VehicleCategory__c
                WHERE ERPCode__c IN :ERPCodeInfoMap.keySet()
        ]) {
            String key = obj.ERPCode__c;

            vehicleKeyMap.put(key, obj);
        }

        // ver1.1 VehicleCategory-Product 관계도 정리
        List<VehicleCategory__c> insertCategoryList = new List<VehicleCategory__c>();
        for(String key : ERPCodeInfoMap.keySet()) {
            // 신규생성
            System.debug('ERPCode : ' + key);
            if(vehicleKeyMap.get(key) == null) {
                AvisOrderInfo__c info = ERPCodeInfoMap.get(key);
                Map<String, String> specMap = CommonUtilCustomController.getSpecMap(info.fm_SpecShort__c);

                String ERPCode = CommonUtilCustomController.parseCarCode(
                        info.fm_Segment1__c,
                        info.fm_SpecShort__c,
                        info.CabMark__c,
                        info.IntarderOption__c,
                        info.WheelBase__c,
                        info.TrimLevel__c,
                        info.EmissionLevelEu__c
                );

                String isDeck = '00';
                if(info.fm_IsDeck__c) isDeck = '01';
                ERPCode += isDeck;

                VehicleCategory__c obj = new VehicleCategory__c();

                obj.ModelType__c = specMap.get('modelType');
                obj.WeightCapacity__c = specMap.get('weightCapacity');
                obj.HorsePower__c = specMap.get('horsePower');
                obj.AxleConfiguration__c = specMap.get('axleConfiguration');
                obj.Suspension__c = specMap.get('suspension');
                obj.IsDeck__c = info.fm_IsDeck__c;

                obj.Segment1__c = SEGMENT1_MAP.get(info.fm_Segment1__c);
                obj.Segment2__c = SEGMENT2_MAP.get(info.fm_Segment2__c);
                obj.WheelBase__c = WHEEL_BASE_MAP.get(info.WheelBase__c);
                obj.CabMark__c = CAB_MARK_MAP.get(info.CabMark__c);

                obj.Kind__c = info.fm_Kind__c;
                obj.SpecShort__c = info.fm_SpecShort__c;
                obj.ERPCode__c = ERPCode;

                vehicleKeyMap.put(ERPCode, obj);
                insertCategoryList.add(obj);
            }
        }
        if(!insertCategoryList.isEmpty()) insert insertCategoryList;
        newCategoryList.addAll(insertCategoryList);

        Map<String, Product2> p2KeyMap = new Map<String, Product2>();
        Map<String, Product2> p2ReportMap = new Map<String, Product2>();
        for(Product2 obj : [
                SELECT Id, SpecShort__c, TrimLevel__c, Segment1__c, Segment2__c, CabMark__c, WheelBase__c, Generation__c,
                        IsOTV__c, IsLNS__c,  IsPTO__c, IsSpoiler__c,
                        ModelYear__c, LocalYear__c, CarAmt__c, PurePrice__c, PurePriceWsc__c, PurePriceWscCfx__c
                FROM Product2
                WHERE VehicleCategory__r.ERPCode__c IN: ERPCodeInfoMap.keySet()
        ]) {
            // ver2.0 Product2 CarAmount 복제
            String cabMark = CommonUtilController.getPicklistLabelForLabel('Product2', 'CabMark__c', obj.CabMark__c);
            String wheelBase = CommonUtilController.getPicklistLabelForLabel('Product2', 'WheelBase__c', obj.WheelBase__c);
            List<String> reportKeyList = new List<String>{
                    obj.SpecShort__c.trim(), cabMark, wheelBase
            };
            String reportKey = String.join(reportKeyList, '^');

            String key = obj.SpecShort__c +
                    obj.Segment1__c +
                    obj.Segment2__c +
                    obj.CabMark__c +
                    obj.WheelBase__c +
                    obj.TrimLevel__c +
                    obj.IsOTV__c +
                    obj.IsLNS__c +
                    obj.IsPTO__c +
//                    obj.IsSpoiler__c +    // ver2.0 Product Key : IsSpoiler여부 제거
                    obj.ModelYear__c +
                    obj.LocalYear__c +
                    obj.Generation__c;

            p2KeyMap.put(key, obj);
            if(obj.CarAmt__c != null) p2ReportMap.put(reportKey, obj);
        }

        // 모수는 AvisOrderInfo의 List
        // ver1.1 VehicleCategory-Product 관계도 정리
        List<Product2> insertP2List = new List<Product2>();
        for(String key : keyMap.keySet()) {
            // 신규생성
            if(p2KeyMap.get(key) == null) {
                AvisOrderInfo__c info = keyMap.get(key);
                String ERPCode = CommonUtilCustomController.parseCarCode(
                        info.fm_Segment1__c,
                        info.fm_SpecShort__c,
                        info.CabMark__c,
                        info.IntarderOption__c,
                        info.WheelBase__c,
                        info.TrimLevel__c,
                        info.EmissionLevelEu__c
                );

                String isDeck = '00';
                if(info.fm_IsDeck__c) isDeck = '01';
                ERPCode += isDeck;

                Product2 p2Obj = new Product2();
                p2Obj.VehicleCategory__c = vehicleKeyMap.get(ERPCode).Id;

                p2Obj.Segment1__c = SEGMENT1_MAP.get(info.fm_Segment1__c);
                p2Obj.Segment2__c = SEGMENT2_MAP.get(info.fm_Segment2__c);
                p2Obj.CabMark__c = CAB_MARK_MAP.get(info.CabMark__c);
                p2Obj.EmissionLevel__c = EMISSION_LEVEL_MAP.get(info.EmissionLevelEu__c);
                p2Obj.Intarder__c = INTARDER_MAP.get(info.IntarderOption__c);
                p2Obj.WheelBase__c = WHEEL_BASE_MAP.get(info.WheelBase__c);
                p2Obj.TrimLevel__c = TRIM_LEVEL_MAP.get(info.TrimLevel__c);

                p2Obj.IsOTV__c = info.Optiview__c > 0;
                p2Obj.IsLNS__c = info.LION_S__c > 0;
                p2Obj.IsPTO__c = info.IsPTO__c > 0;
                p2Obj.IsSpoiler__c = info.IsSpoiler__c > 0;
                p2Obj.IsHypoid__c = info.IsHypoid__c > 0;

                p2Obj.ModelYear__c = String.valueOf(info.ModelYear__c);
                p2Obj.LocalYear__c = info.LocalYear__c;
                p2Obj.Generation__c = info.fm_Generation__c;

                p2Obj.SpecShort__c = info.fm_SpecShort__c;
                p2Obj.TRPCategory__c = info.fm_TRPCategory__c;

                // ver2.0 Product2 금액 복제
                List<String> reportKeyList = new List<String>{
                        info.fm_SpecShort__c, info.CabMark__c, info.WheelBase__c
                };
                String reportKey = String.join(reportKeyList, '^');
                p2Obj.CarAmt__c             = p2ReportMap.containsKey(reportKey) ? p2ReportMap.get(reportKey).CarAmt__c             : null;
                p2Obj.PurePrice__c          = p2ReportMap.containsKey(reportKey) ? p2ReportMap.get(reportKey).PurePrice__c          : null;
                p2Obj.PurePriceWsc__c       = p2ReportMap.containsKey(reportKey) ? p2ReportMap.get(reportKey).PurePriceWsc__c       : null;
                p2Obj.PurePriceWscCfx__c    = p2ReportMap.containsKey(reportKey) ? p2ReportMap.get(reportKey).PurePriceWscCfx__c    : null;

                insertP2List.add(p2Obj);
                p2KeyMap.put(key, p2Obj);
            }
        }
        if(!insertP2List.isEmpty()) insert insertP2List;

        // 3. VehicleStock - Product2 Lookup & Insert
        List<String> workNoList = new List<String>();
        for (VehicleStock__c stock : stockList) {
            AvisOrderInfo__c info = vehicleNoMap.get(stock.Name);
            String p2Key = info.fm_SpecShort__c +
                    SEGMENT1_MAP.get(info.fm_Segment1__c) +
                    SEGMENT2_MAP.get(info.fm_Segment2__c) +
                    CAB_MARK_MAP.get(info.CabMark__c) +
                    WHEEL_BASE_MAP.get(info.WheelBase__c) +
                    TRIM_LEVEL_MAP.get(info.TrimLevel__c) +
                    Boolean.valueOf(info.Optiview__c > 0) +
                    Boolean.valueOf(info.LION_S__c > 0) +
                    Boolean.valueOf(info.IsPTO__c > 0) +
//                    Boolean.valueOf(info.IsSpoiler__c > 0) +  // ver2.0 Product Key : IsSpoiler여부 제거
                    info.ModelYear__c +
                    info.LocalYear__c +
                    info.fm_Generation__c;

            stock.Product__c = p2KeyMap.get(p2Key).Id;
            if(stock.VehicleNo__c != null) workNoList.add(stock.VehicleNo__c);
        }
        upsert stockList;
        if (!workNoList.isEmpty()) PdiController.fetchStatus(workNoList);   // ver2.1 PDI Step INIT추가
    }

    // ver2.0 Stock Status Update조건 IsCompleted 제거
    public void updateStockStatus(List<AvisOrderInfo__c> infoList, Map<String, VehicleStock__c> stockMap) {

        List<VehicleStock__c> updateStockList = new List<VehicleStock__c>();
        for(AvisOrderInfo__c info : infoList) {
            if(stockMap.get(info.ChassisFrameNo__c) == null) continue;

            VehicleStock__c stock = stockMap.get(info.ChassisFrameNo__c);
            if(info.ETA__c != null) {
                if (info.ETA__c <= Date.today() && stock.Status__c != '재고 노출') {
                    // Case. ETA 날짜 <= 현재날짜 && 상태값 '재고 노출'이 아닐때
                    stock.Status__c = '재고 미노출(임시)';
                    stock.StockNoShow__c = true;
                } else {
                    stock.Status__c = '30일 재고';
                    if (info.ETA__c > Date.today().addMonths(2)) stock.Status__c = '60일 재고';
                }
            }
            stock.RealArrivalDate__c = info.RealArrivalDate__c;
            updateStockList.add(stock);
        }
        if(!updateStockList.isEmpty()) update updateStockList;
    }

    public void finish(Database.BatchableContext context) {

        System.debug('########## CreateVehicleStock_ba Finish ##########');
        System.debug('Info : ' + this.infoMap);
        System.debug('dynamicCondition : ' + this.dynamicCondition);

        if(!newCategoryList.isEmpty()) {
            Map<Id, VehicleCategory__c> categoryMap = new Map<Id, VehicleCategory__c>([
                    SELECT Id
                    FROM VehicleCategory__c
                    WHERE Id IN :newCategoryList
            ]);

            Map<String, Product2> ERPCodeMap = new Map<String, Product2>();
            for(Product2 obj : [
                    SELECT Name, SpecShort__c, TRPCategory__c, CreatedDate, fm_HSCode__c, fm_SpecCode__c,
                            Segment1__c, CabMark__c, Intarder__c, WheelBase__c, EmissionLevel__c, TrimLevel__c,
                            VehicleCategory__r.ERPCode__c, VehicleCategory__c
                    FROM Product2
                    WHERE VehicleCategory__c IN: categoryMap.keySet()
            ]) {
                ERPCodeMap.put(obj.VehicleCategory__c, obj);
            }

            String status = 'SUCCESS';
            String requestBody = JSON.serializePretty(ERPCodeMap.keySet());
            String responseBody;
            String responseStatusCode = '200';
            Datetime requestTime = Datetime.now();
            Datetime responseTime;

            Map<String, IFAuditLog__c> logMap = new Map<String, IFAuditLog__c>();
            Map<String, IFAuditLogDetail__c> logDetailMap = new Map<String, IFAuditLogDetail__c>();
            try {
                Map<String, ConfigDetail__c> codeMap = CommonUtilCustomController.getCodeMap(MAN_CODE).get(TRP_CODE);

                for (String categoryId : ERPCodeMap.keySet()) {
                    List<IF_DTO.ERPModel> modelList = new List<IF_DTO.ERPModel>();
                    String logId = CommonUtilCustomController.parseIFId(InterfaceSAP.PREFIX_MODEL);

                    Product2 obj = ERPCodeMap.get(categoryId);
                    IF_DTO.ERPModel model = new IF_DTO.ERPModel(obj, true);
                    Map<String, String> specMap = CommonUtilCustomController.getSpecMap(obj.SpecShort__c);

                    String axleConfiguration = specMap.get('axleConfiguration').substringBefore('-');
                    String weightCapacity = specMap.get('weightCapacity');
                    String horsePower = specMap.get('horsePower');
                    String upperAxleConfiguration = axleConfiguration.toUpperCase();

                    model.SPEC = obj.fm_SpecCode__c;
                    model.SPECNM = obj.SpecShort__c.toUpperCase();
                    model.PERWGT = weightCapacity + horsePower + upperAxleConfiguration.replace('X', '');
                    model.PERWGTNM = weightCapacity + '.' + horsePower + '_' + upperAxleConfiguration;

                    model.IFID = logId;
                    model.ITEMCD = obj.VehicleCategory__r.ERPCode__c;
                    model.TRP = codeMap.get(obj.TRPCategory__c).Attribute1__c;
                    modelList.add(model);

                    // 2025-02-27 최윤석대리와 Teams미팅간 내용. SMS004, SMS007. SMS009는 단건밖에 안된다고 함......
                    Map<String, Object> infoMap = new Map<String, Object>();
                    String reqBody = CommonUtilCustomController.parseStringSAP(IF_ID, modelList, logId);

                    infoMap.put('ifId', IF_ID);
                    infoMap.put('logId', logId);
                    infoMap.put('logType', LOG_TYPE);
                    infoMap.put('items', modelList);
                    infoMap.put('isLog', false);

                    Map<String, Object> resultMap = InterfaceSAP.doCallOutSAPLog(infoMap);
                    Boolean isSuccess = !resultMap.isEmpty() && Boolean.valueOf(resultMap.get('code'));
                    String resBody = JSON.serializePretty(resultMap);
                    responseBody += resBody + '\n';

                    // SAP I/F 감사로그 Bulk Insert
                    // IFAuditLog
                    IFAuditLog__c log = new IFAuditLog__c();
                    log.IF_Id__c = IF_ID;
                    log.Name = logId;
                    log.Type__c = LOG_TYPE;
                    log.RawData__c = reqBody;
                    log.ResponseBody__c = resBody;
                    logMap.put(logId, log);

                    // IFAuditLogDetail
                    IFAuditLogDetail__c logDetail = new IFAuditLogDetail__c();
                    logDetail.ObjectType__c = Id.valueOf(categoryId).getSobjectType().getDescribe().getName();
                    logDetail.ExternalId__c = categoryId;
                    logDetail.IsRequest__c = isSuccess;
                    logDetail.ExternalKey__c = obj.VehicleCategory__r.ERPCode__c;
                    if (isSuccess) {
                        // Heroku 통신 완료시. Sync
                        String herokuMessage = String.valueOf(resultMap.get('message'));
                        Map<String, Object> sapMap = (Map<String, Object>) JSON.deserializeUntyped(herokuMessage);
                        String resultCode = String.valueOf(sapMap.get('Code')) == '0' ? 'Y' : 'C';
                        String resultMessage = String.valueOf(sapMap.get('Message'));

                        logDetail.IsResponse__c = resultCode;
                        logDetail.IsResult__c = resultCode;
                        logDetail.Description__c = resultMessage;
                        logDetail.ResultDatetime__c = Datetime.now();
                    }
                    logDetailMap.put(logId, logDetail);
                }
                responseTime = Datetime.now();
            } catch(Exception e) {
                status = 'ERROR';
                responseBody = e.getMessage();
                responseStatusCode = '500';
                responseTime = Datetime.now();

                System.debug(e.getMessage());
            } finally {
                if(!logMap.isEmpty()) {
                    // SAP I/F 감사로그 Bulk Insert
                    insert logMap.values();

                    List<IFAuditLogDetail__c> details = new List<IFAuditLogDetail__c>();
                    for(String logId : logDetailMap.keySet()) {
                        IFAuditLogDetail__c detail = logDetailMap.get(logId);

                        detail.IFAuditLog__c = logMap.get(logId).Id;
                        details.add(detail);
                    }
                    insert details;
                }

                IF_DTO.LogWrapper objLogWrapper = new IF_DTO.LogWrapper();
                objLogWrapper.status = status;
                objLogWrapper.requestBody = requestBody;
                objLogWrapper.responseBody = responseBody;
                objLogWrapper.errorCode = responseStatusCode;
                objLogWrapper.requestTime = requestTime;
                objLogWrapper.responseTime = responseTime;
                objLogWrapper.logType = IF_DTO.LOG_TYPE.HEROKU_SAP_OUT;

                CommonUtilCustomController.setLog(objLogWrapper);
            }
        }
    }

    public static String getFields() {
        return 'Id, fm_Segment1__c, fm_SpecShort__c, CabMark__c, IntarderOption__c, WheelBase__c, TrimLevel__c, EmissionLevelEu__c, ' +
                'fm_Segment2__c, fm_ProductionSite__c, fm_Generation__c, fm_Kind__c, fm_TRPCategory__c, fm_IsDeck__c, ' +
                'fm_PurchaseInvoiceSAP__c, fm_SpoilerCode__c, fm_SpoilerText__c, fm_CabColor__c, ' +
                'SendTo__c, Suffix__c, Ship__c, HorsePower__c, Leading_Axle__c, CarColor__c, ModelYear__c, LocalYear__c, ' +
                'BLDocumentNo__c, ChassisFrameNo__c, VehicleNo__c, InvoiceNumber__c, ' +
                'IsCompleted__c, IsSpoiler__c, isHypoid__c, isPTO__c, Optiview__c, LION_S__c, ' +
                'Priority__c, KblColumn__c, Destination__c, DriveConcept__c, Overhang__c, ' +
                'SubsideryName__c, WeightKg__c, NameReceiver__c, BasicVehicle__c, DeliveryRelease__c, ' +
                'Exworks__c, HorsePowerMax__c, RAL_Code__c, Pickup__c, ReadyForDelievery__c, Status__c, ' +
                'KswDoneMark__c, KswInside__c, KswOutOfSe__c, ' +
                'EngineNumber__c, EngineRange__c, EngineType__c, ' +
                'Harbour__c, DepartureHarbor__c, HarbourShort__c, Cab_Color__c, ' +
                'Typ__c, TypFamily__c, TypPrefix__c, ' +
                'OrderBurden__c, OrderIntakeNo__c, Ordered__c, OrderMonth__c, ' +
                'TargetRegion__c, TargetMonthArrival__c, ProductionMonth__c, ' +
                'SopMonth__c, SopPlanMonth__c, SopPlan__c, ' +
                'ETA__c, ETAMonth__c, Etd__c, EtdMonth__c, ' +
                'EopMonth__c, EopPlanMonth__c, ' +
                'BLDate__c, EopDate__c, InvoiceDateBefore__c, InvoiceDateLast__c, ' +
                'OrderDate__c, RealSailingDate__c, RealArrivalDate__c, SopDate__c, FassungDate__c ';
    }
}