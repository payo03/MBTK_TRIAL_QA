@IsTest
public with sharing class PaymentTrackerAlimTalk_ba_test {


    static final DefermentRequest__c dr = TestObjectBuilder.createStatusDefermentRequest();
    // static final Opportunity opp = TestObjectBuilder.createOpportunityAdvance();
    static final DefermentRequest__c defermentRequest;

    static {
        // insert TestObjectBuilder.createOpportunityAdvance();
        // TestObjectBuilder.createObjects();
        // insert TestObjectBuilder.createStatusDefermentRequest();
        insert dr;
        // insert opp;
        defermentRequest = [
            SELECT Id, name, fm_ExpiredDate__c, Opportunity__r.Account.Owner.Name, DeferredAmount__c, fm_DeferredAmount__c, Opportunity__r.Account.PersonMobilePhone, toLabel(Status__c), Opportunity__c, Opportunity__r.AccountId, Opportunity__r.VirtualAccount__c, Opportunity__r.VirtualAccount__r.fm_VirtualAccount__c
            FROM DefermentRequest__c
            WHERE Id = :dr.Id
        ];
    }

    @IsTest
    static void test(){

        System.debug('defermentRequest ::: ' + defermentRequest);

        Test.startTest();

        Database.executeBatch(new PaymentTrackerAlimTalk_ba(), 200);
        Test.stopTest();
    }  

}