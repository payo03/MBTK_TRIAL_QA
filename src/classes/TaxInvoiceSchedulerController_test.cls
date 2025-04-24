/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-03-27      jh.jung           Created
*/
@IsTest
private class TaxInvoiceSchedulerController_test {

    static Opportunity oppty;
    static VehicleStock__c vehicleStock;
    static Handover__c handover;
    static Map<String, String> filterMap;

    static {
        TestObjectBuilder.createObjects();
        oppty = TestObjectBuilder.createOpportunity();
        vehicleStock = TestObjectBuilder.createVehicleStock();
        handover = TestObjectBuilder.createHandover();
        filterMap = new Map<String, String> {
                'fm_PaymentStatus__c' => '',
                'Opportunity__r.HandoverDate__c >' => '=2025-03-30',
                'Opportunity__r.HandoverDate__c <' => '=2025-04-30',
                'searchAccountName' => '',
                'searchSalesAgentName' => ''
        };
    }

    @IsTest
    static void testBehavior1() {

        PageReference pageRef = Page.DepositReceiptPDF; // ⚠️ VF 페이지 이름 사용
        Test.setCurrentPage(pageRef);  // 현재 페이지 컨텍스트 지정
        ApexPages.currentPage().getParameters().put('recordId', handover.Id);

        Test.startTest();
        TaxInvoiceSchedulerController.getInit();
        TaxInvoiceSchedulerController.getVFInfo();
        TaxInvoiceSchedulerController.callTaxInvoice(oppty.Id, true);
        TaxInvoiceSchedulerController.getCalendarInit(vehicleStock.Id);
        TaxInvoiceSchedulerController.insertHandoverDateAllocationHistory(Date.today(), oppty.Id, vehicleStock.Id);
        TaxInvoiceSchedulerController.getFilteredHandoverList(filterMap);
        try {
            TaxInvoiceSchedulerController.generatePdfBlobSave(handover.Id);
        } catch(Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
            Blob pdfBlob = Blob.valueOf('Mock PDF Data');
        }
        Test.stopTest();
    }
}