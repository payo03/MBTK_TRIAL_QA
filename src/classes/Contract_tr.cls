/*********************************************************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-13
 * @description : 
 * @target :
==========================================================================================================
 * Ver          Date            Author                          Modification
 * 1.0          2025-01-13      chaebeom.do                     Created
 * 1.1          2025-01-15      San.Kang                        Updated
*********************************************************************************************************/
public without sharing class Contract_tr extends TriggerHandler {
    /** TriggerHandler */
    private final List<Contract> newList { get; set; }
    private final List<Contract> oldList { get; set; }
    private final Map<Id, Contract> oldMap { get; set; }
    private final Map<Id, Contract> newMap { get; set; }

    public Contract_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap = (Map<Id, Contract>) Trigger.newMap;
        oldMap = (Map<Id, Contract>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        updateName();
    }

    public override void beforeUpdate() {

    }

    public override void afterInsert() {

    }

    public override void afterUpdate() {
        oppStageBack();
        createPaymentTracker();
    }

    private void oppStageBack() {
        // 계약의 승인 상태가 '제출됨'에서 '반려됨' 또는 '회수됨'으로 변경되면
        // 연결된 기회의 '계약' 필드를 비우고 
        // 계약 승인 상태가 '반려됨'이면 (진행 중에 mgmt팀에 의한 반려) 'Negotiation'으로
        // 그 외라면 기회 단계를 그대로(ContractCancelController에서 변경 처리)

        List<Opportunity> oppList = new List<Opportunity>();
        List<Quote> quoteList = new List<Quote>();
        for(Contract newCon : newList) {
            Contract oldCon = new Contract();
            if (oldMap != null) oldCon = oldMap.get(newCon.Id);
            if (
                (oldCon.ApprovalStatus__c == '제출됨' && (newCon.ApprovalStatus__c == '반려됨' || newCon.ApprovalStatus__c == '회수됨'))
            ) {
                Opportunity opp = new Opportunity();
                opp.Id = newCon.Opportunity__c;
                opp.ContractId = null;
                if(newCon.ApprovalStatus__c == '반려됨') opp.StageName = 'Negotiation';
                oppList.add(opp);

                Quote q = new Quote();
                q.Id = newCon.Quote__c;
                q.ContractId = null;
                
                quoteList.add(q);
            }
        }
        if(!oppList.isEmpty()) update oppList;
        if(!quoteList.isEmpty()) update quoteList;
    }
    //Contract가 생성될 때 Opportunity에 생성되어있는 계약 버전에 따라 네이밍룰 적용
    private void updateName() {
        try{
            Map<Id, Decimal> versionMap = new Map<Id, Decimal>();
            for (AggregateResult oppGrp : [
                    SELECT COUNT(Id) cnt, Opportunity__c
                    FROM Contract
                    GROUP BY Opportunity__c
            ]) {
                versionMap.put((Id) oppGrp.get('Opportunity__c'), (Decimal) oppGrp.get('cnt'));
            }
            for (Contract newContract : newList) {
                String oppId = newContract.Opportunity__c;
                if(String.isNotBlank(oppId) && versionMap.get(oppId) != null) {
                    Decimal versionNum = versionMap.get(oppId);
                    newContract.Name = '계약서-' + oppId.substring(oppId.length() - 6) + '-V' + ++versionNum;
                }
            }
        }catch(Exception e){
            System.debug('err msg=>' + e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    // 계약 생성시 신청한 승인 프로세스가 승인되면 입금현황, 핸드오버 레코드 생성
    private void createPaymentTracker() {
        List<PaymentTracker__c> insertPTList = new List<PaymentTracker__c>();
        // 트리거가 돈 계약의 기회에 연결 && 상태가 '계약취소'가 아닌 입금현황 쿼리
        // 쿼리한 입금현황이 0이 아니면 입금현황 생성 안함

        Set<String> quoteIdSet = new Set<String>();
        for(Contract newCon : newList) {
            Contract oldCon = oldMap.get(newCon.Id);
            if (oldCon.ApprovalStatus__c == '제출됨' && newCon.ApprovalStatus__c == '승인됨') quoteIdSet.add(newCon.Quote__c);
        }
        System.debug('test contract_tr :: ' + quoteIdSet);

        Map<String, Quote> contractQuoteMap = new Map<String, Quote>();
        for(Quote quote : [
                SELECT ContractId, Deposit__c, DiscountAmt__c,
                        fm_DeliveryPrice__c, fm_TotalLoanAmount__c, fm_DefermentVAT__c,
                        Finance__r.SubventionRate__c, Finance__r.FScompany__c,
                        Opportunity.VATDefermentStatus__c
                FROM Quote
                WHERE Id IN :quoteIdSet
        ]) {
            contractQuoteMap.put(quote.ContractId, quote);
        }
        System.debug('test contract_tr :: ' + contractQuoteMap);

        // 모집단 Contract
        for(Contract newCon : newList) {
            Quote quote = contractQuoteMap.get(newCon.Id);
            if(quote == null) continue;

            PaymentTracker__c paymentTracker = new PaymentTracker__c();
            paymentTracker.Opportunity__c = newCon.Opportunity__c;
            paymentTracker.Account__c = newCon.AccountId;
            paymentTracker.Status__c = 'NEW';

            Decimal subventionRate = (quote.Finance__r != null && quote.Finance__r.SubventionRate__c != null)
                    ? quote.Finance__r.SubventionRate__c : 0;
            Decimal discountAmount = quote.DiscountAmt__c != null ? quote.DiscountAmt__c : 0;
            Decimal vat = quote.Opportunity.VATDefermentStatus__c == '승인됨' ? quote.fm_DefermentVAT__c : 0;
            paymentTracker.TotalAmount__c = quote.Deposit__c + quote.fm_DeliveryPrice__c + vat +
                    (quote.fm_TotalLoanAmount__c * (1 - (subventionRate / 100)));
            if (discountAmount != 0 && quote.Finance__r.FScompany__c == 'MFS') paymentTracker.TotalAmount__c += discountAmount;
            paymentTracker.IsValid__c = true;
            paymentTracker.OwnerId = newCon.OwnerId;

            insertPTList.add(paymentTracker);
        }
        if(!insertPTList.isEmpty()) insert insertPTList;

        createPayments(insertPTList);
        createHandover(insertPTList);
    }

    // TODO 03-28 송찬영. 1. 인도금 유예 통 생성시. 함수호출 필요
    private static void createPayments(List<PaymentTracker__c> paymentTrackerList){
        List<PaymentType__c> typeList = new List<PaymentType__c>();
        Map<String, String> typeMap = CommonUtilController.getPickListMap('PaymentType__c', 'Type__c');

        Set<String> paymentTrackerOppSet = new Set<String>();
        for(PaymentTracker__c pt : paymentTrackerList) {
            paymentTrackerOppSet.add(pt.Opportunity__c);
        }

        Map<String, Opportunity> paymentTrackerOppMap = new Map<String, Opportunity>();
        for(Opportunity opp : [
                SELECT Id, Contract.Quote__r.Deposit__c, Contract.Quote__r.fm_DeliveryPrice__c, 
                Contract.Quote__r.fm_TotalLoanAmount__c, Contract.Quote__r.Finance__r.SubventionRate__c,
                Contract.Quote__r.Finance__r.FScompany__c, Contract.Quote__r.DiscountAmt__c,
                Contract.Quote__r.fm_DefermentVAT__c, PaymentDeferredAmount__c,
                VATDefermentStatus__c, PaymentDefermentStatus__c, Account.Name
                FROM Opportunity
                WHERE Id IN :paymentTrackerOppSet
        ]) {
            paymentTrackerOppMap.put(opp.Id, opp);
        }

        // 모수 PaymentTracker
        for(PaymentTracker__c paymentTracker : paymentTrackerList) {
            Map<String, Decimal> amountMap = new Map<String, Decimal>();
            Opportunity curOpp = paymentTrackerOppMap.get(paymentTracker.Opportunity__c);
            amountMap.put('계약금', curOpp.Contract.Quote__r.Deposit__c);
            amountMap.put('인도금', curOpp.Contract.Quote__r.fm_DeliveryPrice__c);
            if (curOpp.PaymentDefermentStatus__c == '승인됨') {
                amountMap.put('인도금', curOpp.Contract.Quote__r.fm_DeliveryPrice__c - curOpp.PaymentDeferredAmount__c);
                amountMap.put('인도금 유예', curOpp.PaymentDeferredAmount__c);
            }
            if (curOpp.VATDefermentStatus__c == '승인됨') amountMap.put('부가세후취', curOpp.Contract.Quote__r.fm_DefermentVAT__c);
            // null 체크
            Decimal subventionRate = (curOpp.Contract.Quote__r.Finance__r != null && curOpp.Contract.Quote__r.Finance__r.SubventionRate__c != null) 
                        ? curOpp.Contract.Quote__r.Finance__r.SubventionRate__c : 0;
            Decimal discountAmount = curOpp.Contract.Quote__r.DiscountAmt__c != null ? curOpp.Contract.Quote__r.DiscountAmt__c : 0;
            amountMap.put('대출금', curOpp.Contract.Quote__r.fm_TotalLoanAmount__c * (1 - (subventionRate / 100)));
            amountMap.put('대출금 할인금액', curOpp.Contract.Quote__r.fm_TotalLoanAmount__c * subventionRate / 100);
            if (discountAmount != 0 && curOpp.Contract.Quote__r.Finance__r.FScompany__c == 'MFS') {
                amountMap.put('대출금', curOpp.Contract.Quote__r.fm_TotalLoanAmount__c * (1 - (subventionRate / 100)) + discountAmount);
                amountMap.put('MFS 캠페인 할인금액', discountAmount);
            }
            // 입금받을 계정들만 Insert
            for(String key : amountMap.keySet()) {
                // key... 계약금, 대출금, 대출금 할인 금액, 부가세후취.... (Type__c의 Label값)
                String typeValue = typeMap.get(key);
                PaymentType__c pt = new PaymentType__c();
                Decimal amount = amountMap.get(key);
                String inputField = 'RequestAmount__c';
                if(typeValue.contains('SUBVENTION') || typeValue.contains('CAMPAIGN')) inputField = 'DiscountAmount__c';

                pt.RequestAmount__c = 0; // SUBVENTION || CAMPAIGN case / 요청 금액 = 0, 할인 금액 = amount
                pt.PaymentTracker__c = paymentTracker.Id;
                pt.Type__c = typeValue;
                pt.put(inputField, amount);
    
                typeList.add(pt);
            }
            PaymentType__c overType = new PaymentType__c();
            overType.PaymentTracker__c = paymentTracker.Id;
            overType.Type__c = '5_OVER_PAID';
            overType.RequestAmount__c = 999999999;
    
            typeList.add(overType);
        }
        if (!typeList.isEmpty()) {
            insert typeList;    // TODO 03-28 송찬영. 2. upsert로 변경이 필요하다(PaymentType을 선 조회)
        }
    }

    private static void createHandover(List<PaymentTracker__c> paymentTrackerList){
        List<Handover__c> handoverList = new List<Handover__c>();

        Set<String> paymentTrackerOppSet = new Set<String>();
        for(PaymentTracker__c pt : paymentTrackerList) {
            paymentTrackerOppSet.add(pt.Opportunity__c);
        }

        Map<String, Opportunity> handoverOppMap = new Map<String, Opportunity>();
        for(Opportunity opp : [
                SELECT Contract.VehicleStock__c, OwnerId
                FROM Opportunity
                WHERE Id IN :paymentTrackerOppSet
        ]) {
            handoverOppMap.put(opp.Id, opp);
        }

        //모수 PaymentTracker
        for (PaymentTracker__c paymentTracker : paymentTrackerList) {
            Handover__c handover = new Handover__c();
            handover.Opportunity__c = paymentTracker.Opportunity__c;
            handover.PaymentTracker__c = paymentTracker.Id;
            // handover.VehicleStock__c = opp.Contract.VehicleStock__c;
            // handover.OwnerId = opp.OwnerId;
            handover.OwnerId = paymentTracker.OwnerId;
    
            handoverList.add(handover);
        }
        if (!handoverList.isEmpty()) {
            insert handoverList;
        }
    }
}