/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2024-12-17      jh.jung           Created
*/
public with sharing class UpdateRoadAddressField {

    @AuraEnabled
    public static Boolean updateRoadAddress(Id recordId, String roadValue, String detailValue, String postalCode) {

        System.debug('updateRoadAddress ::: ');

        // objectType ::: Account, Contact, Lead
        String objectType = recordId.getSobjectType().getDescribe().getName();
        Savepoint sp = Database.setSavepoint();

        try {
            switch on objectType {
                when 'Account' {
                    Account accountRecord = [SELECT Id, RoadAddress__c, DetailAddress__c, PostalCode__c, IsPersonAccount FROM Account WHERE Id = :recordId LIMIT 1];
                    accountRecord.RoadAddress__c = roadValue;
                    accountRecord.DetailAddress__c = detailValue;
                    accountRecord.PostalCode__c = postalCode;
                    if(accountRecord.IsPersonAccount) {
                        accountRecord.RoadAddress__pc = roadValue;
                        accountRecord.DetailAddress__pc = detailValue;
                        accountRecord.PostalCode__pc = postalCode;
                    }
                    update accountRecord;
//                    CommonUtilController.applyObject(new List<Account> {accountRecord}, 'UPDATE');
                }
                when 'Contact' {
                    Contact contactRecord = [SELECT Id, RoadAddress__c, DetailAddress__c, PostalCode__c FROM Contact WHERE Id = :recordId LIMIT 1];
                    contactRecord.RoadAddress__c = roadValue;
                    contactRecord.DetailAddress__c = detailValue;
                    contactRecord.PostalCode__c = postalCode;
                    update contactRecord;
//                    CommonUtilController.applyObject(new List<Contact> {contactRecord}, 'UPDATE');
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
            System.debug('e.getMessage() :::' + e.getMessage());
            System.debug('e.getStackTraceString() :::' + e.getStackTraceString());
            Database.rollback(sp);
        }

        return false;
    }
    @AuraEnabled
    public static Boolean updateRealDriverRoadAddress(Id recordId, String realDriverRoadAddress, String realDriverName, String realDriverMobile, String realDriverIDNumber) {

        System.debug('updateRealDriverRoadAddress ::: ');

        // objectType ::: Account, Contact
        String objectType = recordId.getSobjectType().getDescribe().getName();
        Savepoint sp = Database.setSavepoint();

        try {
            switch on objectType {
                when 'Account' {
                    Account accountRecord = [
                            SELECT Id, IsPersonAccount, RealDriver__pc, RealDriverAddress__pc, RealDriverMobile__pc, RealDriverIDNumber__pc
                            FROM Account
                            WHERE Id = :recordId
                            LIMIT 1
                    ];
                    // 개인 계정 : __pc 수정 -> contact에도 자동 반영
                    if (accountRecord.IsPersonAccount) {
                        accountRecord.RealDriver__pc            = realDriverName;
                        accountRecord.RealDriverAddress__pc     = realDriverRoadAddress;
                        accountRecord.RealDriverMobile__pc      = realDriverMobile;
                        accountRecord.RealDriverIDNumber__pc    = realDriverIDNumber;
                        update accountRecord;
//                        CommonUtilController.applyObject(new List<Account> {accountRecord}, 'UPDATE');
                    }
                    // 법인 계정 : contact을 직접 생성
                    else {
                        Contact contact = new Contact();
                        contact.LastName        = realDriverName;
                        contact.RoadAddress__c  = realDriverRoadAddress;
                        contact.MobilePhone     = realDriverMobile;
                        contact.IDNumber__c     = realDriverIDNumber;
                        contact.AccountId       = recordId;
                        insert contact;
//                        CommonUtilController.applyObject(new List<Contact> {contact}, 'INSERT');
                    }
                }
                when 'Contact' {
                    Contact contactRecord = [
                            SELECT Id, Name, RoadAddress__c, MobilePhone, IDNumber__c
//                                    RealDriver__c, RealDriverAddress__c, RealDriverMobile__c, RealDriverIDNumber__c
                            FROM Contact
                            WHERE Id = :recordId
                            LIMIT 1
                    ];
                    contactRecord.LastName          = realDriverName;
                    contactRecord.RoadAddress__c    = realDriverRoadAddress;
                    contactRecord.MobilePhone       = realDriverMobile;
                    contactRecord.IDNumber__c       = realDriverIDNumber;
//                    contactRecord.RealDriver__c = realDriverName;
//                    contactRecord.RealDriverAddress__c = realDriverRoadAddress;
//                    contactRecord.RealDriverMobile__c = realDriverMobile;
//                    contactRecord.RealDriverIDNumber__c = realDriverIDNumber;
                    update contactRecord;
//                    CommonUtilController.applyObject(new List<Contact> {contactRecord}, 'UPDATE');
                }
                when else {
                    return false;
                }
            }

            return true;

        } catch (Exception e) {
            System.debug('e.getMessage() :::' + e.getMessage());
            System.debug('e.getStackTraceString() :::' + e.getStackTraceString());
            Database.rollback(sp);
        }

        return false;
    }

    @AuraEnabled
    public static Map<String, String> getRealDriverInfo(Id recordId) {
        System.debug('getRealDriverInfo ::: ');

        Map<String, String> resultMap = new Map<String, String>();
        String objectType = recordId.getSobjectType().getDescribe().getName();
        if(objectType.equals('Account')) {
            Account accountRecord = [SELECT Id, RealDriver__pc, RealDriverAddress__pc, RealDriverMobile__pc, RealDriverIDNumber__pc FROM Account WHERE Id = :recordId LIMIT 1];
            resultMap.put('RealDriver', accountRecord.RealDriver__pc);
            resultMap.put('RealDriverAddress', accountRecord.RealDriverAddress__pc);
            resultMap.put('RealDriverMobile', accountRecord.RealDriverMobile__pc);
            resultMap.put('RealDriverIDNumber', accountRecord.RealDriverIDNumber__pc);
        } else if(objectType.equals('Contact')) {
            Contact contactRecord = [SELECT Id, RealDriver__c, RealDriverAddress__c, RealDriverMobile__c, RealDriverIDNumber__c FROM Contact WHERE Id = :recordId LIMIT 1];
            resultMap.put('RealDriver', contactRecord.RealDriver__c);
            resultMap.put('RealDriverAddress', contactRecord.RealDriverAddress__c);
            resultMap.put('RealDriverMobile', contactRecord.RealDriverMobile__c);
            resultMap.put('RealDriverIDNumber', contactRecord.RealDriverIDNumber__c);
        } else {
            return null;
        }
        return resultMap;
    }

}