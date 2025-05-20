/*************************************************************
 * @author : San.Kang
 * @date : 25. 4. 30.
 * @description : 제원관리번호 정션 Product 연결
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       25. 4. 30.        San.Kang           Created
**************************************************************/
public without sharing class ConnectionToProductController {

    /**
     * Product Wrapper
     */
    public class ProductWrap {
        @AuraEnabled public String id; // product id
        @AuraEnabled public String segment; // product segment
        @AuraEnabled public String name; // product Name
        @AuraEnabled public String modelYear; // product 차대 각자

        public ProductWrap(String id, String segment, String name,  String modelYear) {
            this.id = id;
            this.segment = segment;
            this.name = name;
            this.modelYear = modelYear;
        }
    }

    /**
     * @author san.kang
     * @description Product 데이터 및 필터 Picklist 가져오기
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> getInitData() {

        return new Map<String, Object>{
                'productList' => getDynamicProduct(null),
                'segment' => CommonUtilController.getPickList('Product2', 'Segment2__c'),
                'modelYear' => getModelYear()
        };
    }

    @AuraEnabled
    public static List<ProductWrap> doSearchProduct(Map<String,Object> filterMap) {
        List<String> conditions = new List<String>();

        for (String key : filterMap.keySet()) {
            Object value = filterMap.get(key);
            if (value != null && String.valueOf(value).trim() != '') {
                String stringValue = String.escapeSingleQuotes(String.valueOf(value));

                if (key == 'Name') {
                    conditions.add(key + ' LIKE \'%' + stringValue + '%\'');
                } else {
                    conditions.add(key + ' = \'' + stringValue + '\'');
                }
            }
        }

        String whereCondition = conditions.size() > 0 ? String.join(conditions, ' AND ') : null;

        return getDynamicProduct(whereCondition);
    }

    /**
     * @author san.kang
     * @param whereConditions
     * @description Product 쿼리 후 래퍼에 담기
     * @return List<ProductWrap>
     */
    public static List<ProductWrap> getDynamicProduct(String whereConditions){

        List<ProductWrap> productWraps = new List<ProductWrap>();
        try{
            String obj_fields  = getField(Schema.SObjectType.Product2.fields.getMap()); // product 전체 필드 가져오기
            String selectFields = obj_fields;
            String query = CommonUtilController.buildQuery(selectFields, 'Product2', whereConditions);

            List<Product2> productList = Database.query(query);
            for(Product2 product : productList){
                ProductWrap productWrap = new ProductWrap(
                        product.Id,
                        product.Segment2__c,
                        product.Name,
                        product.ModelYear__c
                );

                productWraps.add(productWrap);
            }
        } catch (Exception e) {
            System.debug('err => ' + e);
        }

        return productWraps;
    }

    /**
     * @author san.kang
     * @description 제원관리번호 정션 차종 업데이트
     */
    @AuraEnabled
    public static void doProductSave(List<String> productIdList, String recordId){
        try{
            if(recordId != null && !productIdList.isEmpty()){
                List<SpecTypeNoJunction__c> specTypeNoJunctionList = new List<SpecTypeNoJunction__c>();
                for(String productId : productIdList){
                    SpecTypeNoJunction__c specTypeNoJunction = new SpecTypeNoJunction__c(
                            SpecTypeNo__c = recordId,
                            Product__c = productId
                    );

                    specTypeNoJunctionList.add(specTypeNoJunction);
                }

                insert specTypeNoJunctionList;
            }

        } catch (Exception e) {
            System.debug('err => ' + e);
        }
    }

    /**
     * @author san.kang
     * @param ObjMap
     * @description Product ModelYear 그룹핑
     * @return List<Map<String, String>>
     */
    public static List<Map<String, String>> getModelYear(){

        List<Map<String, String>> options = new List<Map<String, String>>();

        try{
            List<AggregateResult> groupedYears = [
                    SELECT ModelYear__c
                    FROM Product2
                    WHERE ModelYear__c != null
                    GROUP BY ModelYear__c
                    ORDER BY ModelYear__c DESC
            ];

            for (AggregateResult ar : groupedYears) {
                String year = (String) ar.get('ModelYear__c');
                options.add(new Map<String, String>{
                        'label' => year,
                        'value' => year
                });
            }

        } catch (Exception e){
            System.debug('err => ' + e);
        }
        return options;
    }

    /**
     * @author san.kang
     * @param ObjMap
     * @description Product 모든 필드 가져오기
     * @return String
     */
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