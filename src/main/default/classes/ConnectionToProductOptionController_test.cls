@IsTest
public with sharing class ConnectionToProductOptionController_test {
    
    static final Product2 product;
    static final ProductOption__c productOption;
    static final VehicleOptionMaster__c option;

    static {
        TestObjectBuilder.createObjects();
        product = TestObjectBuilder.product;
        productOption = TestObjectBuilder.productOption;
        option = TestObjectBuilder.option;
    }

    @IsTest
    static void testGetInit() {

        Test.startTest();

        ConnectionToProductOptionController.getInitData();

        Test.stopTest();
    }

    @IsTest
    static void testSaveProductsToOption() {

        Test.startTest();
        List<Id> listProduct = new List<Id>();
        listProduct.add(product.Id);
        ConnectionToProductOptionController.saveProductsToOption(listProduct, option.Id);

        Test.stopTest();
    }

    @IsTest
    static void testGetFilteredProductList() {

        Test.startTest();

        Map<String, String> filterMap = new Map<String, String>{
            'Segment2__c' => 'TGS',
            'SpecShort__c' => 'TGS'
        };

        ConnectionToProductOptionController.getFilteredProductList(filterMap);

        Test.stopTest();
    }

    
}