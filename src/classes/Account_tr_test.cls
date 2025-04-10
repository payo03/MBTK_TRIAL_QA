/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-25
 * @description : Account Trigger 테스트 클래스
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-25        San.Kang           Created
**************************************************************/
@IsTest
private class Account_tr_test {

    static final Account account = TestObjectBuilder.createAccountPerson();

    static {
        insert account;
    }

    @IsTest
    static void testBehavior() {

        Test.startTest();
            account.IDNumber__pc = '550123-1231412';
            update account;
        Test.stopTest();
    }

}