/**
* @Author            : payo03@solomontech.net
* @Description 		 : Test Class
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-13      payo03@solomontech.net           Created
*/
@IsTest
private class AvisOrderInfo_tr_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createConfigBundle();
        TestObjectBuilder2.createOrderBundle();
    }

    @IsTest
    static void testBehavior() {
        Test.startTest();

        List<AvisOrderInfo__c> infos = [
                SELECT Id, OrderIntakeNo__c, EmissionLevelEu__c, fm_Segment2__c, fm_SpecShort__c, IsMail__c
                FROM AvisOrderInfo__c
        ];

        new AvisOrderInfo_tr().test(infos);
        for(AvisOrderInfo__c info : infos) {
            info.IsMail__c= true;
        }
        update infos;

        Test.stopTest();
    }
}