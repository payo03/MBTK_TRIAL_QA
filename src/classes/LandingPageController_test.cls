/*************************************************************
 * @author : San.Kang
 * @date : 2025-01-08
 * @description : LandingPageController 테스트 클래스 완료
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-01-08        San.Kang           Created
**************************************************************/
@IsTest
private class LandingPageController_test {

    static final List<CustomerConsent__c> customerConsents = TestObjectBuilder.createCustomerConsent();
    static final Opportunity opportunity = TestObjectBuilder.createOpportunity();
    static final Lead lead = TestObjectBuilder.createLead();

    static {
        insert customerConsents;
    }

    @IsTest
    public static void test(){
        Test.startTest();
        List<Boolean> LightConsentList = new List<Boolean>{true, true, true, false};
        List<Boolean> fullConsentList = new List<Boolean>{true, true, true, true, true, true, true, true};

        LandingPageController.getConsentType();
        LandingPageController.getCustomerConsent();
        for(CustomerConsent__c customerConsent : customerConsents){
            if(customerConsent.Opportunity__c == null){
                LandingPageController.updateCustomerConsent(customerConsent.Id,LightConsentList);
                LandingPageController.getSubCustomerConsent(customerConsent.Lead__c);
                LandingPageController.resetLeadFields(lead);
            } else {
                LandingPageController.updateCustomerConsent(customerConsent.Id,fullConsentList);
                LandingPageController.getSubCustomerConsent(customerConsent.Opportunity__c);
                LandingPageController.resetOpportunityFields(opportunity);
            }
        }
        LandingPageController.declinedConsent(customerConsents);

        LandingPageController.declinedConsent(customerConsents);

        Test.stopTest();
    }
}