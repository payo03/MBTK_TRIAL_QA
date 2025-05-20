/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-01-21      jh.jung           Created
*/
@IsTest
private class UpdateRoadAddressField_test {

    static Account accountCompany;
    static Account accountPerson;
    static Contact contact;
    static Lead lead;
    static Opportunity oppty;

    static {
//        TestObjectBuilder.createObjects();
        TestObjectBuilder2.createAccountBundle();
        TestObjectBuilder2.createLeadBundle();
        TestObjectBuilder2.createOpportunityBundle();
        accountPerson = TestObjectBuilder2.createAccountPerson();
        lead = TestObjectBuilder2.createLead();
        oppty = TestObjectBuilder2.createOpportunity();
    }

    @IsTest
    static void testBehavior() {
        UpdateRoadAddressField.updateRoadAddress(accountPerson.Id, 'roadValue', 'detailValue', 'postalCode');
        UpdateRoadAddressField.updateRoadAddress(lead.Id, 'roadValue', 'detailValue', 'postalCode');
        UpdateRoadAddressField.updateRoadAddress(oppty.Id, 'roadValue', 'detailValue', 'postalCode');

        UpdateRoadAddressField.updateRealDriverRoadAddress(oppty.Id, 'realDriverName', '01012341234', '123412-1234123');
    }

}