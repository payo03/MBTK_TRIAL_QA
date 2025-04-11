/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-27
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-27        San.Kang           Created
**************************************************************/
@IsTest
private class PDFCommonController_test {

    static final Contract contract = TestObjectBuilder.createContract();
    static final Opportunity opportunity = TestObjectBuilder.createOpportunity();
    static final Account account = TestObjectBuilder.createAccountPerson();
    static final VehicleStock__c vehicleStock = TestObjectBuilder.createVehicleStock();

    static final List<QuoteDetail__c> quoteDetail = TestObjectBuilder.createQuoteDetail();
    static final List<Document> document = TestObjectBuilder.createDocument();



    static {
        insert contract;
        insert quoteDetail;
        insert document;
    }


    @IsTest
    static void testBehavior() {

        Map<String,Object> tempDriverMap = new Map<String,Object>{
                'tempReqDate' => System.today(),
                'drivePurpose' => '신규',
                'driveDays' => 10
        };
        Test.startTest();

        PDFCommonController.getField(Schema.SObjectType.VehicleStock__c.fields.getMap());
        PDFCommonController.getAccounts(opportunity.AccountId);
        PDFCommonController.getVehicleStock(opportunity.VehicleStock__c);
        PDFCommonController.getOpportunity(opportunity.Id);
        PDFCommonController.getDocumentId('man_bizingam');
        PDFCommonController.getProductOptionCnt(vehicleStock.Product__c);
        PDFCommonController.getOpportunityInit(opportunity.Id);
        PDFCommonController.getPaymentTracker(opportunity.Id);
        PDFCommonController.getQuote(opportunity.Id);
        PDFCommonController.getQuoteDetail(quoteDetail[0].Quote__c);
        PDFCommonController.getUsersByRole('');
        PDFCommonController.getValidate(System.today());
        PDFCommonController.getVehicleStockInit(opportunity.VehicleStock__c);
        PDFCommonController.updatedTempDriver(opportunity.VehicleStock__c,tempDriverMap);
        PDFCommonController.checkSAPermissionSet();
        Test.stopTest();
    }
}