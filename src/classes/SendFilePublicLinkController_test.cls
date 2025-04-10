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
private class SendFilePublicLinkController_test {
    static Quote quote;

    static {
        TestObjectBuilder.createObjects();
        quote = TestObjectBuilder.quote;
    }

    @isTest
    static void testGetQuote() {
        Test.startTest();
        SendFilePublicLinkController.getQuote(quote.Id);
        Test.stopTest();
    }

    @isTest
    static void testUpdateQuote() {
        Test.startTest();
        SendFilePublicLinkController.updateQuote(quote.Id);
        Test.stopTest();
    }

    @isTest
    static void testCreatePublicLink() {
        Map<String, String> inputMap = new Map<String, String>{
            'recordId' => quote.Id,
            'language' => 'KR',
            'type' => 'send'
        };
    
        Test.startTest();
        SendFilePublicLinkController.createPublicLink(inputMap);
        Test.stopTest();
    }
}