/************************************************************************************
* Author            : payo03@solomontech.net
* File Name   		: EmailMessage_tr
* Description 		: Email Trigger
* Test Class        : EmailConfigController_test
* Modification Log
* Ver      Date            Author                           Modification
* ===================================================================================
  1.0      2024-10-15      payo03@solomontech.net           Create
*************************************************************************************/
public without sharing class EmailMessage_tr extends TriggerHandler {

    /** TriggerHandler **/
    private List<EmailMessage>    newList { get; set; }
    private List<EmailMessage>    oldList { get; set; }
    private Map<Id, EmailMessage> newMap  { get; set; }
    private Map<Id, EmailMessage> oldMap  { get; set; }

    public EmailMessage_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap  = (Map<Id, EmailMessage>) Trigger.newMap;
        oldMap  = (Map<Id, EmailMessage>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        System.debug('EmailMessage_tr.beforeInsert - start');
        setDefaultValues();
    }

    /**
     * @Description     ExternalId값 Setting
    */
    private void setDefaultValues() {
        String strDate = CommonUtilController.formatDate(Datetime.now(), 'C');
        String selectFields = 'Id, ExternalId__c';
        String fromObject =   'EmailMessage';
        String whereCondition = '';

        for(EmailMessage message : newList) {
            String messageKey = strDate + '_' + message.FromAddress + '_' + message.Subject;

            whereCondition += 'ExternalId__c LIKE \'' + messageKey + '%\' OR ';
        }
        whereCondition = whereCondition.substring(0, whereCondition.length() - 4);

        // '날짜_보낸사람_제목'의 메일중에서 Max Seq Get
        String query = CommonUtilController.buildQuery(selectFields, fromObject, whereCondition);
        List<EmailMessage> messageList = Database.query(query);
        Map<String, Integer> maxSeqMap = fetchMaxSeqMap(messageList);

        for (EmailMessage message : newList) {
            String messageKey = strDate + '_' + message.FromAddress + '_' + message.Subject;
            Integer seq = maxSeqMap.containsKey(messageKey)
                    ? maxSeqMap.get(messageKey) + 1
                    : 1;

            String externalId = messageKey + '_' + seq;
            message.ExternalId__c = externalId;
            maxSeqMap.put(messageKey, seq);
        }
    }

    private static Map<String, Integer> fetchMaxSeqMap(List<EmailMessage> messageList) {
        Map<String, Integer> maxSeqMap = new Map<String, Integer>();

        for(EmailMessage message :messageList) {
            String externalId = message.ExternalId__c;

            Integer lastIndex = externalId.lastIndexOf('_');
            String messageKey = externalId.substring(0, lastIndex);
            Integer messageSeq = Integer.valueOf(externalId.substring(lastIndex + 1));

            if(maxSeqMap.get(messageKey) == null) {
                maxSeqMap.put(messageKey, messageSeq);
            } else {
                Integer existSeq = maxSeqMap.get(messageKey);
                if(messageSeq > existSeq) maxSeqMap.put(messageKey, messageSeq);
            }
        }

        return maxSeqMap;
    }
}