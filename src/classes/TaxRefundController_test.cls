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
private class TaxRefundController_test {

    static List<Document> document = TestObjectBuilder.createDocument();

    static {
        insert document;
    }

    @IsTest
    static void testBehavior1() {


        Test.setCurrentPage(Page.TankVolumeCert);  // 현재 페이지 컨텍스트 지정

        Test.startTest();

        TaxRefundController taxRefundController = new TaxRefundController();
        taxRefundController.init();

        Test.stopTest();
    }
}