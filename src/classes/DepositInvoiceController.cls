/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-03
 * @description : 계약금 요청시 동작 컨트롤러
 * @target : depositInvoice.js
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-03      chaebeom.do     Created
 * 2.0          2025-03-14      chaebeom.do     사전배정 프로세스 삭제로 인한 이름 변경
 * 3.0          2025-04-29      chaebeom.do     AssignRequest__c 오브젝트 삭제로 인한 클래스 이름 변경 및 로직 수정
**************************************************************/
public without sharing class DepositInvoiceController {
    
    public class depositWrap {
        @AuraEnabled public String accName;
        @AuraEnabled public String accPhone;
        @AuraEnabled public String vehicleName;
        @AuraEnabled public String opportunity;
        @AuraEnabled public String vehicleId;
        @AuraEnabled public String bpCode;
        @AuraEnabled public String businessName;
        @AuraEnabled public String businessNumber;
        @AuraEnabled public String idNumber;

        public depositWrap(String accName, String accPhone, String vehicleName, String opportunity, String vehicleId, String bpCode, String businessName, String businessNumber, String idNumber) {
            this.accName = accName;
            this.accPhone = accPhone;
            this.vehicleName = vehicleName;
            this.opportunity = opportunity;
            this.vehicleId = vehicleId;
            this.bpCode = bpCode;
            this.businessName = businessName;
            this.businessNumber = businessNumber;
            this.idNumber = idNumber;
        }
    }

    @AuraEnabled
    public static depositWrap getAcc(String recordId) {

        String selectFields = 'Id, Opportunity__c, Account.Name, Account.PersonMobilePhone, VehicleStock__r.Product__r.Name, VehicleStock__c, Account.BPCode__c, Account.BusinessName__c, Account.BusinessNumber__c, Account.IDNumber__pc';
        String whereConditions = 'Id = \'' + recordId + '\'';
        String query = CommonUtilController.buildQuery(selectFields, 'Contract', whereConditions);

        Contract contract = Database.query(query);

        depositWrap selectedAcc = new depositWrap(
            contract.Account.Name,
            contract.Account.PersonMobilePhone,
            contract.VehicleStock__r.Product__r.Name,
            contract.Opportunity__c,
            contract.VehicleStock__c,
            contract.Account.BPCode__c,
            contract.Account.BusinessName__c,
            contract.Account.BusinessNumber__c,
            contract.Account.IDNumber__pc
        );
        return selectedAcc;
    }

    @AuraEnabled
    public static Map<String, String> assignVirtualAccount(Map<String, String> inputMap) {

        Map<String, String> returnMap = new Map<String, String>();
        
        List<VirtualAccountMaster__c> validVAMList = [
                SELECT Id
                FROM VirtualAccountMaster__c
                WHERE Status__c = '사용가능'
                ORDER BY Name DESC LIMIT 1
        ];
        if(validVAMList.size() == 0) throw new AuraHandledException('No Virtual Account In Available Error. Contact Admin.');

        Opportunity curOppty = [
            SELECT Id, AccountId, Account.Name, ContractId
            FROM Opportunity
            WHERE Id = :inputMap.get('opptyId')
        ];

        List<VirtualAccount__c> assignVAList = new List<VirtualAccount__c>();               // 가상계좌 Junction 생성 List
        List<VirtualAccountMaster__c> usedVAMList = new List<VirtualAccountMaster__c>();    // 가상계좌 마스터 Update List
        List<Contract> requestContractList = new List<Contract>();                          // 계약 Update List
        List<String> accountIdList = new List<String>();                                    // 할당된 고객 Id Set
        // Map<String, VirtualAccount__c> accountVAMap = new Map<String, VirtualAccount__c>(); // 고객에 할당중인 가상계좌 Map
        // for(VirtualAccount__c activeVA : [
        //     SELECT Id, Account__c, Opportunity__c
        //     FROM VirtualAccount__c
        //     WHERE IsValid__c = true
        // ]) {
        //     accountVAMap.put(activeVA.Account__c, activeVA);
        // }

        List<VirtualAccount__c> existingVAList = [
            SELECT Id, Account__c
            FROM VirtualAccount__c
            WHERE IsValid__c = true
            AND Opportunity__c = :inputMap.get('opptyId')
        ];

        if(!existingVAList.isEmpty()) {  // 기존 할당된 VA가 있을 경우 해당 정보 반환  
            VirtualAccount__c matchedVA = existingVAList[0]; // 기회 : VA = 1 : 1
            returnMap.put('recordId', matchedVA.Id);
            returnMap.put('accId', matchedVA.Account__c);

        // if(accountVAMap.containsKey(curOppty.AccountId)) {  // 기존 할당 고객 Case.  
        //     returnMap.put('recordId', accountVAMap.get(curOppty.AccountId).Id);
        //     returnMap.put('accId', accountVAMap.get(curOppty.AccountId).Account__c);
        } else {
            String validVamId = validVAMList.get(0).Id;
            Map<String, Object> paramMap = new Map<String, Object>{
                    'opportunity' => curOppty,
                    'virtualAccountMasterId' => validVamId,
                    'depositAmount' => 1000000,
                    'validDate' => Date.today().addMonths(6)
            };
            // VirtualAccount생성
            VirtualAccount__c assignVA = CommonUtilCustomController.createVirtualAccount(paramMap);
            assignVAList.add(assignVA);
            // 사용한 VAM 할당중 변경
            VirtualAccountMaster__c usedVAM = new VirtualAccountMaster__c(Id = validVamId);
            usedVAM.Status__c = '할당중';
            usedVAMList.add(usedVAM);

            if (!assignVAList.isEmpty()) {
                // Insert 성공한 데이터들만 카카오톡 전송
                Map<String, Map<String, Object>> resultMap = CommonUtilController.applyObject(assignVAList, 'INSERT');
                Map<String, Object> vaMap = resultMap.get('SUCCESS');
                
                List<Opportunity> updateOpptyList = new List<Opportunity>();    // Opportunity Update List
                for(VirtualAccount__c va : [
                    SELECT Id, Account__c, Opportunity__c
                    FROM VirtualAccount__c
                    WHERE Id IN: vaMap.keySet()
                ]) {
                    returnMap.put('recordId', va.Id);
                    returnMap.put('accId', va.Account__c);
                    
                    Opportunity oppty = new Opportunity(Id = va.Opportunity__c);
                    oppty.VirtualAccount__c = va.Id;
                    
                    updateOpptyList.add(oppty);
    
                    accountIdList.add(va.Account__c);
                }
                    
                if(!updateOpptyList.isEmpty()) update updateOpptyList;
                if(!usedVAMList.isEmpty()) update usedVAMList;
                Map<String, Object> infoMap = new Map<String, Object>{
                        'sendType' => AsyncVAInfo.SEND_TYPE.O,
                        'isChain' => true
                };
                System.enqueueJob(new AsyncCustomerInfo(accountIdList, infoMap));
            }
        }

        return returnMap;
    }

    @AuraEnabled
    public static void updateContract(String recordId){
        try {
            // Contract 상태 Update
            Contract contract = new Contract(Id = recordId);
            contract.CheckDepositRequest__c = true;
            contract.FirstDepositRequestDate__c = Date.today();
            update contract;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}