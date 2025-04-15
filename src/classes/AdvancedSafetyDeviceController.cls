/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-12
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-12        San.Kang           Created
**************************************************************/
public with sharing class AdvancedSafetyDeviceController {
    public Boolean checkTractor { get; set; }
    public Boolean checkCargo { get; set; }
    public VehicleStock__c vehicleStock { get; set; }
    public Opportunity opportunity { get; set; }
    public Integer year { get; set; }
    public String docImage1{get; set;}
    public String carName{get; set;}

    public void init() {

        List<String> tractorList = new List<String>{
                'SAFETY PACKAGE PLUS TRACTOR'
        };
        List<String> cargoList = new List<String>{
                'SAFETY PACKAGE CARGO', 'SAFETY PACKAGE TIPPER'
        };
        List<String> dumpList = new List<String>{
                'TGS_41.510_8X4_BB', 'TGS_41.470_8X4_BB', 'TGS_41.510_8x4_BB_CH', 'TGS_41.470_8x4_BB_CH', 'TGS_41.480_8x4_BB_CH', 'TGS_41.520_8x4_BB_CH'
        };
        String vehicleStockId = ApexPages.currentPage().getParameters().get('id');
        vehicleStock = PDFCommonController.getVehicleStock(vehicleStockId);
        opportunity = PDFCommonController.getOpportunity(vehicleStockId).get(0);
        carName = vehicleStock.SpecShort__c != null && vehicleStock.SpecShort__c.length() >= 3 ? vehicleStock.SpecShort__c.substring(0, 3) : '';
        docImage1 = PDFCommonController.getDocumentId('MAN_Truck_Bus_Korea_LOGO');
        String description = (vehicleStock != null && vehicleStock.Safety_Package_Description__c != null) ? vehicleStock.Safety_Package_Description__c : '';
        checkTractor = (tractorList != null) ? tractorList.contains(description.toUpperCase()) : false;
        checkCargo = (cargoList != null) ? cargoList.contains(description.toUpperCase()) : false;
    }
}