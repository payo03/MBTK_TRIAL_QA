/**
* @Author            : chaebeom.do@solomontech.net
* @Description 		 : 계약 재협상 / 계약 취소(실주/반품) 버튼 클릭시 그 동안 진행된 내용에 따른 데이터 상태 변경 및 롤백 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-20      chaebeom.do@solomontech.net      Created
  1.1      2025-04-18      chaebeom.do@solomontech.net      계약 취소시 사유 선택 목록 입력 기능 추가
  1.2      2025-05-09      chaebeom.do@solomontech.net      계약 재협상/취소시 출고일 배정 오브젝트 비활성화 추가
  1.3      2025-05-12      chaebeom.do@solomontech.net      기회 Closed Won일때 계약 취소시 차량재고 Status, VehicleStatus 업데이트 
  1.4      2025-05-19      chaebeom.do@solomontech.net      계약 취소시 사유 선택 목록 입력 기능에 실주 사유, 실패 사유 작성 추가 
*/
public without sharing class ContractCancelController {
    
    @AuraEnabled
    public static Opportunity init(String recordId) {

        Opportunity oppty = [
            SELECT Contract.ContractNumber, StageName, OpportunityCancelStatus__c
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


    public static void cancelByCaseList(List<Map<String, Object>> cancelMapList, Boolean isAll) {

        Map<String, Object> opptyInfoMap = new Map<String, Object>();
        for(Map<String, Object> cancelMap : cancelMapList) {
            String opptyId = String.valueOf(cancelMap.get('opptyId'));

            opptyInfoMap.put(opptyId, cancelMap);
        }
        Map<String, Contract> opptyContractMap = new Map<String, Contract>();
        Map<String, VehicleStock__c> opptyStockMap = new Map<String, VehicleStock__c>();
        Map<String, VirtualAccount__c> opptyVAMap = new Map<String, VirtualAccount__c>();
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity>([
                SELECT Id, VehicleStock__c,
                        StageName, ContractId, TaxInvoiceNumber__c, AccountId, TaxInvoiceDate__c,
                        VehicleStock__r.PDIStepProgress__c, VehicleStock__r.VehicleStatus__c,
                        Contract.ApprovalStatus__c, Contract.Quote__c,
                        (
                                SELECT Id, VirtualAccountMaster__c, VirtualAccountMaster__r.Status__c
                                FROM vaOpp__r
                                WHERE IsValid__c = TRUE
                                ORDER BY CreatedDate DESC
                                LIMIT 1
                        )
                FROM Opportunity
                WHERE Id IN :opptyInfoMap.keySet()
        ]);

        Map<String, PaymentTracker__c> opptyTrackerMap = new Map<String, PaymentTracker__c>();
        for(PaymentTracker__c tracker : [
                SELECT Id, Opportunity__c, Status__c, IsValid__c, StatusBeforeCancel__c
                FROM PaymentTracker__c
                WHERE Opportunity__c IN :opptyMap.keySet()
                AND IsValid__c = TRUE
        ]) {
            String key = tracker.Opportunity__c;
            opptyTrackerMap.put(key, tracker);
        }
        
        Map<String, Handover__c> opptyHandoverMap = new Map<String, Handover__c>();
        for(Handover__c handover : [
                SELECT Id, Opportunity__c
                FROM Handover__c
                WHERE Opportunity__c IN :opptyMap.keySet()
                AND IsActive__c = TRUE
        ]) {
            String key = handover.Opportunity__c;
            opptyHandoverMap.put(key, handover);
        }
        
        Map<String, List<HandoverDateAllocationHistory__c>> opptyHistoryMap = new Map<String, List<HandoverDateAllocationHistory__c>>();
        for(HandoverDateAllocationHistory__c history : [
                SELECT Id, Opportunity__c
                FROM HandoverDateAllocationHistory__c
                WHERE Opportunity__c IN :opptyMap.keySet()
                AND IsAssign__c = TRUE
        ]) {
            String key = history.Opportunity__c;
            
            List<HandoverDateAllocationHistory__c> historyList = opptyHistoryMap.containsKey(key) 
                    ? opptyHistoryMap.get(key)
                    : new List<HandoverDateAllocationHistory__c>();
            
            historyList.add(history);
            opptyHistoryMap.put(key, historyList);
        }

        List<String> vehicleStockList = new List<String>();
        List<String> contractList = new List<String>();
        for(Opportunity oppty : opptyMap.values()) {
            opptyContractMap.put(oppty.Id, oppty.Contract);
            opptyStockMap.put(oppty.Id, oppty.VehicleStock__r);
            if(!oppty.vaOpp__r.isEmpty()) {
                opptyVAMap.put(oppty.Id, oppty.vaOpp__r.get(0));
            }

            contractList.add(oppty.ContractId);
            vehicleStockList.add(oppty.VehicleStock__c);
        }

        Map<String, ProcessInstanceWorkitem> contractItemMap = new Map<String, ProcessInstanceWorkitem>();
        for(ProcessInstanceWorkitem item : [
                SELECT Id, ProcessInstance.TargetObjectId
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId IN :contractList
        ]) {
            contractItemMap.put(item.ProcessInstance.TargetObjectId, item);
        }

        Map<String, List<PDIStep__c>> stockStepListMap = new Map<String, List<PDIStep__c>>();
        for(PDIStep__c step : [
                SELECT Id, VehicleStock__c, IsPass__c
                FROM PDIStep__c
                WHERE VehicleStock__c IN :vehicleStockList
                AND (Stage__c = 'STEP3'
                OR Stage__c = 'STEP4'
                OR Stage__c = 'STEP5')
        ]) {
            String key = step.VehicleStock__c;

            List<PDIStep__c> stepList = stockStepListMap.containsKey(key)
                    ? stockStepListMap.get(key)
                    : new List<PDIStep__c>();
            stockStepListMap.put(key, stepList);
        }

        List<String> contractIdList = new List<String>();
        List<String> opptyIdList = new List<String>();
        List<Date> taxInvoiceDateList = new List<Date>();

        List<Opportunity> opptyUpdateList = new List<Opportunity>();
        List<PDIStep__c> stepUpdateList = new List<PDIStep__c>();
        List<VehicleStock__c> stockUpdateList = new List<VehicleStock__c>();
        List<VirtualAccount__c> vaUpdateList = new List<VirtualAccount__c>();
        List<Contract> contractUpdateList = new List<Contract>();
        List<Quote> quoteUpdateList = new List<Quote>();
        List<PaymentTracker__c> trackerUpdateList = new List<PaymentTracker__c>();
        List<Handover__c> handoverUpdateList = new List<Handover__c>();
        List<HandoverDateAllocationHistory__c> historyUpdateList = new List<HandoverDateAllocationHistory__c>();

        List<Approval.ProcessRequest> requestList = new List<Approval.ProcessRequest>();
        try {
            for (Opportunity oppty : opptyMap.values()) {
                Map<String, Object> cancelInfoMap = (Map<String, Object>) opptyInfoMap.get(oppty.Id);
                System.debug('체크 oppty :: ' + oppty.Id);
                System.debug('체크 cancelInfoMap :: ' + cancelInfoMap);
                
                String type = String.valueOf(cancelInfoMap.get('type'));
                String opptyId = String.valueOf(cancelInfoMap.get('opptyId'));
                String beforeOppStage = oppty.StageName;
                Date targetTaxDate = oppty.TaxInvoiceDate__c;

                Map<String, Object> objMap = (Map<String, Object>) cancelInfoMap.get('selectedValues');
                Map<String, List<String>> selectedValueListMap = new Map<String, List<String>>();
                if(objMap != null) {
                    for(String key : objMap.keySet()) {
                        List<Object> objList = (List<Object>) objMap.get(key);

                        List<String> selectedValueList = new List<String>();
                        for(Object obj : objList) {
                            selectedValueList.add(String.valueOf(obj));
                        }
                        selectedValueListMap.put(key, selectedValueList);
                    }
                }

                Contract contract = opptyContractMap.get(opptyId);
                VirtualAccount__c vaAccount = opptyVAMap.get(opptyId);
                VehicleStock__c stock = opptyStockMap.get(opptyId);

                Quote quote = new Quote(Id = contract.Quote__c, Status = 'Canceled');
                quoteUpdateList.add(quote);

                if(type == 'Renegotiation') {
                    oppty.StageName = 'Negotiation';
                    oppty.IsRenegotiation__c = true;
                }

                oppty.ContractId = null;
                if(type == 'closedLost' || type == 'returnVehicle') {
                    oppty.StageName = 'Closed Lost';
                    //ver1.1 계약 취소시 취소 사유 입력
                    if (selectedValueListMap.containsKey('CompetitorSelection__c')) {
                        oppty.CompetitorSelection__c = String.join(selectedValueListMap.get('CompetitorSelection__c'), ';');
                    }
                    if (selectedValueListMap.containsKey('EconomicReasons__c')) {
                        oppty.EconomicReasons__c = String.join(selectedValueListMap.get('EconomicReasons__c'), ';');
                    }
                    if (selectedValueListMap.containsKey('PersonalReasons__c')) {
                        oppty.PersonalReasons__c = String.join(selectedValueListMap.get('PersonalReasons__c'), ';');
                    }
                    if (selectedValueListMap.containsKey('TechnicalReasons__c')) {
                        oppty.TechnicalReasons__c = String.join(selectedValueListMap.get('TechnicalReasons__c'), ';');
                    }
                    //ver1.4 계약 취소시 실주 사유, 실패 사유 작성 필드 추가 
                    oppty.LostReasonType__c = String.valueOf(selectedValueListMap.get('LostReasonType__c')[0]);
                    oppty.LostReasonText__c = String.valueOf(selectedValueListMap.get('LostReasonText__c')[0]);
                }

                switch on contract.ApprovalStatus__c {
                    when '제출됨' {
                        //계약에 걸려있는 승인 프로세스 회수됨으로 변경

                        ProcessInstanceWorkitem pendingContract = contractItemMap.get(contract.Id);
                        Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                        request.setComments('계약 취소');
                        request.setAction('Removed');
                        request.setWorkitemId(pendingContract.Id);

                        requestList.add(request);
                    }
                    when '승인됨' {
                        // 세금계산서 롤백
                        if(oppty.TaxInvoiceNumber__c != null) opptyIdList.add(opptyId);
                        oppty.TaxInvoiceNumber__c = null;
                        oppty.TaxInvoiceDate__c = null;

                        if(stock != null) {
                            List<PDIStep__c> pdiStepList = stockStepListMap.get(stock.Id);
                            // PDI 단계 해제 > 차량이 재배정 될 수 있으니 실제 스포일러는 탈거하지 않고 두고, 추후 재배정시 옵션 내용에 따라 재작업
                            for(PDIStep__c pdiStep : pdiStepList) {
                                pdiStep.IsPass__c = false;
                                pdiStep.StepWorker__c = null;
                                pdiStep.StepStart__c = null;
                                pdiStep.StepEnd__c = null;

                                stepUpdateList.add(pdiStep);
                            }
                            stock.SpoilerResultMessage__c = '계약 취소 차량 - 추후 재배정시 설치 / 제거 (SAP) 처리 필요';
                            // 차량배정 해제(기회와 연결 제거)
                            stock.Status__c = beforeOppStage == 'Closed Won' ? '재고 미노출(임시)' : '재고 노출';
                            stock.VehicleStatus__c = beforeOppStage == 'Closed Won' ? '출고불가' : '판매준비완료';

                            stockUpdateList.add(stock);

                            oppty.VehicleStock__c = null;
                            oppty.HandoverDate__c = null; // ver 1.2
                            // 250512 추가 - 도채범
                            if(beforeOppStage == 'Closed Won') {
                                oppty.IncentiveHistoryAnnual__c = null;
                                oppty.IncentiveHistoryQuarterly__c = null;
                            }
                        }
                        contractIdList.add(contract.Id);

                        if(vaAccount != null && (type == 'closedLost' || type == 'returnVehicle')) {
                            // 가상계좌 할당 해제?
                            vaAccount.ExpireDate__c = Date.today();
                            vaUpdateList.add(vaAccount);
                        }

                        PaymentTracker__c tracker = opptyTrackerMap.get(opptyId);
                        Handover__c handover = opptyHandoverMap.get(opptyId);
                        List<HandoverDateAllocationHistory__c> historyList = opptyHistoryMap.get(opptyId);

                        // 공통 작업
                        // 계약 상태 취소
                        // 견적 상태 취소
                        // 페이먼트트래커 상태 취소
                        // 핸드오버 유효하지 않음
                        // ver1.2 출고일 배정 유효하지 않음


                        contract.ConStatus__c = '계약 취소';
                        contractUpdateList.add(contract);

                        if(tracker != null) {
                            tracker.IsValid__c = false;
                            tracker.StatusBeforeCancel__c = tracker.Status__c;
                            tracker.Status__c = 'CANCELED';
                            trackerUpdateList.add(tracker);
                        }

                        if(handover != null) {
                            handover.IsActive__c = false;
                            handoverUpdateList.add(handover);
                        }

                        if(historyList != null) {
                            for(HandoverDateAllocationHistory__c history : historyList) {
                                history.IsAssign__c = false;
                            }
                            historyUpdateList.addAll(historyList);
                        }
                    }
                }
                opptyUpdateList.add(oppty);

                if(contract.ApprovalStatus__c == '승인됨') {
                    if(beforeOppStage == 'Closed Won') taxInvoiceDateList.add(targetTaxDate);
//                    if(beforeOppStage == 'Closed Won') {
//                        // 인센티브 취소 배치
//                        // 의미 : targetTaxDate가 포함된 연도 or 분기에 존재하는 인센티브 or 커미션(미정)을 덮는다. + 굿윌도 덮음
//                        AnnualIncentiveCalculation_ba annualBatch = new AnnualIncentiveCalculation_ba(targetTaxDate);
//                        Database.executeBatch(annualBatch);
//                        QuarterlyIncentiveCalculation_ba quarterBatch = new QuarterlyIncentiveCalculation_ba(targetTaxDate);
//                        Database.executeBatch(quarterBatch);
//                        // 굿윌 취소 배치
//                        HalfYearlyGoodWillCalculation_ba goodWillBatch = new HalfYearlyGoodWillCalculation_ba(targetTaxDate);
//                        Database.executeBatch(goodWillBatch);
//                    }
                }
            }
            if(!opptyUpdateList.isEmpty()) update opptyUpdateList;
            if(!stepUpdateList.isEmpty()) update stepUpdateList;
            if(!stockUpdateList.isEmpty()) update stockUpdateList;
            if(!vaUpdateList.isEmpty()) update vaUpdateList;
            if(!contractUpdateList.isEmpty()) update contractUpdateList;
            if(!trackerUpdateList.isEmpty()) update trackerUpdateList;
            if(!handoverUpdateList.isEmpty()) update handoverUpdateList;
            if(!historyUpdateList.isEmpty()) update historyUpdateList;
            if(!quoteUpdateList.isEmpty()) update quoteUpdateList;


            if(!isAll) {
                String moduSignCondition = '' +
                    'AND (Status__c != \'ABORTED\' OR Status__c != \'COMPLETED\') ' +
                    'AND Contract__c IN ' + CommonUtilController.joinedString(contractIdList);

                Database.executeBatch(new CancelRequestModuSign_ba(moduSignCondition), 4);

                Map<String, Object> paramMap = new Map<String, Object>();
                paramMap.put('isCreate', false);	// 세금계산서 취소시 false
                if(!opptyIdList.isEmpty()) System.enqueueJob(new AsyncTaxInvoiceIssuance(opptyIdList, paramMap));

                Set<Date> yearStartSet = new Set<Date>();
                Set<Date> quarterStartSet = new Set<Date>();
                Set<Date> halfYearStartSet = new Set<Date>();
                for (Date taxInvoiceDate : taxInvoiceDateList) {
                    // 인센티브 취소 배치
                    // 의미 : targetTaxDate가 포함된 연도 or 분기에 존재하는 인센티브 or 커미션(미정)을 덮는다. + 굿윌도 덮음

                    Integer year = taxInvoiceDate.year();
                    Integer month = taxInvoiceDate.month();

                    // 연도 시작일 (1월 1일)
                    Date yearStartDate = Date.newInstance(year, 1, 1);
                    yearStartSet.add(yearStartDate);

                    // 분기 시작일
                    Integer quarter = ((month - 1) / 3) + 1;
                    Integer quarterStartMonth = ((quarter - 1) * 3) + 1;
                    Date quarterStartDate = Date.newInstance(year, quarterStartMonth, 1);
                    quarterStartSet.add(quarterStartDate);

                    // 반기 시작일 (1월 or 7월)
                    Integer halfStartMonth = (month <= 6) ? 1 : 7;
                    Date halfYearStartDate = Date.newInstance(year, halfStartMonth, 1);
                    halfYearStartSet.add(halfYearStartDate);

                }
                // 정렬된 리스트로 변환
                List<Date> yearStartDates = new List<Date>();
                yearStartDates.addAll(yearStartSet);
                yearStartDates.sort();

                List<Date> quarterStartDates = new List<Date>();
                quarterStartDates.addAll(quarterStartSet);
                quarterStartDates.sort();

                List<Date> halfYearStartDates = new List<Date>();
                halfYearStartDates.addAll(halfYearStartSet);
                halfYearStartDates.sort();

                for (Date targetTaxDate : yearStartDates) {
                    AnnualIncentiveCalculation_ba annualBatch = new AnnualIncentiveCalculation_ba(targetTaxDate);
                    Database.executeBatch(annualBatch);
                }
                for (Date targetTaxDate : quarterStartDates) {
                    QuarterlyIncentiveCalculation_ba quarterBatch = new QuarterlyIncentiveCalculation_ba(targetTaxDate);
                    Database.executeBatch(quarterBatch);
                }
                for (Date targetTaxDate : halfYearStartDates) {
                    // 굿윌 취소 배치
                    HalfYearlyGoodWillCalculation_ba goodWillBatch = new HalfYearlyGoodWillCalculation_ba(targetTaxDate);
                    Database.executeBatch(goodWillBatch);
                }
            }
        } catch(Exception e) {
            System.debug('msg >> '+e.getMessage() + ' getStackTraceString >>' + e.getStackTraceString());
            throw new CustomException('취소 중 오류가 발생했습니다. :: ' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static void cancelByCase(String type, String opptyId, Map<String, List<String>> selectedValues) {

        String opportunityId;
        opportunityId = opptyId.length() == 15 ? CommonUtilController.convert15to18DigitId(opptyId) : opptyId;
        Map<String, Object> paramMap = new Map<String, Object>();
        paramMap.put('type', type);
        paramMap.put('opptyId', opportunityId);
        paramMap.put('selectedValues', selectedValues);

        cancelByCaseList(new List<Map<String, Object>> {paramMap}, false);
    }

    @AuraEnabled
    public static string createCancelApprovalProcess(String opptyId) {
        try {
            // Create an approval request for the contract
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('계약 취소 요청_' + System.today());
            req.setObjectId(opptyId);
            // Submit the record to the existing process named PTO_Reqwuest_Process
            req.setProcessDefinitionNameOrId('ContractCancelVehicleReturn');
            // Submit the approval request for the contract
            Approval.ProcessResult result = Approval.process(req);
            System.debug(result);
            return '승인 요청이 완료되었습니다.';
        } catch (Exception e) {
            System.debug('e =>'+e.getMessage());
            return 'error';
        }
    }
}