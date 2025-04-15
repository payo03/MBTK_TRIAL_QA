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
public with sharing class OilReceiptController_test {

    static final Contract contract = TestObjectBuilder.createContract();
    static final Opportunity opportunity = TestObjectBuilder.createOpportunity();
    static final VehicleStock__c vehicleStock = TestObjectBuilder.createVehicleStock();

    static final List<QuoteDetail__c> quoteDetail = TestObjectBuilder.createQuoteDetail();
    static final List<Signature__c> signature = TestObjectBuilder.createSignature();

    static {
        insert contract;
        insert quoteDetail;
        insert signature;
    }

    @IsTest
    public static void test(){

        Test.setCurrentPage(Page.OilReceipt);
        ApexPages.currentPage().getParameters().put('id', opportunity.VehicleStock__c);
        Test.startTest();
        OilReceiptController ctrl = new OilReceiptController();
        OilReceiptController.getQuoteDetail(quoteDetail[0].Quote__c);
        OilReceiptController.getField(Schema.SObjectType.QuoteDetail__c.fields.getMap());
        Test.stopTest();
    }
}