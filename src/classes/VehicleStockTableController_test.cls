/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-04
 * @description :
 * @target :
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-14        San.Kang           Created
**************************************************************/

@IsTest
private class VehicleStockTableController_test {

    static final User user = TestObjectBuilder.createUser();
    static final VehicleStock__c vehicleStock = TestObjectBuilder.createVehicleStock();
    static final Product2 product = TestObjectBuilder.createProduct();
    static final VehicleCategory__c vehicleCategory = TestObjectBuilder.createVehicleCategory();


    static {
        insert vehicleStock;
    }

    @IsTest
    static void testBehavior() {
        Map<String,Object> filterMap = new Map<String,Object>{
            'AxleConfiguration__c' => '',
            'HorsePower__c'=> '',
            'Segment2__c' => 'TPP',
            'Styling__c'=> '',
            'Wheelbase__c'=> ''
        };
        vehicleCategory.Name = 'TGL 10.190 4x2 BL CH TN 4850';
        update vehicleCategory;
        System.debug('vehicleCategory::'+vehicleCategory);
        Map<String, String> stringMap = new Map<String, String>();
        for (String key : filterMap.keySet()) {
            Object value = filterMap.get(key);
            stringMap.put(key, value != null ? String.valueOf(value) : null);
        }

        List<String> vehiclestockIds = new List<String>{ vehicleStock.Id };

        String whereConditions = ' Product__r.Segment2__c =\'TPP\' ';
        String categorykey = 'TGL 10.190 4x2 BL CH TN 4850,null';

        Test.startTest();

        VehicleStockTableController.getInitData(vehicleStock.Id);
        VehicleStockTableController.getProductWrap(categorykey,'sa');
        VehicleStockTableController.getProductWrap(categorykey,'admin');
        VehicleStockTableController.getFilteredCategoryList(stringMap);
        VehicleStockTableController.updateStockShow(vehiclestockIds,true);
        VehicleStockTableController.updateStockShow(vehiclestockIds,false);
        VehicleStockTableController.checkSAPermissionSet();
        Test.stopTest();
    }

}