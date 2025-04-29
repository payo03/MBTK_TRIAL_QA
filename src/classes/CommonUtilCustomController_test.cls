/**
 * Created by 송찬영 on 24. 11. 03..
 */

@IsTest
private class CommonUtilCustomController_test {

    @TestSetup
    static void setup() {
        TestObjectBuilder2.createObjects();
        TestObjectBuilder2.createConfigBundle();

        TestObjectBuilder2.createStockBundle();
        TestObjectBuilder2.createLeadBundle();
        TestObjectBuilder2.createContractBundle();
        TestObjectBuilder2.createIfBundle();
    }

    @IsTest
    static void testBehavior() {
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
        APIDocument__c document = [SELECT Id, Contract__r.Name FROM APIDocument__c LIMIT 1];
        Lead lead = [SELECT Id, OwnerId FROM Lead LIMIT 1];
        AvisOrderInfo__c info = [SELECT Id, fm_SpoilerText__c, fm_SpoilerCode__c FROM AvisOrderInfo__c LIMIT 1];

        String strSAP = CommonUtilCustomController.parseStringSAP('HEROKU_SMS001', new List<String>(), 'A001');

        String segment = 'Tipper';
        String specShortRaw = 'TGL 10.190 4x2 BL CH';
        String cabMark = 'M';
        String intarder = 'No Intarder';
        String wheelBase = '2900';
        String trimLevel = 'Premium';
        String emissionLevel = 'Euro5';
        String carCode = CommonUtilCustomController.parseCarCode(segment, specShortRaw, cabMark, intarder, wheelBase, trimLevel, emissionLevel);

        Map<String, String> vinMap = CommonUtilCustomController.getYearByVIN(new List<String>{'1234567890'});

        Map<String, String> specMap = CommonUtilCustomController.getSpecMap(specShortRaw);

        Map<String,String> InfoMap = new Map<String,String>{
                'recordId' => contract.Id,
                'userId' => UserInfo.getUserId(),
                'comment' => 'test',
                'ApprovalProcess' => 'ContractAmendmentProcess'
        };
        CommonUtilCustomController.ContractAmendmentApprovalProcess(InfoMap);

        String ifId = CommonUtilCustomController.parseIFId('U');
        List<Map<String, Object>> configMapList = CommonUtilCustomController.getConfigMapList('[샘플] 개인정보 수집 이용 동의서');

        List<IF_DTO.LogWrapper> logList = new List<IF_DTO.LogWrapper>();
        IF_DTO.LogWrapper log = new IF_DTO.LogWrapper();
        log.requestTime = Datetime.now();
        log.requestBody = 'RequestBody';
        log.status = 'SUCCESS';
        log.responseTime = Datetime.now();
        log.responseBody = 'ResponseBody';
        log.errorCode = '404';
        logList.add(log);

        CommonUtilCustomController.setLog(log);
        CommonUtilCustomController.setLogList(logList);
        CommonUtilCustomController.createTask(contract.Id, 'modusign', 'subject');

        List<Map<String, String>> approvalInputList = new List<Map<String, String>>();
        Map<String,String> approvalInputMap = new Map<String,String>();
        approvalInputMap.put('comment', 'Test');
        approvalInputMap.put('approvalProcess', 'LeadOwnerChange');
        approvalInputMap.put('recordId', lead.Id);
        approvalInputMap.put('userId', lead.OwnerId);

        approvalInputList.add(approvalInputMap);
        Map<String, Object> approvalMap = CommonUtilCustomController.approvalProcessList(approvalInputList);

        Integer pageNumber = CommonUtilCustomController.getPDFPageNumber('TEXT');
        Object value = CommonUtilCustomController.fetchValueRecur(document, 'Contract__r.Name');
        String field = CommonUtilCustomController.modifyField('COPY_OwnerId');
        String spoilerKey = CommonUtilCustomController.getSpoilerKey(info);
        Map<Date, Date> availableDateMap = CommonUtilCustomController.availableDateMap(3);
    }
}