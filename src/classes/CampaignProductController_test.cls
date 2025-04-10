/*************************************************************
 * @author : tw.Choi
 * @date : 2025-01-20
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-20      tw.Choi          Created
**************************************************************/

@IsTest
private class CampaignProductController_test {

    static final Product2 product;
    static final VehicleCategory__c vehicleCategory;
    static final CampaignJunction__c campaignJunction;
    static final CampaignMaster__c amtCampaign;

    static {
        TestObjectBuilder.createObjects();
        product = TestObjectBuilder.product;
        vehicleCategory = TestObjectBuilder.vehicleCategory;
        campaignJunction = TestObjectBuilder.campaignJunction;
        amtCampaign = TestObjectBuilder.amtCampaign;
    }

    @IsTest
    static void testGetInit() {

        Test.startTest();

        CampaignProductController.getInitData();

        Test.stopTest();
    }

    @IsTest
    static void testSaveProductsToCampaign() {

        Test.startTest();
        List<Id> listProduct = new List<Id>();
        listProduct.add(product.Id);
        CampaignProductController.saveProductsToCampaign(listProduct, amtCampaign.Id);

        Test.stopTest();
    }

    @IsTest
    static void testGetFilteredProductList() {

        Test.startTest();

        Map<String, String> filterMap = new Map<String, String>{
            'Segment2__c' => 'TGS',
            'SpecShort__c' => 'TGS'
        };

        CampaignProductController.getFilteredProductList(filterMap);

        Test.stopTest();
    }

}