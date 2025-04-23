/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : AsyncTaxInvoiceIssuance, AsyncCustomerInfo, AsyncVAInfo, AsyncSpoilerRequest, AsyncOffsetRequest, AsyncLoanRequestMFS
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-26      payo03@solomontech.net           Created
*/
@IsTest
private class AsyncInterface_test {

    @TestSetup
    static void setup() {
        TestObjectBuilder2.createObjects();
        TestObjectBuilder2.createConfigBundle();
        TestObjectBuilder2.createIfBundle();

        TestObjectBuilder2.createAccountBundle();
        TestObjectBuilder2.createContractBundle();
        TestObjectBuilder2.createVirtualAccountBundle();
        TestObjectBuilder2.createStockBundle();
        TestObjectBuilder2.createPaymentBundle();

        Account acc = [SELECT Id, BusinessName__c, BusinessNumber__c, IDNumber__pc, Name, PersonEmail, PostalCode__c, RoadAddress__c, DetailAddress__c FROM Account WHERE AccountType__c != 'LICENSE' LIMIT 1];
        System.debug(acc);
        AccountInterface.sendCustomerInfo(acc.Id);
    }

    @IsTest
    static void testBehavior1() {

        List<String> opptyIdList = new List<String>();
        for(QuoteDetail__c detail : [
                SELECT Id, Quote__c, Quote__r.OpportunityId
                FROM QuoteDetail__c
        ]) {
            String opptyId = detail.Quote__r.OpportunityId;

            if(!opptyIdList.contains(opptyId)) opptyIdList.add(opptyId);
        }

        System.enqueueJob(new AsyncTaxInvoiceIssuance(opptyIdList, null));
    }

    @IsTest
    static void testBehavior2() {

        List<String> logIdList = new List<String>();
        for(IFAuditLogDetail__c detail : [
                SELECT Id, fm_LogId__c
                FROM IFAuditLogDetail__c
                WHERE fm_LogType__c = 'CUSTOMER_BP'
        ]) {
            logIdList.add(detail.fm_LogId__c);
        }

        System.enqueueJob(new AsyncVAInfo(logIdList, AsyncVAInfo.SEND_TYPE.S));
    }

    @IsTest
    static void testBehavior3() {

        List<Map<String, Object>> paramMapList = new List<Map<String, Object>>();
        for(VehicleStock__c stock : [
                SELECT Id, SpoilerPart__r.SpoilerCode__c
                FROM VehicleStock__c
        ]) {
            Map<String, Object> paramMap = new Map<String, Object>{
                    'stockId' => stock.Id,
                    'spoilerCode' => stock.SpoilerPart__r.SpoilerCode__c,
                    'isAttach' => true
            };

            paramMapList.add(paramMap);
        }

        System.enqueueJob(new AsyncSpoilerRequest(paramMapList));
    }

    @IsTest
    static void testBehavior4() {

        List<String> opptyIdList = new List<String>();
        for(Opportunity oppty : [
                SELECT Id
                FROM Opportunity
        ]) {
            opptyIdList.add(oppty.Id);
        }

        System.enqueueJob(new AsyncOffsetRequest(opptyIdList));
    }

    @IsTest
    static void testBehavior5() {

        List<String> quoteIdList = new List<String>();
        for(Quote quote : [
                SELECT Id
                FROM Quote
        ]) {
            quoteIdList.add(quote.Id);
        }

        System.enqueueJob(new AsyncLoanRequestMFS(quoteIdList, null));
    }
}