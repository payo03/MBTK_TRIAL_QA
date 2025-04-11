/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-19
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-19        San.Kang           Created
**************************************************************/
public with sharing class CompliancePDFController {
    public VehicleStock__c vehicleStock { get; set; }    // 차량관리
    public Product2 product2 { get; set; }    // 차종관리
    public String TotalWeight { get; set; }
    public String modelTypeName { get; set; }
    public SelfCertWeightLabel__c SWL{get;set;}	// 자기인증/중량 라벨
    public List<SelfCertWeightLabelDtl__c> SWLD{get;set;} // 자기인증/중량 라벨 세부

    public void getInit() {
        String vehicleStockId = ApexPages.currentPage().getParameters().get('id');
        vehicleStock = PDFCommonController.getVehicleStock(vehicleStockId);
        if(vehicleStock.Product__c != null){
            if(vehicleStock.Product__r.SelfCertWeightLabel__c != null){
                SWL = [select id, type__c, TotalWeight__c from SelfCertWeightLabel__c where id =: vehicleStock.Product__r.SelfCertWeightLabel__c];
                TotalWeight = SWL.TotalWeight__c;

                if(!String.isEmpty(vehicleStock.ModelYear__c)){
                    SWLD = [select id, name, TotalWeight__c, Pressure__c, Rim__c, Year__c, Weight__c, Shaft__c, Tire__c, SelfCertWeightLabel__c
                    FROM SelfCertWeightLabelDtl__c WHERE SelfCertWeightLabel__c =: SWL.id and Year__c =: vehicleStock.ModelYear__c order by Shaft__c asc];
                }

                if(SWLD == null || SWLD.isEmpty()){
                    SWLD = [select id, name, TotalWeight__c, Pressure__c, Rim__c, year__c, Weight__c, shaft__c, tire__c, SelfCertWeightLabel__c
                    from SelfCertWeightLabelDtl__c where SelfCertWeightLabel__c =: SWL.id and year__c = null order by Shaft__c asc];
                }

                if(SWLD != null && !SWLD.isEmpty()){
                    for(SelfCertWeightLabelDtl__c dtl : SWLD){ if(!String.isEmpty(dtl.TotalWeight__c)){ TotalWeight = dtl.TotalWeight__c; break; } }
                }
            }
        }

        String modelType = vehicleStock.Product__r.VehicleCategory__r.ModelType__c != null ? vehicleStock.Product__r.VehicleCategory__r.ModelType__c : '';
        if (modelType == 'TGS' || modelType == 'TGL' || modelType == 'TGM') {
            modelTypeName = '화물자동차';
        } else if (modelType == 'TGX') {
            if (vehicleStock.Product__r.VehicleCategory__r.Name.contains('CH')) {
                modelTypeName = '화물자동차';
            } else {
                modelTypeName = '특수자동차';
            }
        } else {
            modelTypeName = '승합자동차';
        }

    }
}