/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-07
 * @description : 첨단안전장치 설치 확인서 PDF
 * @target :
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-07        San.Kang           Created
**************************************************************/
public class TransCertController {
    public VehicleStock__c vehicleStock{get; private set;}
    public Opportunity opportunity{get; set;}
    public Account account{get; set;}
    public String Address{get; set;}
    public String Name{get; set;}
    public String expect{get; set;}
    public String docImage1{get; set;}
    public String printSegment{get; set;}
    public Boolean isNewAddress{get; set;}
    public ApexPages.StandardController ctrl;
    public String typeDate{get; private set;}     //형식승인일자
    public String sHorsePower{get; private set;}  //출력
    public String sInvoiceDate{get; private set;} //세금계산서발행일자
    Map<String, String> egMap;
    public Integer year{get; set;}

    public TransCertController(){}
    public TransCertController(ApexPages.StandardController controller){
    }

    public void init() {

        opportunity = PDFCommonController.getOpportunity(ApexPages.currentPage().getParameters().get('Id')).get(0);
        docImage1 = PDFCommonController.getDocumentId('MAN_Truck_Bus_Korea_LOGO');

        egMap = new Map<String, String>();
        sInvoiceDate = '     년           월          일';

        if (opportunity != null && opportunity.VehicleStock__c != null) {
            vehicleStock = PDFCommonController.getVehicleStock(opportunity.VehicleStock__c);
        }

        if (vehicleStock != null && vehicleStock.Product__r != null) {
            printSegment = vehicleStock.Product__r.Segment2__c;
        }

        if (opportunity != null) {
            String accountId = opportunity.TransferAccount__c != null ? opportunity.TransferAccount__c : opportunity.AccountId;
            if (accountId != null) {
                account = PDFCommonController.getAccounts(accountId).get(0);
            }

            expect = (opportunity.HandoverDate__c != null && opportunity.HandoverDate__c > System.today()) ? '(예정)' : '';
            sHorsePower = '';

            if (vehicleStock != null &&
                    vehicleStock.HorsePower__c != null &&
                    vehicleStock.EmissionLevelEu__c != null) {

                egMap.put('EURO6/640', '1,800/15,200');
                egMap.put('EURO6/560', '1,800/15,256');
                egMap.put('EURO6/520', '1,800/15,200');
                egMap.put('EURO6/480', '1,800/12,419');
                egMap.put('EURO6/440', '1,800/12,419');
                egMap.put('EURO6/400', '1,800/12,419');
                egMap.put('EURO6/340', '2,300/6,871');
                egMap.put('EURO6/290', '2,300/6,871');
                egMap.put('EURO6/250', '2,300/6,871');
                egMap.put('EURO6/341', '2,300/6,871');

                String key = vehicleStock.EmissionLevelEu__c + '/' + vehicleStock.HorsePower__c;
                String inf = egMap.get(key);

                if (inf != null && inf != '') {
                    sHorsePower = vehicleStock.HorsePower__c + ' ps / ' + inf.split('/')[0] + ' rpm';
                }
            }

            if (vehicleStock != null && vehicleStock.Name != null && vehicleStock.Name.length() > 9) {
                year = vehicleStock.Name.charAt(9);
            } else {
                year = 0;
            }
        } else {
            expect = '(예정)';
        }

        if (opportunity != null && opportunity.HandoverDate__c != null) {
            isNewAddress = PDFCommonController.isNewAddress(opportunity.HandoverDate__c);
            typeDate = opportunity.HandoverDate__c.year() + '년  ' +
                    opportunity.HandoverDate__c.month() + '월  ' +
                    opportunity.HandoverDate__c.day() + '일';
        } else {
            isNewAddress = false;
            typeDate = '';
        }
    }
}