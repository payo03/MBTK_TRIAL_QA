/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-17
 * @description : 차량인수인계서 PDF
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-17        San.Kang           Created
**************************************************************/
public class PdfTakeTruckController {
    public VehicleStock__c vehicleStock{get; set;}
    public Opportunity opportunity{get; set;}
    public String checkDate{get; set;}
    public String productOption{get; set;}
    public String docImage1{get; set;}
    public String selectImage{get; set;}

//    public Boolean noApplyOilReceipt{get; set;}
    public Signature__c sig{get; set;}
//    public Document checkImg{get; set;}

    public PdfTakeTruckController(){}
    public void init(){
        vehicleStock = PDFCommonController.getVehicleStock(ApexPages.currentPage().getParameters().get('id'));
        docImage1 = PDFCommonController.getDocumentId('MAN_Truck_Bus_Korea_LOGO');
        List<Opportunity> opportunities = PDFCommonController.getOpportunity(vehicleStock.Id);
        if(opportunities != null && !opportunities.isEmpty()) {
            opportunity = opportunities[0];

            List<AggregateResult> productOptions = PDFCommonController.getProductOptionCnt(vehicleStock.Product__c);
            List<QuoteDetail__c> quoteDetails = new List<QuoteDetail__c>();
            if(!getQuoteDetail(opportunity.Contract.Quote__c).isEmpty() && opportunity.Contract.Quote__c != null) quoteDetails = getQuoteDetail(opportunity.Contract.Quote__c);
            if(!productOptions.isEmpty()){
                for (AggregateResult ar : productOptions) {
                    productOption += ar.get('Name') + ':' + String.valueOf(ar.get('cnt')) + ', ';
                }
            }
            if(!quoteDetails.isEmpty()){
                for(QuoteDetail__c quoteDetail: quoteDetails){
                    productOption += quoteDetail.CampaignMaster__r.Name == null ? '' :  quoteDetail.CampaignMaster__r.Name + ', ' ;
                }
            }
//            List<selSpec__c> sel = [SELECT Option__r.Name, ItemCount__c FROM selSpec__c WHERE Opportunity__c =:opportunity.Id ORDER BY Option__r.Name];
//            polsel='';
//            String sels='';

//            for(Integer i=0;i<sel.size();i++){
//                sels += (sel[i].Option__r.Name+':' + String.valueOf(sel[i].ItemCount__c));
//                if(i<sel.size()-1)
//                    sels += ', ';
//            }
//            polsel = pols + sels;

            /* List<InstalledParts__c> ba = [SELECT PrintPartName__c FROM InstalledParts__c WHERE Type__c='B' ORDER BY PrintPartName__c];
             basic='';
             for(Integer i=0;i<ba.size();i++){
                 basic += ba[i].PrintPartName__c;
                 if(i<ba.size()-1)
                     basic+= ', ';
             }*/
            if([SELECT COUNT() FROM Signature__c WHERE VehicleStock__c =:vehicleStock.Id AND signType__c = '차량재고-차량인수서명'] > 0)
                sig = [SELECT Url__c FROM Signature__c WHERE VehicleStock__c=:vehicleStock.Id AND signType__c = '차량재고-차량인수서명' LIMIT 1];

            selectImage = (vehicleStock.Product__r.Name.startsWith('TGL_8.190_4X2_') ?
                    PDFCommonController.getDocumentId('VehicleCheckReport_100'): PDFCommonController.getDocumentId('VehicleCheckReport'));
            if(vehicleStock.St6End__c!=null){
                checkDate = String.valueOf(vehicleStock.St6End__c.year())+'. '+String.valueOf(vehicleStock.St6End__c.month())+'. '+String.valueOf(vehicleStock.St6End__c.day());
            }
        }

    }
    public static List<QuoteDetail__c> getQuoteDetail(String quoteId) {
        List<QuoteDetail__c> quoteDetails = new List<QuoteDetail__c>();

        // null-safe 필드 추출
        Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.QuoteDetail__c.fields.getMap();
        List<String> accessibleFields = new List<String>();
        for (String fieldName : fieldsMap.keySet()) {
            Schema.DescribeFieldResult fieldDesc = fieldsMap.get(fieldName).getDescribe();
            if (fieldDesc != null && fieldDesc.isAccessible()) {
                accessibleFields.add(fieldName);
            }
        }

        // 동적 SOQL 작성
        String obj_fields = String.join(accessibleFields, ', ');
        String selectFields = obj_fields + ', CampaignMaster__r.Name';
        String whereConditions = ' Quote__c = \'' + quoteId + '\'';
        String query = CommonUtilController.buildQuery(selectFields, 'QuoteDetail__c', whereConditions);

        try {
            quoteDetails = Database.query(query);
        } catch (Exception e) {
            System.debug('Query Failed: ' + e.getMessage());
            // 필요시 예외 처리 로직 추가
        }
        return quoteDetails;
    }

}