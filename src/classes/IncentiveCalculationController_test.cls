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

    private static final Opportunity opportunity = TestObjectBuilder.createOpportunity();
    private static final List<IncentiveTargetMaster__c> incentiveTargetMasterList = TestObjectBuilder.createIncentiveTargetMaster();

    static {
        insert opportunity;
        insert incentiveTargetMasterList;
    }

    @IsTest
    static void doTest() {
        Test.startTest();
        Map<Id, Set<Id>> ownerOpportunityCountMap = new Map<Id, Set<Id>>{
            opportunity.OwnerId => new Set<Id>{opportunity.Id}
        };
        IncentiveCalculationController.execute(ownerOpportunityCountMap, incentiveTargetMasterList);
        Test.stopTest();
    }
}