/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-10
 * @description : 임시운행허가신청서 PDF
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-10        San.Kang           Created
**************************************************************/
public class TempDrivePermitController {
    public VehicleStock__c vehicleStock{get; set;}
    public Opportunity opportunity{get; set;}
    public Account account {get; set;}
    public Integer Segment {get; set;}//1. Tractor 2. Cargo
    public Date CalDate {get; set;}
    public Date tempReqDate {get; set;}
    public TempDrivePermitController(){}
    public void init(){
        //opportunity = [SELECT Id, Name, CustomerType__c, AccountId, ContactHP__c FROM Opportunity WHERE Truck__c =:ApexPages.currentPage().getParameters().get('id') LIMIT 1];
        opportunity = PDFCommonController.getOpportunity(ApexPages.currentPage().getParameters().get('id')).get(0);
        List<String> cargoSegments = new List<String>{'LDC', 'MDC', 'HDC'};
//        Integer period = Integer.valueOf(ApexPages.currentPage().getParameters().get('period'));
        //if(opportunity.CustomerType__c!='개인사업자'){]
        vehicleStock = PDFCommonController.getVehicleStock(ApexPages.currentPage().getParameters().get('id'));
        Segment = -1;
        if(opportunity != null){
            System.debug(cargoSegments.contains(vehicleStock.Product__r.Segment2__c));
            if(vehicleStock.Product__r.Segment2__c.contains('TRT') || cargoSegments.contains(vehicleStock.Product__r.Segment2__c)){
                String tempReqDateVal = String.valueOf(ApexPages.currentPage().getParameters().get('tempReqDate'));
                tempReqDate = Date.valueOf(tempReqDateVal);
                Integer driveDays = Integer.valueOf(ApexPages.currentPage().getParameters().get('driveDays'));
                CalDate = Date.valueOf(tempReqDateVal).addDays(driveDays-1);
                System.debug(CalDate);

                account = PDFCommonController.getAccounts(opportunity.AccountId).get(0);
                Segment = vehicleStock.Product__r.Segment2__c.contains('TRT') ? 1 : 2;
            }
        }
    }
}