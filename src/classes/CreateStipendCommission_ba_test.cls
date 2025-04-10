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
private class CreateStipendCommission_ba_test {

    @IsTest
    static void doTest() {
        Database.executeBatch(new CreateStipendCommission_ba());
    }
}