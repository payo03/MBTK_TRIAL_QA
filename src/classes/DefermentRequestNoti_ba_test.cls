@IsTest
public with sharing class DefermentRequestNoti_ba_test {

    static final DefermentRequest__c dr = TestObjectBuilder.createStatusDefermentRequest();
    static final DefermentRequest__c defermentRequest;
    
    static {
        insert dr;
        dr.Type__c = '';
        dr.RequestDueDate__c = Date.today().addDays(+3);
        update dr;

        defermentRequest = [
            SELECT Id, RequestDueDate__c, fm_ExpiredDate__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.OwnerId
            FROM DefermentRequest__c
            WHERE Id = :dr.Id
        ];

    }

    @IsTest
    static void test() {
        Test.startTest();
        Database.executeBatch(new DefermentRequestNoti_ba(), 200);
        Test.stopTest();

    }

}