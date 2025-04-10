/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-02-19      payo03@solomontech.net           Created
  1.1      2025-03-07      payo03@solomontech.net           IFAudigLogDetail. VehicleStock을 연결하기위해 데이터 GET
  1.2      2025-03-10      payo03@solomontech.net           IFAudigLogDetail. Async-Sync 공통 Update함수 추가
  1.3      2025-03-11      payo03@solomontech.net           차량재고조회 함수 추가
*/
public with sharing class SAPCommon {

    // SAP Interface를 위한 필드Set
    public static List<AvisOrderInfo__c> fetchOrderInfoList(List<String> idList) {
        return [
                SELECT Id, OrderConfirmSAP__c, IsSpoiler__c, fm_IsDeck__c, fm_SpoilerCode__c, fm_CabColor__c, fm_SpoilerText__c,
                        OrderIntakeNo__c, ChassisFrameNo__c, HorsePower__c, EngineNumber__c, EngineType__c, WeightKg__c, VehicleNo__c,
                        OrderDate__c, Etd__c, ETA__c, BuyingPrice__c, InvoiceNumber__c, BLDocumentNo__c, Ship__c, HarbourShort__c,
                        Harbour__c, Destination__c, AdjustTargetRos__c, InvoiceDateLastAdjusted__c, BLDate__c,
                        fm_Segment1__c, fm_SpecShort__c, CabMark__c, IntarderOption__c, WheelBase__c, TrimLevel__c, EmissionLevelEu__c,
                        RealArrivalDate__c, CarColor__c,
                        (
                            SELECT Id, Name, VehicleNo__c
                            FROM VehicleStock__r
                        )
                FROM AvisOrderInfo__c
                WHERE Id IN :idList
        ];
    }

    // Spoiler데이터 GET. KEY : getSpoilerKey Value(fm_SpoilerText 혹은 fm_SpoilerCode), Value : SpoilerPart
    public static Map<String, SpoilerPart__c> fetchSpoilerMap(List<AvisOrderInfo__c> infoList) {
        Map<String, SpoilerPart__c> spoilerMap = new Map<String, SpoilerPart__c>();

        // Spoiler 포함여부 확인
        for (AvisOrderInfo__c info : infoList) {

            spoilerMap.put(CommonUtilCustomController.getSpoilerKey(info), null);
        }

        // 특수차량에 대한 Spoiler
        for(SpoilerPart__c part : [
                SELECT Id, Name, SpoilerCode__c, Price__c
                FROM SpoilerPart__c
                WHERE Name IN :spoilerMap.keySet() OR SpoilerCode__c IN :spoilerMap.keySet()
        ]) {
            String key = part.Name;
            if(spoilerMap.keySet().contains(part.SpoilerCode__c)) key = part.SpoilerCode__c;

            spoilerMap.put(key, part);
        }

        return spoilerMap;
    }

    /**
     * @param logId     Update 기준 logId
     * @param infoMap   Heroku 통신 Map데이터
     * @description     Heroku Async처리건. Request 결과 Update
     */
    // ver1.2 IFAudigLogDetail. Async-Sync 공통 Update함수 추가
    public static void asyncLogDetailUpdate(String logId, Map<String, Object> infoMap) {
        if(infoMap.isEmpty() || !Boolean.valueOf(infoMap.get('code'))) return;

        // Heroku 통신 완료시. Async
        List<IFAuditLogDetail__c> logDetailList = [
                SELECT Id, IsRequest__c, Description__c
                FROM IFAuditLogDetail__c
                WHERE fm_LogId__c = :logId
        ];
        for(IFAuditLogDetail__c logDetail : logDetailList) {
            logDetail.IsRequest__c = true;
            logDetail.Description__c = String.valueOf(infoMap.get('message'));
        }
        update logDetailList;
    }

    /**
     * @param logId     Update 기준 logId
     * @param infoMap   Heroku 통신 Map데이터
     * @description     Heroku Async처리건. Request 결과 Update
     */
    // ver1.2 IFAudigLogDetail. Async-Sync 공통 Update함수 추가
    public static void syncLogDetailUpdate(String logId, Map<String, Object> infoMap) {
        if(infoMap.isEmpty() || !Boolean.valueOf(infoMap.get('code'))) return;

        Boolean isAll = infoMap.containsKey('isAll') ? Boolean.valueOf(infoMap.get('isAll')) : false;
        String message = String.valueOf(infoMap.get('message'));
        if(Test.isRunningTest()) message = JSON.serialize(infoMap.get('message'));
        // Heroku 통신 완료시. Sync
        // 1. IsRequest Update
        List<IFAuditLogDetail__c> logDetailList = [
                SELECT Id, IsRequest__c, IsResponse__c, Description__c
                FROM IFAuditLogDetail__c
                WHERE fm_LogId__c = :logId
        ];
        for(IFAuditLogDetail__c logDetail : logDetailList) {
            logDetail.IsRequest__c = true;
            logDetail.Description__c = message;
        }

        // 2. IsResponse Update
        Map<String, Object> sapMap = (Map<String, Object>) JSON.deserializeUntyped(message);
        String resultCode = String.valueOf(sapMap.get('Code')) == '0' ? 'Y' : 'C';
        String resultMessage = String.valueOf(sapMap.get('Message'));
        for(IFAuditLogDetail__c logDetail : logDetailList) {
            logDetail.IsResponse__c = resultCode;
            logDetail.Description__c = resultMessage;

            if(isAll) logDetail.IsResult__c = resultCode;
            if(isAll) logDetail.ResultDatetime__c = Datetime.now();
        }
        update logDetailList;
    }


    /* ------------------------------------------------------------------------------------------- */
    /* ----------------------------------------- API CALL ----------------------------------------- */
    /* ------------------------------------------------------------------------------------------- */

    /**
     * @param spoilerCodeSet    조회할 SpoilerCode List
     * @description             재고조회 호출 API
     * @return                  IF_DTO.PartStock Value
     */
    public static IF_DTO.PartStock fetchSpoilerStockAPI(Set<String> spoilerCodeSet) {
        IF_DTO.PartStock partStock = new IF_DTO.PartStock();

        List<Map<String, String>> codeMapList = new List<Map<String, String>>();
        for(String spoilerCode : spoilerCodeSet) {
            Map<String, String> codeMap = new Map<String, String>();
            codeMap.put('ITEMCD', spoilerCode);

            codeMapList.add(codeMap);
        }

        Map<String, Object> responseMap = new Map<String, Object>();
        for(Integer i = 0; i < 3; i++) {
            // Heroku Server 불안정으로.... Read timed out 발생시 재호출을 위해.. 3번까지 재 수행
            responseMap = InterfaceSAP.doCallOutSAP(InterfaceSAP.IF_SMS001, codeMapList);

            if(!responseMap.isEmpty()) break;
        }

        if(!responseMap.isEmpty()) {
            Boolean isSuccess = Boolean.valueOf(responseMap.get('code'));
            String jsonString = String.valueOf(responseMap.get('message'));
            if (isSuccess) {
                if(Test.isRunningTest()) jsonString = testDTOBody();
                Map<String, Object> messageMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

                partStock = (IF_DTO.PartStock) JSON.deserialize(JSON.serialize(messageMap), IF_DTO.PartStock.class);
            }
        }

        return partStock;
    }

    /**
     * @param paramMapList      조회할 치량재고 Map [ITEMCD - ERPCode], [DISNUM - chassisFrameNo]
     * @description             재고조회 호출 API
     * @return                  IF_DTO.VehicleStock Value
     */
    public static IF_DTO.VehicleStock fetchVehicleStockAPI(List<Map<String, String>> paramMapList) {
        IF_DTO.VehicleStock vehicleStock = new IF_DTO.VehicleStock();

        List<Map<String, String>> codeMapList = new List<Map<String, String>>();
        for(Map<String, String> paramMap : paramMapList) {

            Map<String, String> codeMap = new Map<String, String>();
            for(String key : paramMap.keySet()) {
                codeMap.put(key, paramMap.get(key));
            }
            codeMapList.add(codeMap);
        }

        Map<String, Object> responseMap = new Map<String, Object>();
        for(Integer i = 0; i < 3; i++) {
            // Heroku Server 불안정으로.... Read timed out 발생시 재호출을 위해.. 3번까지 재 수행
            responseMap = InterfaceSAP.doCallOutSAP(InterfaceSAP.IF_SMS002, codeMapList);

            if(!responseMap.isEmpty()) break;
        }

        if(!responseMap.isEmpty()) {
            Boolean isSuccess = Boolean.valueOf(responseMap.get('code'));
            String jsonString = String.valueOf(responseMap.get('message'));
            if (isSuccess) {
                if(Test.isRunningTest()) jsonString = testDTOBody();
                Map<String, Object> messageMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

                vehicleStock = (IF_DTO.VehicleStock) JSON.deserialize(JSON.serialize(messageMap), IF_DTO.VehicleStock.class);
            }
        }

        return vehicleStock;
    }

    public static String testDTOBody() {
        return '{"ResultData": [],"Message": "성공","Code": "0"}';
    }
}