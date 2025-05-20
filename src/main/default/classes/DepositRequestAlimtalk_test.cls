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
public with sharing class DepositRequestAlimtalk_test {

    static {

//        Account account = TestObjectBuilder.createAccountPerson();
        VirtualAccount__c virtualAccount = TestObjectBuilder.createVirtualAccount();

//        if(account != null) insert account;
        if(virtualAccount != null) insert virtualAccount;
    }

    @IsTest
    static void testBehavior() {
        List<String> accountIdList = new List<String>();
        List<VirtualAccount__c> virtualAccounts = [SELECT Id FROM VirtualAccount__c];
        System.debug('virtualAccounts' + virtualAccounts);
        List<Account> accounts = [SELECT Id FROM Account];
        for(Account account : accounts){
            accountIdList.add(account.Id);
        }

        Test.startTest();
        DepositRequestAlimtalk.PreAssignRequestAlimtalk(accountIdList);
        Test.stopTest();
    }
}