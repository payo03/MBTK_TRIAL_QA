/*************************************************************
 * @author : chaebeom.do
 * @date : 2024-12-17
 * @description :
 * @target :
==============================================================
     * Ver          Date            Author          Modification
 * 1.0          2024-12-17      chaebeom.do     Created
 * 1.1          2025-04-21      chaebeom.do     견적의 단계가 Draft일 때엔 저장된 파일을 지우고 새로 저장하는 로직 추가
 **************************************************************/
public with sharing class SendFilePublicLinkController {
    
    @AuraEnabled
    public static Map<String, String> getQuote(String recordId) {
        Map<String, String> resultMap = new Map<String, String>();
        
        Quote q = [SELECT Id, AccountId, Name, Product__c, Product__r.Name, ConfigurationNo__c, VersionNo__c FROM Quote WHERE Id = :recordId];
        String configNo = q.ConfigurationNo__c < 10 ? '_Q0' + q.ConfigurationNo__c : '_Q' + q.ConfigurationNo__c;
        String verNo = q.VersionNo__c < 10 ? '_V0' + q.VersionNo__c : '_V' + q.VersionNo__c;
        resultMap.put('name', q.Name);
        resultMap.put('acc', q.AccountId);
        return resultMap;
    }
    
    @AuraEnabled
    public static void updateQuote(String recordId) {
        
        Quote q = new Quote();
        
        q.Id = recordId;
        q.Status = 'SentOut';
        
        Quote curQ = [SELECT Id, OpportunityId FROM Quote WHERE Id = :recordId];
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :curQ.OpportunityId];
        if (opp.StageName == 'Quotation') {
            opp.StageName = 'Negotiation';
        }
        
        update q;
        update opp;
    }
    
    /**
     * @author chaebeom.do
     * @description 견적 레코드의 필드를 visualforce로 넘겨 pdf 생성 후 저장, file Public Link 생성
     * @return Map<String, String>
     */
    @AuraEnabled
    public static Map<String, String> createPublicLink(Map<String, String> inputMap) {
        Map<String, String> resultMap = new Map<String, String>();
        
        PageReference quotePdf = Page.QuotePdf;
        quotePdf.getParameters().put('id', inputMap.get('recordId'));
        quotePdf.getParameters().put('language', inputMap.get('language'));
        Blob body;
        if(!Test.isRunningTest()){
            body = quotePdf.getContent();
        }else{
            body = Blob.valueOf('Some Text'); // 테스트 클래스용 더미
        }
        Quote curQuote = [SELECT Id, Name, ConfigurationNo__c, VersionNo__c, Status
            FROM Quote 
            WHERE Id =:inputMap.get('recordId') LIMIT 1];
        String fileName = curQuote.Name + '_' + inputMap.get('language');
        ContentVersion cv2;
        // 현재 버전 견적서가 파일에 있는지 확인
        List<ContentDocumentLink> docLinks = [
            SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.FileExtension 
            FROM ContentDocumentLink 
            WHERE ContentDocument.Title = :fileName
            AND LinkedEntityId = :inputMap.get('recordId')];
        // ver1.1 견적의 단계가 Draft일 때엔 기존 파일 삭제
        Set<Id> contentDocIdsToDelete = new Set<Id>();
        for (ContentDocumentLink link : docLinks) {
            if (link.ContentDocument.LatestPublishedVersion.Title.contains(fileName) &&
                    link.ContentDocument.LatestPublishedVersion.FileExtension == 'pdf') {
                contentDocIdsToDelete.add(link.ContentDocumentId);
            }
        }
        if (!contentDocIdsToDelete.isEmpty() && curQuote.Status == 'Draft') {
            delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocIdsToDelete];
        }
        if(docLinks.isEmpty() || (!contentDocIdsToDelete.isEmpty() && curQuote.Status == 'Draft')) {
            resultMap.put('isNewV', 'yes');
            // 컨텐츠버전 만들기
            ContentVersion cv = new ContentVersion();
            cv.PathOnClient = fileName + '.pdf';
            cv.title  = fileName;
            cv.VersionData = body;
            cv.origin = 'C';
            insert cv;
            
            // 컨텐츠다큐먼트 가져오기
            cv2 = [SELECT Id, Title, ContentDocumentId 
            FROM ContentVersion
            WHERE Id = :cv.Id LIMIT 1];
            
            // 컨텐츠링크 만들기
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = inputMap.get('recordId');
            cdl.ContentDocumentId = cv2.ContentDocumentId;
            cdl.ShareType = 'V';
            insert cdl;
        } else {
            cv2 = [SELECT Id, Title, ContentDocumentId 
            FROM ContentVersion
            WHERE ContentDocumentId = :docLinks[0].ContentDocumentId LIMIT 1];
            resultMap.put('isNewV', 'no');
        }
        resultMap.put('contentDocumentId', cv2.ContentDocumentId);
        if(inputMap.get('type') == 'send') {
            try {
                ContentDistribution cd = new ContentDistribution();
                cd.Name = curQuote.Name + '_발송_'+Date.today().format().replace('/', '-');
                cd.ContentVersionId = cv2.Id;
                cd.PreferencesAllowViewInBrowser = true;
                cd.PreferencesLinkLatestVersion = true;
                cd.PreferencesPasswordRequired = false;
                // 만료기간 설정
                cd.PreferencesExpires = false;
                // cd.ExpiryDate = datetime.now().addMinutes(5);
                // pdf 접속시 알림 설정
                cd.PreferencesNotifyOnVisit = false;
                // cd.OwnerId = ''; // 버튼 클릭시 누른 사람이 디폴트
                
                insert cd;
                
                ContentDistribution cdNew = [SELECT DistributionPublicUrl, ExpiryDate
                                            FROM ContentDistribution
                                            WHERE Id = :cd.Id];
                
                String publicLink = cdNew.DistributionPublicUrl;
                resultMap.put('domain', Label.LightningHost);
                resultMap.put('publicLink', publicLink);
                resultMap.put('fileName', fileName);
                return resultMap;
            } catch (Exception e) {
                System.debug('e.getMessage() :::' + e.getMessage());
                System.debug('e.getStackTraceString() :::' + e.getStackTraceString());
                return null;
            }
        }
        return resultMap;
    }
}