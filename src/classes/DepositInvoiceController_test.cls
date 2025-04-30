/**
* @Author            : chaebeom.do@solomontech.net
* @Description 		 : DepositInvoiceController의 테스트 클래스
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-21      chaebeom.do@solomontech.net           Created
  2.0      2025-03-14      chaebeom.do@solomontech.net           사전배정 프로세스 삭제로 인한 이름 변경
  3.0      2025-04-29      chaebeom.do@solomontech.net           AssignRequest__c 오브젝트 삭제로 인한 클래스 이름 변경 및 로직 수정
*/
@isTest
public class DepositInvoiceController_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createContractBundle2();
    }

    @isTest
    static void testBehavior() {

        Test.startTest();
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        DepositInvoiceController.getAcc(contract.Id);

        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        VehicleStock__c stock = [SELECT Id FROM VehicleStock__c LIMIT 1];
        Map<String, String> inputMap = new Map<String, String>{
            'opptyId' => opportunity.Id,
            'deposit' => '1000000',
            'stockId' => stock.Id,
            'contractId' => contract.Id
        };
        DepositInvoiceController.assignVirtualAccount(inputMap);
        Test.stopTest();
    }
}