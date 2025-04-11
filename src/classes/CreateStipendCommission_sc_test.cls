/*************************************************************
 * @author : th.kim
 * @description : 
 * @target : 
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-04-01      th.kim          Created
**************************************************************/
@IsTest
private class CreateStipendCommission_sc_test {

    @IsTest
    static void doTest() {
        Test.startTest();
        String cron = '0 0 1 1 * ? *';
        System.schedule('Create Stipend Commission Test', cron, new CreateStipendCommission_sc());
        Test.stopTest();
    }
}