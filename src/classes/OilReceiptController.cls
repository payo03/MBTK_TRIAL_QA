/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-11
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-11        San.Kang           Created
**************************************************************/
public without sharing class OilReceiptController {
    public VehicleStock__c vehicleStock{

        get{
            if(vehicleStock == null){
                vehicleStock = PDFCommonController.getVehicleStock(paramId);
            }
            return vehicleStock;
        }
        private set;
    }

    public String paramId{

        get{
            return ApexPages.currentPage().getParameters().get('id');
        }
        private set;
    }
    public Opportunity opportunity{

        get{
            return PDFCommonController.getOpportunity(vehicleStock.Id).get(0);
        }
        private set;
    }

    public Decimal TotalOilCouponAmt{

        get{
            Decimal totalOilCouponAmt = 0;
            if(opportunity.Contract.Quote__c != null){
                List<QuoteDetail__c> quoteDetails = getQuoteDetail(opportunity.Contract.Quote__c);
                if(!quoteDetails.isEmpty()){
                    for(QuoteDetail__c quoteDetail : quoteDetails){
                        Decimal oilAmt = quoteDetail.OilCouponCount__c > 0 ? quoteDetail.OilCouponCount__c * 100000 : 0;
                        totalOilCouponAmt = totalOilCouponAmt + oilAmt;
                    }
                }
            }
            return totalOilCouponAmt;
        }
        private set;
    }

    public Signature__c signature{

        get{
            if(signature == null){
                List<Signature__c> signatures = [SELECT Url__c FROM Signature__c WHERE VehicleStock__c=:vehicleStock.Id AND SignType__c = '차량관리-주유상품권서명' LIMIT 1];
                System.debug(signatures);
                if(!signatures.isEmpty()) signature = signatures[0];
            }
            return signature;
        }
        private set;
    }

    public static List<QuoteDetail__c> getQuoteDetail(String quoteId){

        String obj_fields = getField(Schema.SObjectType.QuoteDetail__c.fields.getMap());
        String selectFields = obj_fields + ' ,CampaignMaster__r.Name ';
        String whereConditions = ' Quote__c = \'' + quoteId + '\'';
        String query = CommonUtilController.buildQuery(selectFields, 'QuoteDetail__c', whereConditions);

        return Database.query(query);
    }

    public static String getField(Map<String, Schema.SObjectField> ObjMap){

        List<String> accessibleFields = new List<String>();

        for (String fieldName : ObjMap.keySet()) {
            Schema.DescribeFieldResult fieldDesc = ObjMap.get(fieldName).getDescribe();
            // 접근 가능한 필드만 추가
            if (fieldDesc.isAccessible()) {
                accessibleFields.add(fieldName);
            }
        }
        return String.join(accessibleFields, ', ');
    }
}