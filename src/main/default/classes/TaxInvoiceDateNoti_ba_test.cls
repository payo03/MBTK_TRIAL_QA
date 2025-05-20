/*************************************************************
 * @author : San.Kang
 * @date : 25. 4. 29.
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       25. 4. 29.        San.Kang           Created
**************************************************************/
@IsTest
public with sharing class TaxInvoiceDateNoti_ba_test {

    static final Opportunity opportunity = TestObjectBuilder.createOpportunity();

    static {
        if(opportunity != null) insert opportunity;
        opportunity.TaxInvoiceDate__c = Date.today().addDays(+1);
        update opportunity;
    }

    @IsTest
    static void test() {
        Test.startTest();
        Database.executeBatch(new TaxInvoiceDateNoti_ba(), 200);
        Test.stopTest();
    }
}