/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2024-12-17      jh.jung           Created
  1.0      2025-04-23      jh.jung           updateRealDriverRoadAddress / 실차주 -> Account 생성으로 변경
*/
public with sharing class UpdateRoadAddressField {

    @AuraEnabled
    public static Boolean updateRoadAddress(Id recordId, String roadValue, String detailValue, String postalCode) {

        System.debug('updateRoadAddress ::: ');

        // objectType ::: Account, Lead
        String objectType = recordId.getSobjectType().getDescribe().getName();

        try {
            switch on objectType {
                when 'Account' {
                    Account accountRecord = [SELECT Id, RoadAddress__c, DetailAddress__c, PostalCode__c, IsPersonAccount FROM Account WHERE Id = :recordId LIMIT 1];
                    accountRecord.RoadAddress__c = roadValue;
                    accountRecord.DetailAddress__c = detailValue;
                    accountRecord.PostalCode__c = postalCode;
                    update accountRecord;
//                    CommonUtilController.applyObject(new List<Account> {accountRecord}, 'UPDATE');
                }
                when 'Lead' {
                    Lead leadRecord = [SELECT Id, RoadAddress__c, DetailAddress__c, PostalCode__c FROM Lead WHERE Id = :recordId LIMIT 1];
                    leadRecord.RoadAddress__c = roadValue;
                    leadRecord.DetailAddress__c = detailValue;
                    leadRecord.PostalCode__c = postalCode;
                    update leadRecord;
//                    CommonUtilController.applyObject(new List<Lead> {leadRecord}, 'UPDATE');
                }
                when else {
                    return false;
                }
            }

            return true;

        } catch (Exception e) {
            System.debug('e.getMessage() :::' + e.getMessage() + '\n' + e.getStackTraceString());
        }

        return false;
    }

    // 사용위치 : Oppty
    // 실차주를 Account로 생성으로 변경하고 Oppty에 룩업 바꿔주기 (4/23)
    @AuraEnabled
//    public static Boolean updateRealDriverRoadAddress(Id recordId, String realDriverRoadAddress, String realDriverName, String realDriverMobile, String realDriverIDNumber) {
    public static Boolean updateRealDriverRoadAddress(Id recordId, String realDriverName, String realDriverMobile, String realDriverIDNumber) {

        System.debug('updateRealDriverRoadAddress ::: ' + recordId);

        // objectType ::: Account, Opportunity
        String objectType = recordId.getSobjectType().getDescribe().getName();

        try {
            switch on objectType {
                when 'Opportunity' {
                    // Account를 만들고 해당 Account를 부모로 가지는 실차주 Account를 생성
                    Account realDriverAccount = new Account();
                    realDriverAccount.LastName = realDriverName;
                    realDriverAccount.PersonMobilePhone = realDriverMobile;
                    realDriverAccount.IDNumber__pc = realDriverIDNumber;
                    realDriverAccount.AccountType__c = '실차주';
                    insert realDriverAccount;

                    Opportunity oppty = [
                            SELECT Id, RealDriverAccount__c
                            FROM Opportunity
                            WHERE Id = :recordId
                    ];
                    oppty.RealDriverAccount__c = realDriverAccount.Id;
                    update oppty;
                }
                when else {
                    return false;
                }
            }

            return true;

        } catch (Exception e) {
            System.debug('e.getMessage() :::' + e.getMessage() + '\n' + e.getStackTraceString());
        }

        return false;
    }
}