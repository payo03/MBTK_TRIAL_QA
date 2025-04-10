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
        TestObjectBuilder.createObjects();
        accountCompany = TestObjectBuilder.createAccountCompany();
        accountPerson = TestObjectBuilder.createAccountPerson();
        contact = TestObjectBuilder.createContact();
        lead = TestObjectBuilder.createLead();
        oppty = TestObjectBuilder.createOpportunity();
    }

    @IsTest
    static void testBehavior() {
        UpdateRoadAddressField.updateRoadAddress(accountPerson.Id, 'roadValue', 'detailValue', 'postalCode');
        UpdateRoadAddressField.updateRoadAddress(accountCompany.Id, 'roadValue', 'detailValue', 'postalCode');
        UpdateRoadAddressField.updateRoadAddress(contact.Id, 'roadValue', 'detailValue', 'postalCode');
        UpdateRoadAddressField.updateRoadAddress(lead.Id, 'roadValue', 'detailValue', 'postalCode');
        UpdateRoadAddressField.updateRoadAddress(oppty.Id, 'roadValue', 'detailValue', 'postalCode');

        UpdateRoadAddressField.updateRealDriverRoadAddress(accountPerson.Id, 'realDriverRoadAddress', 'realDriverName', '01012341234', 'realDriverIDNumber');
        UpdateRoadAddressField.updateRealDriverRoadAddress(accountCompany.Id, 'realDriverRoadAddress', 'realDriverName', 'realDriverMobile', 'realDriverIDNumber');
        UpdateRoadAddressField.updateRealDriverRoadAddress(contact.Id, 'realDriverRoadAddress', 'realDriverName', '01012341234', 'realDriverIDNumber');
        UpdateRoadAddressField.updateRealDriverRoadAddress(oppty.Id, 'realDriverRoadAddress', 'realDriverName', '01012341234', 'realDriverIDNumber');

        UpdateRoadAddressField.getRealDriverInfo(accountPerson.Id);
        UpdateRoadAddressField.getRealDriverInfo(contact.Id);
        UpdateRoadAddressField.getRealDriverInfo(oppty.Id);
    }

}