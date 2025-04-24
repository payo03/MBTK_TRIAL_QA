/**
* @Author            : chaebeom.do@solomontech.net
* @Description 		 : 계약 재협상 / 계약 취소(실주/반품) 버튼 클릭시 그 동안 진행된 내용에 따른 데이터 상태 변경 및 롤백 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-20      chaebeom.do@solomontech.net      Created
  1.1      2025-04-18      chaebeom.do@solomontech.net      계약 취소시 사유 선택 목록 입력 기능 추가
*/
public without sharing class ContractCancelController {
    
    @AuraEnabled
    public static Opportunity init(String recordId) {

        Opportunity oppty = [
            SELECT Contract.ContractNumber
            FROM Opportunity 
            WHERE Id = :recordId
        ];
        return oppty;
    }

    //ver 1.1
    @AuraEnabled
    public static Map<String, List<String>> getPicklistValues(String objectName, List<String> fieldNames) {

        Map<String, List<String>> result = new Map<String, List<String>>();

        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        if (sObjectType == null) return result;

        Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();

        for (String fieldName : fieldNames) {
            List<String> picklistValues = new List<String>();
            if (describeResult.fields.getMap().containsKey(fieldName)) {
                Schema.DescribeFieldResult fieldResult = describeResult.fields.getMap().get(fieldName).getDescribe();
                for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                    picklistValues.add(entry.getLabel()); // 또는 entry.getValue()
                }
            }
            result.put(fieldName, picklistValues);
        }

        return result;
    }

    @AuraEnabled
    public static void cancelByCase(String type, String opptyId, Map<String, List<String>> selectedValues) {

        Opportunity opp = [
            SELECT Id, VehicleStock__c, StageName, ContractId, TaxInvoiceNumber__c, AccountId, TaxInvoiceDate__c
            FROM Opportunity
            WHERE Id = :opptyId
            ];
        Contract targetContract = [
            SELECT Id, ApprovalStatus__c, Quote__c
            FROM Contract
            WHERE Id = :opp.ContractId
        ];
        List<VehicleStock__c> vehicle = [
            SELECT Id, PDIStepProgress__c, VehicleStatus__c
            FROM VehicleStock__c
            WHERE Id = :opp.VehicleStock__c
        ];
        List<VirtualAccount__c> virtualAccount = [
            SELECT Id, VirtualAccountMaster__c, VirtualAccountMaster__r.Status__c
            FROM VirtualAccount__c
            WHERE Account__c = :opp.AccountId
            AND IsValid__c = true
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        List<PDIStep__c> canceledPDI = new List<PDIStep__c>();  
        String beforeOppStage = opp.StageName;
        Date targetTaxDate = opp.TaxInvoiceDate__c;
        try {
            if(type == 'Renegotiation') {
                opp.StageName = 'Negotiation';
                opp.IsRenegotiation__c = true;
            } 
            opp.ContractId = null;
            if(type == 'closedLost' || type == 'returnVehicle') {
                opp.StageName = 'Closed Lost';
                //ver1.1 계약 취소시 취소 사유 입력
                if (selectedValues.containsKey('CompetitorSelection__c')) {
                    opp.CompetitorSelection__c = String.join(selectedValues.get('CompetitorSelection__c'), ';');
                }
                if (selectedValues.containsKey('EconomicReasons__c')) {
                    opp.EconomicReasons__c = String.join(selectedValues.get('EconomicReasons__c'), ';');
                }
                if (selectedValues.containsKey('PersonalReasons__c')) {
                    opp.PersonalReasons__c = String.join(selectedValues.get('PersonalReasons__c'), ';');
                }
                if (selectedValues.containsKey('TechnicalReasons__c')) {
                    opp.TechnicalReasons__c = String.join(selectedValues.get('TechnicalReasons__c'), ';');
                }        
            }
            if(targetContract.ApprovalStatus__c == '제출됨') {
                //계약에 걸려있는 승인 프로세스 회수됨으로 변경
                ProcessInstanceWorkitem pendingContract = [
                    SELECT Id
                    FROM ProcessInstanceWorkitem
                    WHERE ProcessInstance.TargetObjectId = :targetContract.Id
                ];
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setComments('계약 취소');
                req.setAction('Removed');
                req.setWorkitemId(pendingContract.Id);
                Approval.ProcessResult result = Approval.process(req);
            } else if(targetContract.ApprovalStatus__c == '승인됨') {
                List<PDIStep__c> pdiStatus = [
                    SELECT Id, IsPass__c
                    FROM PDIStep__c
                    WHERE VehicleStock__c = :opp.VehicleStock__c
                    AND (Stage__c = 'STEP3'
                    OR Stage__c = 'STEP4'
                    OR Stage__c = 'STEP5')
                ];
                // 세금계산서 롤백
                if(opp.TaxInvoiceNumber__c != null) TaxInvoiceSchedulerController.callTaxInvoice(opptyId, false);
                opp.TaxInvoiceNumber__c = null;
                opp.TaxInvoiceDate__c = null;
                // PDI 단계 해제 > 차량이 재배정 될 수 있으니 실제 스포일러는 탈거하지 않고 두고, 추후 재배정시 옵션 내용에 따라 재작업
                for(PDIStep__c pdi : pdiStatus) {
                    pdi.IsPass__c = false;
                    pdi.StepWorker__c = null;
                    pdi.StepStart__c = null;
                    pdi.StepEnd__c = null;
                    canceledPDI.add(pdi);
                }
                if(opp.VehicleStock__c != null) {
                    vehicle[0].SpoilerResultMessage__c = '계약 취소 차량 - 추후 재배정시 설치 / 제거 (SAP) 처리 필요';
                    // 차량배정 해제(기회와 연결 제거)
                    vehicle[0].VehicleStatus__c = type == 'returnVehicle' ? '출고불가' : '판매준비완료';
                    opp.VehicleStock__c = null;
                    // 차량배정 해제(SAP 재고 이동 취소) -> Opportunity_tr에서 처리하기 때문에 여기서 추가 작업 필요 없음
                } 
                String targetModuSignCondition = 'AND (Status__c != \'ABORTED\' OR Status__c != \'COMPLETED\') AND Contract__c = \'' + targetContract.Id + '\'';
                Database.executeBatch(new CancelRequestModuSign_ba(targetModuSignCondition), 4);
                
                if(virtualAccount.size() > 0 && (type == 'closedLost' || type == 'returnVehicle')) {
                    // 가상계좌 할당 해제?
                    update new VirtualAccount__c(Id = virtualAccount[0].Id, IsValid__c = false);
                    update new VirtualAccountMaster__c(Id = virtualAccount[0].VirtualAccountMaster__c, Status__c = '사용가능');
                }

            }
            update opp;
            update new Quote(Id = targetContract.Quote__c, Status = 'Canceled');
            if(targetContract.ApprovalStatus__c == '승인됨') {
                if(beforeOppStage == 'Closed Won') {
                    // 인센티브 취소 배치
                    AnnualIncentiveCalculation_ba annualBatch = new AnnualIncentiveCalculation_ba(targetTaxDate);
                    Database.executeBatch(annualBatch);
                    QuarterlyIncentiveCalculation_ba quarterBatch = new QuarterlyIncentiveCalculation_ba(targetTaxDate);
                    Database.executeBatch(quarterBatch);
                    // 굿윌 취소 배치
                    HalfYearlyGoodWillCalculation_ba goodWillBatch = new HalfYearlyGoodWillCalculation_ba(targetTaxDate);
                    Database.executeBatch(goodWillBatch);
                }
                // 공통 작업)
                // 계약 상태 취소
                // 견적 상태 취소
                // 페이먼트트래커 상태 취소
                // 핸드오버 유효하지 않음
                PaymentTracker__c pt = [
                    SELECT Id
                    FROM PaymentTracker__c
                    WHERE Opportunity__c = :opp.Id
                    AND IsValid__c = true
                ];
                Handover__c ho = [
                    SELECT Id
                    FROM Handover__c
                    WHERE Opportunity__c = :opp.Id
                    AND IsActive__c = true
                ];
                update vehicle;
                if(!canceledPDI.isEmpty()) update canceledPDI;
                update new Contract(Id = targetContract.Id, ConStatus__c = '계약 취소');
                update new PaymentTracker__c(Id = pt.Id, IsValid__c = false, Status__c = 'CANCELED');
                update new Handover__c(Id = ho.Id, IsActive__c = false); 
            }
        } catch (Exception e) {
            System.debug('msg >> '+e.getMessage() + ' getStackTraceString >>' + e.getStackTraceString());
            throw new AuraHandledException('취소 중 오류가 발생했습니다. :: ' + e.getStackTraceString());
        }
    }
}