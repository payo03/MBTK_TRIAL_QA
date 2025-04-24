/*************************************************************
 * @author : San.Kang
 * @date : 25. 4. 18.
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       25. 4. 18.        San.Kang           Created
**************************************************************/
@IsTest
private class SalesResultReportController_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder.createObjects();
    }

    @IsTest
    static void testBehavior() {
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        ProductOption__c productOption = [SELECT Id, Product__c, VehicleOptionMaster__c, VehicleOptionMaster__r.Division__c FROM ProductOption__c LIMIT 1];

        VehicleOptionMaster__c vehicleOptionMaster = new VehicleOptionMaster__c(
                Name = 'CareFree 5 - TGX 510,470 6X2 (EW-WSC)(RMC)',
                Division__c = '기본제공',
                EwWscPrice__c = 100,
                RmcPrice__c = 100,
                OptionCodeRMC__c = 'ML100'
        );

        insert vehicleOptionMaster;

        ProductOption__c productOption2 = new ProductOption__c(
                Product__c = productOption.Product__c,
                VehicleOptionMaster__c = vehicleOptionMaster.Id
        );

        insert productOption2;

        PageReference pageRef = Page.SalesResultReport;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', opportunity.Id);

        // 3. StandardController 생성자 주입
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);

        Test.startTest();
        SalesResultReportController controller = new SalesResultReportController(sc);
        controller.init();
        Test.stopTest();
    }
}