/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-26      payo03@solomontech.net           Created
*/
@IsTest
private class MTBKEmailHandler_test {
    @IsTest
    static void testBehavior() {

        Test.startTest();

        String csvContent = 'Name,Age,Active\nJohn,30,TRUE\nJane,25,FALSE';
        Blob csvBlob = Blob.valueOf(csvContent);

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@example.com';
        email.subject = 'Test Email';
        email.plainTextBody = 'test.';
        email.htmlBody = '<p>test.</p>';

        Messaging.InboundEmail.BinaryAttachment csvAttachment = new Messaging.InboundEmail.BinaryAttachment();
        csvAttachment.fileName = 'test.csv';
        csvAttachment.body = csvBlob;
        email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{ csvAttachment };

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.toAddress = 'receiver@example.com';

        Messaging.InboundEmailResult result = new MTBKEmailHandler().handleInboundEmail(email, envelope);

        Test.stopTest();
    }
}