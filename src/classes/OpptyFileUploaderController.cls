public with sharing class OpptyFileUploaderController {

    private static String recordId;

    @AuraEnabled
    public static Map<String, Object> getInit(String recordId) {

        OpptyFileUploaderController.recordId = recordId;

        return new Map<String, Object> {
            'userName' => getUserName()
        };
    }

    @AuraEnabled
    public static String getUserName() {

        String accName = [SELECT Id, AccountId, Account.Name FROM Opportunity WHERE Id =: recordId].Account.Name;

        System.debug('accName ::: ' +  accName);

        return accName;
    }

    @AuraEnabled
    public static void updateIsCheck(String opportunityId, Map<String, Boolean> opportunityFieldMap) {
        // Opportunity 레코드 가져오기
        System.debug('updateIsCheck 시작');
        System.debug('key :::' + opportunityFieldMap.keySet());
        Opportunity opp = [SELECT Id, IsJumin__c, IsBusiness__c, IsVAT__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

        for(String key : opportunityFieldMap.keySet()) {
            opp.put(key, opportunityFieldMap.get(key));
        }
        
        update opp;
    }


    @AuraEnabled
    public static String doRollback(List<Id> setSaveId) {

        String strReturn = 'success';
        List<SObject> listSObject = new List<SObject>();
        try {
            for (Id recordId : setSaveId) {
                String objName = recordId.getSobjectType().getDescribe().getName();
                SObject record = Schema.getGlobalDescribe().get(objName).newSObject(recordId);
                listSObject.add(record);
            }

            if (!listSObject.isEmpty()) delete listSObject;
        } catch (Exception e) {
            strReturn = e.getMessage();
        }
        return strReturn;
    }

    @AuraEnabled
    public static List<ContentVersion> initFileList(List<Id> cvList) {
        List<ContentVersion> fileList = new List<ContentVersion>();

        if (!cvList.isEmpty()) {
            fileList = [
                SELECT Id, Title, Type__c, FileType, CreatedBy.Name, ContentDocumentId, ContentSize
                FROM ContentVersion
                WHERE Id IN :cvList
            ];
        }
        System.debug('initFileList ::: ' + fileList);

        return fileList;
    }

    @AuraEnabled
    public static void updateFileName(List<String> fileIds, String sectionName, String username, Integer fileIndex) {

        System.debug('fileIds ::: ' + fileIds);
        System.debug('sectionName ::: ' + sectionName);
        System.debug('username ::: ' + username);

        try {
            List<ContentVersion> cvList = [SELECT Id, Title FROM ContentVersion WHERE Id IN :fileIds];

            System.debug('cvList ::: ' + cvList);

//            Integer index = 1;

            for (ContentVersion cv : cvList) {

                if(sectionName == '주민등록증' || sectionName == '사업자등록증') {
                    cv.Title = sectionName + '_' + username;
                } else {
                    cv.Title = sectionName + fileIndex + '_' + username;
                    fileIndex++;
                }
            }
            update cvList;

        } catch (Exception e) {
            System.debug('파일 제목 변경 중 오류 발생: ' + e.getMessage());
            throw new AuraHandledException('파일 이름 변경 실패: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Opportunity getCheckStatus(String recordId) {
        Opportunity opp = [SELECT Id, IsJumin__c, IsBusiness__c, IsVAT__c, VATDefermentStatus__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
        return opp;
    }

    @AuraEnabled
    public static Map<String, Boolean> checkFile(String recordId, String sectionName, List<Id> cvList) {  
        if (String.isBlank(recordId) || String.isBlank(sectionName) || cvList == null || cvList.isEmpty()) {
            return null;
        }
    
        System.debug('업로드된 파일 목록 ::: ' + cvList);
    
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink cdLink : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ]) {
            contentDocumentIds.add(cdLink.ContentDocumentId);
        }
    
        System.debug('기존 ContentDocumentIds ::: ' + contentDocumentIds);
    
        Map<String, Boolean> checkFileMap = new Map<String, Boolean>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId, Type__c 
            FROM ContentVersion 
            WHERE ContentDocumentId IN :contentDocumentIds
        ]) {
            if (cv.Type__c != null) {
                checkFileMap.put(cv.Type__c, true);
            }
        }
    
        System.debug('기존 checkFileMap ::: ' + checkFileMap);
    
        List<ContentVersion> versionsToUpdate = new List<ContentVersion>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId, Type__c 
            FROM ContentVersion 
            WHERE Id IN :cvList 
        ]) {
            if (cv.Type__c == null) {
                cv.Type__c = sectionName;
                versionsToUpdate.add(cv);
            }
        }
    
        if (!versionsToUpdate.isEmpty()) {
            update versionsToUpdate;
            System.debug('Type__c 업데이트 완료 ::: ' + versionsToUpdate);
        }
    
        return checkFileMap;
    }

}