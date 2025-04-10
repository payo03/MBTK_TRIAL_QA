/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-07
 * @description : 안전기준 적합 여부 확인서 PDF
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-07        San.Kang           Created
**************************************************************/
public class CarSafetyStandardsController {

    public String vehicleStockId {get;set;}// 차량관리id
//    public String uzIngam {get;set;}
//    public Boolean check{get;set;}//_Ch 확인
    public VehicleStock__c vehicleStock {get;set;} // 차량관리개체

    public void init(){
        vehicleStockId = ApexPages.currentPage().getParameters().get('id');
        vehicleStock = PDFCommonController.getVehicleStock(vehicleStockId);
//        uzIngam = PDFCommonController.getDocumentId('man_useingam');
    }
}