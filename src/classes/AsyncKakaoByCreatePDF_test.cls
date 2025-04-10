/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-03-31      jh.jung           Created
*/

@IsTest
private class AsyncKakaoByCreatePDF_test {

    static Map<String, Object> paramMap;
    static {
        TestObjectBuilder.createObjects();
        Account account = TestObjectBuilder.createAccountPerson();
        Contract contract = TestObjectBuilder.createContract();
        paramMap = new Map<String, Object> {
                'templateTitle' => 'all',
                'recordId' => contract.Id,
                'infoMapList' => new List<Object>{
                    new Map<Object, Object> {
                        'recordId' => account.Id
                        , 'customerType' => 'owner'
                    }
                },
                'externalId' => contract.Id
        };
    }

    @IsTest
    static void testBehavior() {
        Test.startTest();
        AsyncKakaoByCreatePDF queue = new AsyncKakaoByCreatePDF(paramMap);
        queue.execute(null);
        Test.stopTest();
    }
}