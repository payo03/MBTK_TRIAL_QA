/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-05-07      jh.jung           Created
*/
@isTest
private class OppModifyRequest_tr_test {


    @TestSetup
    static void setup() {
        TestObjectBuilder2.createOpportunityBundle();
        TestObjectBuilder2.createObjects();
    }

    @IsTest
    static void testBehavior() {

        Test.startTest();

        Opportunity opportunityObj = [SELECT Id FROM Opportunity LIMIT 1];
        OppModifyRequest__c oppModifyRequest = new OppModifyRequest__c();
        oppModifyRequest.Opportunity__c = opportunityObj.Id;
        oppModifyRequest.Comments__c = 'test';
        insert oppModifyRequest;

        oppModifyRequest.Approved__c = true;
        update oppModifyRequest;

        Test.stopTest();
    }

}