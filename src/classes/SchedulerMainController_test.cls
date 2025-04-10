/*************************************************************
 * @author : th.kim
 * @date : 2025-02-20
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-02-20      th.kim          Created
**************************************************************/
@IsTest
private class SchedulerMainController_test {

    static {
        insert TestObjectBuilder.createHandover();
    }

    @IsTest
    static void testGetInit() {
        Test.startTest();
        SchedulerMainController.getInit();
        Test.stopTest();
    }
}