/**
* @Author            : payo03@solomontech.net
* @Description 		 : User_tr
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-02-06      payo03@solomontech.net           Created
  1.1      2025-03-12      payo03@solomontech.net           User 가상계좌 할당 Trigger제어
*/
public without sharing class User_tr extends TriggerHandler {
    /** TriggerHandler */
    private List<User> newList { get; set; }
    private List<User> oldList { get; set; }
    private Map<Id, User> oldMap { get; set; }
    private Map<Id, User> newMap { get; set; }

    private final static Date EXPIRED_DATE = Date.valueOf('2999-12-31');

    public User_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap = (Map<Id, User>) Trigger.newMap;
        oldMap = (Map<Id, User>) Trigger.oldMap;
    }

    public override void beforeInsert() {

    }

    public override void beforeUpdate() {

    }

    public override void afterInsert() {
        applyRelatedObject(JSON.serialize(newList));
    }

    public override void afterUpdate() {
        doSetDefaultValues();
    }

    // ver1.1 User 가상계좌 할당 Trigger제어
    private void doSetDefaultValues() {
        List<String> idList = new List<String>();
        List<User> userList = new List<User>();

        for (User newUser : newList) {
            User oldUser = oldMap.get(newUser.Id);

            if (newUser.IsActive && !oldUser.IsActive) userList.add(newUser);   // 활성화 Case
            if (!newUser.IsActive && oldUser.IsActive) idList.add(newUser.Id);  // 비활성화 Case
        }

        Set<String> accountSet = new Set<String>();
        for(Account acc : [
                SELECT Id
                FROM Account
                WHERE User__c IN :idList
        ]) {
            accountSet.add(acc.Id);
        }

        if(!userList.isEmpty()) applyRelatedObject(JSON.serialize(userList));   // 활성화 Case
        if(!accountSet.isEmpty()) cleanRelatedObject(accountSet);               // 비활성화 Case
    }

    @Future
    private static void applyRelatedObject(String jsonStr) {
        List<User> userList = (List<User>) JSON.deserialize(jsonStr, List<User>.class);

        // 1. Account Dummy 생성. 이름이 같으면 에러난다!!
        Map<String, Account> accountMap = new Map<String, Account>();
        for(User user : userList) {
            Account account = new Account();
            account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACCOUNT_PERSON').getRecordTypeId();
            account.LastName = 'LICENSE_' + user.LastName;
            account.AccountType__c = '영업인';
            account.User__c = user.Id;

            accountMap.put(account.LastName, account);
        }
        if(!accountMap.isEmpty()) insert accountMap.values();

        // 2. Opportunity Dummy 생성
        Map<String, Opportunity> opportunityMap = new Map<String, Opportunity>();
        Set<String> accountSet = new Set<String>();
        for(String key : accountMap.keySet()) {
            Account acc = accountMap.get(key);
            Opportunity oppty = new Opportunity();

            oppty.Name = acc.LastName;
            oppty.StageName = 'Payment';
            oppty.CloseDate = EXPIRED_DATE;
            oppty.AccountId = acc.Id;

            accountSet.add(acc.Id);
            opportunityMap.put(key, oppty);
        }
        if(!opportunityMap.isEmpty()) insert opportunityMap.values();

        // 3. VirtualAccount Insert
        List<VirtualAccountMaster__c> validVAMList = [
                SELECT Id, Status__c
                FROM VirtualAccountMaster__c
                WHERE Status__c = '사용가능'
                ORDER BY Name DESC
                LIMIT :accountSet.size()
        ];

        Map<String, VirtualAccount__c> vaAccountMap = new Map<String, VirtualAccount__c>();
        List<VirtualAccountMaster__c> updateVAMList = new List<VirtualAccountMaster__c>();
        for(Opportunity oppty : [
                SELECT Id, AccountId, Account.Name
                FROM Opportunity
                WHERE AccountId IN :accountSet
        ]) {
            if(validVAMList.isEmpty()) break;   // 가상계좌 소진시 종료

            VirtualAccountMaster__c vam = validVAMList.remove(0);
            vam.Status__c = '할당중';
            updateVAMList.add(vam);

            Map<String, Object> paramMap = new Map<String, Object>{
                    'opportunity' => oppty,
                    'virtualAccountMasterId' => vam.Id,
                    'depositAmount' => 0,
                    'validDate' => EXPIRED_DATE
            };
            vaAccountMap.put(oppty.Id, CommonUtilCustomController.createVirtualAccount(paramMap));
        }
        if(!vaAccountMap.isEmpty()) insert vaAccountMap.values();
        if(!updateVAMList.isEmpty()) update updateVAMList;

        // 4. Object Update
        // Opportunity - VirtualAccount 매핑
        List<Opportunity> updateList = new List<Opportunity>();
        for(String opptyId : vaAccountMap.keySet()) {
            Opportunity oppty = new Opportunity(Id = opptyId);
            oppty.VirtualAccount__c = vaAccountMap.get(opptyId).Id;

            updateList.add(oppty);
        }
        if(!updateList.isEmpty()) update updateList;
    }

    @Future
    private static void cleanRelatedObject(Set<String> accountSet) {
        List<VirtualAccount__c> vaExpiredList = [
                SELECT Id, ExpireDate__c
                FROM VirtualAccount__c
                WHERE Account__c IN :accountSet
        ];
        for (VirtualAccount__c va : vaExpiredList) {
            va.ExpireDate__c = Date.today();
        }

        List<Opportunity> opportunityList = [SELECT Id FROM Opportunity WHERE AccountId IN :accountSet];
        List<Account> accountList = [SELECT Id FROM Account WHERE Id IN :accountSet];

        if (!vaExpiredList.isEmpty()) update vaExpiredList;
        if (!opportunityList.isEmpty()) delete opportunityList;
        if (!accountList.isEmpty()) delete accountList;
    }
    
    @TestVisible
    private void test(List<User> userList) {
        newList = new List<User>();
        for(User user : userList) {
            user.IsActive = true;
        }
        newList.addAll(userList);

        oldList = new List<User>();
        oldMap = new Map<Id, User>();
        for(User user : userList) {
            User oldInfo = user.clone(false);
            oldInfo.IsActive = false;

            oldList.add(oldInfo);
            oldMap.put(user.Id, oldInfo);
        }

        Set<String> accountSet = new Set<String>();
        for(Account acc : [
                SELECT Id
                FROM Account
                WHERE User__c IN :oldMap.keySet()
        ]) {
            accountSet.add(acc.Id);
        }

        doSetDefaultValues();
        cleanRelatedObject(accountSet);
    }
}