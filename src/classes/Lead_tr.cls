/**
* @Author            : jh.jung
* @Description 		 :
* @Target            :
* @Modification Log
  Ver      Date            Author            Modification
  ===================================================================================
  1.0      2024-11-20      jh.jung           Created
  1.1      2024-03-17      san.kang          Light Consent 로직 추가
*/
public without sharing class Lead_tr extends TriggerHandler {

    private static final String IF_ID = 'API_KAKAO_MAP';

    /** TriggerHandler */
    private final List<Lead> newList   { get; set; }
    private final List<Lead> oldList   { get; set; }
    private final Map<Id, Lead> oldMap { get; set; }
    private final Map<Id, Lead> newMap { get; set; }

    public Lead_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        oldMap = (Map<Id, Lead>) Trigger.oldMap;
        newMap = (Map<Id, Lead>) Trigger.newMap;
    }

    public class KakaoApiResponse {
        public List<Document> documents;
    }

    public class Document {
        public Decimal x;
        public Decimal y;
    }


    protected override void afterInsert() {
        setLocationValues(newMap.keySet());
        insertCustomerConsent(newMap);
        System.debug(newMap);
    }

    protected override void afterUpdate() {
        // CustomerConsent 업데이트 로직
        updateCustomerConsent();
        Set<Id> changedAddressLeadIdSet = new Set<Id>();
        List<Lead> approvedLeadList = new List<Lead>();
        List<Lead> rejectLeadList = new List<Lead>();

        for(Lead lead : newList) {
            Lead oldLead = oldMap.get(lead.Id);
            if(lead.RoadAddress__c != oldLead.RoadAddress__c && lead.RoadAddress__c != null) {
                changedAddressLeadIdSet.add(lead.Id);
            }

            if(lead.ApprovalStatus__c == '승인됨' && oldLead.ApprovalStatus__c != '승인됨') {
                approvedLeadList.add(lead);
            } else if(lead.ApprovalStatus__c == '반려됨' && oldLead.ApprovalStatus__c != '반려됨') {
                rejectLeadList.add(lead);
            }
        }
        if(!changedAddressLeadIdSet.isEmpty()) {
            setLocationValues(changedAddressLeadIdSet);
        }
        if(!approvedLeadList.isEmpty()) {
            approveProcess(approvedLeadList);
        }
        if(!rejectLeadList.isEmpty()) {
            rejectProcess(rejectLeadList);
        }
    }

    // 승인
    // 1. 계정 소유자 변경 (lead의 OwnerId), 이전 소유자가 가진 Oppty 잠금
    // 2. createPreQuote retry
    // 3. 이전 SA, 현재 SA에게 노티
    private static void approveProcess(List<Lead> leadList) {
        System.debug('approveProcess START');
        List<Account> updateList = new List<Account>();
        List<Opportunity> lockOpptyList = new List<Opportunity>();
        Set<String> accountIdSet = new Set<String>();

        // 1. Lead Update
        Map<String, Map<String, Object>> leadInfoMap = new Map<String, Map<String, Object>>();
        List<Map<String, Object>> inputLeadMapList = new List<Map<String, Object>>();

        // 변경해야할 AccMap
        Map<String, Map<String, String>> dupAccInfoMap = LeadManagementController.getAccountIdByLeadList(leadList);  // Key : LeadId, Value : accInfoMap

        for(Lead lead : leadList) {
            Map<String, String> infoMap = dupAccInfoMap.get(lead.Id);
            leadInfoMap.put(lead.Id, infoMap);

            if (infoMap != null && infoMap.containsKey('accountId')) {
                String accountId = infoMap.get('accountId');
                Account dupAcc = new Account();
                dupAcc.Id = accountId;
                dupAcc.OwnerId = lead.OwnerId;

                updateList.add(dupAcc);
                accountIdSet.add(accountId);
            }

//            Map<String, Object> inputLeadMap = new Map<String, Object> {
//                'leadId' => lead.Id
//                , 'productId' => lead.ProductId__c
//                , 'campaignIdList' => ''
//                , 'financeId' => lead.Finance__c
//                , 'totalLoan' => 0
//                , 'advancePayment' => lead.AdvancePayment__c != null ? lead.AdvancePayment__c : 0
//                , 'interestRate' => lead.DefaultInterestRate__c != null ? lead.DefaultInterestRate__c : 0
//                , 'duration' => lead.MonthDivideInputMonth__c != null ? lead.MonthDivideInputMonth__c : 0
//            };
            Map<String, Object> inputLeadMap = new Map<String, Object> {
                    'leadId' => lead.Id
                    , 'productId' => lead.ProductId__c
                    , 'campaignIdList' => ''
                    , 'financeId' => null
                    , 'totalLoan' => 0
                    , 'advancePayment' => 0
                    , 'interestRate' => 0
                    , 'duration' => 0
            };
            inputLeadMapList.add(inputLeadMap);
        }

        if(!updateList.isEmpty()) update updateList;

        // 변경해야할 accountIdSet이 이미 갖고있는 Oppty들 Lock
        if (!accountIdSet.isEmpty()) {
            lockOpptyList = [
                SELECT Id, Name, Account.Name
                FROM Opportunity
                WHERE AccountId IN :accountIdSet
            ];
            System.debug('lockOpptyList ::: ' + lockOpptyList);

            Approval.LockResult[] lockResults = Approval.lock(lockOpptyList, false);

            List<Opportunity> lockList = new List<Opportunity>();
            for(Integer i = 0; i<lockOpptyList.size(); i++) {
                Opportunity lockOppty = lockOpptyList.get(i);
                lockOppty.IsLock__c = lockResults.get(i).isSuccess();
                lockOppty.StageName = 'Closed Lost';
                System.debug(i + ' lockOppty ::: ' + lockOppty);
                lockList.add(lockOppty);
            }

            System.debug('lockList ::: ' + lockList);
            if(!lockList.isEmpty()) update lockList;

            // Lock 로그
            for (Approval.LockResult result : lockResults) {
                if (result.isSuccess()) {
                    System.debug('Successfully locked Opportunity with Id: ' + result.getId());
                } else {
                    System.debug('Failed to lock Opportunity with Id: ' + result.getId() + '. Error: ' + result.getErrors()[0].getMessage());
                }
            }
        }


        // 2. Owner 변경 및 재시도 -> Return Value 받음
        Map<String, Map<String, Object>> returnKeyMap = LeadManagementController.createPreQuoteList(inputLeadMapList);

        // 3. 승인시 노티 전송
        String titleMessage;
        String bodyMessage;
        String targetId;
        String sendId;
        for(String leadId : returnKeyMap.keySet()) {
            Map<String, Object> returnInfo = returnKeyMap.get(leadId);
            Map<String, Object> infoMap = leadInfoMap.get(leadId);
            System.debug('returnInfo ::: ' + JSON.serialize(returnInfo));
            // {"value":"0Q0H2000000E5D8KAK","isSuccess":true,"accountId":"001H200001Z2gM3IAJ"}

            if(Boolean.valueOf(returnInfo.get('isSuccess'))) {
                // 성공한 SA에게 노티
                titleMessage = '소유권 변경 승인.';
                bodyMessage = '담당자가 계정 소유 변경을 승인하였습니다. 생성된 견적으로 이동합니다.';
                targetId = String.valueOf(returnInfo.get('value'));
                sendId = String.valueOf(infoMap.get('requestId'));
                sendNotification(titleMessage, bodyMessage, targetId, sendId);

                // 뺏긴 SA에게 노티
                titleMessage = '소유중이던 계정이 다른 SA로 변경되었습니다.';
//                bodyMessage = '소유중이던 계정이 다른 SA로 변경되었습니다. 바뀐 계정 Id : ' + String.valueOf(returnInfo.get('accountId'));
                bodyMessage = '소유중이던 계정이 다른 SA로 변경되었습니다. \n이름 : ' + String.valueOf(infoMap.get('accountName'));
                targetId = String.valueOf(returnInfo.get('accountId'));
                sendId = String.valueOf(infoMap.get('ownerId'));
                sendNotification(titleMessage, bodyMessage, targetId, sendId);
            } else {
                System.debug(returnInfo);
            }
        }


    }

    // 반려
    // 1. 요청한 SA에게 노티
    // todo- 거절 당하면 해당 리드 삭제?
    private static void rejectProcess(List<Lead> leadList) {
        System.debug('rejectProcess START');
        String titleMessage;
        String bodyMessage;
        String targetId;
        String sendId;

        Set<Id> rejectedLeadIdSet = new Set<Id>();
        for(Lead lead : leadList) {
            titleMessage = '소유권 변경 거절.';
            bodyMessage = '담당자가 계정 소유 변경을 거절하였습니다.';
            targetId = lead.Id;
            sendId = lead.OwnerId;
            sendNotification(titleMessage, bodyMessage, targetId, sendId);

            rejectedLeadIdSet.add(lead.Id);
        }

        deleteRejectedLeadList(rejectedLeadIdSet);
    }

    @Future
    private static void deleteRejectedLeadList(Set<Id> rejectedLeadIdSet) {

        delete [SELECT Id FROM Lead WHERE Id IN:rejectedLeadIdSet];
    }

    private static void sendNotification(String titleMessage, String bodyMessage, String targetId, String sendId) {
        // 알림 생성

        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Custom' LIMIT 1];

        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(titleMessage);
        notification.setBody(bodyMessage);
        notification.setTargetId(targetId);
        notification.setNotificationTypeId(notificationType.Id);
        notification.setSenderId(UserInfo.getUserId());
        notification.send(new Set<String> { sendId });
        System.debug('notification :: ' + notification);
    }

    // leadId에 맞는 Account를 찾아 현재 ownerId와 accountId를 리턴
//    private static Map<String, String> getAccountIdByLead(Lead lead) {
//        String selectFields = 'Id, OwnerId';
//        String accWhereConditions = 'Name = \'' + lead.LastName +
//                '\' AND PersonMobilePhone = \'' + lead.MobilePhone + '\'';
//        String accountQuery = CommonUtilController.buildQuery(selectFields, 'Account', accWhereConditions);
//        List<Account> accountList = Database.query(accountQuery);
//
//        selectFields += ', AccountId';
//        String conWhereConditions = 'LastName = \'' + lead.LastName +
//                '\' AND MobilePhone = \'' + lead.MobilePhone + '\'';
//        String contactQuery = CommonUtilController.buildQuery(selectFields, 'Contact', conWhereConditions);
//        List<Contact> contactList = Database.query(contactQuery);
//
//        String ownerId = accountList.isEmpty() ? contactList[0].OwnerId : accountList[0].OwnerId;
//        String accId = accountList.isEmpty() ? contactList[0].AccountId : accountList[0].Id;
//
//        return new Map<String, String>{
//            'accountId' => accId
//            , 'ownerId' => ownerId
//        };
//    }

    @Future(Callout=true)
    private static void setLocationValues(Set<Id> leadIdSet) {
        List<Lead> leadList = [
                SELECT Id, RoadAddress__c, Longitude__c, Latitude__c
                FROM Lead
                WHERE Id IN :leadIdSet
        ];
        for (Lead lead : leadList) {
            try {
                if (lead.RoadAddress__c != null) {
                    IF_Util ifUtil = new IF_Util(IF_ID);
                    String body = 'query=' + EncodingUtil.urlEncode(lead.RoadAddress__c, 'UTF-8');
                    HttpResponse res = ifUtil.webCallout(body);

                    KakaoApiResponse response = (KakaoApiResponse) JSON.deserialize(res.getBody(), KakaoApiResponse.class);
                    if(response != null) {
                        lead.Latitude__c = response.documents.get(0).y;
                        lead.Longitude__c = response.documents.get(0).x;
                    }
                }

            } catch (Exception e) {
                System.debug('API 호출 중 오류: ' + e.getMessage());
            }
        }
        update leadList;
    }

    //리드 생성 시 Light Consent 생성
    private static void insertCustomerConsent(Map<Id, Lead> leadMap){

        // 중복이 있는 lead나 Account인지 확인
        String conditions = '';

        for (Lead lead : leadMap.values()) {
            if (String.isNotBlank(lead.MobilePhone) && String.isNotBlank(lead.LastName)) {
                String mobile = String.escapeSingleQuotes(lead.MobilePhone);
                String lastName = String.escapeSingleQuotes(lead.LastName);

                conditions += ' (Account__r.PersonMobilePhone = \'' + mobile + '\' AND Account__r.LastName = \'' + lastName + '\') OR ';
                conditions += ' (Lead__r.MobilePhone = \'' + mobile + '\' AND Lead__r.LastName = \'' + lastName + '\') OR ' ;
            }
        }

        conditions = conditions != null ? conditions.substring(0, conditions.length() - 4) : '';

        // 조건이 하나라도 있어야 쿼리 실행
        String query = ' SELECT Id, Account__c, Lead__c ' +
                ' FROM CustomerConsent__c ' +
                ' WHERE ConsentStatus__c = \'작성완료됨\' ';

        if (conditions != '') {
            query += ' AND (' + conditions + ')';
        }
        // 4. Dynamic SOQL 실행
        List<CustomerConsent__c> duplicateConsent = Database.query(query);

        try{
            if(duplicateConsent.size() == 0){

            List<CustomerConsent__c> insertCustomerConsentList = new List<CustomerConsent__c>();

                for(Id leadId : leadMap.keySet()){
                    CustomerConsent__c customerConsent = new CustomerConsent__c(
                            Lead__c = leadId,
                            ConsentStatus__c = '링크 전송됨',
                            SendAlimTalkDate__c = System.today()
                    );
                    insertCustomerConsentList.add(customerConsent);
                }
                if(!insertCustomerConsentList.isEmpty()) insert insertCustomerConsentList;

            }
        } catch (Exception e){
            System.debug('err :: ' + e);
        }
    }

    //리드 생성 시 Light Consent 생성
    private void updateCustomerConsent() {

        Set<Id> updateLeadIdSet = new Set<Id>();
        for (Id leadId : newMap.keySet()) {
            if (newMap.get(leadId).ConvertedOpportunityId != oldMap.get(leadId).ConvertedOpportunityId ) {
                updateLeadIdSet.add(leadId);
            }
        }

        System.debug('updateLeadIdSet' + updateLeadIdSet);
        if(!updateLeadIdSet.isEmpty()) {
            List<CustomerConsent__c> updateCustomerConsents = new List<CustomerConsent__c>();
            try {
                for(CustomerConsent__c customerConsent : [SELECT Id, Lead__r.ConvertedOpportunityId FROM CustomerConsent__c WHERE Lead__c =:updateLeadIdSet]){
                    customerConsent.Opportunity__c = customerConsent.Lead__r.ConvertedOpportunityId;
                    customerConsent.Account__c = customerConsent.Lead__r.ConvertedOpportunity.AccountId;
                    customerConsent.ConsentStatus__c = '링크 전송됨';
                    customerConsent.SendAlimTalkDate__c = System.today();
                    customerConsent.ConsentDate__c = null;

                    updateCustomerConsents.add(customerConsent);
                }
                if(!updateCustomerConsents.isEmpty()) update updateCustomerConsents;
            } catch (Exception e) {
                System.debug('err :: ' + e);
            }
        }
    }
}