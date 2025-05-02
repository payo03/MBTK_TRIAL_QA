/*********************************************************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-07
 * @description : 
 * @target :
==========================================================================================================
 * Ver          Date            Author                          Modification
 * 1.0          2025-01-07      chaebeom.do                     Created
 * 2.0          2025-03-14      chaebeom.do                     사전배정 프로세스 삭제로 인한 이름 변경
 * 2.1          2025-04-01      chaebeom.do                     계약 재협상으로 인한 재생성시 할당중인 가상계좌 있으면 연결 제외
 * 2.2          2025-04-08      chaebeom.do                     기존 할당 고객 카톡 전송 추가
*********************************************************************************************************/
public without sharing class AssignRequest_tr extends TriggerHandler {
//     /** TriggerHandler */
//     private final List<AssignRequest__c> newList { get; set; }
//     private final List<AssignRequest__c> oldList { get; set; }
//     private final Map<Id, AssignRequest__c> oldMap { get; set; }
//     private final Map<Id, AssignRequest__c> newMap { get; set; }

//     public AssignRequest_tr() {
//         newList = Trigger.new;
//         oldList = Trigger.old;
//         newMap = (Map<Id, AssignRequest__c>) Trigger.newMap;
//         oldMap = (Map<Id, AssignRequest__c>) Trigger.oldMap;
//     }

//     public override void beforeInsert() {

//     }

//     public override void beforeUpdate() {

//     }

//     public override void afterInsert() {
//         assignVirtualAccount2();
//     }

//     public override void afterUpdate() {
//         assignVirtualAccount2();
//     }

//     private void assignVirtualAccount2() {
//         List<VirtualAccountMaster__c> validVAMList = [
//                 SELECT Id
//                 FROM VirtualAccountMaster__c
//                 WHERE Status__c = '사용가능'
//                 ORDER BY Name DESC LIMIT :newList.size()
//         ];
//         // if(validVAMList.size() != newList.size()) throw new TriggerHandlerException('No Virtual Account In Available Error. Contact Admin.');

//         Map<String, String> requestOpptyMap = new Map<String, String>();
//         for(AssignRequest__c newRequest : newList) {
//             requestOpptyMap.put(newRequest.Id, newRequest.Opportunity__c);
//         }

//         Map<Id, Opportunity> curOpptyMap = new Map<Id, Opportunity>([
//                 SELECT Id, AccountId, Account.Name, ContractId
//                 FROM Opportunity
//                 WHERE Id IN :requestOpptyMap.values()
//         ]);

//         List<VirtualAccount__c> assignVAList = new List<VirtualAccount__c>();               // 가상계좌 Junction 생성 List
//         List<VirtualAccountMaster__c> usedVAMList = new List<VirtualAccountMaster__c>();    // 가상계좌 마스터 Update List
//         List<Contract> requestContractList = new List<Contract>();                          // 계약 Update List
//         List<String> accountIdList = new List<String>();                                    // 할당된 고객 Id Set
//         Map<String, VirtualAccount__c> accountVAMap = new Map<String, VirtualAccount__c>(); // 고객에 할당중인 가상계좌 Map
//         for(VirtualAccount__c activeVA : [
//             SELECT Id, Account__c
//             FROM VirtualAccount__c
//             WHERE IsValid__c = true
//         ]) {
//             accountVAMap.put(activeVA.Account__c, activeVA);
//         }

//         for(AssignRequest__c newRequest : newList) {
//             if(validVAMList.size() == 0) break;         // 가상계좌 사용끝난경우 배제. Exception과 해당라인 둘중 하나는 삭제필요

//             String requestId = newRequest.Id;
//             String validVamId = validVAMList.get(0).Id;
//             AssignRequest__c oldRequest = Trigger.isUpdate && oldMap.containsKey(newRequest.Id) ? oldMap.get(newRequest.Id) : new AssignRequest__c();
//             Opportunity curOppty = curOpptyMap.get(requestOpptyMap.get(requestId));

//             if(accountVAMap.containsKey(curOppty.AccountId)) {
//                 Map<String, String> oldAccountMap = new Map<String, String>();  // ver 2.2 기존 할당 고객용 Call KakaoTalk Map
//                 oldAccountMap.put('recordId', accountVAMap.get(curOppty.AccountId).Id);
//                 oldAccountMap.put('accId', accountVAMap.get(curOppty.AccountId).Account__c);
//                 callKakaoTalk(oldAccountMap);
//                 Contract contract = new Contract(Id = curOppty.ContractId);
//                 contract.CheckDepositRequest__c = true;
//                 requestContractList.add(contract);
//                 continue;  // ver 2.1 계약 재협상으로 인한 재생성시 할당중인 가상계좌 있으면 연결 제외
//             }

//             Map<String, Object> paramMap = new Map<String, Object>{
//                     'opportunity' => curOppty,
//                     'virtualAccountMasterId' => validVamId,
//                     'depositAmount' => newRequest.Payment__c,
//                     'validDate' => Date.today().addMonths(6)
//             };
//             if (Trigger.isInsert && newRequest.Status__c == '승인' && newRequest.Type__c == '일반배정') {
//                 validVAMList.remove(0); // 사용한 Id 제거

//                 // VirtualAccount생성
//                 VirtualAccount__c assignVA = CommonUtilCustomController.createVirtualAccount(paramMap);
//                 assignVAList.add(assignVA);

//                 // 사용한 VAM 할당중 변경
//                 VirtualAccountMaster__c usedVAM = new VirtualAccountMaster__c(Id = validVamId);
//                 usedVAM.Status__c = '할당중';
//                 usedVAMList.add(usedVAM);

//                 // Contract 상태 Update
//                 Contract contract = new Contract(Id = curOppty.ContractId);
//                 contract.CheckDepositRequest__c = true;
//                 requestContractList.add(contract);
//             } else if (Trigger.isUpdate && oldRequest.Status__c == '제출' && newRequest.Status__c == '승인' && newRequest.Type__c == '사전배정') {
//                 validVAMList.remove(0); // 사용한 Id 제거

//                 VirtualAccount__c assignVA = CommonUtilCustomController.createVirtualAccount(paramMap);
//                 assignVAList.add(assignVA);

//                 // 사용한 VAM 할당중 변경
//                 VirtualAccountMaster__c usedVAM = new VirtualAccountMaster__c(Id = validVamId);
//                 usedVAM.Status__c = '할당중';
//                 usedVAMList.add(usedVAM);

//                 // Contract 상태 Update
//                 Contract contract = new Contract(Id = curOppty.ContractId);
//                 contract.CheckDepositRequest__c = true;
//                 requestContractList.add(contract);
//             }

//         }
        
//         if (!assignVAList.isEmpty()) {
//             // Insert 성공한 데이터들만 카카오톡 전송
//             Map<String, Map<String, Object>> returnMap = CommonUtilController.applyObject(assignVAList, 'INSERT');
//             Map<String, Object> vaMap = returnMap.get('SUCCESS');
            
//             List<Opportunity> updateOpptyList = new List<Opportunity>();    // Opportunity Update List
//             for(VirtualAccount__c va : [
//                 SELECT Id, Account__c, Opportunity__c
//                 FROM VirtualAccount__c
//                 WHERE Id IN: vaMap.keySet()
//             ]) {
//                 Map<String, String> inputMap = new Map<String, String>();   // Call KakaoTalk 변수
//                 inputMap.put('recordId', va.Id);
//                 inputMap.put('accId', va.Account__c);
//                 callKakaoTalk(inputMap);
                
//                 Opportunity oppty = new Opportunity(Id = va.Opportunity__c);
//                 oppty.VirtualAccount__c = va.Id;
                
//                 updateOpptyList.add(oppty);

//                 accountIdList.add(va.Account__c);
//             }
                
//             if(!updateOpptyList.isEmpty()) update updateOpptyList;
//             if(!usedVAMList.isEmpty()) update usedVAMList;
//         }
//         if(!requestContractList.isEmpty()) update requestContractList;

//         Map<String, Object> infoMap = new Map<String, Object>{
//                 'sendType' => AsyncVAInfo.SEND_TYPE.O,
//                 'isChain' => true
//         };
//         System.enqueueJob(new AsyncCustomerInfo(accountIdList, infoMap));
//     }

//     @Future(Callout=true)
//     private static void callKakaoTalk(Map<String, String> inputMap){
//         List<Object> infoMapList = new List<Object>();

//         Map<Object,Object> objNameMap = new Map<Object,Object>{
//             'objectName' => 'Account',
//             'recordId' => inputMap.get('accId') // 실제 사용
//             // 'recordId' => '001H200001ZKbj8IAD' // < 테스트용 카톡 수신자 (도채범)
//         };
//         infoMapList.add(objNameMap);
        
//         Map<String, Object> InfoMap = new Map<String, Object>{
//             'templateTitle' => '가상계좌정보 전송2',
//             'object' => 'VirtualAccount__c',
//             'recordId' => inputMap.get('recordId'),
//             'infoMapList' => infoMapList,
//             'externalId' => inputMap.get('accId')
//         };
//         InterfaceKakao.doCallOutKakaoAlimTalk(InfoMap);
//     }
}