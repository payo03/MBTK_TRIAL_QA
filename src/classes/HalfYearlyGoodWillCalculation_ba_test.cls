/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-03-28
 * @description : HalfYearlyGoodWillCalculation_ba의 test class
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-28      chaebeom.do     Created
**************************************************************/
@isTest
private class HalfYearlyGoodWillCalculation_ba_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createGoodWillBundle();
        TestObjectBuilder2.createOpportunityBundle();
    }
    
    @IsTest
    static void doTest() {
        List<User> salesAgentList = [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'MTBK Agent'
            AND IsActive = true 
            AND LastName = '테스트용 유저'
        ];
        Opportunity opportunityObj = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
        opportunityObj.OwnerId = salesAgentList[0].Id;
        update opportunityObj;
        GoodWillMaster__c goodWillMaster = [SELECT Id FROM GoodWillMaster__c LIMIT 1];
        goodWillMaster.User__c = salesAgentList[0].Id;
        update goodWillMaster;

        Test.startTest();
        Database.executeBatch(new HalfYearlyGoodWillCalculation_ba(Date.today()));
        Test.stopTest();
    }
}