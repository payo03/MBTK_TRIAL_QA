/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : CreateVehicleStock_ba, AsyncCustomsInfo
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

        Database.executeBatch(new CreateVehicleStock_ba(null, null), 200);
    }

    @IsTest
    static void testBehavior() {
        String fields = CreateVehicleStock_ba.getFields();
        String fromObject = 'AvisOrderInfo__c';
        String buildQuery = CommonUtilController.buildQuery(fields, fromObject, '');
        List<AvisOrderInfo__c> infos = Database.query(buildQuery);

        List<String> idList = new List<String>();
        for(AvisOrderInfo__c info : infos) {
            idList.add(info.Id);
        }

        Test.startTest();

        CreateVehicleStock_ba ba = new CreateVehicleStock_ba(null, null);
        Database.QueryLocator queryLocator = ba.start(null);
        ba.execute(null, infos);
        ba.finish(null);
        System.enqueueJob(new AsyncCustomsInfo(idList, null));

        Test.stopTest();
    }
}