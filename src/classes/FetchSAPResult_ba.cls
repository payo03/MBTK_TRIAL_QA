/**
* @Author            : payo03@solomontech.net
* @Description 		 : SAP 처리결과 Fetch
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-10      payo03@solomontech.net           Created
  1.1      2025-04-16      payo03@solomontech.net           취소IF Case 추가
*/
public without sharing class FetchSAPResult_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    private final static Map<String, List<String>> PARAM_KEY_MAP = new Map<String, List<String>>{
            InterfaceSAP.IF_SMS010_ASYNC => new List<String>{'IFID'},
            InterfaceSAP.IF_SMS011_ASYNC => new List<String>{'IFID'},
            InterfaceSAP.IF_SMS012_ASYNC => new List<String>{'IFID'},
            InterfaceSAP.IF_SMS013 => new List<String>{'IFID', 'ISREQNO', 'CRTP'}
    };
    private final static Map<String, String> IF_KEY_MAP = new Map<String, String>{
            InterfaceSAP.IF_SMS010_ASYNC => InterfaceSAP.IF_SMS014,
            InterfaceSAP.IF_SMS011_ASYNC => InterfaceSAP.IF_SMS015,
            InterfaceSAP.IF_SMS012_ASYNC => InterfaceSAP.IF_SMS016,
            InterfaceSAP.IF_SMS013 => InterfaceSAP.IF_SMS017
    };
    private final static Set<String> CHAIN_PROCESS_IF_ID = new Set<String>{
            InterfaceSAP.IF_SMS014, InterfaceSAP.IF_SMS015
    };
    public static final String DEFAULT_CONDITION =
            'Id IN ( ' +
                    '   SELECT IFAuditLog__c ' +
                    '   FROM IFAuditLogDetail__c ' +
                    '   WHERE IsResult__c IN (\'C\', \'N\') ' +
                    '   AND IsResponse__c = \'Y\' '+
                    ') ';
    private final static Integer BATCH_SIZE = 10;  // Schedule 배치 200 Size고정

    public String dynamicField;                     // 필드조건 SELECT
    public String dynamicCondition;                 // 특정조건으로만 Batch 실행

    public FetchSAPResult_ba(String dynamicField, String dynamicCondition) {
        System.debug(this.dynamicField);
        System.debug(this.dynamicCondition);
        if(dynamicField != null) this.dynamicField = dynamicField;
        if(dynamicCondition != null) this.dynamicCondition = dynamicCondition;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        System.debug(this.dynamicField);
        System.debug(this.dynamicCondition);
        String selectFields                                 = getFields();
        if(this.dynamicField != null) selectFields          = this.dynamicField;

        String fromObject                                   = 'IFAuditLog__c ';
        // IsResult : SAP Process Fetch 결과. IsResponse : SAP Request 결과
        String whereConditions                              = DEFAULT_CONDITION;
        if(this.dynamicCondition != null) whereConditions   = this.dynamicCondition;

        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, whereConditions);
        System.debug(buildQuery);
        return Database.getQueryLocator(buildQuery);
    }

    public void execute(SchedulableContext context) {
        String dynamicField = null;
        String dynamicCondition = null;

        if(this.dynamicField != null) dynamicField = this.dynamicField;
        if(this.dynamicCondition != null) dynamicCondition = this.dynamicCondition;

        Database.executeBatch(new FetchSAPResult_ba(dynamicField, dynamicCondition), BATCH_SIZE);
    }

    public void execute(Database.BatchableContext context, List<SObject> records) {

        // InterfaceId별 List Map
        Map<String, String> externalIdMap = new Map<String, String>();
        Map<String, List<IFAuditLog__c>> ifIdLogListMap = new Map<String, List<IFAuditLog__c>>();
        for(SObject record :records) {
            IFAuditLog__c log = (IFAuditLog__c) record;
            String key = log.IF_Id__c;

            for (IFAuditLogDetail__c detail : log.IFAuditLogDetails__r) {
                externalIdMap.put(detail.Id, detail.ExternalId__c);
            }

            List<IFAuditLog__c> logList = ifIdLogListMap.containsKey(key)
                    ? ifIdLogListMap.get(key)
                    : new List<IFAuditLog__c>();
            logList.add(log);
            ifIdLogListMap.put(key, logList);
        }

        // AfterProcess를 위한 데이터 GET
        Map<String, Opportunity> opportunityMap = new Map<String, Opportunity>();
        for(Opportunity oppty : [
                SELECT Id, VehicleStock__r.Name
                FROM Opportunity
                WHERE Id IN :externalIdMap.values()
        ]) {
            String key = oppty.VehicleStock__r.Name;

            opportunityMap.put(key, oppty);
        }

        Map<String, VehicleStock__c> infoStockMap = new Map<String, VehicleStock__c>();
        for(VehicleStock__c stock : [
                SELECT Id, AvisOrderInfo__c, VehicleStatus__c
                FROM VehicleStock__c
                WHERE AvisOrderInfo__c IN :externalIdMap.values()
        ]) {
            infoStockMap.put(stock.AvisOrderInfo__c, stock);
        }

        // InterfaceId별 Parameter Setting
        Map<String, List<Map<String, String>>> paramIfIdLogListMap = new Map<String, List<Map<String, String>>>(); // API Parameter용
        for(String ifId : ifIdLogListMap.keySet()) {
            // DOCNO, IFID등 InterfaceId별 Key값, Key조합값 다름
            List<String> infoKeyList = PARAM_KEY_MAP.get(ifId);

            List<Map<String, String>> logMapList = new List<Map<String, String>>();
            for(IFAuditLog__c log : ifIdLogListMap.get(ifId)) {
                // IF_Id별 Log List
                String rawData = log.RawData__c;    // Request Body값
                Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(rawData);
                List<Object> items = (List<Object>) requestMap.get('ITEMS');

                // 2025-02-27 최윤석대리와 Teams미팅간 내용. SMS004, SMS007. SMS009는 단건밖에 안된다고 함......
                // 그외 데이터들은 List 배열로 구성됨(ex, SMS010, SMS011, SMS012, SMS013)
                for(Object item : items) {
                    // If_Id의 Body목록
                    Map<String, Object> itemMap = (Map<String, Object>) item;
                    Map<String, String> logMap = new Map<String, String>();

                    System.debug(JSON.serializePretty(itemMap));
                    for(String infoKey : infoKeyList) {
                        // IF_Id별 조회 Key 목록
                        String value = String.valueOf(itemMap.get(infoKey));

                        logMap.put(infoKey, value);
                    }
                    logMapList.add(logMap);
                }
            }
            paramIfIdLogListMap.put(ifId, logMapList);
        }
        System.debug(JSON.serializePretty(paramIfIdLogListMap));

        List<String> invoiceInfoIdList = new List<String>();            // OrderConfirm완료시 PurchaseInvoice 호출
        Map<Id, IFAuditLogDetail__c> updateLogMap = new Map<Id, IFAuditLogDetail__c>();
        Map<Id, AvisOrderInfo__c> updateInfoMap = new Map<Id, AvisOrderInfo__c>();
        Map<Id, VehicleStock__c> updateStockMap = new Map<Id, VehicleStock__c>();
        Map<Id, Opportunity> updateOpptyMap = new Map<Id, Opportunity>();
        Map<String, String> statusFieldMap = new Map<String, String>{
                '항구도착전' => '항구도착',
                '항구도착' => '항구도착전'
        };
        for(String ifId : paramIfIdLogListMap.keySet()) {
            // InterfaceId별 묶음 IFAuditLog(여러 LogId가 존재)
            // InterfaceId - LogId = 1 : N
            String fetchIfId = IF_KEY_MAP.get(ifId);

            System.debug('Original InterfaceId ' + ifId);
            System.debug('Fetch InterfaceId ' + fetchIfId);

            List<Map<String, String>> bodyMapList = paramIfIdLogListMap.get(ifId);
            Map<String, Object> responseMap = InterfaceSAP.doCallOutSAP(fetchIfId, bodyMapList);
            System.debug(JSON.serializePretty(responseMap));

            if (!responseMap.isEmpty() && Boolean.valueOf(responseMap.get('code'))) {
                // Heroku 통신 완료시. Sync
                String herokuMessage = String.valueOf(responseMap.get('message'));
                if(Test.isRunningTest()) herokuMessage = JSON.serialize(responseMap.get('message'));

                Map<String, Object> sapMap = (Map<String, Object>) JSON.deserializeUntyped(herokuMessage);
                if(String.valueOf(sapMap.get('Code')) == '0') {
                    // SAP 통신 완료시
                    List<Object> items = (List<Object>) sapMap.get('ResultData');
                    String resultCode = items.isEmpty() ? 'C' : 'Y';
                    String resultMessage = String.valueOf(sapMap.get('Message'));

                    List<IFAuditLog__c> logList = ifIdLogListMap.get(ifId);
                    for (IFAuditLog__c log : logList) {
                        // ver1.1 취소IF Case 추가
                        String updateCode = log.Type__c.contains('CANCEL') ? 'N' : resultCode;

                        // InterfaceId별 Log
                        List<IFAuditLogDetail__c> logDetails = log.IFAuditLogDetails__r;
                        for (IFAuditLogDetail__c logDetail : logDetails) {
                            // LogDetail(Record)별 Update
                            logDetail.IsResult__c = resultCode;
                            logDetail.ResultDatetime__c = Datetime.now();
                            logDetail.Description__c = resultMessage;

                            /* ============================================================================= */
                            /* ===================== Interface별 추가 Process작업 Start ===================== */
                            /* =============================================================================*/

                            Boolean isChain = CHAIN_PROCESS_IF_ID.contains(fetchIfId);              // Case. SMS010(OrderConfirm), SMS011(PurchaseInvoice)
                            Boolean isCustoms = InterfaceSAP.IF_SMS016.contains(fetchIfId);         // Case. SMS012(CustomsInfo)
                            Boolean isTax = InterfaceSAP.IF_SMS017.equals(fetchIfId);               // Case. SMS013(TaxInvoice)

                            if (isChain) {
                                // OrderConfirm, PurchaseInvoice Confirm

                                Boolean isOrderConfirm = InterfaceSAP.IF_SMS014.equals(fetchIfId);  // Case. SMS010(OrderConfirm)
                                String infoId = externalIdMap.get(logDetail.Id);
                                String field = isOrderConfirm
                                        ? 'OrderConfirmSAP__c'
                                        : 'PurchaseInvoiceSAP__c';

                                AvisOrderInfo__c info = new AvisOrderInfo__c(Id = infoId);
                                if(updateInfoMap.get(info.Id) != null) info = (AvisOrderInfo__c) updateInfoMap.get(info.Id);

                                info.put(field, updateCode);
                                updateInfoMap.put(info.Id, info);

                                // OrderConfirm 완료시.
                                // 1. 조회결과 Y, 2. CANCEL건x, 3. OrderConfirm IF
                                if (resultCode == 'Y' && updateCode == 'Y' && isOrderConfirm) invoiceInfoIdList.add(infoId);
                            } else if (isCustoms) {
                                // 세관통관 전송
                                String infoId = externalIdMap.get(logDetail.Id);
                                VehicleStock__c stock = infoStockMap.get(infoId);
                                if(updateStockMap.get(stock.Id) != null) stock = (VehicleStock__c) updateStockMap.get(stock.Id);

                                stock.put('VehicleStatus__c', '항구도착');

                                // ver1.1 취소IF Case 추가
                                if (resultCode == 'Y' && stock.VehicleStatus__c == '항구도착전') updateStockMap.put(stock.Id, stock);
                            } else if (isTax) {
                                // TaxInvoice. 매출번호/세금계산서 번호 Update

                                IF_DTO.TaxInvoice taxInvoice = (IF_DTO.TaxInvoice) JSON.deserialize(JSON.serialize(sapMap), IF_DTO.TaxInvoice.class);
                                for (IF_DTO.TaxInvoiceInfo invoiceInfo : taxInvoice.ResultData) {
                                    // SAP에서 LogId - 데이터 1개로 추정... 처리도 못했겠지만...  유일Key를 VIN Number로 가져오기
                                    String vinNumber = invoiceInfo.DISNUM;              // Key
                                    String saleNumber = invoiceInfo.ARNO;               // 매출번호
                                    String taxInvoiceNumber = invoiceInfo.TAXNO;        // 세금계산서 번호
                                    if (saleNumber == null) {
                                        logDetail.IsResult__c = 'N';
                                        logDetail.ResultDatetime__c = Datetime.now();
                                    }

                                    Opportunity oppty = opportunityMap.get(vinNumber);
                                    if(updateOpptyMap.get(oppty.Id) != null) oppty = (Opportunity) updateOpptyMap.get(oppty.Id);

                                    oppty.put('SaleNumber__c', saleNumber);
                                    oppty.put('TaxInvoiceNumber__c', taxInvoiceNumber);
                                    updateOpptyMap.put(oppty.Id, oppty);
                                }
                            }
                            updateLogMap.put(logDetail.Id, logDetail);

                            /* ============================================================================= */
                            /* ====================== Interface별 추가 Process작업 End ====================== */
                            /* ============================================================================= */
                        }
                    }
                }
            }
        }

        if(!updateLogMap.isEmpty()) update updateLogMap.values();     // DML
        if(!updateInfoMap.isEmpty()) update updateInfoMap.values();     // DML
        if(!updateStockMap.isEmpty()) update updateStockMap.values();     // DML
        if(!updateOpptyMap.isEmpty()) update updateOpptyMap.values();     // DML
        if(!invoiceInfoIdList.isEmpty()) System.enqueueJob(new AsyncPurchaseInvoice(invoiceInfoIdList, null));
    }

    public void finish(Database.BatchableContext context) {

        System.debug('########## FetchSAPResult_ba Finish ##########');
        System.debug('dynamicCondition : ' + this.dynamicCondition);
    }

    public static String getFields() {
        return 'Id, Name, If_Id__c, RawData__c, Type__c, ' +
                '( ' +
                '   SELECT Id, ExternalId__c ' +
                '   FROM IFAuditLogDetails__r ' +
                '   WHERE IsResult__c IN (\'C\', \'N\') ' +
                '   AND IsResponse__c = \'Y\' '+
                ') ';
    }
}