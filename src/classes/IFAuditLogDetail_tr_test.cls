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

        Database.executeBatch(new CreateVehicleStock_ba(null, null), 200);
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