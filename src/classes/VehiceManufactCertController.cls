/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-10
 * @description : 제작증 PDF
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-10        San.Kang           Created
**************************************************************/
public with sharing class VehiceManufactCertController {
    public VehicleStock__c vehicleStock { get; private set; }
    public Opportunity opportunity { get; set; }
    public Integer year { get; set; }
    public String Address { get; set; }
    public String rpm { get; set; }
    public String expect { get; set; }
    public String uzIngam { get; set; }
    public Boolean checkMagt { get; set; }
    public Decimal SalePrice { get; set; }
    public Boolean isNewAddress { get; set; }
    public VehiceManufactCertController() {
    }

    public void init() {

        opportunity = PDFCommonController.getOpportunity(ApexPages.currentPage().getParameters().get('id')).get(0);
        vehicleStock = PDFCommonController.getVehicleStock(opportunity.VehicleStock__c);
        expect = '';
        SalePrice = 0;
        isNewAddress = true;
        checkMagt = PDFCommonController.profileCheck('MTBK Internal');
        Quote quote = PDFCommonController.getQuote(opportunity.Contract.Quote__c) != null ?
                PDFCommonController.getQuote(opportunity.Contract.Quote__c) : new Quote();
        if(opportunity.HandoverDate__c != null) isNewAddress = isNewAddress(opportunity.HandoverDate__c);
            ///-----공급가액 계산----
            if (String.isBlank(opportunity.VehicleStock__r.TaxType__c) || opportunity.VehicleStock__r.TaxType__c == 'A') {
                SalePrice = quote.fm_SupplyAmt__c;
            } else if (opportunity.VehicleStock__r.TaxType__c == 'C') {
                SalePrice = opportunity.fm_RealSellAmt__c;
            }

            expect =  opportunity.HandoverDate__c > System.today() ? '(예정)' : '';
            year = opportunity.VehicleStock__r.Name.length() > 9 ? opportunity.VehicleStock__r.Name.charAt(9) : 0;

            uzIngam = PDFCommonController.getDocumentId('man_useingam');
    }

    public static Boolean isNewAddress(Date releaseDate){
        return releaseDate >= Date.newInstance(2017,2,23);
    }
}