/**
* @Author            : payo03@solomontech.net
* @Description 		 :
* @Target            : EmailConfigController, EmailMessage_tr
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-03      payo03@solomontech.net           Created
*/
@IsTest
private class EmailConfigController_test {

    @IsTest
    static void testBehavior() {
        // 이메일 메시지 Map 생성
        List<Map<String, Object>> mailInfoList = new List<Map<String, Object>>();

        // 수신자 설정
        List<String> toAddresses = new List<String>{
                'payo03@solomontech.net',
                'ccy2010@solomontech.net'
        };
        String subject = '테스트 이메일 제목';
        String subject2 = '테스트 이메일 제목2';

        String emailBody = '안녕하세요 내용 입니다';
        String emailBody2 = '안녕하세요 내용 입니다2';

        String sender = 'Solomontech Info';
        List<String> ccAddresses = new List<String>{
                'payo03@solomontech.net'
        };
        List<String> bccAddresses = new List<String>{
                'ccy2010@solomontech.net'
        };

        Map<String, Object> mailInfo = new Map<String, Object>();
        mailInfo.put('to', toAddresses);
        mailInfo.put('subject', subject);
        mailInfo.put('body', emailBody);
        mailInfo.put('sender', sender);
        mailInfo.put('cc', ccAddresses);
        mailInfo.put('bcc', bccAddresses);
        mailInfo.put('encrypt', true);
        mailInfoList.add(mailInfo);

        Map<String, Object> mailInfo2 = new Map<String, Object>();
        mailInfo2.put('to', toAddresses);
        mailInfo2.put('subject', subject2);
        mailInfo2.put('body', emailBody2);
        mailInfo2.put('sender', sender);
        mailInfo2.put('cc', ccAddresses);
        mailInfo2.put('bcc', bccAddresses);
        mailInfo2.put('encryptSHA', true);
        mailInfoList.add(mailInfo2);

        Boolean isSend = EmailConfigController.sendEmail(mailInfoList);
        if(isSend) {
            // 복호화 하는 방법
            List<EmailMessage> messages = [
                    SELECT Id, EncryptKey__c, TextBody, TextBodyRaw__c
                    FROM EmailMessage
                    WHERE EncryptKey__c != NULL
            ];

            for(EmailMessage message : messages) {
                String key = message.EncryptKey__c;
                String body = message.TextBody;

                if(key.contains('.')) {
                    // SHA 방식일경우

                    String shaKey = String.valueOf(Double.valueOf(key));
                    Boolean isEqual = EmailConfigController.compareHash(shaKey, message.TextBodyRaw__c, message.TextBody);
                } else {
                    // AES 방식일경우

                    String strBody = EmailConfigController.decryptEmailBody(key, body);
                }
            }
        }

        // EmailMessage_tr 발동
        EmailConfigController.sendEmail(mailInfoList);
    }
}