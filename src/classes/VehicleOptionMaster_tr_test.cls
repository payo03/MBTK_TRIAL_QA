/*************************************************************
 * @author : th.kim
 * @description : 
 * @target : 
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-26      th.kim          Created
**************************************************************/
@IsTest
private class VehicleOptionMaster_tr_test {

    @IsTest
    static void doTest() {
        Test.startTest();
        VehicleOptionMaster__c option = TestObjectBuilder.createOption();
        option.Division__c = '필수 옵션';
        insert option;
        update option;
        Test.stopTest();
    }
}