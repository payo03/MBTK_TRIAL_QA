/**
* @Author            : payo03@solomontech.net
* @Description 		 :
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-26      payo03@solomontech.net           Created
*/
@IsTest
private class HandoverDateAllocationHistory_tr_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder.createObjects();

        Database.executeBatch(new CustomCalendar_ba(-1), 100);
        Database.executeBatch(new CustomCalendar_ba(0), 100);
    }

    @IsTest
    static void testBehavior() {
        Test.startTest();

        List<CustomCalendar__c> calendarList = [
                SELECT Id
                FROM CustomCalendar__c
                LIMIT 10
        ];
        List<Opportunity> opptyList = [
                SELECT Id
                FROM Opportunity
        ];
        List<VehicleStock__c> stockList = [
                SELECT Id
                FROM VehicleStock__c
        ];

        List<HandoverDateAllocationHistory__c> historyList = new List<HandoverDateAllocationHistory__c>();
        for(CustomCalendar__c calendar : calendarList) {
            HandoverDateAllocationHistory__c history = new HandoverDateAllocationHistory__c();

            if(opptyList.isEmpty()) break;
            if(stockList.isEmpty()) break;

            history.CustomCalendar__c = calendar.Id;
            history.IsAssign__c = true;
            history.Opportunity__c = opptyList.remove(0).Id;
            history.VehicleStock__c = stockList.remove(0).Id;

            historyList.add(history);
        }
        insert historyList;

        Test.stopTest();
    }
}