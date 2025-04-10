/*************************************************************
 * @author : th.kim
 * @date : 2025-02-21
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-02-21      th.kim          Created
**************************************************************/
@IsTest
private class Handover_tr_test {

    static final Handover__c handover = TestObjectBuilder.createHandover();

    @IsTest
    static void doTest() {
        Test.startTest();

        insert handover;
        Handover__c newHandover = handover.clone();
        newHandover.IsNeedToCheckUpdate__c = true;
        insert newHandover;
        update newHandover;
        newHandover.IsNeedToCheckUpdate__c = false;
        update newHandover;

        Test.stopTest();
    }
}