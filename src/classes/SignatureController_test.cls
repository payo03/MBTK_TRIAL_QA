/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-28
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-28        San.Kang           Created
**************************************************************/
@IsTest
private class SignatureController_test {

    static final Opportunity opportunity = TestObjectBuilder.createOpportunity();
    static final VehicleStock__c vehicleStock = TestObjectBuilder.createVehicleStock();
    static{
        insert opportunity;
    }
    @IsTest
    static void testBehavior() {
        Test.startTest();
        SignatureController.signSave('',opportunity.VehicleStock__c,'차량관리-주유상품권서명');
        SignatureController.signSave('',opportunity.VehicleStock__c,'차량재고-차량인수서명');
        SignatureController.sObjectQuery(opportunity.VehicleStock__c,'차량재고-차량인수서명');
//        SignatureController.saveImg('/servlet/servlet.FileDownload?file','차량재고-차량인수서명');
        Test.stopTest();
    }
}