/*************************************************************
 * @author : tw.Choi
 * @date : 2025-01-21
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-21      tw.Choi          Created
**************************************************************/

@isTest
private class OpptyFileUploaderController_test {

    static final Opportunity opportunity;
    static final Opportunity opportunity2;

    static {
//        TestObjectBuilder.createObjects();
//        opportunity = TestObjectBuilder.createOpportunity();
//        opportunity2 = TestObjectBuilder.createOpportunityAdvance();

        TestObjectBuilder2.createOpportunityBundle();

        opportunity = TestObjectBuilder2.createOpportunityAdvance();
    }

    @isTest
    static void testGetInit() {

        Test.startTest();

        String recordId = opportunity.Id;

        OpptyFileUploaderController.getInit(recordId);

        Test.stopTest();
        
    }

    @isTest
    static void testUpdateIsCheck() {

        Test.startTest();

        Map<String, Boolean> fieldUpdates = new Map<String, Boolean>{
            'IsJumin__c' => true,
            'IsBusiness__c' => true,
            'IsVAT__c' => false
        };

        // update opportunity;

        OpptyFileUploaderController.updateIsCheck(opportunity.Id, fieldUpdates);

        Test.stopTest();
        
    }

    @isTest
    static void testDoRollback() {

        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < 2; i++) {
            testOpportunities.add(new Opportunity(Name = 'Test Opp ' + i, StageName = 'Prospecting', CloseDate = Date.today()));
        }
        insert testOpportunities;

        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : testOpportunities) {
            oppIds.add(opp.Id);
        }

        Test.startTest();

        OpptyFileUploaderController.doRollback(oppIds);

        Test.stopTest();
    }

    @isTest
    static void testInitFileList() {

        List<ContentVersion> testContentVersions = new List<ContentVersion>();

        ContentVersion testVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Data'),
            FirstPublishLocationId = UserInfo.getUserId() // 필수 필드
        );
        insert testVersion;

        testContentVersions = [SELECT Id FROM ContentVersion WHERE Id = :testVersion.Id];

        List<Id> cvIds = new List<Id>();
        for (ContentVersion cv : testContentVersions) {
            cvIds.add(cv.Id);
        }

        Test.startTest();

        OpptyFileUploaderController.initFileList(cvIds);

        Test.stopTest();
    }

    @isTest
    static void testUpdateFileName() {

        List<ContentVersion> testContentVersions = new List<ContentVersion>();

        ContentVersion testVersion1 = new ContentVersion(
            Title = 'Test File 1',
            PathOnClient = 'Test1.pdf',
            VersionData = Blob.valueOf('Test Data 1'),
            FirstPublishLocationId = UserInfo.getUserId()
        );
        
        ContentVersion testVersion2 = new ContentVersion(
            Title = 'Test File 2',
            PathOnClient = 'Test2.pdf',
            VersionData = Blob.valueOf('Test Data 2'),
            FirstPublishLocationId = UserInfo.getUserId()
        );

        insert new List<ContentVersion>{testVersion1, testVersion2};

        // 생성된 ContentVersion 조회
        testContentVersions = [SELECT Id, Title FROM ContentVersion WHERE Id IN (:testVersion1.Id, :testVersion2.Id)];

        List<String> fileIds = new List<String>();
        for (ContentVersion cv : testContentVersions) {
            fileIds.add(cv.Id);
        }

        Test.startTest();

        OpptyFileUploaderController.updateFileName(fileIds, '주민등록증', 'Test', 1);

        Test.stopTest();
    }

    @isTest
    static void testGetCheckStatus() {

        Test.startTest();

        OpptyFileUploaderController.getCheckStatus(opportunity.Id);

        Test.stopTest();
    }

    @isTest
    static void testCheckFile() {

        List<ContentVersion> testContentVersions = new List<ContentVersion>();

        ContentVersion testVersion1 = new ContentVersion(
            Title = 'Test File 1',
            PathOnClient = 'Test1.pdf',
            VersionData = Blob.valueOf('Test Data 1'),
            FirstPublishLocationId = opportunity.Id
        );

        ContentVersion testVersion2 = new ContentVersion(
            Title = 'Test File 2',
            PathOnClient = 'Test2.pdf',
            VersionData = Blob.valueOf('Test Data 2'),
            FirstPublishLocationId = opportunity.Id
        );

        insert new List<ContentVersion>{testVersion1, testVersion2};

        List<ContentDocumentLink> existingLinks = [
            SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :opportunity.Id
        ];

        Set<Id> existingDocIds = new Set<Id>();
        for (ContentDocumentLink link : existingLinks) {
            existingDocIds.add(link.ContentDocumentId);
        }

        List<ContentDocument> docs = [
            SELECT Id FROM ContentDocument WHERE Id IN 
            (SELECT ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId = :opportunity.Id)
        ];
        
        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
        for (ContentDocument doc : docs) {
            if (!existingDocIds.contains(doc.Id)) {
                newLinks.add(new ContentDocumentLink(
                    LinkedEntityId = opportunity.Id,
                    ContentDocumentId = doc.Id,
                    ShareType = 'V'
                ));
            }
        }

        if (!newLinks.isEmpty()) {
            insert newLinks;
        }

        testContentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId = :opportunity.Id];

        update new ContentVersion(Id = testContentVersions[0].Id, Type__c = '주민등록증');

        List<Id> cvList = new List<Id>{testContentVersions[0].Id, testContentVersions[1].Id};

        Test.startTest();

        OpptyFileUploaderController.checkFile(opportunity.Id, '사업자등록증', cvList);

        Test.stopTest();
    }

}