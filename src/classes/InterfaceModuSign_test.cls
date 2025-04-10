/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : InterfaceModuSign, IF_Util
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-27      payo03@solomontech.net           Created
*/
@IsTest
private class InterfaceModuSign_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createIfBundle();

        TestObjectBuilder2.createContractBundle();
    }

    @IsTest
    static void testBehavior() {
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
        APIDocument__c document = [SELECT Id FROM APIDocument__c LIMIT 1];

        IF_DTO.Participant participant1 = new IF_DTO.Participant();
        // Field 1: TEXT
        IF_DTO.Field textField = new IF_DTO.Field();
        textField.type = IF_DTO.FieldType.TEXT;
        textField.required = false;
        textField.size = new IF_DTO.Size();         // 입력란 크기
        textField.size.width = 0.02;
        textField.size.height = 0.02;
        textField.position = new IF_DTO.Position(); // InputBox 위치. 참조링크 https://modusign.github.io/pdf-position-tool/
        textField.position.x = 0.05;
        textField.position.y = 0.05;
        textField.position.page = 4;
        textField.textStyle = new IF_DTO.TextStyle();
        textField.textStyle.size = 48;
        textField.textStyle.font = IF_DTO.FontType.NOTO_SANS;   // textStyle지정시 필수

        IF_DTO.CheckboxFieldGroup checkboxGroup = new IF_DTO.CheckboxFieldGroup();
        checkboxGroup.minCheckRequired = 1;
        checkboxGroup.groupLabel = 'GROUP1';
        // Field 2: CHECKBOX
        IF_DTO.Field checkboxField1 = new IF_DTO.Field();
        checkboxField1.type = IF_DTO.FieldType.CHECKBOX;
        checkboxField1.required = true;
        checkboxField1.size = new IF_DTO.Size();
        checkboxField1.size.width = 0.02;
        checkboxField1.size.height = 0.02;
        checkboxField1.position = new IF_DTO.Position();
        checkboxField1.position.x = 0.03;
        checkboxField1.position.y = 0.03;
        checkboxField1.position.page = 3;
        checkboxField1.groupLabel = 'GROUP1';    // groupLabel은 기본 Checkbox가 2개이상이여야 함, required 무효화됨

        // Field 2: CHECKBOX
        IF_DTO.Field checkboxField2 = new IF_DTO.Field();
        checkboxField2.type = IF_DTO.FieldType.CHECKBOX;
        checkboxField2.required = true;
        checkboxField2.size = new IF_DTO.Size();
        checkboxField2.size.width = 0.02;
        checkboxField2.size.height = 0.02;
        checkboxField2.position = new IF_DTO.Position();
        checkboxField2.position.x = 0.035;
        checkboxField2.position.y = 0.035;
        checkboxField2.position.page = 3;
        checkboxField2.groupLabel = 'GROUP1';    // groupLabel은 기본 Checkbox가 2개이상이여야 함, required 무효화됨

        // SigningMethod 설정
        IF_DTO.SigningMethod signingMethod1 = new IF_DTO.SigningMethod();
        signingMethod1.type = 'KAKAO';
        signingMethod1.value = '01089460314';

        participant1.fields = new List<IF_DTO.Field>();
        participant1.checkboxFieldGroups = new List<IF_DTO.CheckboxFieldGroup>();

        participant1.locale = 'ko';
        participant1.signingDuration = 20160;   // 기준단위. 분
        participant1.role = '고객';
        participant1.name = '송찬영';
        participant1.signingOrder = 1;
        participant1.signingMethod = signingMethod1;
        participant1.fields.add(textField);
        participant1.fields.add(checkboxField1);
        participant1.fields.add(checkboxField2);
        participant1.checkboxFieldGroups.add(checkboxGroup);

        IF_DTO.Participant participant2 = new IF_DTO.Participant();
        // Fields 설정
        IF_DTO.Field signatureField = new IF_DTO.Field();
        signatureField.type = IF_DTO.FieldType.SIGNATURE;
        signatureField.required = true; // 서명은 항상 TRUE여야함

        signatureField.signatureTypes = new List<IF_DTO.SignatureType>{IF_DTO.SignatureType.SIGN, IF_DTO.SignatureType.STAMP};
        signatureField.size = new IF_DTO.Size();
        signatureField.size.width = 0.2;
        signatureField.size.height = 0.2;
        signatureField.position = new IF_DTO.Position();
        signatureField.position.x = 0.07;
        signatureField.position.y = 0.07;
        signatureField.position.page = 9;

        // SigningMethod 설정
        IF_DTO.SigningMethod signingMethod2 = new IF_DTO.SigningMethod();
        signingMethod2.type = 'EMAIL';
        signingMethod2.value = 'modu.kim@modusign.net';

        participant2.fields = new List<IF_DTO.Field>();

        participant2.role = '근로자';
        participant2.name = '테스트2';
        participant2.signingOrder = 1;
        participant2.locale = 'ko';
        participant2.signingDuration = 20160;
        participant2.signingMethod = signingMethod2;
        participant2.fields.add(signatureField);

        IF_DTO.SigningRequestByPDF signingRequest = new IF_DTO.SigningRequestByPDF();
//        Blob sampleBlob = [SELECT VersionData FROM ContentVersion WHERE FileType = 'PDF' ORDER BY CreatedDate DESC LIMIT 1].VersionData;

        IF_DTO.File file = new IF_DTO.File();
        file.extension = 'pdf';
//        file.base64 = EncodingUtil.base64Encode(sampleBlob);
        file.base64 = 'Blob to String';
        signingRequest.participants = new List<IF_DTO.Participant>();

        signingRequest.title = '개인정보 수집 동의서';
        signingRequest.file = file;
        signingRequest.fileOpenPassword = '123456';
        signingRequest.participants.add(participant1);
        signingRequest.participants.add(participant2);
        InterfaceModuSign.doCallOutSignRequestByPDF(signingRequest, contract.Id);

        Map<Object, Object> infoMapEntry1 = new Map<Object, Object>();
        infoMapEntry1.put('objectName', 'Account');
        infoMapEntry1.put('recordId', account.Id);
        infoMapEntry1.put('validDuration', 4);
        infoMapEntry1.put('sendType', 'kakao');
        infoMapEntry1.put('role', '근로자');
        infoMapEntry1.put('locale', 'en');
        Map<Object, Object> infoMapEntry2 = new Map<Object, Object>();
        infoMapEntry2.put('objectName', 'User');
        infoMapEntry2.put('recordId', UserInfo.getUserId());
        infoMapEntry2.put('validDuration', 4);
        infoMapEntry2.put('sendType', 'kakao');
        infoMapEntry2.put('role', '을');

        List<Map<Object, Object>> infoMapList = new List<Map<Object, Object>>{infoMapEntry1, infoMapEntry2};

        Map<String, Object> templateMap = new Map<String, Object>();
        templateMap.put('templateTitle', '[샘플] 개인정보 수집 이용 동의서');
        templateMap.put('object', 'Contract');
        templateMap.put('recordId', contract.Id);
        templateMap.put('documentTitle', '[Test] 개인정보 수집 이용 동의서');
        templateMap.put('infoMapList', infoMapList);
        InterfaceModuSign.doCallOutSignRequestByTemplate(templateMap);

        Map<String, String> draftMap = new Map<String, String>();
        draftMap.put('templateTitle', '[샘플] 개인정보 수집 이용 동의서');
        draftMap.put('recordId', contract.Id);
        InterfaceModuSign.doCallOutDraft(draftMap);

        InterfaceModuSign.doCallOutURLtoPDF(document.Id, 'COMPLETED(CUSTOMER)', false);
        InterfaceModuSign.getSmallestValue(100);
        InterfaceModuSign.doCallOutCancel(new Map<String, Object>(), '');
    }
}