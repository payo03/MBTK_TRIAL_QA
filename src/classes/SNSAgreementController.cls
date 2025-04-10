/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-06
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-06        San.Kang           Created
**************************************************************/
public with sharing class SNSAgreementController {
    public Opportunity opportunity { get; set; }

    public void init() {
        String vehicleStockId = ApexPages.currentPage().getParameters().get('id');
        VehicleStock__c vehicleStock = PDFCommonController.getVehicleStock(vehicleStockId);
        opportunity = PDFCommonController.getOpportunity(vehicleStockId).get(0);
    }
}