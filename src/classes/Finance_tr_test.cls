/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-03-28      jh.jung           Created
*/

@IsTest
private class Finance_tr_test {

    static Finance__c finance;

    static {
//        TestObjectBuilder.createObjects();
        insert TestObjectBuilder2.createFinance();
        finance = TestObjectBuilder2.createFinance();
    }

    @IsTest
    static void testBehavior1() {
        Test.startTest();
        finance.StartDate__c = Date.today().addMonths(1);
        update finance;
        Test.stopTest();
    }
}