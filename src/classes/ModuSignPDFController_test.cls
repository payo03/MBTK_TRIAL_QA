/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-01-20      jh.jung           Created
*/
@IsTest
private class ModuSignPDFController_test {

    static Quote quote;
    static Contract contract;
    static Contract contract2;
    static Account account;
    static Opportunity oppty;
    static VehicleStock__c vehicleStock;
    static Product2 product;
    static Map<String, String> signInfo;

    static {
        TestObjectBuilder.createObjects();
        // contract = TestObjectBuilder.contract;
        contract2 = TestObjectBuilder.createContractAdvance();
        quote = TestObjectBuilder.quote;
        account = TestObjectBuilder.accountPerson;
        oppty = TestObjectBuilder.opportunity;
        vehicleStock = TestObjectBuilder.vehicleStock;
        product = TestObjectBuilder.product;
        signInfo = new Map<String, String>();
        signInfo.put('MobilePhone', '01098868298');
        signInfo.put('Info', '고객');
        signInfo.put('Name', 'Test');
        signInfo.put('RoadAddress', 'roadaddress');
        signInfo.put('PostalCode', '12345');

    }

    @IsTest
    static void testGetVFInfo() {

        // Contract contract = [SELECT Id FROM Contract LIMIT 1];

        Test.startTest();

        ApexPages.currentPage().getParameters().put('recordId', contract2.Id);
        ApexPages.currentPage().getParameters().put('Language', 'ko');
        // Test.setCurrentPageReference(new PageReference('/apex/ModuSignPDFController?id=' + contract.Id));

        ModuSignPDFController.getVFInfo();
        Test.stopTest();
    
    }

    @IsTest
    static void testBehavior() {
        Test.startTest();
        ModuSignPDFController.getAccountInfo(contract2.Id);
        ModuSignPDFController.getAccInfoByOppty(oppty.Id);

        Quote tempQuote = [SELECT Id, ContractId FROM Quote WHERE Id =: quote.Id];
        tempQuote.ContractId = contract2.Id;
        update tempQuote;

        Blob mockedPdfBlob = Blob.valueOf('mocked PDF content');

        ModuSignPDFController.asyncGeneratePdfBlob(contract2.Id, 'all', signInfo, 'ko');

        // PageReference 생성 (Visualforce 페이지 대신 Mock 데이터 반환)
        PageReference mockPage = Page.ModusignPDFTemplate;
        mockPage.getParameters().put('recordId', contract2.Id);
        mockPage.getParameters().put('selectedOption', 'all');

        Map<String, Object> result = new Map<String, Object>();
        result.put('pdfBase64', EncodingUtil.base64Encode(mockedPdfBlob));

        ModuSignPDFController.createRequest((String) result.get('pdfBase64'), 'all', contract2.Id, signInfo, 1);
        ModuSignPDFController.createRequest((String) result.get('pdfBase64'), 'contract', contract2.Id, signInfo, 1);
        ModuSignPDFController.createRequest((String) result.get('pdfBase64'), 'riomds', contract2.Id, signInfo, 1);

        Test.stopTest();
    }

}