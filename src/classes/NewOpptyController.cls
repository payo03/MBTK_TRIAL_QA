/*************************************************************
 * @author : th.kim
 * @date : 2024-11-11
 * @description : VehicleStock 레코드 페이지에서 Opportunity 자동 생성 (삭제 예정)
 * @target : newOppty.js
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-11      th.kim          Created
**************************************************************/
public with sharing class NewOpptyController {

    @AuraEnabled
    public static String createOppty(Map<String, String> dataParams) {

        try {
            String recordId = dataParams.get('recordId');
            String accountId = dataParams.get('accountId');

            if (String.isNotBlank(recordId)) {
                VehicleStock__c vehicleStock = [SELECT Id, Name FROM VehicleStock__c WHERE Id = :recordId LIMIT 1];

                // TODO :: Oppty에 들어갈 필드 정의 필요
                Opportunity opp = new Opportunity(
                    Name = 'test ' + accountId,
                    StageName = 'Qualification',
                    CloseDate = Date.today(),
                    VehicleStock__c = recordId
                );
                insert opp;
                return opp.Id;
            } else {
                throw new AuraHandledException('recordId is null');
            }
        } catch (Exception e) {
            System.debug('err ::' + e.getMessage() + ', ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
}