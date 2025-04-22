/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-13      payo03@solomontech.net           Created
*/
@IsTest
private class CreateVehicleController_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createConfigBundle();
        TestObjectBuilder2.createOrderBundle();
    }

    @IsTest
    static void testBehavior() {
        Map<String, List<Map<String, String>>> pickListMap = CreateVehicleController.screenInit();

        List<AvisOrderInfo__c> infos = [SELECT Id FROM AvisOrderInfo__c];
        ApexPages.StandardSetController pageController = new ApexPages.StandardSetController(infos);
        CreateVehicleController controller = new CreateVehicleController(pageController);

        controller.selectFilterOrder();
        ApexPages.currentPage().getParameters().put('targetURL', '/lightning/o/AvisOrderInfo__c/home');
        controller.navigationPage();

        List<AvisOrderInfo__c> infoList = CreateVehicleController.selectInfoList(new List<String>{infos.get(0).Id});
        CreateVehicleController.createVehicleStock(infos);

        CreateVehicleController.selectLogList(new List<String>());

        Map<String, Object> paramMap = new Map<String, Object>();
        paramMap.put('type', 'else');
        paramMap.put('infoIdList', new List<String>());
        CreateVehicleController.handleIFAction(paramMap);
    }
}