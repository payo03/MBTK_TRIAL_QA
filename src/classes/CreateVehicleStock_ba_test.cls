/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : CreateVehicleStock_ba, AsyncOrderConfirm, AsyncPurchaseInvoice
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-13      payo03@solomontech.net           Created
*/
@IsTest
private class CreateVehicleStock_ba_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createAccountBundle();
        TestObjectBuilder2.createOrderBundle();
    }

    @IsTest
    static void testBehavior() {
        String fields = CreateVehicleStock_ba.getFields();
        String fromObject = 'AvisOrderInfo__c';
        String buildQuery = CommonUtilController.buildQuery(fields, fromObject, '');

        List<AvisOrderInfo__c> infos = Database.query(buildQuery);
        CreateVehicleStock_ba ba = new CreateVehicleStock_ba(null, null);

        Test.startTest();

        Database.QueryLocator queryLocator = ba.start(null);
        ba.execute(null, infos);
        ba.finish(null);

        List<String> idList = new List<String>();
        for(AvisOrderInfo__c info : infos) {
            idList.add(info.Id);
        }
        System.enqueueJob(new AsyncCustomsInfo(idList, null));

        Test.stopTest();
    }
}