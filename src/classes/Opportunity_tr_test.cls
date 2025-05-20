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
        insert TestObjectBuilder2.createApprovalHierarchyPaymentDeferred();
        TestObjectBuilder2.createUser();
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
                SELECT Id, VATDefermentStatus__c, OwnerId, PaymentDefermentStatus__c, AccountId, Account.LastName, Account.PersonMobilePhone, PaymentDeferredApprover1__c, PaymentDeferredApprover2__c, PaymentDeferredApprover3__c
                FROM Opportunity
        ];

        List<VehicleStock__c> stockList = [SELECT Id,LongTermStock__c,IsSpecial__c,IsOptionDiscount__c FROM VehicleStock__c];

        // Oppty Owner와 다른 User가 Owner여야 차량배정 Noti가 발송됨
        User diffUser = [SELECT Id FROM User WHERE Id !=:opportunities[0].OwnerId AND IsActive = TRUE LIMIT 1];
        System.runAs(diffUser){
            Quote quote = new Quote(
                    VehicleStock__c = stockList[0].Id,
                    OpportunityId = opportunities[0].Id
            );

            insert quote;
        }

        for(Opportunity opportunity : opportunities) {
            customerConsent.Opportunity__c = opportunity.Id;
            opportunity.VATDefermentStatus__c = '승인됨';
            // opportunity.PaymentDefermentStatus__c = '반려됨';

            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();

            request.setObjectId(opportunity.Id);
            request.setSubmitterId(UserInfo.getUserId());
            request.setProcessDefinitionNameOrId('PaymentDeferred');
//            request.setProcessDefinitionNameOrId('VATDeferred');  // 송찬영. 수정하시오
            request.setComments('test');

            Approval.ProcessResult submitResult = Approval.process(request);
            opportunity.VehicleStock__c = null;
            opportunity.PaymentDeferredApprover1__c = UserInfo.getUserId();
            opportunity.PaymentDeferredApprover2__c = UserInfo.getUserId();
            opportunity.PaymentDeferredApprover3__c = UserInfo.getUserId();

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
            opportunity.PaymentStatus__c = 'COMPLETE';
        }

        update opportunities;
        Test.stopTest();
    }
}