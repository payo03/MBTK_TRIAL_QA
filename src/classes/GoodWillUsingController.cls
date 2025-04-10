/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-03-13
 * @description : 
 * @target : goodWillUsing.js
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-13      chaebeom.do     Created
**************************************************************/
public with sharing class GoodWillUsingController {
    @AuraEnabled
    public static Map<string, Object> init(String userId){
        Map<String, Object> resultMap = new Map<String, Object>();
        List<GoodWillMaster__c> gwList = [
            SELECT Id, ru_TotalGoodWillPoints__c 
            FROM GoodWillMaster__c
            WHERE User__c =: userId
        ];
        List<GoodWillUsing__c> gwUsingList = [
            SELECT Id, GoodWillVIN__c, UsingGoodWill__c, ApprovalStatus__c
            FROM GoodWillUsing__c
            WHERE GoodWillMaster__c = :gwList[0].Id
            ORDER BY CreatedDate DESC
        ];
        resultMap.put('goodWillMaster', gwList);
        resultMap.put('goodWillUsing', gwUsingList);
        return resultMap;
        // return gwList;
    }

    @AuraEnabled
    public static void attachFiles(List<Map<String, String>> fileDetails, String recordId){
        //ContentVersion 생성
        List<ContentVersion> cvList = new List<ContentVersion>();
        for(Map<String, String> fileDetail : fileDetails){
            ContentVersion cv = new ContentVersion();
            cv.PathOnClient = fileDetail.get('name');
            cv.title  = fileDetail.get('name');
            cv.VersionData = EncodingUtil.base64Decode(fileDetail.get('base64'));
            cv.origin = 'C';
            cvList.add(cv);
        }
        insert cvList;
        
        //컨텐츠다큐먼트 가져오기
        List<ContentVersion> cvList2 = [
            SELECT Id, Title, ContentDocumentId 
            FROM ContentVersion
            WHERE Id IN :cvList];

        //컨텐츠링크 생성
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for(ContentVersion cv2 : cvList2){
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = recordId;
            cdl.ContentDocumentId = cv2.ContentDocumentId;
            cdl.ShareType = 'V';
            cdlList.add(cdl);
        }
        insert cdlList;
        createApprovalProcess(recordId);
    }

    //굿윌 사용 생성되면 Approval Process 호출
    private static void createApprovalProcess(String recordId){
        GoodWillUsing__c goodWill = [
            SELECT Description__c
            FROM GoodWillUsing__c 
            WHERE Id =: recordId
        ];
        // Create an approval request for the contract
        Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();
        approvalReq.setComments(goodWill.Description__c);
        approvalReq.setObjectId(recordId);
        // Submit the record to the existing process named GoodWillUsing
        approvalReq.setProcessDefinitionNameOrId('GoodWillUsing');
        // Submit the approval request for the GoodWillUsing__c
        if(!Test.isRunningTest()) Approval.ProcessResult result = Approval.process(approvalReq);
        // System.debug(result);
    }
}