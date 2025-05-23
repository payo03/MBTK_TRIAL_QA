/*************************************************************
 * @author : th.kim
 * @date : 2025-01-22
 * @description : 스케줄 관리 Main Controller
 * @target : HandoverSchedulerController, SchedulerMainController
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-22      th.kim          Created
 * 1.1          2025-04-24      chaebeom.do     워크넘버 클릭시 PDI 메인으로 이동하게 url 추가
 * 1.2          2025-04-29      jh.jung         주유상품권 추가를 위한 quote 추가
 * 1.3          2025-05-09      jh.jung         HandoverWrap 필드 추가
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
        @AuraEnabled public String vehicleNoUrl;        // ver 1.1
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
        @AuraEnabled public String oilCoupon;
        @AuraEnabled public String oilCouponFormat;

        // ver 1.3
        @AuraEnabled public String handoverRequest;
        @AuraEnabled public String shirtSize;
        @AuraEnabled public String safetyPackageDescription;
        @AuraEnabled public String eopDate;
        @AuraEnabled public String modelYear;
        @AuraEnabled public String productName;
        @AuraEnabled public String segment2;
        @AuraEnabled public String taxInvoiceRequestDate;
        @AuraEnabled public String saleNumber;

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
            VehicleStock__c vehicleStock,
            Decimal oilCoupon
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
                this.vehicleNoUrl = '/lightning/n/PDIMain?c__stockId=' + vehicleStock.Id + '&c__vehicleNo=' + vehicleStock.VehicleNo__c;     // ver 1.1
                this.vehicleStatus = vehicleStock.VehicleStatus__c;
                this.vehicleStock = vehicleStock;
                // ver 1.3
                this.safetyPackageDescription = vehicleStock.Safety_Package_Description__c;
                this.eopDate = vehicleStock.EopDate__c != null ? String.valueOf(vehicleStock.EopDate__c) : '';
                this.modelYear = vehicleStock.Product__r?.ModelYear__c;
                this.productName = vehicleStock.Product__r?.Name;
                this.segment2 = vehicleStock.Product__r?.Segment2__c;
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
            // ver 1.2
            Decimal oilAmt = oilCoupon != null ? oilCoupon : 0;
            this.oilCoupon = String.valueOf(10*oilAmt);
            this.oilCouponFormat = (10*oilAmt).format() + '만원';

            // ver 1.3
            this.handoverRequest = opp.HandoverRequest__c;
            this.saleNumber = opp.SaleNumber__c;
            // this.shirtSize = opp.Shirtsize__c != null ? String.valueOf(opp.Shirtsize__c) : '';
            this.shirtSize = opp.Shirtsize__c != null ? opp.Shirtsize__c : '';
            this.taxInvoiceRequestDate = opp.TaxInvoicRequestDate__c != null ? String.valueOf(opp.TaxInvoicRequestDate__c) : '';

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
            'handoverList' => getHandoverData(),
            'permissionSet' => getPermissionSet()
        };
    }

    // 유저가 가진 권한 가져오기
    private static Map<String, String> getPermissionSet() {

        String userRole = 'default';

        List<PermissionSetAssignment> permissionSetAssignments = [
            SELECT Id, PermissionSet.Name, PermissionSet.Label
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
        ];

        for(PermissionSetAssignment tempObj : permissionSetAssignments) {
            if('SA'.equals(tempObj.PermissionSet.Name)) {
                userRole = 'sa';
                break;
            } else if('HandOver'.equals(tempObj.PermissionSet.Name)) {
                userRole = 'handover';
                break;
            } else if('PDI'.equals(tempObj.PermissionSet.Name)) {
                userRole = 'pdi';
                break;
            }
        }

        return new Map<String, String> {
            'userRole' => userRole
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
            ' fm_PaymentStatus__c, fm_IsDeposit__c, fm_IsVat__c, Opportunity__r.TaxInvoiceDate__c, ' +
            ' Opportunity__r.SaleNumber__c, Opportunity__r.HandoverRequest__c, Opportunity__r.TaxInvoicRequestDate__c, Opportunity__r.Shirtsize__c, Opportunity__r.VehicleStock__r.Safety_Package_Description__c, Opportunity__r.VehicleStock__r.EopDate__c, Opportunity__r.VehicleStock__r.Product__r.ModelYear__c';
        whereCondition = String.isNotBlank(whereCondition) ? whereCondition + ' AND IsActive__c = TRUE' : 'IsActive__c = TRUE';
        String query = CommonUtilController.buildQuery(selectFields, 'Handover__c', whereCondition, 'Opportunity__r.CreatedDate DESC, fm_PaymentStatus__c DESC NULLS LAST');
        System.debug('check query :: ' + whereCondition);
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

        Map<Id, Quote> contractQuoteMap = new Map<Id, Quote>();
        for (Quote quote : [
            SELECT Id, Name, OpportunityId, ru_OilCoupon__c
            FROM Quote
            WHERE OpportunityId IN :opportunityId
            AND OpportunityId != NULL
            AND Status = 'Published'
        ]) {
            contractQuoteMap.put(quote.OpportunityId, quote);
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
                handover.Opportunity__r.VehicleStock__r,
                contractQuoteMap.get(handover.Opportunity__c)?.ru_OilCoupon__c
            ));
        }

        return handoverWrapList;
    }
}