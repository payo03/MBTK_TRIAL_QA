/**
* @Author            : payo03@solomontech.net
* @Description 		 : Test Class
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-26      payo03@solomontech.net           Created
*/
@IsTest
private class IFAuditLogDetail_tr_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createConfigBundle();
        TestObjectBuilder2.createOrderBundle();

        String fields = CreateVehicleStock_ba.getFields();
        String fromObject = 'AvisOrderInfo__c';
        String buildQuery = CommonUtilController.buildQuery(fields, fromObject, '');
        List<AvisOrderInfo__c> infos = Database.query(buildQuery);
        CreateVehicleStock_ba ba = new CreateVehicleStock_ba(null, null);
        ba.execute(null, infos);
        ba.finish(null);

        List<String> idList = new List<String>();
        for(AvisOrderInfo__c info : infos) {
            idList.add(info.Id);
        }
        System.enqueueJob(new AsyncOrderConfirm(idList, null));
    }

    @IsTest
    static void testBehavior() {
        Test.startTest();

        List<IFAuditLogDetail__c> details = [
                SELECT Id, IsResponse__c
                FROM IFAuditLogDetail__c
        ];
        for(IFAuditLogDetail__c detail : details) {
            detail.IsResponse__c = 'N';
        }
        update details;
        for(IFAuditLogDetail__c detail : details) {
            detail.IsResponse__c = 'C';
        }
        update details;

        Test.stopTest();
    }
}