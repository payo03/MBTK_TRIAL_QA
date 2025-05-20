/*************************************************************
 * @author : San.Kang
 * @date : 25. 5. 2.
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       25. 5. 2.        San.Kang           Created
**************************************************************/
@IsTest
public with sharing class ConnectionToProductController_test {

    static {
        Product2 product = TestObjectBuilder.createProduct();
        SpecTypeNo__c specTypeNo = TestObjectBuilder.createSpecTypeNo();

        if(product != null) insert product;
        if(specTypeNo != null) insert specTypeNo;
    }

    @IsTest
    static void testGetFilteredProductList() {

        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        List<String> productIdList = new List<String>();
        productIdList.add(product.Id);
        SpecTypeNo__c specTypeNoJunction = [SELECT Id FROM SpecTypeNo__c LIMIT 1];
        Test.startTest();

        ConnectionToProductController.getInitData();
        ConnectionToProductController.doSearchProduct(new Map<String,String>{'Name' => 'TGS'});
        ConnectionToProductController.doProductSave(productIdList, specTypeNoJunction.Id);

        Test.stopTest();
    }
}