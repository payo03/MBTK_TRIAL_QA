/*************************************************************
 * @author : th.kim
 * @date : 2025-01-22
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-22      th.kim          Created
**************************************************************/
public with sharing class SchedulerMainController {

    public class HandoverWrap {
        @AuraEnabled public String id;
        @AuraEnabled public String agency;
        @AuraEnabled public String agent;
        @AuraEnabled public String customer;
        @AuraEnabled public String oppUrl;
        @AuraEnabled public String oppName;
        @AuraEnabled public String stockId;
        @AuraEnabled public String stockUrl;
        @AuraEnabled public String VIN;
        @AuraEnabled public String vehicleNo;
        @AuraEnabled public String vehicleStatus;
        @AuraEnabled public String productId;
        @AuraEnabled public String handoverDate;
        @AuraEnabled public String paymentStatus;
        @AuraEnabled public String lastModifiedDate;
        @AuraEnabled public String lastModifiedBy;
        @AuraEnabled public Boolean isDeposit;
        @AuraEnabled public Boolean isVat;
        @AuraEnabled public String taxInvoiceDate;
        @AuraEnabled public String conStatus;
        @AuraEnabled public Boolean isNeedToCheckUpdate;
        @AuraEnabled public List<String> updatedFieldList;
        @AuraEnabled public List<QuoteDetail__c> quoteDetailList;
        @AuraEnabled public Opportunity opp;
        @AuraEnabled public VehicleStock__c vehicleStock;

        public HandoverWrap(
            String id,
            String agent,
            String paymentStatus,
            String lastModifiedDate,
            String lastModifiedBy,
            Boolean isDeposit,
            Boolean isVat,
            String conStatus,
            Boolean isNeedToCheckUpdate,
            String updatedField,
            List<QuoteDetail__c> quoteDetailList,
            Opportunity opp,
            VehicleStock__c vehicleStock
        ) {
            this.id = id;
            this.agency = opp.Owner.Agency__c;
            this.agent = agent;
            this.customer = opp.Account.Name;
            this.oppUrl = '/lightning/r/Opportunity/' + opp.Id + '/view';
            this.oppName = opp.Name;
            if (vehicleStock != null) {
                this.stockId = vehicleStock.Id;
                this.stockUrl = '/lightning/r/VehicleStock__c/' + vehicleStock.Id + '/view';
                this.vehicleNo = vehicleStock.VehicleNo__c;
                this.vehicleStatus = vehicleStock.VehicleStatus__c;
                this.vehicleStock = vehicleStock;
            }
            this.VIN = vehicleStock?.Name ?? '차량 배정';
            this.productId = opp.Contract.Quote__r.Product__c;
            this.handoverDate = opp.HandoverDate__c != null ? String.valueOf(opp.HandoverDate__c) : '출고일 지정';
            this.paymentStatus = paymentStatus;
            this.lastModifiedDate = lastModifiedDate;
            this.lastModifiedBy = lastModifiedBy;
            this.isDeposit = isDeposit;
            this.isVat = isVat;
            this.taxInvoiceDate = opp.TaxInvoiceDate__c != null ? String.valueOf(opp.TaxInvoiceDate__c) : '';
            this.conStatus = conStatus;
            this.isNeedToCheckUpdate = isNeedToCheckUpdate;
            updatedFieldList = new List<String>(updatedField?.split(','));
            this.quoteDetailList = quoteDetailList;
            this.opp = opp;
        }
    }

    /**
     * @author th.kim
     * @description 초기 세팅을 위한 데이터 가져오기
     * @return 초기 세팅 데이터
     */
    @AuraEnabled
    public static Map<String, Object> getInit() {

        return new Map<String, Object>{
            'paymentStatusOption' => CommonUtilController.getPickList('PaymentTracker__c', 'Status__c', null),
            'vehicleStatusOption' => CommonUtilController.getPickList('VehicleStock__c', 'VehicleStatus__c', null),
            'handoverList' => getHandoverData()
        };
    }

    /**
     * @author th.kim
     * @description 기본 조건(이번달)으로 핸드오버 데이터 조회
     * @return 이번달 핸드오버
     */
    public static List<HandoverWrap> getHandoverData() {

        return getHandoverData('Opportunity__r.HandoverDate__c = THIS_MONTH');
    }

    /**
     * @author th.kim
     * @description 핸드오버 데이터 가져오기
     * @param whereCondition 조건
     *
     * @return 핸드오버 데이터
     */
    public static List<HandoverWrap> getHandoverData(String whereCondition) {

        String selectFields = 'Id, fm_SalesAgent__c, fm_ContractStatus__c, FORMAT(LastModifiedDate) lastModifiedDate, LastModifiedBy.Name,' +
            ' IsNeedToCheckUpdate__c, UpdatedFields__c, Opportunity__c, Opportunity__r.HandoverDate__c, ' +
            ' Opportunity__r.Name, Opportunity__r.Account.Name, Opportunity__r.Owner.Agency__c, Opportunity__r.ContractId, Opportunity__r.Contract.Quote__r.Product__c, ' +
            ' Opportunity__r.VehicleStock__r.Name, Opportunity__r.VehicleStock__r.VehicleStatus__c, Opportunity__r.VehicleStock__r.VehicleNo__c, ' +
            ' Opportunity__r.VehicleStock__r.Product__c, Opportunity__r.VehicleStock__r.Product__r.Name, Opportunity__r.VehicleStock__r.Product__r.Segment2__c, ' +
            ' fm_PaymentStatus__c, fm_IsDeposit__c, fm_IsVat__c, Opportunity__r.TaxInvoiceDate__c';
        whereCondition = String.isNotBlank(whereCondition) ? whereCondition + ' AND IsActive__c = TRUE' : 'IsActive__c = TRUE';
        String query = CommonUtilController.buildQuery(selectFields, 'Handover__c', whereCondition, 'Opportunity__r.HandoverDate__c ASC NULLS LAST');
        List<Handover__c> handoverList = Database.query(query);

        Set<Id> opportunityId = new Set<Id>();
        for (Handover__c handover : handoverList) {
            if (String.isNotBlank(handover.Opportunity__c)) opportunityId.add(handover.Opportunity__c);
        }

        Map<Id, List<QuoteDetail__c>> contractQuoteDetailMap = new Map<Id, List<QuoteDetail__c>>();
        for (QuoteDetail__c quoteDetail : [
            SELECT Id, Name, Type__c, fm_DetailType__c, Quote__r.OpportunityId
            FROM QuoteDetail__c
            WHERE Quote__r.OpportunityId IN :opportunityId
            AND Quote__r.OpportunityId != NULL
            AND Quote__r.Status = 'Published'
            AND (Type__c = '옵션' OR Type__c = '특장')
        ]) {
            // 계약 별 옵션 데이터 추가
            if (!contractQuoteDetailMap.containsKey(quoteDetail.Quote__r.OpportunityId)) {
                contractQuoteDetailMap.put(quoteDetail.Quote__r.OpportunityId, new List<QuoteDetail__c>());
            }
            contractQuoteDetailMap.get(quoteDetail.Quote__r.OpportunityId).add(quoteDetail);
        }

        List<HandoverWrap> handoverWrapList = new List<HandoverWrap>();
        for (Handover__c handover : handoverList) {
            handoverWrapList.add(new HandoverWrap(
                handover.Id,
                handover.fm_SalesAgent__c,
                CommonUtilController.getPicklistLabelForLabel('PaymentTracker__c', 'Status__c', handover.fm_PaymentStatus__c),
                String.valueOf(handover.get('lastModifiedDate')),
                handover.LastModifiedBy.Name,
                handover.fm_IsDeposit__c,
                handover.fm_IsVat__c,
                handover.fm_ContractStatus__c,
                handover.IsNeedToCheckUpdate__c,
                handover.UpdatedFields__c,
                contractQuoteDetailMap.get(handover.Opportunity__c),
                handover.Opportunity__r,
                handover.Opportunity__r.VehicleStock__r
            ));
        }

        return handoverWrapList;
    }
}