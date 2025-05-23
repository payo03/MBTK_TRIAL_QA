@IsTest
public with sharing class ConnectionToProductOptionController_test {
    
    // static final Product2 product;
    static final ProductOption__c productOption;
    static final VehicleOptionMaster__c option;

    static {
        // TestObjectBuilder.createObjects();
        // product = TestObjectBuilder.createProduct();
        productOption = TestObjectBuilder.createProductOption();
        option = TestObjectBuilder.createOption();
    }

    @IsTest
    static void testGetInit() {

        Test.startTest();

        ConnectionToProductOptionController.getInitData(option.Id);

        Test.stopTest();
    }

    @IsTest
    static void testSaveProductsToOption() {

        Product2 product = new Product2(
            Name = 'TGS 33.460 8X4-4 BB M 3300 STANDARD',
            Segment2__c = 'TPP',
            SpecShort__c = 'TGS 33.460 8X4-4 BB',
            ISDiscontinued__c = false
        );
        insert product;

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
            'Segment2__c' => 'TPP',
            'Name ' => 'TGS 33.460 8X4-4 BB M 3300 STANDARD',
            'SpecShort__c' => 'TGS 33.460 8X4-4 BB'
        };

        ConnectionToProductOptionController.getFilteredProductList(filterMap);

        Test.stopTest();
    }

    
}