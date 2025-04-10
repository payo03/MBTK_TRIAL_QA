/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-03-28
 * @description : GoodWillSavingController의 test class
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-28      chaebeom.do     Created
**************************************************************/
@isTest
private class GoodWillSavingController_test {
    static final Opportunity opportunityObj;
    static final User user;

    static {
        TestObjectBuilder.createObjects();
        opportunityObj = TestObjectBuilder.opportunity;
        user = TestObjectBuilder.user;
    }

    @isTest
    static void execute() {
        List<User> salesAgentList = [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'MTBK Agent'
            AND IsActive = true 
            AND (LastName = '테스트용 유저'
            OR LastName = '테스트용 매니저')
        ];
        opportunityObj.OwnerId = salesAgentList[0].Id;
        update opportunityObj;
        Test.startTest();
        Map<Id, Integer> ownerOpportunityCountMap = new Map<Id, Integer>{
            opportunityObj.OwnerId => 1
        };
        GoodWillSavingController.execute(ownerOpportunityCountMap, salesAgentList);
        Test.stopTest();
    }
}