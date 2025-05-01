/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : IF_SAP_test
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-02-14      payo03@solomontech.net           Created
  1.1      2025-02-22      payo03@solomontech.net           Bulk Update. Payment금액은 Fetch해서 가져와야함
  1.2      2025-03-27      payo03@solomontech.net           배정 실패시 알림추가
  1.3      2025-04-17      payo03@solomontech.net           모두싸인 후처리 Process 상속Class 구현
  1.3      2025-04-30      jh.jung                          출고일 지정 실패시 noti target 변경
*/
global without sharing class StageUpdateCommonController extends CommonAfterProcess {

    // 체크대상. Document의 상태, 계약금 입금여부 확인
    // Object관계도 간략 기입
    /*
        Opportunity : VehicleStock = 1 : 1
        Opportunity : PaymentTracker = N : 1
        Opportunity : PaymentTracker(IsValid) = 1 : 1
        Opportunity : Contract = N : 1, Opportunity => Contract는 1
    */

    // ver1.3 모두싸인 후처리 Process 상속Class 구현
    public override Object doAfterProcess(Object obj) {
        System.debug('doAfterProcess : ' + obj);

        String contractId = String.valueOf(obj);
        doUpdateOpportunity(contractId);

        return null;
    }

    public static void doUpdateOpportunity(String contractId) {
        Contract contract = [SELECT Id, OwnerId, Opportunity__c, Opportunity__r.Name, Quote__r.VehicleStock__c, Quote__r.VehicleStock__r.Product__r.Name FROM Contract WHERE Id = :contractId];
        String opportunityId = contract.Opportunity__c;
        String stockId = contract.Quote__r.VehicleStock__c;
        String productName = contract.Quote__r.VehicleStock__r.Product__r.Name;

        Boolean isNoti = false;
        Boolean isNotiByHandoverDateNotAssign = false;
        List<String> notiTitleList = new List<String>();
        List<String> notiBodyList = new List<String>();
        String senderId = UserInfo.getUserId();
        String targetId = contract.Opportunity__c;
        Set<String> userIdSet = new Set<String>{contract.OwnerId};

        try {
            // 1. 계약서 완료, 계약금 입금완료여부 확인, 대출심사여부 확인
            List<APIDocument__c> documents = [
                    SELECT Id
                    FROM APIDocument__c
                    WHERE Contract__c = :contractId
                    AND Status__c IN ('COMPLETED(CUSTOMER)', 'COMPLETED')
                    AND FileName__c LIKE '계약서%'
            ];
            if (documents.isEmpty()) throw new CustomException('계약서가 완료되지 않았습니다.');

            List<PaymentType__c> types = [
                    SELECT Id
                    FROM PaymentType__c
                    WHERE PaymentTracker__r.Opportunity__r.ContractId = :contractId
                    AND PaymentTracker__r.IsValid__c = TRUE
                    AND Type__c = '1_DEPOSIT'
                    AND fm_LeftAmount__c = 0
            ];
            if (types.isEmpty()) throw new CustomException('계약금 입금이 완료되지 않았습니다.');

            // 2. Opportunity, Contract Update
            update new Opportunity(Id = opportunityId, VehicleStock__c = stockId, StageName = 'Payment');
            update new Contract(Id = contractId, ConStatus__c = '계약금 및 서명 완료');

            // 3. Quote의 출고예정일. 출고 지정가능한 조건에 부합한경우 Insert
            List<Quote> quotes = [
                    SELECT Id, HopeHandoverDate__c, OpportunityId, VehicleStock__c
                    FROM Quote
                    WHERE ContractId = :contractId
                    AND Status = 'Published'
                    AND (
                        Opportunity.StageName = 'Payment' AND
                        Opportunity.VehicleStock__c != NULL
                    )
            ];
            if (quotes.isEmpty()) {
                // ver1.2 배정 실패시 알림추가
                isNoti = true;
                notiTitleList.add('견적구성 오류 혹은 차량 배정불가');
                notiBodyList.add('차량이 배정되지 않았습니다.\n관리자에게 문의 바랍니다.\n 차종명 : ' + productName);
            }

            Quote quote = quotes[0];
            Date targetDate = quote.HopeHandoverDate__c != null ? quote.HopeHandoverDate__c : Date.today();
            List<Map<String, Object>> paramMapList = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'targetDate' => targetDate,
                    'opportunityId' => opportunityId,
                    'stockId' => stockId
                }
            };
            HandoverDateAllocationHistory__c history = TaxInvoiceSchedulerController.createHistory(paramMapList).get(opportunityId);

            if (history != null) insert history;
            else {
                // History가 NULL일경우. 수동으로 출고일 지정필요
//                isNoti = true;
                isNotiByHandoverDateNotAssign = true;
                notiTitleList.add('출고일 자동 선택 불가');
                notiBodyList.add('해당 기회의 출고일을 다시 선택해 주세요. \n 기회 이름 : ' + contract.Opportunity__r.Name);
            }
        } catch (Exception e) {

            System.debug(e.getMessage());
        } finally {
            // ver1.2 배정 실패시 알림추가
            CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Custom' LIMIT 1];
            CommonUtilController.NotificationWrap notiWrap = new CommonUtilController.NotificationWrap(
                    String.join(notiTitleList, '\n'),
                    String.join(notiBodyList, '\n'),
                    notificationType.Id,
                    senderId,
                    targetId,
                    userIdSet
            );
            if(isNoti) CommonUtilController.sendNotification(notiWrap);
            // 출고일 지정 실패시 노티 변경 (04/30)
            if(isNotiByHandoverDateNotAssign) {
                Map<String, Object> mapObj = new Map<String, Object> {
                    'type' => 'standard__navItemPage',
                    'attributes' => new Map<String, String> {
                        'apiName' => 'SchedulerMain'
                    },
                    'state' => new Map<String, String> {
                        'c__origin' => 'handoverDateNotAssign'
                    }
                };

                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle(String.join(notiTitleList, '\n'));
                notification.setBody(String.join(notiBodyList, '\n'));
                notification.setNotificationTypeId(notificationType.Id);
                notification.setSenderId(senderId);
                notification.setTargetPageRef(JSON.serialize(mapObj));
                notification.send(userIdSet);
            }
        }
    }

    // ver1.1 Bulk Update. Payment금액은 Fetch해서 가져와야함
    /*
    @Future
    public static void doUpdateOpportunityList(List<String> contractIdList) {
        try {
            // 1. 계약서 서명 완료여부 확인
            Set<String> docFilterSet = new Set<String>();
            List<APIDocument__c> documents = [
                    SELECT Id, Contract__c
                    FROM APIDocument__c
                    WHERE Contract__c IN :contractIdList
                    AND Status__c IN ('COMPLETED(CUSTOMER)', 'COMPLETED')
                    AND FileName__c LIKE '계약서%'
            ];
            for(APIDocument__c document : documents) {
                docFilterSet.add(document.Contract__c);
            }

            // 2. 계약금 입금완료여부 확인
            Set<String> typeFilterSet = new Set<String>();
            List<PaymentType__c> types = [
                    SELECT Id, PaymentTracker__r.Opportunity__r.ContractId
                    FROM PaymentType__c
                    WHERE PaymentTracker__r.Opportunity__r.ContractId IN :docFilterSet
                    AND PaymentTracker__r.IsValid__c = TRUE
                    AND Type__c = '1_DEPOSIT'
                    AND fm_LeftAmount__c = 0
            ];
            for(PaymentType__c type : types) {
                typeFilterSet.add(type.PaymentTracker__r.Opportunity__r.ContractId);
            }

            // 3. 계약서 서명 및 계약금 입금 Filtering된 Quote.
            List<Quote> quotes = [
                    SELECT Id, OpportunityId, VehicleStock__c, ContractId, 
                        HopeHandoverDate__c
                    FROM Quote
                    WHERE ContractId IN :typeFilterSet
                    AND Status = 'Published'
            ];

            List<Opportunity> updateOpptyList = new List<Opportunity>();
            List<Contract> updateContractList = new List<Contract>();
            for(Quote quote : quotes) {

                Opportunity updateOppty = new Opportunity(
                        Id = quote.OpportunityId,
                        StageName = 'Payment',
                        VehicleStock__c = quote.VehicleStock__c
                );
                Contract updateContract = new Contract(
                        Id = quote.ContractId,
                        ConStatus__c = '계약금 및 서명 완료'
                );

                updateOpptyList.add(updateOppty);
                updateContractList.add(updateContract);
            }

            // 4. DML
            if(!updateOpptyList.isEmpty()) update updateOpptyList;          // Opportunity 차량배정. 배정될 VehicleStock이 기 배정된경우 조건에 따라 순차배정
            if(!updateContractList.isEmpty()) update updateContractList;    // Contract Update

            // 5. Opportunity 차량배정된 VehicleStock에 대한 출고일 Update
            List<Quote> updateQuotes = [
                    SELECT Id, OpportunityId, VehicleStock__c, ContractId,
                            HopeHandoverDate__c
                    FROM Quote
                    WHERE ContractId IN :typeFilterSet
                    AND Status = 'Published'
                    AND (
                        Opportunity.StageName = 'Payment' AND
                        Opportunity.VehicleStock__c != NULL AND
                        Contract.ConStatus__c = '계약금 및 서명 완료'
                    )
            ];
            List<Map<String, Object>> checkHistoryList = new List<Map<String, Object>>();
            for(Quote quote : updateQuotes) {
                Map<String, Object> checkHistoryMap = new Map<String, Object>{
                        'targetDate' => quote.HopeHandoverDate__c != null ? quote.HopeHandoverDate__c : Date.today(),
                        'opportunityId' => quote.OpportunityId,
                        'stockId' => quote.VehicleStock__c
                };

                checkHistoryList.add(checkHistoryMap);
            }

            // 6. History 데이터 INSERT 여부 확인
            List<HandoverDateAllocationHistory__c> insertHistoryList = TaxInvoiceSchedulerController.createHistory(checkHistoryList).values();
            if(!insertHistoryList.isEmpty()) insert insertHistoryList; // History가 NULL일경우. 수동으로 출고일 지정필요
        } catch (Exception e) {

            System.debug(e.getMessage());
        }
    }
    */
}