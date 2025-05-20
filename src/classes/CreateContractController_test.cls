/**
* @Author            : chaebeom.do@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-23      chaebeom.do@solomontech.net      Created
*/
@isTest
private class CreateContractController_test {
    static final Quote testQuote;
    static final Account testAcc;
    static final Opportunity testOpportunity;
    static final VehicleStock__c testStock;
    static final Product2 testProduct;

    static {
        TestObjectBuilder2.createQuoteBundle();
        insert TestObjectBuilder2.createPDIStep();
        testQuote = TestObjectBuilder2.quote;
        testAcc = TestObjectBuilder2.accountPerson;
        testOpportunity = TestObjectBuilder2.opportunity;
        testStock = TestObjectBuilder2.vehicleStock;
        testProduct = TestObjectBuilder2.product;
    }

    @isTest
    static void testGetQuote() {
        Test.startTest();
        CreateContractController.getQuote(testQuote.Id);
        Test.stopTest();
    }

    @isTest
    static void testCreateContract() {
        Map<String, String> inputMap = new Map<String, String>{
            'recordId' => testQuote.Id,
            'accId' => testAcc.Id,
            'stockId' => testStock.Id,
            'productId' => testProduct.Id,
            'opptyId' => testOpportunity.Id,
            'segment' => testQuote.Segment__c,
            'totalLoanAmount' => '10000000'
        };
        testQuote.IsApproveLoan__c = true;
        update testQuote;
        
        PDIStep__c testStep = [
            SELECT Id, Stage__c, IsPass__c
            FROM PDIStep__c
            WHERE VehicleStock__c = :testStock.Id
            AND Stage__c = 'STEP2' 
        ];

        testStep.IsPass__c = true;
        update testStep;

        Test.startTest();
        CreateContractController.createContract(inputMap);
        Test.stopTest();
    }
}