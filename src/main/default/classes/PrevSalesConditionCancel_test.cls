/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-05-14      jh.jung           Created
*/

@IsTest
private class PrevSalesConditionCancel_test {

    @TestSetup
    static void setup() {
        TestObjectBuilder2.createContractNotTaxDateBundle();
    }

    @IsTest
    static void testBehavior() {
        PrevSalesConditionCancel.init();
        PrevSalesConditionCancel.process();
    }


}