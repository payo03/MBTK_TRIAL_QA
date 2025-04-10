/**
* @Author            : payo03@solomontech.net
* @Description 		 : ListView 목록 Vehicle Stock 생성
* @Target            : AvisOrderInfo > BL(BL Info & Convert)
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-21      payo03@solomontech.net           Created
  1.1      2024-11-27      payo03@solomontech.net           ListView의 Filter된 idList값을 VF Page로 Return
  1.2      2025-03-25      payo03@solomontech.net           세관정보 전송버튼 추가
*/
public with sharing class CreateVehicleController {
    public String filterId { get; set; }
    public String infoString { get; set; }
    public String actionType { get; set; }
    public ApexPages.StandardSetController vfController { get; set; }

    private static final String PRODUCT = 'Product2';
    private static final String VEHICLE_STOCK = 'VehicleStock__c';
    private static final String AVIS_ORDER_INFO = 'AvisOrderInfo__c';
    private static final Integer MAX_SIZE = 100;

    public CreateVehicleController(ApexPages.StandardSetController controller) {
        vfController = controller;
        filterId = vfController.getFilterId();
    }

    @AuraEnabled(Cacheable=true)
    public static Map<String, List<Map<String, String>>> screenInit() {
        Map<String, List<Map<String, String>>> returnMap = new Map<String, List<Map<String, String>>>();

        List<Map<String, String>> listViews = CommonUtilController.getListView('AvisOrderInfo__c');

        List<Map<String, String>> sendToPickList = CommonUtilController.getPickList(AVIS_ORDER_INFO, 'SendTo__c');
        List<Map<String, String>> suffixPickList = CommonUtilController.getPickList(AVIS_ORDER_INFO, 'Suffix__c');
        List<Map<String, String>> cabMarkPickList = CommonUtilController.getPickList(PRODUCT, 'CabMark__c');
        List<Map<String, String>> segment1PickList = CommonUtilController.getPickList(PRODUCT, 'Segment1__c');
        List<Map<String, String>> wheelBasePickList = CommonUtilController.getPickList(PRODUCT, 'WheelBase__c');
        List<Map<String, String>> carColorPickList = CommonUtilController.getPickList(VEHICLE_STOCK, 'CarColor__c');
        List<Map<String, String>> arrivalHarborCodePickList = CommonUtilController.getPickList(AVIS_ORDER_INFO, 'ArrivalHarborCode__c');

        returnMap.put('listViews', listViews);

        returnMap.put('sendTo__c', sendToPickList);
        returnMap.put('suffix__c', suffixPickList);
        returnMap.put('cabMark__c', cabMarkPickList);
        returnMap.put('segment1__c', segment1PickList);
        returnMap.put('wheelBase__c', wheelBasePickList);
        returnMap.put('carColor__c', carColorPickList);
        returnMap.put('arrivalHarborCode__c', arrivalHarborCodePickList);

        return returnMap;
    }

    // VF Page
    public void selectFilterOrder() {
        String filterId = ApexPages.currentPage().getParameters().get('filterId');
        String type = ApexPages.currentPage().getParameters().get('actionType');
        System.debug(type);

        vfController.setFilterId(filterId);
        vfController.setPageSize(vfController.getResultSize() >= MAX_SIZE ? MAX_SIZE : vfController.getResultSize());

        infoString = JSON.serialize(vfController.getRecords());
        actionType = type;
    }

    // VF Page
    public PageReference navigationPage() {
        String targetURL = ApexPages.currentPage().getParameters().get('targetURL');

        PageReference tabPage = new PageReference(targetURL);
        tabPage.setRedirect(true);

        return tabPage;
    }

    // ListView에 해당하는 SELECT 결과값 Return
    @AuraEnabled
    public static List<AvisOrderInfo__c> selectInfoList(List<String> idList) {
        return [
                SELECT Id, IsMail__c, ChassisFrameNo__c, ModelYear__c, fm_SpecShort__c, CabMark__c, CarColor__c, fm_Segment1__c,
                        Suffix__c, SendTo__c, WheelBase__c, ArrivalHarborCode__c, BLDocumentNo__c, BLDate__c, RealSailingDate__c, RealArrivalDate__c
                FROM AvisOrderInfo__c
                WHERE Id IN :idList
        ];
    }

    // Batch Call(Async)
    @AuraEnabled
    public static void createVehicleStock(List<AvisOrderInfo__c> orderList) {
        List<String> targetList = new List<String>();
        for(AvisOrderInfo__c order : orderList) {
            // 화면 수정값 Update
            targetList.add(order.Id);
        }
        update orderList;

        String whereQuery = 'Id IN ' + CommonUtilController.joinedString(targetList);
        Database.executeBatch(new CreateVehicleStock_ba(null, whereQuery), 200);
    }

    @AuraEnabled
    public static void sendCustomsInfo(List<String> idList) {
        System.enqueueJob(new AsyncCustomsInfo(idList, null));
    }
}