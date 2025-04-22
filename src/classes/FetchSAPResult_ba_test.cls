/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-25      payo03@solomontech.net           Created
*/
@IsTest
private class FetchSAPResult_ba_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createIfBundle();
        TestObjectBuilder2.createOrderBundle();
        TestObjectBuilder2.createConfigBundle();

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
        List<IFAuditLogDetail__c> details = [
                SELECT Id, IsRequest__c, IsResponse__c, IsResult__c, fm_InterfaceId__c
                FROM IFAuditLogDetail__c
        ];
        for(IFAuditLogDetail__c detail : details) {
            if(detail.fm_InterfaceId__c.contains('SMS009')) continue;

            detail.IsRequest__c = true;
            detail.IsResponse__c = 'Y';
            System.debug(detail);
        }
        update details;

        String selectFields                                 = FetchSAPResult_ba.getFields();
        String fromObject                                   = 'IFAuditLog__c ';
        String whereConditions                              = FetchSAPResult_ba.DEFAULT_CONDITION;
        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, whereConditions);
        List<SObject> records = Database.query(buildQuery);

        FetchSAPResult_ba ba = new FetchSAPResult_ba(null, null);

        Test.startTest();

        Database.QueryLocator queryLocator = ba.start(null);
        ba.execute(null, records);
        ba.execute(null);
        ba.finish(null);

        Test.stopTest();
    }
}