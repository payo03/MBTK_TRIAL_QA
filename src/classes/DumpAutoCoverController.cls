/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-12
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-12        San.Kang           Created
**************************************************************/

public class DumpAutoCoverController {
    public DumpAutoCoverController(){}
    public String docImage1{get;set;}
    public String docImage2{get;set;}
    public String docImage3{get;set;}
    public String docImage4{get;set;}
    public Opportunity opportunity{get; set;}
    public VehicleStock__c vehicleStock{get; set;}
    public String Validity{get; set;}//유효기간
    public String docDate{get; set;}

    public void init(){

        String year = ApexPages.currentPage().getParameters().get('year');
        String month = ApexPages.currentPage().getParameters().get('month');
        String day = ApexPages.currentPage().getParameters().get('day');
        if(!String.isBlank(year)&& !String.isBlank(month) && !String.isBlank(day)){
            Date mDate = Date.newInstance(Integer.valueOf(year),Integer.valueOf(month),Integer.valueOf(day));
            Validity = PDFCommonController.getValidate(mDate);
        }
        docImage1 = PDFCommonController.getDocumentId('MAN_Truck_Bus_Korea_LOGO');
        docImage2 = PDFCommonController.getDocumentId('doc_covertable_img1');
        docImage3 = PDFCommonController.getDocumentId('doc_covertable_img2');
        docImage4 = PDFCommonController.getDocumentId('doc_profidrive_img1');
        String vehicleStockId = ApexPages.currentPage().getParameters().get('Id').trim();
        vehicleStock = PDFCommonController.getVehicleStock(vehicleStockId);
        opportunity = PDFCommonController.getOpportunity(vehicleStockId).get(0);
        if(opportunity != null && opportunity.HandoverDate__c != null){
            Date HandoverDate = opportunity.HandoverDate__c;
            docDate = String.valueOf(HandoverDate.year()) + '. ' + String.valueOf(HandoverDate.month()) + '. ' + String.valueOf(HandoverDate.day());
        }
    }
}