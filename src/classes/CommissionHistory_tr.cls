/*************************************************************
 * @author : th.kim
 * @description : 
 * @target : 
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-06      th.kim          Created
**************************************************************/
public without sharing class CommissionHistory_tr extends TriggerHandler {

    private final List<CommissionHistory__c> newList { get; set; }
    private final List<CommissionHistory__c> oldList { get; set; }
    private final Map<Id, CommissionHistory__c> newMap { get; set; }
    private final Map<Id, CommissionHistory__c> oldMap { get; set; }

    public CommissionHistory_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap = (Map<Id, CommissionHistory__c>) Trigger.newMap;
        oldMap = (Map<Id, CommissionHistory__c>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        setFieldDataForRollUp();
    }

    public override void afterInsert() {
        createCommissionIncentiveMaster();
    }

    public override void beforeDelete() {
        deleteCommissionIncentiveMaster();
    }

    /**
     * @author th.kim
     * @description 롤업에 사용하기 위한 필드 세팅
     */
    private void setFieldDataForRollUp() {

        Set<Id> opportunityIdSet = new Set<Id>();
        for (CommissionHistory__c history : newList) {
            opportunityIdSet.add(history.Opportunity__c);
        }
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
            SELECT Id, VATDefermentStatus__c, Contract.fm_RealSalesPrice__c, Contract.Quote__c, toLabel(VehicleStock__r.Product__r.Segment1__c)
            FROM Opportunity
            WHERE Id IN :opportunityIdSet
        ]);
        Set<Id> quoteIdSet = new Set<Id>();
        for (Opportunity opportunity : opportunityMap.values()) {
            quoteIdSet.add(opportunity.Contract.Quote__c);
        }

        // 견적별 데이터 및 주유상품권 데이터 가져오기
        Map<Id, Quote> quoteMap = new Map<Id, Quote>([
            SELECT Id, fm_DefermentVAT__c, (
                SELECT Type__c, fm_Price__c
                FROM QuoteDetail__r
                WHERE Type__c = '주유상품권'
                LIMIT 1
            )
            FROM Quote
            WHERE Id IN :quoteIdSet
        ]);

        for (CommissionHistory__c newHistory : newList) {
            Opportunity opportunity = opportunityMap.get(newHistory.Opportunity__c);
            if (opportunity != null) {
                Quote quote = quoteMap.get(opportunity.Contract.Quote__c);
                Decimal oilCouponPrice = (quote != null && quote.QuoteDetail__r != null && !quote.QuoteDetail__r.isEmpty())
                    ? quote.QuoteDetail__r[0].fm_Price__c
                    : 0;

                // 커미션 내역 필드 세팅
                String segment = opportunity.VehicleStock__r?.Product__r?.Segment1__c;
                Integer salesPrice = Math.round((opportunity.Contract.fm_RealSalesPrice__c - oilCouponPrice) / 1.1);
                Integer commission = Math.round((salesPrice * (Decimal.valueOf(Label.CommissionRate) / 100)) / 100) * 100;
                Integer totalCommission = Math.round(commission * 1.1);
                if (newHistory.Type__c == 'FinishedDefermentVAT') {
                    newHistory.Commission__c = Math.round(totalCommission * 0.3);
                } else {
                    newHistory.SalesPrice__c = salesPrice;
                    newHistory.Segment1__c = segment;
                    newHistory.Commission__c = commission;
                    Boolean isVAT = opportunity.VATDefermentStatus__c == '승인됨';
                    newHistory.HoldingPayment__c = isVAT ? Math.round(totalCommission * 0.3) : 0;
                    newHistory.Type__c = isVAT ? 'DefermentVAT' : 'Complete';
                }
            }
        }
    }

    /**
     * @author th.kim
     * @description 커미션 내역 생성 시 커미션 & 인센티브 마스터 생성
     */
    private void createCommissionIncentiveMaster() {

        Set<Id> managementIdSet = new Set<Id>();
        for (CommissionHistory__c newHistory : newList) {
            managementIdSet.add(newHistory.CommissionManagement__c);
        }
        Map<Id, CommissionManagement__c> ownerIdByManagementMap = new Map<Id, CommissionManagement__c>([SELECT Id, OwnerId FROM CommissionManagement__c WHERE Id IN :managementIdSet]);

        List<CommissionIncentiveMaster__c> commissionIncentiveMasterList = new List<CommissionIncentiveMaster__c>();
        for (CommissionHistory__c newHistory : newList) {
            commissionIncentiveMasterList.add(new CommissionIncentiveMaster__c(
                    CommissionHistory__c = newHistory.Id,
                    Type__c = 'Commission',
                    OwnerId = ownerIdByManagementMap.get(newHistory.CommissionManagement__c).OwnerId
            ));
        }

        insert commissionIncentiveMasterList;
    }

    /**
     * @author th.kim
     * @description 커미션 내역 삭제 시 커미션 & 인센티브 마스터 삭제
     */
    private void deleteCommissionIncentiveMaster() {

        List<CommissionIncentiveMaster__c> commissionIncentiveMasterList = [
                SELECT Id
                FROM CommissionIncentiveMaster__c
                WHERE CommissionHistory__c IN :oldMap.keySet()
        ];

        delete commissionIncentiveMasterList;
    }
}