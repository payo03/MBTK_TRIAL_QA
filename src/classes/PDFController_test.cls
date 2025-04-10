/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-23
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-23      chaebeom.do     Created
**************************************************************/
@isTest
private class PDFController_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder.createObjects();
    }

    @isTest
    static void doTest() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        ApexPages.currentPage().getParameters().put('Language', 'KR');
        PDFController.getImgList();
        Test.stopTest();
    }
}