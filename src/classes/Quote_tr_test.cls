/*************************************************************
 * @author : th.kim
 * @date : 2025-01-20
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-20      th.kim          Created
**************************************************************/
@IsTest
private class Quote_tr_test {

    static final Quote quote;
    static final Product2 product;

    static {
        quote = TestObjectBuilder.createQuote();
        product = TestObjectBuilder.createProduct();
    }

    @IsTest
    static void doTest() {

        Test.startTest();

        insert quote;

        Quote publishedQuote = new Quote(
            OpportunityId = quote.OpportunityId,
            Finance__c = quote.Finance__c,
            Product__c = quote.Product__c,
            // IsPublished__c = true
            Status = 'SentOut'
        );
        insert publishedQuote;

        Product2 newProduct = new Product2(
            Name = 'TGL 10.190 4x2 BL CH TN 4850_t',
            Generation__c = 'TG3',
            Quantity__c = 1,
            CarAmt__c = 100000000,
            Segment2__c = 'TPP',
            LocalYear__c = 'LMY25',
            ModelYear__c = '2025',
            EmissionLevel__c = 'A'
        );
        insert newProduct;

        Quote changeProductQuote = new Quote(
            OpportunityId = quote.OpportunityId,
            Finance__c = quote.Finance__c,
            Product__c = newProduct.Id
        );
        insert changeProductQuote;

        publishedQuote.Status = 'Published';
        update publishedQuote;

        Test.stopTest();
    }
}