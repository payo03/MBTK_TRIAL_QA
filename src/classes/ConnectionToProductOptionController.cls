public with sharing class ConnectionToProductOptionController {

    public class OptionWrap {
        @AuraEnabled public String id;
        @AuraEnabled public String segment;
        @AuraEnabled public String name;
        @AuraEnabled public String specShort;
        
        public OptionWrap(String id, String segment, String name, String specShort) {
            this.id = id;
            this.segment = segment;
            this.name = name;
            this.specShort = specShort;
        }
    }

    private static List<OptionWrap> getProductList(String whereConditions) {
        
        List<String> queryList = new List<String>();

        queryList.add('SELECT Id, Name, SpecShort__c, Segment2__c ');
        queryList.add('FROM Product2');
        if(String.isNotBlank(whereConditions)) {
            queryList.add('WHERE ' + whereConditions);
        }
        queryList.add(' ORDER BY Name');

        System.debug('queryList ::: ' +  queryList);

        String query = String.join(queryList, ' ');

        List<Product2> productList = Database.query(query);

        List<OptionWrap> OptionWrapList = new List<OptionWrap>();

        for(Product2 product : productList) {

            OptionWrap OptionWrap = new OptionWrap(
                product.Id,
                product.Segment2__c,
                product.Name,
                product.SpecShort__c
            );
            OptionWrapList.add(OptionWrap);
        }
        System.debug('OptionWrapList ::: ' +  OptionWrapList);
        return OptionWrapList;
    }

    @AuraEnabled
    public static Map<String, Object> getInitData() {

        return new Map<String, Object>{
            'pList' => getProductList(''),
            'segment' => CommonUtilController.getPickList('Product2', 'Segment2__c')
        };
    }

    @AuraEnabled
    public static List<OptionWrap> getFilteredProductList(Map<String, String> filterMap) {

        String whereConditions = buildWhereConditions(filterMap);
        System.debug('whereConditions ::: ' +  whereConditions);
        System.debug('whereConditions11 ::: ' +  getProductList(whereConditions));
        return getProductList(whereConditions);
    }

    private static String buildWhereConditions(Map<String, String> filterMap) {

        String whereConditions = '';
        String tempWhere = '';
        Boolean isFirstCondition = true; // 첫 번째 조건인지 여부를 판단

        System.debug('filterMap ::: ' +  filterMap.keySet());

        // 필터 맵 순회
        for (String key : filterMap.keySet()) {
            String value = filterMap.get(key);
            System.debug('value ::: ' +  value);
            if (String.isNotBlank(value)) { // 값이 비어있지 않은 경우만 처리
                if (key == 'Name') {
                    tempWhere += key + ' LIKE \'%' + String.escapeSingleQuotes(value) + '%\'';
                } else {
                    tempWhere += key + ' = \'' + String.escapeSingleQuotes(value) + '\'';
                }

                if (isFirstCondition) {
                    whereConditions += tempWhere;
                    isFirstCondition = false; // 첫 번째 조건 이후부터는 AND/OR 처리
                    tempWhere = '';
                } else {
                    whereConditions += ' AND ' + tempWhere;
                    tempWhere = '';
                }
            }
        }
        return whereConditions; // 완성된 WHERE 절 반환
    }

    @AuraEnabled
    public static void saveProductsToOption(List<Id> productIds, Id optionId) {

        System.debug('productIds ::: ' + productIds);

        if (String.isBlank(optionId)) {
            throw new AuraHandledException('option ID is required.');
        }

        VehicleOptionMaster__c option = [SELECT Id, Name FROM VehicleOptionMaster__c WHERE Id = :optionId];

        List<ProductOption__c> optionProducts = new List<ProductOption__c>();

        for (Id productId : productIds) {
            ProductOption__c product = new ProductOption__c();
            product.VehicleOptionMaster__c = optionId;
            product.Product__c = productId;
            product.Name = option.Name;

            optionProducts.add(product);
        }
        System.debug('optionProducts ::: ' + optionProducts);

        insert optionProducts;
    }
    
}