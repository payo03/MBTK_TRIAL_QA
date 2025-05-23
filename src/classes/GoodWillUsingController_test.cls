/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-03-28
 * @description : GoodWillUsingController의 test class
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-28      chaebeom.do     Created
**************************************************************/
@isTest
private class GoodWillUsingController_test {

    @TestSetup
    static void setup() {
        insert TestObjectBuilder2.createApprovalHierarchyGoodwill();
        TestObjectBuilder2.createGoodWillBundle();
    }

    @isTest
    static void testInit() {

        User testUser = [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'MTBK Agent'
            AND IsActive = true 
            AND LastName = '테스트용 유저'
        ];
        
        Test.startTest();
        GoodWillUsingController.init(testUser.Id);
        Test.stopTest();
    }

    @isTest
    static void testAttachFiles() {

        List<Map<String, String>> fileDetails = new List<Map<String, String>>();
        Map<String, String> fileDetail = new Map<String, String>();
        fileDetail.put('name', 'Test');
        fileDetail.put('base64', 'Test FILE');
        fileDetails.add(fileDetail);
        
        User testUser = [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'MTBK Agent'
            AND IsActive = true 
            AND LastName = '테스트용 유저'
        ];
        GoodWillUsing__c goodWillUsing = [
            SELECT Id
            FROM GoodWillUsing__c
            LIMIT 1
        ];
        goodWillUsing.GoodWillApprover__c = testUser.Id;
        update goodWillUsing;

        Test.startTest();
        GoodWillUsingController.attachFiles(fileDetails, goodWillUsing.Id);
        Test.stopTest();
    }
}