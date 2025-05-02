/**
 * Created by 송찬영 on 24. 11. 03..
 */

@IsTest
private class CommonUtilCustomController_test {

    @IsTest
    static void testBehavior1() {
        TestObjectBuilder2.createConfigBundle();
        TestObjectBuilder2.createContractBundle();
        TestObjectBuilder2.createStockBundle();
        TestObjectBuilder2.createIfBundle();

        Contract contract = [SELECT Id FROM Contract LIMIT 1];
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
    }

    @IsTest
    static void testBehavior2() {
        TestObjectBuilder2.createContractBundle();

        Contract contract = [SELECT Id FROM Contract LIMIT 1];

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
    }

    @IsTest
    static void testBehavior3() {
        TestObjectBuilder2.createLeadBundle();

        Lead lead = [SELECT Id, OwnerId FROM Lead LIMIT 1];

        List<Map<String, String>> approvalInputList = new List<Map<String, String>>();
        Map<String,String> approvalInputMap = new Map<String,String>();
        approvalInputMap.put('comment', 'Test');
        approvalInputMap.put('approvalProcess', 'LeadOwnerChange');
        approvalInputMap.put('recordId', lead.Id);
        approvalInputMap.put('userId', lead.OwnerId);

        approvalInputList.add(approvalInputMap);
        Map<String, Object> approvalMap = CommonUtilCustomController.approvalProcessList(approvalInputList);
    }

    @IsTest
    static void testBehavior4() {
        TestObjectBuilder2.createConfigBundle();
        TestObjectBuilder2.createStockBundle();
        TestObjectBuilder2.createIfBundle();

        APIDocument__c document = [SELECT Id, Contract__r.Name FROM APIDocument__c LIMIT 1];
        AvisOrderInfo__c info = [SELECT Id, fm_SpoilerText__c, fm_SpoilerCode__c FROM AvisOrderInfo__c LIMIT 1];

        Integer pageNumber = CommonUtilCustomController.getPDFPageNumber('TEXT');
        Object value = CommonUtilCustomController.fetchValueRecur(document, 'Contract__r.Name');
        String field = CommonUtilCustomController.modifyField('COPY_OwnerId');
        String spoilerKey = CommonUtilCustomController.getSpoilerKey(info);
        Map<Date, Date> availableDateMap = CommonUtilCustomController.availableDateMap(3);
    }
}