/**
* @Author            : payo03@solomontech.net
* @Description 		 :
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-22      payo03@solomontech.net           Created
  1.1      2025-04-21      chaebeom.do@solomontech.net      PDI step3 완료시 기회 연결 로직 추가
  1.2      2025-04-22      chaebeom.do@solomontech.net      PDI step4Init 수정
*/
public with sharing class PdiController {

    @AuraEnabled
    public static List<VehicleStock__c> screenInit() {
        String query = getStockList('');
        List<VehicleStock__c> stockList = Database.query(query);
        return stockList;
    }

    // git TEst
    @AuraEnabled
    public static List<PDIStep__c> fetchStatus(List<String> workNo) {
        List<PDIStep__c> steps = new List<PDIStep__c>();        // Return Value
        List<PDIStep__c> insertList = new List<PDIStep__c>();   // Init
        for(VehicleStock__c stock : [
                SELECT Id, Name,
                    (
                        SELECT Id, Name, Stage__c, IsPass__c, VehicleStock__c, StepEnd__c
                        FROM PDI_Steps__r
                    )
                FROM VehicleStock__c
                WHERE VehicleNo__c IN :workNo
        ]) {
            if(stock.PDI_Steps__r.isEmpty()) {
                for(Integer i = 1; i <= 5; i++) {
                    PDIStep__c step = new PDIStep__c();
                    String stage = 'STEP' + i;

                    step.VehicleStock__c = stock.Id;
                    step.Stage__c = stage;
                    step.Name = stock.Name + '_' + stage;
                    step.IsPass__c = false;

                    insertList.add(step);
                }
            }
            if(!stock.PDI_Steps__r.isEmpty()) steps.addAll(stock.PDI_Steps__r);
        }

        if(!insertList.isEmpty()) {
            insert insertList;
            steps.addAll(insertList);
        }
        return steps;
    }

    @AuraEnabled
    public static List<VehicleStock__c> searchVINbyKey(String keyword) {
        String searchKey = (keyword == null) ? '%%' : 'VehicleNo__c LIKE \'%' + keyword + '%\'';
        String query = getStockList(searchKey);
        return Database.query(query);
    }

    @AuraEnabled
    public static Map<String, Map<String, String>> rollbackVehicleStock(String stepName, List<Map<String, String>> vinInfoList) {

        Map<String, Map<String, String>> resultMap = new Map<String, Map<String, String>>();

        Map<String, String> tempMap = new Map<String, String>();
        String workNo = vinInfoList[0].get('WorkNo');
        tempMap.put('WorkNo', workNo);
        tempMap.put('RequestRes', '업데이트 실패');
        resultMap.put(workNo, tempMap);

        VehicleStock__c stockInfo = [
                SELECT Id, Name
                FROM VehicleStock__c
                WHERE VehicleNo__c = :workNo
                LIMIT 1
        ];
        if (stockInfo == null)  { return null; }

        String status;

        // 정방향
//        when 'STEP0' { status = '입고'; entryDate = Date.today(); driveDistance = false;}
//        when 'STEP1' { status = '입고'; entryDate = Date.today(); driveDistance = true; }
//        when 'STEP2' { status = '판매준비완료'; driveDistance = true; }
//        when 'STEP3' { status = '출고예정'; driveDistance = false;}
//        when 'STEP4' { driveDistance = false;}
//        when 'STEP5' { status = '출고준비완료'; driveDistance = false;}

        // 역방향
        switch on stepName {
            when 'STEP1' { status = '항구도착'; }
            when 'STEP2' { status = '입고'; }
            when 'STEP3' { status = '판매준비완료'; }
            when 'STEP4' { status = '판매준비완료'; }
//            when 'STEP4' { status = '출고예정'; driveDistance = false;}  // TODO: 스포일러 SAP 통신 필요
            when 'STEP5' { status = '출고예정';}
        }

        stockInfo.VehicleStatus__c = status;

        Map<String, Map<String, Object>> returnMap = CommonUtilController.applyObject(new List<VehicleStock__c> { stockInfo }, 'update');
        List<PDIStep__c> updateStepList = new List<PDIStep__c>();

        Map<String, Object> successMap = returnMap.get('SUCCESS');
        for(PDIStep__c step : [
                SELECT Id, Name, VehicleStock__r.VehicleNo__c
                FROM PDIStep__c
                WHERE VehicleStock__c IN :successMap.keySet()
                AND Stage__c = :stepName
        ]) {
            step.IsPass__c = false;
            step.StepStart__c = null;
            step.StepEnd__c = null;
            step.StepWorker__c = null;
            updateStepList.add(step);

            String key = step.VehicleStock__r.VehicleNo__c;
            String requestRes = '롤백 성공';
            Map<String, String> tempMap2 = resultMap.get(key);
            tempMap2.put('RequestRes', requestRes);
            resultMap.put(key, tempMap2);
        }

        if(!updateStepList.isEmpty()) update updateStepList;
        return resultMap;
    }

    @AuraEnabled
    public static Map<String, Map<String, String>> updateVehicleStock(String stepName, List<Map<String, String>> vinInfoList) {
        Map<String, Map<String, String>> resultMap = new Map<String, Map<String, String>>();
        List<String> vinNumberList = new List<String>();
        for (Map<String, String> vinInfoMap : vinInfoList) {
            vinNumberList.add(vinInfoMap.get('WorkNo'));
            Map<String, String> tempMap = new Map<String, String>();
            tempMap.put('WorkNo', vinInfoMap.get('WorkNo'));
            tempMap.put('DriveDistance', vinInfoMap.get('DriveDistance'));
            tempMap.put('RequestRes', '업데이트 실패');
            resultMap.put(vinInfoMap.get('WorkNo'), tempMap);
        }
        List<VehicleStock__c> stockList = [
                SELECT Id, Name, VehicleNo__c
                FROM VehicleStock__c
                WHERE VehicleNo__c IN :vinNumberList
        ];
        if (stockList.isEmpty()) return null;

        Date entryDate;
        String status;
        Boolean driveDistance;
        switch on stepName {
            when 'STEP0' { status = '입고'; entryDate = Date.today(); driveDistance = false;}
            when 'STEP1' { status = '입고'; entryDate = Date.today(); driveDistance = true; }
            when 'STEP2' { status = '판매준비완료'; driveDistance = true; }
            when 'STEP3' { status = '출고예정'; driveDistance = false;}
            when 'STEP4' { status = '출고예정'; driveDistance = false;}
            when 'STEP5' { status = '출고준비완료'; driveDistance = false;}
        }

        for (VehicleStock__c stock : stockList) {
            stock.VehicleStatus__c = status;
            if(entryDate != null) stock.PDIEntryDate__c = entryDate;
            if(driveDistance) stock.DriveDistance__c = Decimal.valueOf(resultMap.get(stock.VehicleNo__c).get('DriveDistance'));
        }

        Map<String, Map<String, Object>> returnMap = CommonUtilController.applyObject(stockList, 'update');

        List<PDIStep__c> updateStepList = new List<PDIStep__c>();

        Map<String, Object> successMap = returnMap.get('SUCCESS');
        for(PDIStep__c step : [
                SELECT Id, Name, VehicleStock__r.VehicleNo__c
                FROM PDIStep__c
                WHERE VehicleStock__c IN :successMap.keySet()
                AND Stage__c = :stepName
        ]) {
            step.IsPass__c = true;
            step.StepStart__c = System.now();
            step.StepEnd__c = System.now();
            step.StepWorker__c = UserInfo.getName();
            updateStepList.add(step);

            String key = step.VehicleStock__r.VehicleNo__c;
            String requestRes = '업데이트 성공';
            Map<String, String> tempMap2 = resultMap.get(key);
            tempMap2.put('RequestRes', requestRes);
            resultMap.put(key, tempMap2);
        }

        if(!updateStepList.isEmpty()) update updateStepList;
        return resultMap;
    }

    //step3 Start
    @AuraEnabled
    public static String step3Init(String vinId) {
        Product2 product = [
            SELECT Id
            FROM Product2
            WHERE Id IN (SELECT Product__c FROM VehicleStock__c WHERE Id = :vinId)
        ];
        return product.Id;
    }

    @AuraEnabled
    public static List<IFAuditLogDetail__c> step3CheckSpoiler(String vinId) {
        List<IFAuditLogDetail__c> spoilerRequestList = [
            SELECT Id, fm_LogType__c, IsRequest__c, IsResponse__c, ExternalId__c, ExternalKey__c
            FROM IFAuditLogDetail__c 
            WHERE ExternalId__c = :vinId
            AND fm_LogType__c = 'SPOILER_REQUEST'
        ];
        return spoilerRequestList;
    }

    //ver 1.1
    /**
     * @author chaebeom.do
     * @description 선택된 차량의 배정 확정(단건)
     * @param completeMap 출고할 차량, 기회, 현재 기회에 배정된 차량
     */
    @AuraEnabled
    public static void doCompleteStep3(Map<String, String> completeMap) {

        List<SObject> updateList = new List<SObject>();
        updateList.add(new VehicleStock__c(
            Id = completeMap.get('stockId'),
            VehicleStatus__c = '출고예정'
        ));
        PDIStep__c selectedVINStep = [
            SELECT Id
            FROM PDIStep__c
            WHERE VehicleStock__c = :completeMap.get('stockId')
            AND Stage__c = 'STEP3'
        ];
        updateList.add(new PDIStep__c(
            Id = selectedVINStep.Id,
            IsPass__c = true,
            StepStart__c = System.now(),
            StepEnd__c = System.now(),
            StepWorker__c = UserInfo.getName()
        ));
        // 기회에 선택한 차량과 다른 차량이 배정되어있을 경우
        if(completeMap.get('stockId') != completeMap.get('previousStockId')) {
            updateList.add(new VehicleStock__c(
                Id = completeMap.get('previousStockId'),
                VehicleStatus__c = '판매준비완료'
            ));
            for(PDIStep__c previousVINStep : [
                SELECT Id
                FROM PDIStep__c
                WHERE VehicleStock__c = :completeMap.get('previousStockId')
                AND Stage__c IN ('STEP3', 'STEP4', 'STEP5')
            ]) {
                updateList.add(new PDIStep__c(
                    Id = previousVINStep.Id,
                    IsPass__c = false,
                    StepStart__c = null,
                    StepEnd__c = null,
                    StepWorker__c = null
                ));
            }
            updateList.add(new Opportunity(
                Id = completeMap.get('opportunityId'),
                VehicleStock__c = completeMap.get('stockId')
            ));
        }

        if (!updateList.isEmpty()) update updateList;
    }
    //ver 1.1
    /**
     * @author chaebeom.do
     * @description 선택된 차량의 배정 취소(단건)
     * @param rollbackMap 취소할 기회, 기회에 배정된 차량
     */
    @AuraEnabled
    public static void doRollbackStep3(Map<String, String> rollbackMap) {

        List<SObject> updateList = new List<SObject>();
        updateList.add(new VehicleStock__c(
            Id = rollbackMap.get('previousStockId'),
            VehicleStatus__c = '판매준비완료'
        ));
        for(PDIStep__c previousVINStep : [
            SELECT Id
            FROM PDIStep__c
            WHERE VehicleStock__c = :rollbackMap.get('previousStockId')
            AND Stage__c IN ('STEP3', 'STEP4', 'STEP5')
        ]) {
            updateList.add(new PDIStep__c(
                Id = previousVINStep.Id,
                IsPass__c = false,
                StepStart__c = null,
                StepEnd__c = null,
                StepWorker__c = null
            ));
        }
        updateList.add(new Opportunity(
            Id = rollbackMap.get('opportunityId'),
            VehicleStock__c = null
        ));

        if (!updateList.isEmpty()) update updateList;
    }
    //step3 End

    //step4 Start
    @AuraEnabled
    public static Map<String, Object> step4Init(String selectVIN) {
        // 선택 차량의 publish된 견적 옵션 리스트 가져오기
        String selectFields = 'Id, VehicleOptionMaster__r.Division__c, VehicleOptionMaster__r.Name, VehicleOptionMaster__r.Price__c';

        List<String> whereConditionList = new List<String>();
        whereConditionList.add('Quote__r.Status = \'Published\'');
        whereConditionList.add('VehicleOptionMaster__c != null');
        whereConditionList.add('Quote__r.Opportunity.VehicleStock__c = \'' + selectVIN + '\'');


        List<QuoteDetail__c> optionList = Database.query(CommonUtilController.buildQuery(selectFields, 'QuoteDetail__c', String.join(whereConditionList, ' AND '), 'VehicleOptionMaster__r.Division__c ASC'));
        List<OptionWrap> optionWrapList = new List<OptionWrap>();
        for (QuoteDetail__c option : optionList) {
            VehicleOptionMaster__c optionMaster = option.VehicleOptionMaster__r;
            optionWrapList.add(new OptionWrap(optionMaster?.Id, optionMaster?.Name, optionMaster?.Division__c, optionMaster?.Price__c));
        }

        // 선택 차량에 연결된 Spoiler Id 가져오기
        VehicleStock__c curStock = [
            SELECT Id, Name, SpoilerPart__c
            FROM VehicleStock__c
            WHERE Id = :selectVIN
        ];

        // 선택 차량에 연결된 Spoiler 가져오기
        List<SpoilerPart__c> installList = [
            SELECT Id, Name, SpoilerCode__c
            FROM SpoilerPart__c
            WHERE Id = :curStock.SpoilerPart__c
        ];

        // Spoiler 목록 가져오기
        List<SpoilerPartsJuntion__c> spoilerPartsJuntion = [
            SELECT Id, Name, SpoilerParts__c, SpoilerParts__r.Name, SpoilerParts__r.SpoilerCode__c
            FROM SpoilerPartsJuntion__c
            ORDER BY CreatedDate DESC
        ];

        Set<String> spoilerCodeSet = new Set<String>();
        for(SpoilerPartsJuntion__c tempSpoilerPartsJuntion : spoilerPartsJuntion) {
            spoilerCodeSet.add(tempSpoilerPartsJuntion.SpoilerParts__r.SpoilerCode__c);
        }
        IF_DTO.PartStock partStock = SAPCommon.fetchSpoilerStockAPI(spoilerCodeSet);

        Map<String, Map<String, Integer>> qtySpoilerMap = new Map<String, Map<String, Integer>>();
        for (IF_DTO.PartStockInfo detailInfo : partStock.ResultData) {
            String spoilerCode = detailInfo.ITEMCD;
            Map<String, Integer> tempMap = new Map<String, Integer>();

            // SpoilerCode별 WareHouse 수량
            for (IF_DTO.WarehouseInfo WHInfo : detailInfo.STK) {
                if(WHInfo.WHSCD.equals('P11') || WHInfo.WHSCD.equals('P21')) {
                    tempMap.put(WHInfo.WHSCD, Integer.valueOf(WHInfo.QTY));
                }
            }
            qtySpoilerMap.put(spoilerCode, tempMap);
        }

        List<Map<String, Object>> customSpoilerPartsJuntionList = new List<Map<String, Object>>();
        for(SpoilerPartsJuntion__c tempspoilerPartsJuntion : spoilerPartsJuntion) {
            Map<String, Object> tempMap = new Map<String, Object> {
                    'Id' => tempspoilerPartsJuntion.Id
                    , 'Name' => tempspoilerPartsJuntion.Name
                    , 'SpoilerParts__c' => tempspoilerPartsJuntion.SpoilerParts__c
                    , 'SpoilerParts__r' => new Map<String, String> {
                            'Name' => tempspoilerPartsJuntion.SpoilerParts__r.Name
                            , 'SpoilerCode__c' => tempspoilerPartsJuntion.SpoilerParts__r.SpoilerCode__c
                            , 'P11' => String.valueOf(qtySpoilerMap.get(tempspoilerPartsJuntion.SpoilerParts__r.SpoilerCode__c).get('P11'))
                            , 'P21' => String.valueOf(qtySpoilerMap.get(tempspoilerPartsJuntion.SpoilerParts__r.SpoilerCode__c).get('P21'))
                    }
            };
            customSpoilerPartsJuntionList.add(tempMap);
        }

        return new Map<String, Object>{
            'selectedOption' => optionWrapList,
            'installList' => installList,
            'spoilerPartsJuntion' => customSpoilerPartsJuntionList
        };
    }

    @AuraEnabled
    public static void installSpoilerToVehicleStock(Map<String, String> inputMap) {
        VehicleStock__c vehicleStock = new VehicleStock__c();
        vehicleStock.Id = inputMap.get('stockId');
        vehicleStock.SpoilerPart__c = inputMap.get('spoilerId');

        update vehicleStock;
    }

    @AuraEnabled
    public static void updateStep4(String stockId) {
        PDIStep__c step = [
            SELECT Id, IsPass__c
            FROM PDIStep__c
            WHERE VehicleStock__c = :stockId
            AND Stage__c = 'STEP4'
        ];
        step.IsPass__c = true;
        step.StepStart__c = System.now();
        step.StepEnd__c = System.now();
        step.StepWorker__c = UserInfo.getName();
        update step;
    }

    @AuraEnabled
    public static void spoilerDropoffSAP(List<Map<String, Object>> inputMapList) {
        System.enqueueJob(new AsyncSpoilerRequest(inputMapList));
    }
    //step4 End

    public static String getStockList(String whereCondition) {
        String selectFields =   'Id, Name, RealArrivalDate__c, Product__r.Name, VehicleNo__c, VehicleStatus__c, Status__c, SpoilerPart__c, SpoilerPart__r.SpoilerCode__c, toLabel(CarColor__c), fm_PdiNextStep__c, fm_UnresolvedIssues__c, DriveDistance__c';
        String fromObject =     'VehicleStock__c';

        List<String> whereConditionList = new List<String>();
        whereConditionList.add('VehicleStatus__c != \'항구도착전\'');
        whereConditionList.add('VehicleStatus__c != \'출고됨\''); // 출고불가도 안보여줄지?
        whereConditionList.add('Name LIKE \'WMA%\''); 
        if(whereCondition != '') whereConditionList.add(whereCondition);

        String query = CommonUtilController.buildQuery(selectFields, fromObject, String.join(whereConditionList, ' AND '), 'fm_PdiNextStep__c ASC NULLS LAST, VehicleNo__c NULLS LAST, Name NULLS LAST'); // 단계, 워크넘버, vin 순서로 정렬
        query +=                ' LIMIT 200';
        return query;
    }

    public class OptionWrap {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public Decimal price { get; set; }

        public OptionWrap(String id, String name, String type, Decimal price) {
            this.id = id;
            this.name = name;
            this.type = type;
            this.price = price;
        }
    }
}