/*************************************************************
 * @author : th.kim
 * @description : 
 * @target : 
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-26      th.kim          Created
**************************************************************/
@IsTest
private class IncentiveCalculationController_test {

    @TestSetup
    static void setup() {
        insert TestObjectBuilder2.createIncentiveTargetMaster();
        TestObjectBuilder2.createOpportunityBundle();

        Database.executeBatch(new AnnualIncentiveCalculation_ba(Date.today()));
    }

    @IsTest
    static void doTest() {
        Test.startTest();

        Opportunity opportunity = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
        List<IncentiveTargetMaster__c> incentiveTargetMasterList = [
                SELECT Id, MinSalesTarget__c, Year__c, TargetType__c, Quarter__c
                FROM IncentiveTargetMaster__c
        ];

        System.debug('TEST : ' + opportunity.OwnerId + ' / ' + opportunity.Id);
        Map<Id, Set<Id>> ownerOpportunityCountMap = new Map<Id, Set<Id>>{
            opportunity.OwnerId => new Set<Id>{opportunity.Id}
        };
        IncentiveCalculationController.execute(ownerOpportunityCountMap, incentiveTargetMasterList);
        Test.stopTest();
    }
}