public with sharing class PaymentTrackerController {

    public class PaymentTrackerWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String oppId;
        @AuraEnabled public String ptName;
        @AuraEnabled public String sa;
        @AuraEnabled public String product;
        @AuraEnabled public String productUrl;
        @AuraEnabled public String oppUrl;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public String saleNumber;
        @AuraEnabled public String status;
        @AuraEnabled public String progressLabel;
        @AuraEnabled public Boolean isVat;
        @AuraEnabled public Boolean isPayment;
        // @AuraEnabled public Date dueDate;
        @AuraEnabled public String remark;
        @AuraEnabled public Date taxDate;
        @AuraEnabled public Date handoverDate;
        @AuraEnabled public String contractUrl;
        @AuraEnabled public String contractNumber;

        public PaymentTrackerWrapper(String id, String oppId, String ptName, String sa, String product, String productUrl, String oppUrl, String opportunityName, String saleNumber, String status, String progressLabel, Boolean isVat, Boolean isPayment, /* Date dueDate, */ String remark, Date taxDate, Date handoverDate, String contractUrl, String contractNumber) {
            this.id = id;
            this.oppId = oppId;
            this.ptName = ptName;
            this.sa = sa;
            this.product = product;
            this.oppUrl = oppUrl;
            this.productUrl = productUrl;
            this.status = status;
            this.progressLabel = progressLabel;
            this.opportunityName = opportunityName;
            this.saleNumber = saleNumber;
            this.isVat = isVat;
            this.isPayment = isPayment;
            // this.dueDate = dueDate;
            this.remark = remark;
            this.taxDate = taxDate;
            this.handoverDate = handoverDate;
            this.contractUrl = contractUrl;
            this.contractNumber = contractNumber;
        }
    }

    public class PaymentTypeWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal requestAmount;
        @AuraEnabled public Decimal depositAmount;
        @AuraEnabled public String progressLabel;
        
        public PaymentTypeWrapper(String id, String name, String status, Decimal requestAmount, Decimal depositAmount, String progressLabel) {
            this.id = id;
            this.name = name;
            this.status = status;
            this.requestAmount = requestAmount;
            this.depositAmount = depositAmount;
            this.progressLabel = progressLabel;
        }
    }

    @AuraEnabled
    public static Map<String, Object> getInitData() {

        return new Map<String, Object>{
            'paymentTrackerList' => getPaymentTracker(''),
            'status' => CommonUtilController.getPickList('PaymentTracker__c', 'Status__c')
        };
    }

    @AuraEnabled
    public static void startBatchJob(List<String> oppIdList) {
        AsyncOffsetRequest batchJob = new AsyncOffsetRequest(oppIdList);
        System.enqueueJob(batchJob);
    }

    @AuraEnabled
    public static List<PaymentTrackerWrapper> getFilteredPaymentTrackerList(Map<String, String> filterMap) {

        String whereConditions = buildWhereConditions(filterMap);
        return getPaymentTracker(whereConditions);
    }

    // PaymentTrackerWrapper - 입금현황관리
    private static List<PaymentTrackerWrapper> getPaymentTracker(String whereConditions) {

        List<String> queryList = new List<String>();

        queryList.add('SELECT Id, Name, Account__c, Opportunity__c, Opportunity__r.Owner.Name, Opportunity__r.Description, Opportunity__r.ContractId, Opportunity__r.Contract.ContractNumber, Opportunity__r.Contract.Quote__r.Product__c, Opportunity__r.Contract.Quote__r.Product__r.Name, Opportunity__r.SaleNumber__c, Opportunity__r.Name, Opportunity__r.HandoverDate__c, Opportunity__r.TaxInvoiceDate__c, Opportunity__r.Contract.fm_RealSalesPrice__c, fm_dueDate__c, toLabel(Status__c), TotalAmount__c, ru_DepositAmount__c, fm_IsVATDeferred__c, fm_IsPaymentDeferred__c, IsValid__c ');
        queryList.add('FROM PaymentTracker__c');
        queryList.add('WHERE IsValid__c = true');
        if(String.isNotBlank(whereConditions)) {
            queryList.add('AND ' + whereConditions);
        }
        queryList.add('ORDER BY Name');

        String query = String.join(queryList, ' ');

        List<PaymentTracker__c> paymentTrackerList = Database.query(query);

        List<PaymentTrackerWrapper> paymentTrackerWrapList = new List<PaymentTrackerWrapper>();

        for(PaymentTracker__c paymentTracker : paymentTrackerList) {

            Decimal price = 0;
            Decimal totalPrice = 0;
            totalPrice = paymentTracker.ru_DepositAmount__c;
            price = paymentTracker.TotalAmount__c;

            PaymentTrackerWrapper paymentTrackerWrap = new PaymentTrackerWrapper(
                paymentTracker.Id,
                paymentTracker.Opportunity__c != null ? paymentTracker.Opportunity__c : null,
                paymentTracker.Name,
                paymentTracker.Opportunity__c != null ? paymentTracker.Opportunity__r.Owner.Name : null,
                paymentTracker.Opportunity__r.Contract.Quote__r.Product__c != null ? paymentTracker.Opportunity__r.Contract.Quote__r.Product__r.name : null,
                paymentTracker.Opportunity__r.Contract.Quote__r.Product__c,
                paymentTracker.Opportunity__c,
                paymentTracker.Opportunity__c != null ? paymentTracker.Opportunity__r.Name : null,
                paymentTracker.Opportunity__c != null ? paymentTracker.Opportunity__r.SaleNumber__c : null,
                paymentTracker.Status__c,
                // ((paymentTracker.Payment__r.ru_DepositAmount__c / paymentHistory.Payment__r.Price__c ) * 100).setScale(0, RoundingMode.DOWN) + '%',
                totalPrice != 0 ? ((totalPrice / price) *100).setScale(1, RoundingMode.HALF_UP) + '%' : '0%',
                paymentTracker.fm_IsVATDeferred__c,
                paymentTracker.fm_IsPaymentDeferred__c,
                // paymentTracker.fm_dueDate__c,
                paymentTracker.Opportunity__r.Description,
                paymentTracker.Opportunity__c != null ? paymentTracker.Opportunity__r.TaxInvoiceDate__c : null,
                paymentTracker.Opportunity__c != null ? paymentTracker.Opportunity__r.HandoverDate__c : null,
                paymentTracker.Opportunity__r.ContractId != null ? '/lightning/r/Contract/' + paymentTracker.Opportunity__r.ContractId + '/view' : null,
                paymentTracker.Opportunity__r.Contract.ContractNumber != null ? paymentTracker.Opportunity__r.Contract.ContractNumber : null
            );
            paymentTrackerWrapList.add(paymentTrackerWrap);
        }

        return paymentTrackerWrapList;
    }

    // PaymentTypeWrapper - 입급현황 종류
    @AuraEnabled
    public static List<PaymentTypeWrapper> getPaymentType(String recordId) {
        
        List<PaymentType__c> paymentTypeList = [
            SELECT Id, Name, RequestAmount__c, ExpirationDate__c, PaymentTracker__c,
                   DepositAmount__c, toLabel(Type__c), fm_LeftAmount__c, DiscountAmount__c, UpdateStage__c
            FROM PaymentType__c  
            WHERE PaymentTracker__c = :recordId
        ]; 

        List<PaymentTypeWrapper> paymentTypeWrapList = new List<PaymentTypeWrapper>();

        for(PaymentType__c paymentType : paymentTypeList) {

            PaymentTypeWrapper paymentTypeWrap = new PaymentTypeWrapper(
                paymentType.PaymentTracker__c,
                paymentType.Name,
                paymentType.Type__c,
                paymentType.RequestAmount__c,
                paymentType.DepositAmount__c,
                paymentType.DepositAmount__c != 0 ? ((paymentType.DepositAmount__c / paymentType.RequestAmount__c) *100).setScale(1, RoundingMode.HALF_UP) + '%' : '0%'
            );
            paymentTypeWrapList.add(paymentTypeWrap);
        }

        return paymentTypeWrapList;
    }


    private static String buildWhereConditions(Map<String, String> filterMap) {

        String whereConditions = '';
        String tempWhere = '';
        Boolean isFirstCondition = true; // 첫 번째 조건인지 여부를 판단

        Map<String, String> fieldMap = new Map<String, String>{
            'status' => 'PaymentTracker__c.Status__c',
            'opportunityName' => 'Opportunity__r.Owner.Name'
        };

        // 필터 맵 순회
        for (String key : filterMap.keySet()) {
            String value = filterMap.get(key);
    
            if (String.isNotBlank(value)) {
                String actualField = fieldMap.containsKey(key) ? fieldMap.get(key) : key; // 변환

                String condition = '';

                if (actualField == 'Opportunity__r.Owner.Name') {
                    condition = actualField + ' LIKE \'%' + String.escapeSingleQuotes(value) + '%\'';
                } else {
                    condition = actualField + ' = \'' + String.escapeSingleQuotes(value) + '\'';
                }
                // 첫 번째 조건인지 확인하여 WHERE 절 생성
                if (isFirstCondition) {
                    whereConditions += condition;
                    isFirstCondition = false;
                } else {
                    whereConditions += ' AND ' + condition;
                }
            }
        }
    
        return whereConditions;

    }

}