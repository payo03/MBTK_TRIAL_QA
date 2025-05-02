/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-05-02      payo03@solomontech.net           Created
*/
@IsTest
private class ModuSignIDProces_test {

    @TestSetup
    static void setup() {
        TestObjectBuilder2.createContractBundle();
        TestObjectBuilder2.createIfBundle();
    }

    @IsTest
    static void testBehavior() {
        APIDocument__c doc = [SELECT Id, Status__c, Opportunity__c FROM APIDocument__c LIMIT 1];
        doc.Status__c = 'COMPLETED';

        Test.startTest();

        ModuSignIDProcess process = new ModuSignIDProcess();
        process.doAfterProcess(doc.Opportunity__c);

        Test.stopTest();
    }
}