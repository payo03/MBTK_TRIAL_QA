/**
* @Author            : payo03@solomontech.net
* @Description 		 :
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-08      payo03@solomontech.net           Created
  1.1      2025-01-10      San.Kang                         Updated
  1.2      2025-01-24      th.kim                           updateHandover 추가
  1.3      2025-02-17      payo03@solomontech.net           VehicleStock 가용가능한 record로 Update
  1.4      2025-03-07      payo03@solomontech.net           VehicleStock 자동배정 조건필드 추가(VehicleStatus)
  1.5      2025-03-13      payo03@solomontech.net           차량 배정 Process. 재고이동요청 CALL
  1.6      2025-03-13      payo03@solomontech.net           재고이동요청 CALL After Update로 분리
  1.7      2025-03-21      San.Kang                         개인정보 미동의 시 필드 락 로직 추가
  1.8      2025-03-31      chaebeom.do                      인도금 유예 신규추가시 금액 재조정 insert
  1.9      2025-04-16      th.kim                           updateIncentiveHistory() 추가
  1.10     2025-04-16      th.kim                           부가세 유예일 수 기회에 업데이트 추가
  1.11     2025-04-18      payo03@solomontech.net           주민등록증 세금계산서 발행여부 완료시 고객정보전송
*/
global without sharing class Opportunity_tr extends TriggerHandler {

    private final List<Opportunity> newList { get; set; }
    private final List<Opportunity> oldList { get; set; }
    private final Map<Id, Opportunity> newMap { get; set; }
    private final Map<Id, Opportunity> oldMap { get; set; }

    private final Map<String, String> opptyStockIdMap { get; set; }
    private final Map<String, List<Id>> VATDeferredListMap { get; set; }
    private final Map<String, List<Id>> PaymentDeferredListMap { get; set; }
    private final List<Map<String, Object>> requestStockMapList { get; set; }
    private final List<String> IDNumberUpdateList { get; set; }


    private final static List<String> updateStatusList = new List<String>{
            '승인됨', '반려됨'
    };

    public Opportunity_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap = (Map<Id, Opportunity>) Trigger.newMap;
        oldMap = (Map<Id, Opportunity>) Trigger.oldMap;

        if (Trigger.isUpdate && Trigger.isBefore) {
            opptyStockIdMap = getUpdateStockMap();
        }

        if (Trigger.isUpdate && Trigger.isAfter) {
            VATDeferredListMap = getDeferredListMap('VATDefermentStatus__c');
            PaymentDeferredListMap = getDeferredListMap('PaymentDefermentStatus__c');
            requestStockMapList = getRequestStockMapList();     // ver1.6 재고이동요청 CALL After Update로 분리
            IDNumberUpdateList = getIDNumberUpdateList();       // ver1.11 주민등록증 세금계산서 발행여부 완료시 고객정보전송
        }
    }

    public override void beforeUpdate() {
        if (!opptyStockIdMap.isEmpty()) doUpdateAvailableStock();
    }

    public override void afterInsert() {
//        udpateName();
//        updateCustomerConsent();
    }
    public override void afterUpdate() {
        updateCustomerConsent();
        // LightConsent 큐 삭제 후 Full Consent 발송
        sendFullConsent();
        // 개인정보 고객 미동의 필드 락 로직
        consentFieldLock();
        // 기회 필드 업데이트 시 Handover 트리거 실행
        updateHandover();

        updateIncentiveHistory();

        // 승인 완료 Process
        if (!VATDeferredListMap.isEmpty()) approvalAfterProcess(VATDeferredListMap, 'VATDeferred');
        if (!PaymentDeferredListMap.isEmpty()) approvalAfterProcess(PaymentDeferredListMap, 'PaymentDeferred');
        if (!requestStockMapList.isEmpty()) System.enqueueJob(new AsyncStockRequest(requestStockMapList));          // ver1.6 재고이동요청 CALL After Update로 분리

        Map<String, Object> infoMap = new Map<String, Object>{
                'isChain' => false
        };
        if (!IDNumberUpdateList.isEmpty()) System.enqueueJob(new AsyncCustomerInfo(IDNumberUpdateList, infoMap));   // ver1.11 주민등록증 세금계산서 발행여부 완료시 고객정보전송
    }

    // 2025.01.10 프로세스 추가될 예정
    private static void approvalAfterProcess(Map<String, List<Id>> VATDeferredListMap, String approvalType) {
        // A. 유예요청 Object Update
        List<Id> VATdeferredActionList = new List<Id>();
        for (List<Id> VATDeferredList : VATDeferredListMap.values()) {
            VATdeferredActionList.addAll(VATDeferredList);
        }

        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        for (Opportunity obj : [
                SELECT Id, VATDeferredApprover__c, PaymentDeferredApprover1__c, PaymentDeferredApprover2__c,
                        PaymentDeferredApprover3__c, VATDeferredDays__c, (
                        SELECT Id, Comments, StepStatus, ActorId
                        FROM ProcessSteps
                        WHERE StepStatus IN ('Approved', 'Rejected')
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                )
                FROM Opportunity
                WHERE Id IN :VATdeferredActionList
        ]) {
            /* 2025.01.14 Sprint2 리뷰. Validation 해제
            // 승인, 반려자가 명확한지 Validation
            ProcessInstanceHistory process = obj.ProcessSteps.get(0);
            List<String> paymentActorList = new List<String>{obj.PaymentDeferredApprover1__c, obj.PaymentDeferredApprover2__c, obj.PaymentDeferredApprover3__c};
            String VATActorId = obj.VATDeferredApprover__c;

            if(VATActorId == process.ActorId || paymentActorList.contains(process.ActorId)) opportunityMap.put(obj.Id, obj);
            */
            opportunityMap.put(obj.Id, obj);
        }

        // TODO. 유예요청을 각 단계별로 관리해야한다면.... 재설계 필요함(현재설계기준. Comment는 최종 승인-반려에 대한 Comment만 기록)
        List<DefermentRequest__c> requestList = [
                SELECT Id, Opportunity__c, DeferredAmount__c, Comment__c, Status__c, Type__c, RequestDays__c
                FROM DefermentRequest__c
                WHERE Opportunity__c = :opportunityMap.keySet()
                AND Status__c = 'IN_PROGRESS'
                AND Type__c = :approvalType
        ];

        // ver1.8 도채범 인도금 유예 신규추가시 금액 재조정 insert
        Map<String, PaymentType__c> opptyTypeMap = new Map<String, PaymentType__c>();     // KEY : Opportunity, VALUE : PaymentType
        for (PaymentType__c type : [
                SELECT Id, Type__c, RequestAmount__c, PaymentTracker__c, PaymentTracker__r.Opportunity__c
                FROM PaymentType__c
                WHERE PaymentTracker__r.Opportunity__c IN :opportunityMap.keySet()
                AND Type__c = '2_DOWN_PAYMENT'
        ]) {
            opptyTypeMap.put(type.PaymentTracker__r.Opportunity__c, type);
        }

        List<PaymentType__c> upsertTypeList = new List<PaymentType__c>();
        List<Opportunity> updateOpportunityList = new List<Opportunity>();
        for (DefermentRequest__c request : requestList) {
            Opportunity obj = opportunityMap.get(request.Opportunity__c);
            ProcessInstanceHistory process = obj.ProcessSteps.get(0);

            String status;
            switch on process.StepStatus {
                when 'Approved' {
                    status = 'COMPLETED';
                    // ver1.8 도채범 인도금 유예 신규추가시 금액 재조정 insert
                    if (approvalType == 'PaymentDeferred') {

                        PaymentType__c existType = new PaymentType__c();
                        existType.Id = opptyTypeMap.get(obj.Id).Id;
                        // existType.RequestAmount__c -= request.DeferredAmount__c;
                        existType.RequestAmount__c = opptyTypeMap.get(obj.Id).RequestAmount__c - request.DeferredAmount__c;
                        upsertTypeList.add(existType);

                        PaymentType__c newType = new PaymentType__c();
                        newType.Type__c = '3_DEFERRED_PAYMENT';
                        newType.PaymentTracker__c = opptyTypeMap.get(obj.Id).PaymentTracker__c;
                        newType.RequestAmount__c = request.DeferredAmount__c;
                        upsertTypeList.add(newType);

                    }

                    // 부가세 유예일 수 기회에 업데이트 추가 (25-04-16)
                    if (approvalType == 'VATDeferred') {
                        obj.VATDeferredDays__c = request.RequestDays__c;
                        updateOpportunityList.add(obj);
                    }
                }
                when 'Rejected' {
                    status = 'REJECTED';
                }
            }
            request.Status__c = status;
            request.Comment__c = process.Comments;
        }
        update requestList;
        update updateOpportunityList; // 부가세 유예일 수 기회에 업데이트 추가 (25-04-16)
        upsert upsertTypeList;  // ver1.8 도채범 인도금 유예 신규추가시 금액 재조정 insert
    }

    /**
     * @author th.kim
     * @description Oppty 데이터 업데이트 시 핸드오버도 트리거 태워주기 위한 메서드
     */
    private void updateHandover() {

        List<Handover__c> handoverList = [SELECT Id FROM Handover__c WHERE Opportunity__c IN :newMap.keySet()];
        update handoverList;
    }

    // ver1.3 VehicleStock 가용가능한 record로 Update
    private void doUpdateAvailableStock() {
        /*
            변수정리
            opptyStockIdMap : Init을 통해 생성
                Key     : OpportunityId
                Value   : VehicleStockId(지정값)
            stockIdMap : VehicleStock의 Map.
                Key     : VehicleStockId
                Value   : VehicleStock
            stockProductIdMap : 지정된 Stock에 대한 Product Map.
                Key     : VehicleStockId(지정값)
                Value   : Product2Id(Stock의 Product2Id)
            opptyProductIdMap : Opportunity에 대한 Product Map. opptyStockIdMap의 Stock에 대한 Product를 가져와야하기 때문
                Key     : OpportunityId
                Value   : Product2Id(Stock의 Product2Id)
            productStockMap : Product2Id별 VehicleStock의 Map. opptyProductIdMap를 통해 VehicleStock의 데이터를 가져와야하기 때문
                Key     : Product2Id
                Value   : Map<String, VehicleStock> [ Key : StockId, Value : VehicleStock ]
        */

        System.debug(opptyStockIdMap.values());
        // VehicleStock의 Product 전체조회
        Map<String, VehicleStock__c> stockIdMap = new Map<String, VehicleStock__c>();
        Map<String, String> stockProductIdMap = new Map<String, String>();
        Map<String, String> opptyProductIdMap = new Map<String, String>();
        Map<String, Map<String, VehicleStock__c>> productStockMap = new Map<String, Map<String, VehicleStock__c>>();
        for (VehicleStock__c stock : [
                SELECT Id, Name, Product__c, LongTermStock__c, IsSpecial__c, IsOptionDiscount__c
                FROM VehicleStock__c
                WHERE Id IN :opptyStockIdMap.values()
        ]) {
            stockProductIdMap.put(stock.Id, stock.Product__c);
            stockIdMap.put(stock.Id, stock);
        }

        // 기존재 Opportunity-VehicleStock 확인
        Set<String> assignedStockSet = new Set<String>();
        List<Opportunity> existOpportunities = [
                SELECT Id, Name, VehicleStock__c
                FROM Opportunity
                WHERE VehicleStock__r.Product__c IN :stockProductIdMap.values()   // Product별로 전부 조회필요
        ];
        for (Opportunity obj : existOpportunities) {
            assignedStockSet.add(obj.VehicleStock__c);
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>([
                SELECT Id, (
                        SELECT Id, Name, LongTermStock__c, IsSpecial__c, IsOptionDiscount__c
                        FROM VehicleStock__r
                        WHERE Status__c = '재고 노출'
                        AND VehicleStatus__c != '출고불가'  // ver1.4 VehicleStock 자동배정 조건필드 추가(VehicleStatus)
                        ORDER BY EopDate__c ASC
                )
                FROM Product2
                WHERE Id IN :stockProductIdMap.values()
        ]);
        for (String opportunityId : opptyStockIdMap.keySet()) {
            String stockId = opptyStockIdMap.get(opportunityId);
            String productId = stockProductIdMap.get(stockId);
            Product2 product = productMap.get(productId);

            for (VehicleStock__c stock : product.VehicleStock__r) {
                if (assignedStockSet.contains(stock.Id)) continue;    // Opportunity에 기 할당된 차량인경우 PASS

                Map<String, VehicleStock__c> stockMap = productStockMap.containsKey(productId)
                        ? productStockMap.get(productId)
                        : new Map<String, VehicleStock__c>();

                stockMap.put(stock.Id, stock);
                productStockMap.put(productId, stockMap);
            }
            opptyProductIdMap.put(opportunityId, productId);
        }

        // ver1.5 차량 배정 Process. 재고이동요청 CALL
        List<String> cancelList = new List<String>();
        List<String> assignList = new List<String>();

        // 1. Product별 List<VehicleStock> 데이터 조회(ORDER BY 적용)
        // 2. 확정된 견적(Quote)의 VehicleStock. 특수 할인여부 확인
        // 3. 사용자 지정, 특수여부등 확인
        for (Opportunity newObj : newList) {
            // VehicleStock Case Update. 전체 NEW 데이터중 VehicleStock업데이트된것만 PICK
            String stockId = opptyStockIdMap.get(newObj.Id);        // 사용자 지정한 VehicleStockId
            if (stockId == null) continue;

            newObj.VehicleStock__c = null;                          // INIT
            String productId = opptyProductIdMap.get(newObj.Id);    // ProductId

            // ver1.5 차량 배정 Process. 재고이동요청 CALL
            Opportunity oldObj = oldMap.get(newObj.Id);
            if (oldObj.VehicleStock__c != null && oldObj.VehicleStock__c != newObj.VehicleStock__c) cancelList.add(oldObj.VehicleStock__c);  // 기 배정된 차량은 취소 재고이동요청 해야함

            // 1. Product별 List<VehicleStock>데이터 조회(ORDER BY 적용)
            Map<String, VehicleStock__c> stockMap = productStockMap.containsKey(productId)
                    ? productStockMap.get(productId)
                    : new Map<String, VehicleStock__c>();
            if (stockMap.isEmpty()) continue;    // Validation. 사용완료시 PASS

            // 2. Quote의 VehicleStock. 특수여부, 재고 노출여부 확인
            VehicleStock__c requestStock = stockIdMap.get(stockId);
            Boolean isSpecial = requestStock.LongTermStock__c || requestStock.IsSpecial__c || requestStock.IsOptionDiscount__c;

            // 할인조건이 같은차량 Search
            List<VehicleStock__c> sameConditionList = new List<VehicleStock__c>();
            for (VehicleStock__c stock : stockMap.values()) {
                if (
                        (stock.LongTermStock__c == requestStock.LongTermStock__c) &&
                                (stock.IsSpecial__c == requestStock.IsSpecial__c) &&
                                (stock.IsOptionDiscount__c == requestStock.IsOptionDiscount__c)
                ) {
                    sameConditionList.add(stock);
                }
            }

            /*
                3. 사용자 지정, 특수여부등 확인
                WHEN. 사용자 지정차량이 가능할때
                    - Stock PUT
                ELSE. 사용자 차량이 불가능할때
                    WHEN. 특수 차량인경우
                        WHEN. 같은 조건의 차가 있을경우
                            - 해당조건 차량 PUT
                        ELSE
                            - NULL
                    ELSE
                        - 오래된 차량기준 PUT (EOP Date)
            */
            VehicleStock__c assignStock = stockMap.containsKey(requestStock.Id)
                    ? requestStock
                    : isSpecial
                            ? !sameConditionList.isEmpty()
                                    ? sameConditionList.get(0)
                                    : null
                            : stockMap.values().get(0);

            if (assignStock != null) {
                // 차량 배정 가능할 때
                newObj.VehicleStock__c = assignStock.Id;
                stockMap.remove(assignStock.Id);
                productStockMap.put(productId, stockMap);

                // ver1.5 차량 배정 Process. 재고이동요청 CALL
                assignList.add(assignStock.Id);
            }
        }

        // ver1.5 차량 배정 Process. 재고이동요청 CALL
//        if (!assignList.isEmpty()) System.enqueueJob(new AsyncStockRequest(assignList, true));  // 차량 재고이동요청
//        if (!cancelList.isEmpty()) System.enqueueJob(new AsyncStockRequest(cancelList, false)); // 차량 재고이동요청 취소
    }

    //네이밍 룰에 따른 업데이트 AccountName-ContactName-ProductName OpportunityLineItem이 Opportunity 생성 후에 생성되어 안나옴
//    private void udpateName() {
//        try{
//            Opportunity opportunityObj = [SELECT Id,Account.Name, AccountId, Name, (SELECT Id,Product2.Name FROM OpportunityLineItems)
//                FROM Opportunity
//                WHERE Id =:newList[0].Id];
//            Account accountObj = [SELECT Id, (SELECT Id,Name FROM Contacts) FROM Account WHERE Id =:opportunityObj.AccountId];
//            OpportunityLineItem opportunityLineItemObj = [SELECT Id, Name FROM OpportunityLineItem WHERE OpportunityId =:opportunityObj.Id];
//            List<Opportunity> updateOpportunityList = new List<Opportunity>();
//            System.debug('acc:::'+accountObj.Contacts);
//            System.debug('opp:::'+opportunityLineItemObj.Name);
//            opportunityObj.Name = opportunityObj.Account.Name + ' ' + accountObj.Contacts[0].Name + ' ' + opportunityObj.OpportunityLineItems[0].Product2.Name;
//            updateOpportunityList.add(opportunityObj);
//            if(updateOpportunityList.size()>0) update updateOpportunityList;
//        }catch(Exception e){
//            System.debug('err msg=>' + e.getMessage() + ' ' + e.getStackTraceString());
//        }
//    }

    /* ------------------------------------------------------------------------------------------------------------------------- */
    /* ------------------------------------------------------------------------------------------------------------------------- */
    /* ------------------------------------------------------------------------------------------------------------------------- */

    private Map<String, List<Id>> getDeferredListMap(String field) {
        Map<String, List<Id>> deferredListMap = new Map<String, List<Id>>();

        for (Opportunity newObj : newList) {
            Opportunity oldObj = oldMap.get(newObj.Id);

            if (oldObj.get(field) != newObj.get(field)) {
                String status = String.valueOf(newObj.get(field));
                if (!updateStatusList.contains(status)) continue;

                List<Id> deferredList = deferredListMap.containsKey(status)
                        ? deferredListMap.get(status)
                        : new List<Id>();

                deferredList.add(newObj.Id);
                deferredListMap.put(status, deferredList);
            }
        }

        return deferredListMap;
    }

    // ver1.3 VehicleStock 가용가능한 record로 Update
    private Map<String, String> getUpdateStockMap() {
        Map<String, String> opptyStockIdMap = new Map<String, String>();

        for (Opportunity newObj : newList) {
            // VehicleStock Update Case
            Opportunity oldObj = oldMap.get(newObj.Id);
            if (
                    newObj.VehicleStock__c != null &&
                            oldObj.VehicleStock__c != newObj.VehicleStock__c
            ) {
                // 1. 신규 VehicleStock이 존재할 경우
                // 2. 기존 VehicleStock과 신규 VehicleStock과 다를경우
                // ex, [A1 -> A2, A1 -> null]
                opptyStockIdMap.put(newObj.Id, newObj.VehicleStock__c);
            }
        }

        return opptyStockIdMap;
    }

    // ver1.5 재고이동요청 CALL
    private List<Map<String, Object>> getRequestStockMapList() {
        List<Map<String, Object>> requestStockMapList = new List<Map<String, Object>>();

        for (Opportunity newObj : newList) {
            Opportunity oldObj = oldMap.get(newObj.Id);
            String oldStockId = oldObj.VehicleStock__c;
            String newStockId = newObj.VehicleStock__c;

            /*
                Case1. 차량 신규배정
                    - newStockId != null            / A
                    - oldStockId = null             / null
                    - newStockId != oldStockId      / Not Equal
                Case2. 차량 배정변경
                    - newStockId != null            / A
                    - oldStockId != null            / B
                    - newStockId != oldStockId      / Not Equal
                Case3. 차량 배정취소
                    - newStockId = null             / null
                    - oldStockId != null            / A
                    - newStockId != oldStockId      / Not Equal
                Case4. 차량 배정유지
                    - newStockId != null            / A
                    - oldStockId != null            / A
                    - newStockId == oldStockId      / Equal
            */

            if (newStockId != null && newStockId != oldStockId) {
                // 신규 할당 or 재고 변경 => Attach
                requestStockMapList.add(new Map<String, Object>{
                        'stockId' => newStockId,
                        'isAttach' => true
                });
            }

            if (oldStockId != null && oldStockId != newStockId) {
                // 기존 재고 취소 => Detach
                requestStockMapList.add(new Map<String, Object>{
                        'stockId' => oldStockId,
                        'isAttach' => false
                });
            }
        }

        return requestStockMapList;
    }

    // ver1.11 주민등록증 세금계산서 발행여부 완료시 고객정보전송
    private List<String> getIDNumberUpdateList() {
        List<String> accountIdList = new List<String>();

        for(Opportunity newOppty : newList) {
            Opportunity oldOppty = oldMap.get(newOppty.Id);

            if(newOppty.IsTaxIDNumber__c != oldOppty.IsTaxIDNumber__c) accountIdList.add(newOppty.fm_TaxAccountId__c);
        }

        return accountIdList;
    }

    // 개인정보 고객 미동의 필드 락 로직
    private void consentFieldLock() {
        List<String> byPassfieldList = new List<String>{
                'islockconsent__c', 'lastmodifieddate', 'systemmodstamp'
        };
        for (Id opportunityId : newMap.keySet()) {
            if (newMap.get(opportunityId).IsLockConsent__c && newMap.get(opportunityId).StageName == 'Negotiation') {
                Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(Opportunity.getSObjectType().getDescribe().getName()).getDescribe().fields.getMap();
                for (String field : fieldMap.keySet()) {
                    Schema.DescribeFieldResult fieldDesc = fieldMap.get(field).getDescribe();
                    Object newValue;
                    Object oldValue;
                    if (fieldDesc.isAccessible()) {
                        newValue = newMap.get(opportunityId).get(field);
                        oldValue = oldMap.get(opportunityId).get(field);
                    }

                    // 접근 가능한 필드만 추가
                    if ((newValue != oldValue) && !byPassfieldList.contains(field.toLowerCase())) {
                        if (!Test.isRunningTest()) newMap.get(opportunityId).addError('개인정보 고객 동의를 진행해주세요.');
                        break;
                    }
                }
            }
        }
    }
    //oppty 생성 시 고객 동의 연결
    private void updateCustomerConsent() {
        try {
            Set<Id> duplicateLeadIdSet = new Set<Id>();
            for (Id opportunityId : newMap.keySet()) {
                if (oldMap.get(opportunityId).StageName == 'Quotation' && newMap.get(opportunityId).StageName == 'Negotiation') {
                    duplicateLeadIdSet.add(newMap.get(opportunityId).AccountId);
                }
            }
            // Account 정보 조회
            if (!duplicateLeadIdSet.isEmpty()) {
                Map<Id, Account> accountMap = new Map<Id, Account>(
                        [SELECT Id, PersonMobilePhone, Name FROM Account WHERE Id IN :duplicateLeadIdSet]
                );
                // Lead 매칭 조건 생성
                List<String> conditions = new List<String>();
                for (Account acc : accountMap.values()) {
                    if (String.isNotBlank(acc.PersonMobilePhone) && String.isNotBlank(acc.Name)) {
                        conditions.add(' (MobilePhone = \'' + String.escapeSingleQuotes(acc.PersonMobilePhone) + '\' AND LastName = \'' + String.escapeSingleQuotes(acc.Name) + '\')');
                    }
                }
                if (conditions.isEmpty()) return;

                String queryStr = 'SELECT Id, MobilePhone, LastName FROM Lead WHERE ' + String.join(conditions, ' OR ');
                List<Lead> matchedLeads = Database.query(queryStr);

                // Lead → Opportunity 매핑
                Map<String, Id> leadKeyToOppId = new Map<String, Id>();
                for (Opportunity opp : newMap.values()) {
                    Account acc = accountMap.get(opp.AccountId);
                    if (acc == null) continue;

                    String key = acc.PersonMobilePhone + '_' + acc.Name;
                    leadKeyToOppId.put(key, opp.Id);
                }

                Map<String, Id> customerConsentOpptyIdMap = new Map<String, Id>();

                for (Lead lead : matchedLeads) {
                    String key = lead.MobilePhone + '_' + lead.LastName;
                    if (leadKeyToOppId.containsKey(key)) {
                        customerConsentOpptyIdMap.put(lead.Id, leadKeyToOppId.get(key));
                    }
                }
                List<CustomerConsent__c> updateCustomerConsentList = new List<CustomerConsent__c>();
                for (CustomerConsent__c customerConsent : [SELECT Id, Lead__c FROM CustomerConsent__c WHERE Lead__c = :customerConsentOpptyIdMap.keySet() AND Opportunity__c = null ORDER BY CreatedDate DESC LIMIT 1]) {
                    customerConsent.Opportunity__c = customerConsentOpptyIdMap.get(customerConsent.Lead__c);
                    customerConsent.Account__c = newMap.get(customerConsentOpptyIdMap.get(customerConsent.Lead__c)).AccountId;
                    customerConsent.ConsentStatus__c = '링크 전송됨';
                    customerConsent.SendAlimTalkDate__c = System.today();
                    customerConsent.ConsentDate__c = null;

                    updateCustomerConsentList.add(customerConsent);
                }

                if (!updateCustomerConsentList.isEmpty()) update updateCustomerConsentList;

                List<Opportunity> opportunityList = [SELECT Id, IsLockConsent__c FROM Opportunity WHERE Id = :newMap.keySet()];
                if (!opportunityList.isEmpty()) {
                    for (Opportunity opportunity : opportunityList) {
                        opportunity.IsLockConsent__c = true;
                    }

                    update opportunityList;
                }

            }
        } catch (Exception e) {
            System.debug('err :: ' + e);
        }
    }

    // Full Cosnent 발송 로직
    private void sendFullConsent() {
        Id sendOpportunityId;
        for (Id opportunityId : newMap.keySet()) {
            if (oldMap.get(opportunityId).StageName == 'Quotation' && newMap.get(opportunityId).StageName == 'Negotiation') {
                sendOpportunityId = opportunityId;
            }
        }
        if (sendOpportunityId != null) {
            List<CustomerConsent__c> customerConsents = [
                    SELECT Id, Opportunity__c
                    FROM CustomerConsent__c
                    WHERE Opportunity__c = :sendOpportunityId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];
            if (!customerConsents.isEmpty()) {
                String jobName = 'SendLightConsent_ba(' + customerConsents[0].Id + ')';
                String query = 'SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = \'' + jobName + '\'';

                List<CronTrigger> jobs = Database.query(query);
                for (CronTrigger job : jobs) {
                    System.abortJob(job.Id);
                }
                LandingPageController.sendConsentKakaoAlimtalk(customerConsents[0].Id);
            }
        }
    }

    /**
     * @author th.kim
     * @description 모든 기회가 모든입금완료 시 인센티브 모든입금완료 필드 업데이트
     */
    private void updateIncentiveHistory() {

        Set<Id> incentiveIdSet = new Set<Id>();
        for (Opportunity newOpportunity : newList) {
            Opportunity oldOpportunity = oldMap.get(newOpportunity.Id);
            if (oldOpportunity.PaymentStatus__c != newOpportunity.PaymentStatus__c && newOpportunity.PaymentStatus__c == 'COMPLETE') {
                if (String.isNotBlank(newOpportunity.IncentiveHistoryQuarterly__c)) incentiveIdSet.add(newOpportunity.IncentiveHistoryQuarterly__c);
                if (String.isNotBlank(newOpportunity.IncentiveHistoryAnnual__c)) incentiveIdSet.add(newOpportunity.IncentiveHistoryAnnual__c);
            }
        }

        // 모든입금완료로 업데이트된 기회의 인센티브 내역 리스트
        List<IncentiveHistory__c> incentiveHistoryList = [
                SELECT Id, IsAllPaymentCompleted__c
                FROM IncentiveHistory__c
                WHERE Id IN :incentiveIdSet
        ];

        // 업데이트할 인센티브 내역의 Opportunity 리스트
        List<Opportunity> incentiveOpportunityList = [
                SELECT Id, IncentiveHistoryQuarterly__c, IncentiveHistoryAnnual__c, PaymentStatus__c
                FROM Opportunity
                WHERE IncentiveHistoryQuarterly__c IN :incentiveIdSet
                OR IncentiveHistoryAnnual__c IN :incentiveIdSet
        ];

        Map<Id, List<Opportunity>> opportunityByIncentiveIdMap = new Map<Id, List<Opportunity>>();
        // 인센티브 내역 별 기회 데이터 리스트 가져오기
        for (Opportunity opportunity : incentiveOpportunityList) {
            String incentiveIdQuarter = opportunity.IncentiveHistoryQuarterly__c;
            String incentiveIdAnnual = opportunity.IncentiveHistoryAnnual__c;
            if (String.isNotBlank(incentiveIdQuarter)) {
                if (opportunityByIncentiveIdMap.get(incentiveIdQuarter) == null) {
                    opportunityByIncentiveIdMap.put(incentiveIdQuarter, new List<Opportunity>());
                }
                opportunityByIncentiveIdMap.get(incentiveIdQuarter).add(opportunity);
            }
            if (String.isNotBlank(incentiveIdAnnual)) {
                if (opportunityByIncentiveIdMap.get(incentiveIdAnnual) == null) {
                    opportunityByIncentiveIdMap.put(incentiveIdAnnual, new List<Opportunity>());
                }
                opportunityByIncentiveIdMap.get(incentiveIdAnnual).add(opportunity);
            }
        }

        List<IncentiveHistory__c> updateList = new List<IncentiveHistory__c>();
        for (IncentiveHistory__c incentiveHistory : incentiveHistoryList) {
            Boolean isAllPaymentCompleted = true;

            List<Opportunity> opportunityList = opportunityByIncentiveIdMap.get(incentiveHistory.Id);
            // 모든 기회 입금완료인지 체크
            for (Opportunity opportunity : opportunityList) {
                if (opportunity.PaymentStatus__c != 'COMPLETE') {
                    isAllPaymentCompleted = false;
                    break;
                }
            }

            if (isAllPaymentCompleted) {
                incentiveHistory.IsAllPaymentCompleted__c = isAllPaymentCompleted;
                updateList.add(incentiveHistory);
            }
        }

        update updateList;
    }
}