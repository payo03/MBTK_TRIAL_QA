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
private class TankVolumeCertController_test {

    @TestSetup
    static void setup() {

        Quote Quote = TestObjectBuilder.createQuote();
        List<Document> documentList = TestObjectBuilder.createDocument();
        List<AvisOrderInfo__c> avisOrderInfoList = TestObjectBuilder.createAvisOrderInfoList();

        System.debug([SELECT SpecShort__c, ChassisFrameNo__c FROM AvisOrderInfo__c]);
        System.debug(avisOrderInfoList);

        insert Quote;
        insert documentList;
        if(avisOrderInfoList == null) insert avisOrderInfoList;

    }


    @IsTest
    static void testBehavior() {
        Opportunity opportunity = [SELECT Id, VehicleStock__c FROM Opportunity LIMIT 1];
        Test.setCurrentPage(Page.TankVolumeCert);
        ApexPages.currentPage().getParameters().put('id', opportunity.VehicleStock__c);
        Test.startTest();
        TankVolumeCertController tankVolumeCertController = new TankVolumeCertController();
        tankVolumeCertController.init();
        Test.stopTest();
    }
}