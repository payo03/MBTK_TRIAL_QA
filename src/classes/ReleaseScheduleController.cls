/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-13
 * @description : 출고예정서 PDF
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-13        San.Kang           Created
**************************************************************/
public class ReleaseScheduleController {
    public Opportunity opportunity{get; set;}
    public Integer year{get; set;}
    public ReleaseScheduleController(){}
    public String docImage1{get; set;}
    public String uzIngam{get; set;}
    public String TotalWeight{get; set;}
    public String MaxLoad{get; set;}
    public Boolean isNewAddress{get; set;}
    public void init(){
        docImage1 = PDFCommonController.getDocumentId('MAN_Truck_Bus_Korea_LOGO');
        opportunity = PDFCommonController.getOpportunity(ApexPages.currentPage().getParameters().get('id')).get(0);
        year = opportunity.VehicleStock__r.Name.length() > 9 ? opportunity.VehicleStock__r.Name.charAt(9) : 0;
        TotalWeight = opportunity.VehicleStock__r.Product__r.TotalWeight__c == null ? '' : opportunity.VehicleStock__r.Product__r.TotalWeight__c.replace(',','.');
        MaxLoad = opportunity.VehicleStock__r.Product__r.MaxLoad__c == null ? '' : opportunity.VehicleStock__r.Product__r.MaxLoad__c.replace(',','.');
        isNewAddress = PDFCommonController.isNewAddress(opportunity.HandoverDate__c);
        uzIngam = PDFCommonController.getDocumentId('man_useingam');
    }
}