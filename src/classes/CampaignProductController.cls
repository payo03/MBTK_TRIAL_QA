public with sharing class CampaignProductController {


    public class ProductWrap {
        @AuraEnabled public String id;
        @AuraEnabled public String segment;
        @AuraEnabled public String specShort;
        @AuraEnabled public String emissionLevel;
        @AuraEnabled public String modelYear;
        @AuraEnabled public String cabMark;
        @AuraEnabled public String wheelBase;
        // @AuraEnabled public String axleConfiguration;
        @AuraEnabled public String axleConfiguration;
        @AuraEnabled public String horsePower;
        
        public ProductWrap(String id, String segment, String specShort, String emissionLevel, String modelYear, String cabMark, String wheelBase, String axleConfiguration, String horsePower) {
            this.id = id;
            this.segment = segment;
            this.specShort = specShort;
            this.emissionLevel = emissionLevel;
            this.modelYear = modelYear;
            this.cabMark = cabMark;
            this.wheelBase = wheelBase;
            // this.axleConfiguration = axleConfiguration;
            this.axleConfiguration = axleConfiguration;
            this.horsePower = horsePower;
        }
    }

    private static List<ProductWrap> getProductList(String whereConditions) {
        
        List<String> queryList = new List<String>();

        queryList.add('SELECT Id, SpecShort__c, toLabel(WheelBase__c), toLabel(CabMark__c), Segment2__c, Quantity__c, ModelYear__c, toLabel(EmissionLevel__c), VehicleCategory__r.HorsePower__c, VehicleCategory__r.AxleConfiguration__c');
        queryList.add('FROM Product2');
        if(String.isNotBlank(whereConditions)) {
            queryList.add('WHERE ' + whereConditions);
        }

        System.debug('queryList ::: ' +  queryList);

        String query = String.join(queryList, ' ');

        List<Product2> productList = Database.query(query);

        List<ProductWrap> productWrapList = new List<ProductWrap>();
        for(Product2 product : productList) {

            // String axleConfiguration = product.VehicleCategory__r != null ? product.VehicleCategory__r.AxleConfiguration__c : null;
            // String horsePower = product.VehicleCategory__r != null ? product.VehicleCategory__r.HorsePower__c : null;

            ProductWrap productWrap = new ProductWrap(
                product.Id,
                product.Segment2__c,
                product.SpecShort__c,
                product.EmissionLevel__c,
                product.ModelYear__c,
                product.CabMark__c,
                product.WheelBase__c,
                product.VehicleCategory__r != null ? product.VehicleCategory__r.AxleConfiguration__c : null,
                product.VehicleCategory__r != null ? product.VehicleCategory__r.HorsePower__c : null
                // horsePower
                // axleConfiguration
            );
            productWrapList.add(productWrap);
        }
        System.debug('productWrapList ::: ' +  productWrapList);
        return productWrapList;
    }

    @AuraEnabled
    public static Map<String, Object> getInitData() {

        return new Map<String, Object>{
            'pList' => getProductList(''),
            'segment' => CommonUtilController.getPickList('Product2', 'Segment2__c'),
            'axle' => CommonUtilController.getPickList('VehicleCategory__c', 'AxleConfiguration__c')
        };
    }

    @AuraEnabled
    public static List<ProductWrap> getFilteredProductList(Map<String, String> filterMap) {

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
                if (key == 'SpecShort__c') {
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
    public static void saveProductsToCampaign(List<Id> productIds, Id campaignId) {

        System.debug('productIds ::: ' + productIds);

        if (String.isBlank(campaignId)) {
            throw new AuraHandledException('Campaign ID is required.');
        }

        // Map<Id, String> productIdToNameMap = new Map<Id, String>();
        // List<Product2> listProductIds = [SELECT Id, Name FROM Product2 WHERE Id IN :productIds];

        // for (Product2 product : listProductIds) {
        //     productIdToNameMap.put(product.Id, product.Name);
        // }

        List<CampaignJunction__c> campaignProducts = new List<CampaignJunction__c>();
        for (Id productId : productIds) {
            // String productName = productIdToNameMap.get(productId);
            campaignProducts.add(new CampaignJunction__c(
                CampaignMaster__c = campaignId,
                Product__c = productId
                // Name = '연결된 차종 ' + productName
            ));
        }
        System.debug('campaignProducts ::: ' +  campaignProducts);

        insert campaignProducts;
    }



}