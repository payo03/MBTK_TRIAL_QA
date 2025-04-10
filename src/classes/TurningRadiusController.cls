/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-14
 * @description : 최소회전반경적합확인서 PDF
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-14        San.Kang           Created
**************************************************************/
public with sharing class TurningRadiusController {
    public TurningRadiusController(){}
    public String docImage1 {get;set;}
    public String docImage5 {get;set;}
    public VehicleStock__c vehicleStock {get;set;}

    public void init(){
        String vehicleStockId = ApexPages.currentPage().getParameters().get('Id').trim();
        vehicleStock = PDFCommonController.getVehicleStock(vehicleStockId);

        docImage1 = PDFCommonController.getDocumentId('MAN_Truck_Bus_Korea_LOGO');
        docImage5 = PDFCommonController.getDocumentId('doc_TurningRadius_stamp');
    }
}