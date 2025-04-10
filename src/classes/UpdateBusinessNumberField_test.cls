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
private class UpdateBusinessNumberField_test {

    static Account account;
    static Lead lead;
    static Opportunity oppty;

    static {
        TestObjectBuilder.createObjects();
        account = TestObjectBuilder.accountPerson;
        lead = TestObjectBuilder.lead;
        oppty = TestObjectBuilder.opportunity;
    }

    @IsTest
    static void testBehavior() {
        UpdateBusinessNumberField.getBizNum(account.Id);
        UpdateBusinessNumberField.getBizNum(lead.Id);
        UpdateBusinessNumberField.getBizNum(oppty.Id);

        UpdateBusinessNumberField.updateBizNum(account.Id, '1231231234');
        UpdateBusinessNumberField.updateBizNum(lead.Id, '1231231234');
        UpdateBusinessNumberField.updateBizNum(oppty.Id, '1231231234');
    }
}