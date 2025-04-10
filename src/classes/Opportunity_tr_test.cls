/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-21      payo03@solomontech.net           Created
*/
@IsTest
private class Opportunity_tr_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createIfBundle();
        TestObjectBuilder2.createConsentBundle();
        TestObjectBuilder2.createStockBundle();
        TestObjectBuilder2.createAccountBundle();
        TestObjectBuilder2.createPaymentBundle();
    }

    @IsTest
    static void testBehavior() {

        Test.startTest();
        CustomerConsent__c customerConsent = [SELECT Id,Lead__c FROM CustomerConsent__c LIMIT 1];
        Lead lead = [SELECT Id, LastName, MobilePhone, Phone FROM Lead WHERE Id =:customerConsent.Lead__c LIMIT 1];
        System.debug('lead::'+lead);

        List<Opportunity> opportunities = [
                SELECT Id, VATDefermentStatus__c, PaymentDefermentStatus__c, AccountId, Account.LastName, Account.PersonMobilePhone
                FROM Opportunity
        ];
        System.debug('opportunities::'+opportunities);
        List<VehicleStock__c> stockList = [SELECT Id FROM VehicleStock__c];

        for(Opportunity opportunity : opportunities) {
            customerConsent.Opportunity__c = opportunity.Id;
            opportunity.VATDefermentStatus__c = '승인됨';
            opportunity.PaymentDefermentStatus__c = '반려됨';

            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();

            request.setObjectId(opportunity.Id);
            request.setSubmitterId(UserInfo.getUserId());
            request.setProcessDefinitionNameOrId('PaymentDeferred');
            request.setComments('test');

            Approval.ProcessResult submitResult = Approval.process(request);
            List<ProcessInstanceWorkitem> workitems = [
                    SELECT Id, ProcessInstance.Status
                    FROM ProcessInstanceWorkitem
                    WHERE ProcessInstance.TargetObjectId = :opportunity.Id
            ];

            for (ProcessInstanceWorkitem workitem : workitems) {
                Approval.ProcessWorkitemRequest workitemRequest = new Approval.ProcessWorkitemRequest();
                workitemRequest.setAction('Approve');
                workitemRequest.setComments('Test');
                workitemRequest.setWorkitemId(workitem.Id);
                Approval.ProcessResult workitemResult = Approval.process(workitemRequest);
            }

            opportunity.VehicleStock__c = null;
        }
        update opportunities;
        update customerConsent;

        for(Opportunity opportunity : opportunities) {
            if(!stockList.isEmpty()) opportunity.VehicleStock__c = stockList.remove(0).Id;
        }
        update opportunities;

        for(Opportunity opportunity : opportunities) {
            opportunity.StageName = 'Quotation';
        }
        update opportunities;

        for(Opportunity opportunity : opportunities) {
            opportunity.IsLockConsent__c = true;
            opportunity.StageName = 'Negotiation';
        }

        update opportunities;
        Test.stopTest();
    }
}