/**
* @Author            : chaebeom.do@solomontech.net
* @Description 		 : CreateAssignRequestController의 테스트 클래스
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-21      chaebeom.do@solomontech.net           Created
  2.0      2025-03-14      chaebeom.do@solomontech.net           사전배정 프로세스 삭제로 인한 이름 변경
*/
@isTest
public class CreateAssignRequestController_test {
    static final Quote testQuote;
    static final Contract testContract;
    static final Opportunity testOpportunity;
    static final VehicleStock__c testVehicleStock;

    static {
        TestObjectBuilder.createObjects();
        testQuote = TestObjectBuilder.quote;
        testContract = TestObjectBuilder.contract;
        testOpportunity = TestObjectBuilder.opportunity;
        testVehicleStock = TestObjectBuilder.vehicleStock;
    }

    @isTest
    static void testGetAcc() {
        Test.startTest();
        CreateAssignRequestController.getAcc(testContract.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetQuote() {
        Test.startTest();
        CreateAssignRequestController.getQuote(testQuote.Id);
        Test.stopTest();
    }

    // @isTest
    // static void testGetPreAllocationStatus() {
    //     Test.startTest();
    //     CreateAssignRequestController.getPreAllocationStatus(testQuote.Id);
    //     Test.stopTest();
    // }

    // //사전배정
    // @isTest
    // static void testCreateApprovalProcess() {
    //     Map<String, String> inputMap = new Map<String, String>{
    //         'recordId' => testQuote.Id,
    //         'comment' => '승인 테스트',
    //         'deposit' => '1000000',
    //         'type' => 'preAllocation'
    //     };

    //     Test.startTest();
    //     CreateAssignRequestController.createApprovalProcess(inputMap);
    //     Test.stopTest();
    // }

    //일반배정
    @isTest
    static void testCreateAssignRequest() {
        testOpportunity.ContractId = testContract.Id;
        update testOpportunity;
        Map<String, String> inputMap = new Map<String, String>{
            'recordId' => testOpportunity.Id,
            'deposit' => '1000000',
            'stockId' => testVehicleStock.Id,
            'contractId' => testContract.Id,
            'type' => 'deposit'
        };

        Test.startTest();
        CreateAssignRequestController.createAssignRequest(inputMap);
        Test.stopTest();
    }
}