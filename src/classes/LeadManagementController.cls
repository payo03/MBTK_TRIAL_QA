/*************************************************************
 * @author : th.kim
 * @date : 2024-11-07
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-07      th.kim         Initial Version
 * 1.1          2024-11-18      jh.jung        convertByLead 추가
 * 1.2          2024-11-27      jh.jung        getLeadListByFilter 추가
 * 1.3          2024-12-09      jh.jung        convertByLead 업데이트(Oppty, OpptyLineItem, Quote, QuoteLineItem)
**************************************************************/
public without sharing class LeadManagementController {

    public class ProductWrap {
        public String id;
        public String segment;
        public String name;
        public Decimal quantity;
        public Decimal carAmt;
        public List<PricebookEntry> pricebookEntryList;
        public Decimal salesConditionRate;
    }

    public class CampaignWrap {
        public String id;
        public String name;
        public Date expireDate;
        public Decimal discountPrice;
        public Decimal discountRate;

    }

    @AuraEnabled
    public static List<Lead> getLeadListByFilter(Integer num) {

        String addDateQuery = ' ';
        if(num == 15) {
            addDateQuery = ' AND CreatedDate >= LAST_N_DAYS:15';
        } else if(num == 30) {
            addDateQuery = ' AND CreatedDate >= LAST_N_DAYS:30 AND CreatedDate < LAST_N_DAYS:15';
        } else if(num == 60) {
            addDateQuery = ' AND CreatedDate >= LAST_N_DAYS:60 AND CreatedDate < LAST_N_DAYS:30';
        } else if(num == 999) {
            addDateQuery = ' AND CreatedDate < LAST_N_DAYS:60';
        }
        String query = '';
        query += ' SELECT Id, Name, MobilePhone, RoadAddress__c, CreatedDate, Latitude__c, Longitude__c, Company, fm_Rating__c, ProductId__c, ProductId__r.Name ';
        query += ' FROM Lead ';
//        query += ' WHERE IsConverted = FALSE ';
        query += ' WHERE Status != \'Converted\' ';
        query += addDateQuery;
        query += ' AND OwnerId = \'' + UserInfo.getUserId() +'\'';
        query += ' ORDER BY CreatedDate DESC ';

        System.debug(query);

        return Database.query(query);
    }

    @AuraEnabled
    public static List<Task> getTaskListByLeadId(String leadId) {
        return [
                SELECT Id, Subject, Status, ActivityDate, Description, CreatedDate
                FROM Task
                WHERE WhoId = :leadId
                ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static void saveTask(String leadId, String Subject, String description) {
        Task newTask = new Task();
        newTask.Subject = Subject;
        newTask.Description = description;
        newTask.WhoId = leadId;
        newTask.Status = 'Open';
        newTask.OwnerId = UserInfo.getUserId();
        insert newTask;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getDashboardData() {

        Date threeMonthsAgo = System.today().addMonths(-3);

        Integer openLeads = [
                SELECT COUNT()
                FROM Lead
                WHERE Status != 'Converted'
                AND CreatedDate >= :threeMonthsAgo
                AND OwnerId = :UserInfo.getUserId()
        ];
        Integer convertedLeads = [
                SELECT COUNT()
                FROM Lead
//                WHERE IsConverted = true
                WHERE Status = 'Converted'
                AND CreatedDate >= :threeMonthsAgo
                AND OwnerId = :UserInfo.getUserId()
        ];
        Integer highTempLeads = [
                SELECT COUNT()
                FROM Lead
                WHERE fm_Rating__c = 'Hot'
                AND CreatedDate >= :threeMonthsAgo
                AND OwnerId = :UserInfo.getUserId()
        ];
        Integer totalLeads = [
                SELECT COUNT()
                FROM Lead
                WHERE CreatedDate >= :threeMonthsAgo
                AND OwnerId = :UserInfo.getUserId()
        ];

        return new Map<String, Integer>{
                'openLeads' => openLeads,
                'convertedLeads' => convertedLeads,
                'highTempLeads' => highTempLeads,
                'totalLeads' => totalLeads
        };
    }

    /**
     * @param inputMap
     *      String leadId
     *      String productId
     *      List<String> campaignIdList
     *      Integer firstAmt  -> 대출금 (totalLoan)
     *      Decimal interestRate
     *      Integer duration
     *      + financeId 도 필요
     * @return returnMap
     *      // 견적 생성 관련 Value
     *      Boolean isSuccess
     *      String value
     *      // 승인프로세스 관련 Value
     *      String accountId
     *      String leadId
     *      String dupType
     */
    @AuraEnabled
    public static Map<String, Object> createPreQuote(Map<String, Object> inputMap) {
        System.debug('createPreQuote input ::: ' + JSON.serialize(inputMap));
        String leadId = String.valueOf(inputMap.get('leadId'));
        return createPreQuoteList(new List<Map<String, Object>> { inputMap }).get(leadId);
    }

    @AuraEnabled
    public static Map<String, Map<String, Object>> createPreQuoteList(List<Map<String, Object>> inputMapList) {
        System.debug('createPreQuoteList input ::: ' + JSON.serialize(inputMapList));


        Date closeDate = Date.newInstance(System.today().year(), 12, 31);

        Set<String> leadIdSet = new Set<String>();
        Set<String> productIdSet = new Set<String>();
        Set<String> campaignIdSet = new Set<String>();

        Map<String, Map<String, Object>> inputMapByLeadId = new Map<String, Map<String, Object>>();
        for(Map<String, Object> inputMap : inputMapList) {
            if(inputMap == null) continue;
            if(inputMap.containsKey('leadId')) {
                inputMapByLeadId.put(String.valueOf(inputMap.get('leadId')), inputMap);
                leadIdSet.add((String) inputMap.get('leadId'));
            }
            if(inputMap.containsKey('productId')) {
                productIdSet.add((String) inputMap.get('productId'));
            }
            System.debug(inputMap.get('campaignIdList'));
            if(inputMap.containsKey('campaignIdList') && inputMap.get('campaignIdList') != '') {
//                List<String> campaignIdList = inputMap.get('campaignIdList').str;
                List<String> campaignIdList = (List<String>) JSON.deserialize((String) inputMap.get('campaignIdList'), List<String>.class);
                for (String campaignId : campaignIdList) {
                    if (String.isNotBlank(campaignId)) {
                        campaignIdSet.add((String)  campaignId); // String -> Id로 캐스팅
                    }
                }
            }
        }

        List<Lead> leadList = [SELECT Id, LastName, OwnerId FROM Lead WHERE Id IN :leadIdSet];
        Map<String, Lead> leadMap = new Map<String, Lead>(leadList);

        Map<String, ProductWrap> ProductWrapMap = getProductWrapMap(productIdSet);

        List<CampaignMaster__c> campaignList = [SELECT Id, Name, DiscountPrice__c, DiscountRate__c  FROM CampaignMaster__c WHERE Id IN :campaignIdSet];
        Map<String, CampaignMaster__c> campaignMap = new Map<String, CampaignMaster__c>(campaignList);

        Map<String, Map<String, Object>> resultKeyMap = new Map<String, Map<String, Object>>();
        String convertedStatus = [SELECT ApiName FROM LeadStatus WHERE IsConverted = TRUE AND ApiName = 'Converted'].ApiName;

        List<Lead> fetchLeads = getLeadList(inputMapList);

        User user = fetchLeads[0].Owner;

        Map<String, Map<String, String>> duplicateInfoMap = getAccountIdByLeadList(fetchLeads);
        System.debug('duplicateInfoMap ::: ' + JSON.serialize(duplicateInfoMap));

        List<Database.LeadConvert> converts = new List<Database.LeadConvert>();
        List<Lead> updateList = new List<Lead>();
        Map<String, String> leadAccountIdMap = new Map<String, String>();

        // leadId 별 중복 확인
        for(String leadId : duplicateInfoMap.keySet()) {
            Map<String, String> infoMap = duplicateInfoMap.get(leadId);

            String type = infoMap.get('type');
            String accountId = infoMap.get('accountId');

            Map<String, Object> returnMap = new Map<String, Object> {
                    'isSuccess' => false,
                    'value' => null,
                    'accountId' => null,
                    'dupType' => null
            };

            System.debug('type ::: ' + type);
            System.debug('accountId ::: ' + accountId);

            if(type.equals('noDuplicate')) {
                // 중복 없으면 Lead 변환 -> Account, Contact, Oppty 생성

                // Lead Conversion 설정
                Database.LeadConvert leadConvert = new Database.LeadConvert();
                leadConvert.setLeadId(leadId);
                leadConvert.setConvertedStatus(convertedStatus);

                converts.add(leadConvert);
            } else if(type.equals('myAcc')) {
                // 본인 소유의 Account 존재 -> Lead 상태 변경, 해당 Account로 이후 작업
                // 리드는 상태 변경해서 구분
                Lead currentLead = new Lead(Id = leadId,
                        Status = 'Converted',
                        Description = '기존 계정으로 견적 생성됨_' + Date.today().format().replace('/', '-'));
                updateList.add(currentLead);
                leadAccountIdMap.put(leadId, accountId);
            } else {
                // 다른 SA가 Account를 보유중
                // type, accountId 보유중, isSuccess = false
                returnMap.put('accountId', accountId);
                returnMap.put('dupType', 'otherAcc');
                resultKeyMap.put(leadId, returnMap);
            }
        }

        Savepoint sp = Database.setSavepoint();

        try {
            // 이 시점에서 leadAccountIdMap는 myAcc인 경우만 존재 -> 빈 기회 만들어주기
            List<Opportunity> insertOppList = new List<Opportunity>();
            for (String accountId : leadAccountIdMap.values()) {
                Opportunity opp = new Opportunity();
                opp.AccountId = accountId;
                opp.CloseDate = closeDate;
                opp.StageName = 'Quotation';
                opp.Name = '빈 기회';
                insertOppList.add(opp);
            }
            if (!insertOppList.isEmpty()) {
                insert insertOppList;
            }

            Set<Id> opportunityIdSet = new Set<Id>();
            for (Opportunity opportunity : insertOppList) {
                opportunityIdSet.add(opportunity.Id);
            }
            System.debug('resultKeyMap ::: ' + resultKeyMap);

            // convert 할 leadId 모음
            // leadAccountIdMap : 기존 myAcc에 convert 케이스 추가
            if (!converts.isEmpty()) {
                List<Database.LeadConvertResult> resultList = Database.convertLead(converts, false);
                for (Database.LeadConvertResult result : resultList) {
                    if (result.isSuccess()) {
                        leadAccountIdMap.put(result.getLeadId(), result.getAccountId());
                        opportunityIdSet.add(result.getOpportunityId());
                    }
                }
            }
            if (!updateList.isEmpty()) {
                update updateList;
            }


            Map<String, Map<String, Object>> addInputMapByAcc = new Map<String, Map<String, Object>>();
            // 변환된 lead, myAcc였던 lead를 기반으로 프로세스 진행
            for (String leadId : leadAccountIdMap.keySet()) {
                Map<String, Object> inputInfo = inputMapByLeadId.get(leadId);
                String accountId = leadAccountIdMap.get(leadId);
                String dupType = duplicateInfoMap.get(leadId).get('type');

                // inputInfo
                inputInfo.put('accountId', accountId);
                inputInfo.put('dupType', dupType);
                addInputMapByAcc.put(accountId, inputInfo);

            }
            System.debug('addInputMapByAcc ::: ' + addInputMapByAcc);

            // 잠금 아닌 기회 가져오기( 컨버트된 Oppty, 본인 소유 Account의 oppty(빈 Oppty) )
            List<Opportunity> opptyList = [
                    SELECT Id, AccountId, OwnerId, Owner.Agency__c
                    FROM Opportunity
//                    WHERE AccountId IN :addInputMapByAcc.keySet() AND IsLock__c = FALSE
                    WHERE Id IN :opportunityIdSet AND IsLock__c = FALSE
            ];
            System.debug('opptyList ::: ' + opptyList);

            Map<String, Opportunity> opptyMap = new Map<String, Opportunity>();
            Map<String, Quote> quoteMap = new Map<String, Quote>();

            Map<String, OpportunityLineItem> opptyLineItemMap = new Map<String, OpportunityLineItem>();
            Map<String, QuoteLineItem> quoteLineItemMap = new Map<String, QuoteLineItem>();
            //        Map<String, QuoteDetail__c> quoteDetailMap = new Map<String, QuoteDetail__c>();
            List<QuoteDetail__c> quoteDetailList = new List<QuoteDetail__c>();

            // oppty start
            for (Opportunity oppty : opptyList) {
                Map<String, Object> inputInfo = addInputMapByAcc.get(oppty.AccountId);

                Lead lead = leadMap.get((String) inputInfo.get('leadId'));
                ProductWrap productWrap = ProductWrapMap.get((String) inputInfo.get('productId'));

                // 수정할 정보 추가 & 업데이트
                oppty.Name = oppty.Owner.Agency__c + '-' + lead.LastName + ' ' + productWrap.Name;
                oppty.StageName = 'Quotation';
                oppty.CloseDate = closeDate;
                oppty.OwnerId = lead.OwnerId;

                opptyMap.put(oppty.AccountId, oppty);
            }
            update opptyMap.values();
            System.debug('opptyMap.values() ::: ' + opptyMap.values());

            // Product에 Pricebook 없는 케이스 처리 : productPricebookEntry 생성
            Pricebook2 pricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE AND IsActive = TRUE LIMIT 1];

            Map<Id, PricebookEntry> productPricebookEntryMap = new Map<Id, PricebookEntry>();
            for (Opportunity oppty : opptyList) {
                Map<String, Object> inputInfo = addInputMapByAcc.get(oppty.AccountId);
                ProductWrap productWrap = ProductWrapMap.get((String) inputInfo.get('productId'));

                if(productWrap?.pricebookEntryList.isEmpty()) {
                    // pricebookEntryList.add(new PricebookEntry(
                    //     Pricebook2Id = pricebook.Id,
                    //     Product2Id = productWrap.id,
                    //     UnitPrice = productWrap.carAmt,
                    //     IsActive = true
                    // ));
                    productPricebookEntryMap.put(productWrap.id, new PricebookEntry(
                        Pricebook2Id = pricebook.Id,
                        Product2Id = productWrap.id,
                        UnitPrice = productWrap.carAmt,
                        IsActive = true
                    ));
                }
            }
            insert productPricebookEntryMap.values();

            // opptyLineItem start
            for (Opportunity oppty : opptyList) {
                Map<String, Object> inputInfo = addInputMapByAcc.get(oppty.AccountId);
                Lead lead = leadMap.get((String) inputInfo.get('leadId'));
                ProductWrap productWrap = ProductWrapMap.get((String) inputInfo.get('productId'));

                Decimal tempPrice = productWrap.carAmt * (1 - (productWrap.salesConditionRate / 100));

                List<String> campaignIdList = new List<String>();
                if(inputInfo.get('campaignIdList') != '') {
                    campaignIdList = (List<String>) JSON.deserialize(String.valueOf(inputInfo.get('campaignIdList')), List<String>.class);
                    for (String campaignId : campaignIdList) {
                        System.debug('campaignId ::: ' + campaignId);
                        CampaignMaster__c campaign = campaignMap.get(campaignId);
                        System.debug('campaign ::: ' + campaign);
                        tempPrice -= (campaign.DiscountRate__c != null)
                                ? (productWrap.carAmt * campaign.DiscountRate__c) / 100
                                : campaign.DiscountPrice__c;
                    }
                }

                OpportunityLineItem opptyLineItem = new OpportunityLineItem();
                opptyLineItem.OpportunityId = oppty.Id;
                opptyLineItem.Product2Id = productWrap.Id;
                // pricebookId가 없는 경우도 존재... -> pricebook
                opptyLineItem.PricebookEntryId = productWrap.pricebookEntryList.isEmpty()
                        ? productPricebookEntryMap.get(productWrap.Id).Id
                        : productWrap.pricebookEntryList[0].Id;
                opptyLineItem.UnitPrice = tempPrice;
                opptyLineItem.Quantity = 1;

                opptyLineItemMap.put(oppty.Id, opptyLineItem);
            }
            insert opptyLineItemMap.values();
            System.debug('opptyLineItemMap.values() ::: ' + opptyLineItemMap.values());

            // quote start
            for (Opportunity oppty : opptyList) {
                Map<String, Object> inputInfo = addInputMapByAcc.get(oppty.AccountId);
                ProductWrap productWrap = ProductWrapMap.get((String) inputInfo.get('productId'));
                Lead lead = leadMap.get((String) inputInfo.get('leadId'));

                Decimal tempPrice = productWrap.carAmt * (1 - (productWrap.salesConditionRate / 100));
                Decimal discountPrice = 0;

                List<String> campaignIdList = new List<String>();
                if(inputInfo.get('campaignIdList') != '') {
                    campaignIdList = (List<String>) JSON.deserialize(String.valueOf(inputInfo.get('campaignIdList')), List<String>.class);
                    for (String campaignId : campaignIdList) {
                        CampaignMaster__c campaign = campaignMap.get(campaignId);
//                        tempPrice -= (campaign.DiscountRate__c != null)
//                                ? (productWrap.carAmt * campaign.DiscountRate__c) / 100
//                                : campaign.DiscountPrice__c;
                        discountPrice += (campaign.DiscountRate__c != null)
                                ? (productWrap.carAmt * campaign.DiscountRate__c) / 100
                                : campaign.DiscountPrice__c;
                    }
                }
                tempPrice -= discountPrice;

                System.debug('totalLoan ::: ' + inputInfo.get('totalLoan'));
                System.debug('interestRate ::: ' + inputInfo.get('interestRate'));
                Decimal totalLoan = Decimal.valueOf(String.valueOf(inputInfo.get('totalLoan')));
                Decimal interestRate = Decimal.valueOf(String.valueOf(inputInfo.get('interestRate')));

                Quote quote = new Quote();
                quote.Name = 'quoteName';
                quote.OpportunityId = oppty.Id;
                quote.Status = 'Draft';
                // pricebookId가 없는 경우도 존재... -> pricebook?
                quote.Pricebook2Id = productWrap.pricebookEntryList.isEmpty()
                        ? productPricebookEntryMap.get(productWrap.Id).Pricebook2Id
                        : productWrap.pricebookEntryList[0].Pricebook2Id;
                quote.TotalVehiclePrice__c = productWrap.carAmt;
                quote.SalesconditionDiscountAmt__c = productWrap.carAmt * (productWrap.salesConditionRate / 100);
                quote.DiscountAmt__c = discountPrice;
//                quote.RealSalesPrice__c = tempPrice;
                quote.Deposit__c = 1000000;
                // Decimal loadAmount = inputInfo.get('totalLoan') != null ? totalLoan : 0;
                //                quote.LoanAmount__c = inputInfo.get('totalLoan') != null ? totalLoan : 0;
                // quote.AdvancePayment__c = tempPrice - loadAmount;
                quote.AdvancePayment__c = inputInfo.get('advancePayment') != null ? totalLoan : 0;
                Decimal loadAmount = quote.TotalVehiclePrice__c - quote.SalesconditionDiscountAmt__c - quote.DiscountAmt__c - quote.Deposit__c - quote.AdvancePayment__c;
//                quote.DeliveryPrice__c = quote.TotalVehiclePrice__c - quote.Deposit__c - quote.LoanAmount__c;
                quote.DefaultInterestRate__c = inputInfo.get('interestRate') != null ? interestRate : 0;
                quote.MonthDivideInputMonth__c = Integer.valueOf(inputInfo.get('duration'));
                quote.MonthlyPayment__c = calPMT(quote.DefaultInterestRate__c, quote.MonthDivideInputMonth__c, loadAmount);
                quote.Finance__c = String.valueOf(inputInfo.get('financeId'));
                quote.Product__c = String.valueOf(inputInfo.get('productId'));
                quote.OwnerId = lead.OwnerId;

                quoteMap.put(oppty.Id, quote);
            }
            insert quoteMap.values();
            System.debug('quoteMap.values() ::: ' + quoteMap.values());

            // quoteLineItem start
            for (Opportunity oppty : opptyList) {
                Map<String, Object> inputInfo = addInputMapByAcc.get(oppty.AccountId);
                ProductWrap productWrap = ProductWrapMap.get((String) inputInfo.get('productId'));

                Decimal tempPrice = productWrap.carAmt * (1 - (productWrap.salesConditionRate / 100));

                List<String> campaignIdList = new List<String>();
                if(inputInfo.get('campaignIdList') != '') {
                    campaignIdList = (List<String>) JSON.deserialize(String.valueOf(inputInfo.get('campaignIdList')), List<String>.class);
                    for (String campaignId : campaignIdList) {
                        CampaignMaster__c campaign = campaignMap.get(campaignId);
                        tempPrice -= (campaign.DiscountRate__c != null)
                                ? (productWrap.carAmt * campaign.DiscountRate__c) / 100
                                : campaign.DiscountPrice__c;
                    }
                }

                QuoteLineItem quoteLineItem = new QuoteLineItem();
                quoteLineItem.QuoteId = quoteMap.get(oppty.Id).Id;
                // pricebookId가 없는 경우도 존재... -> pricebook?
                quoteLineItem.PricebookEntryId = productWrap.pricebookEntryList.isEmpty()
                        ? productPricebookEntryMap.get(productWrap.Id).Id
                        : productWrap.pricebookEntryList[0].Id;
                quoteLineItem.UnitPrice = tempPrice;
                quoteLineItem.Quantity = 1;

                quoteLineItemMap.put(oppty.Id, quoteLineItem);
            }
            insert quoteLineItemMap.values();
            System.debug('quoteLineItemMap.values() ::: ' + quoteLineItemMap.values());

            // quoteDetail start

            List<Quote> insertedQuotes = [
                    SELECT Id, Name, OpportunityId, Opportunity.AccountId
                    FROM Quote
                    WHERE Id IN :quoteMap.values()
            ];

            //        for(Quote quote : quoteMap.values()) {
            for (Quote quote : insertedQuotes) {

                Map<String, Object> inputInfo = addInputMapByAcc.get(quote.Opportunity.AccountId);
                ProductWrap productWrap = ProductWrapMap.get((String) inputInfo.get('productId'));

                Lead lead = leadMap.get((String) inputInfo.get('leadId'));

                QuoteDetail__c quoteDetailByProduct = new QuoteDetail__c();
                quoteDetailByProduct.Quote__c = quote.Id;
                quoteDetailByProduct.Type__c = '차종';
                quoteDetailByProduct.Name = productWrap.name;
                quoteDetailByProduct.Product__c = productWrap.id;

                quoteDetailList.add(quoteDetailByProduct);

                List<String> campaignIdList = new List<String>();
                if(inputInfo.get('campaignIdList') != '') {
                    campaignIdList = (List<String>) JSON.deserialize(String.valueOf(inputInfo.get('campaignIdList')), List<String>.class);
                    for (String campaignId : campaignIdList) {
                        CampaignMaster__c campaign = campaignMap.get(campaignId);

                        QuoteDetail__c quoteDetailByCampaign = new QuoteDetail__c();
                        quoteDetailByCampaign.Quote__c = quote.Id;
                        quoteDetailByCampaign.Type__c = '캠페인';
                        quoteDetailByCampaign.Name = campaign.Name;
                        quoteDetailByCampaign.CampaignMaster__c = campaignId;

                        quoteDetailList.add(quoteDetailByCampaign);
                    }
                }

            }
            insert quoteDetailList;
            System.debug('quoteDetailList ::: ' + quoteDetailList);

            for (String leadId : leadAccountIdMap.keySet()) {
                String accountId = leadAccountIdMap.get(leadId);
                String opptyId = opptyMap.get(accountId).Id;
                Map<String, Object> returnMap = new Map<String, Object>{
                        'accountId' => accountId,
                        'isSuccess' => quoteMap.containsKey(opptyId),
                        'value' => quoteMap.get(opptyId).Id
                };

                resultKeyMap.put(leadId, returnMap);
            }
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('e.toString() ::: ' + e.toString());
            System.debug('e.getStackTraceString() ::: ' + e.getStackTraceString());
        }
        System.debug('createPreQuoteList return ::: ' + JSON.serialize(resultKeyMap));
        return resultKeyMap;
    }

    private static Double calPMT(Decimal interestRate, Decimal nper, Decimal pv) {
        Double rate = (interestRate / 100) / 12;
        if(nper == 0) return 0.0;
        if(rate == 0) return pv / nper;

        Double pmtValue = (pv * rate) / (1 - Math.pow(1 + rate, -Double.valueOf(nper))); // PMT
        return Math.round(pmtValue / 10) * 10;   // 1원 절삭
    }

    /**
     * @param inputMap
     *      String accountId
     *      String leadId
     * @return returnMap
     *      Boolean isSuccess
     *      String value
     */
    @AuraEnabled
    public static Map<String, Object> callApprovalProcess(Map<String, String> inputMap) {
        String leadId = inputMap.get('leadId');
        return callApprovalProcessList(new List<Map<String, String>> { inputMap }).get(leadId);
    }

    @AuraEnabled
    public static Map<String, Map<String, Object>> callApprovalProcessList(List<Map<String, String>> inputMapList) {

        // Id : leadKey
        // value : returnMap(isSuccess, value)
        Map<String, Map<String, Object>> resultKeyMap = new Map<String, Map<String, Object>>();

        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> leadIdSet = new Set<Id>();
        String approvalProcess = 'LeadOwnerChange';

        for (Map<String, String> inputMap : inputMapList) {
            if (inputMap.containsKey('accountId')) {
                accountIdSet.add(inputMap.get('accountId'));
            }
            if (inputMap.containsKey('leadId')) {
                leadIdSet.add(inputMap.get('leadId'));
            }
        }

        Map<String, String> leadIdToAccountIdMap = new Map<String, String>();
        for(Map<String, String> inputMap : inputMapList) {
            leadIdToAccountIdMap.put(inputMap.get('leadId'), inputMap.get('accountId'));
        }

        Map<Id, Account> accountMap = new Map<Id, Account>();

        Map<Id, Lead> leadMap = new Map<Id, Lead>([
                SELECT Id, MobilePhone, LastName, ProductId__r.Name, ProductId__r.Segment1__c, ProductId__r.Segment2__c, OwnerId, ApprovalUser__c,
                        TYPEOF Owner WHEN User THEN Name, Agency__c, ManagerId END
                FROM Lead
                WHERE Id IN :leadIdSet
        ]);

        Map<Id, Account> tempAccountMap = new Map<Id, Account>([
                SELECT Id, Name, Owner.Name, Owner.Agency__c, PersonMobilePhone, Phone FROM Account WHERE Id IN :accountIdSet
        ]);
        for (Id leadId : leadIdToAccountIdMap.keySet()) {
            Id accountId = leadIdToAccountIdMap.get(leadId);
            if (tempAccountMap.containsKey(accountId)) {
                accountMap.put(leadId, tempAccountMap.get(accountId));
            }
        }

        System.debug('Lead Map: ' + leadMap);
        System.debug('Account Map: ' + accountMap);


        List<Map<String,String>> approvalInputList = new List<Map<String, String>>();
        for(String leadId : leadMap.keySet()) {
            Map<String, Object> returnMap = new Map<String, Object>{
                'isSuccess' => false
                , 'value' => '전달할 메세지'
            };

            Lead lead = leadMap.get(leadId);
            Account account = accountMap.get(leadId);

            System.debug('account ::: ' + account);
            System.debug('lead ::: ' + lead);

            User newSA = lead.Owner;
            System.debug('newSA.Agency__c ::: ' + newSA.Agency__c);
            User prevSA = account.Owner;
            System.debug('prevSA.Agency__c ::: ' + prevSA.Agency__c);

//            if(newSA.ManagerId == null) {
            if(lead.ApprovalUser__c == null) {
                returnMap.put('value', '담당 관리자가 없습니다.');
                resultKeyMap.put(leadId, returnMap);
                continue;
            }

            String comment = '기존 SA : ' + prevSA.Name;
            if(prevSA.Agency__c != null) {
                comment += '(' + prevSA.Agency__c + ')';
            }

            comment += '\n 요청한 SA : ' + newSA.Name;
            if(newSA.Agency__c != null) {
                comment += '(' + newSA.Agency__c + ')';
            }

            String accountPhone = (account.PersonMobilePhone != null)
                    ? account.PersonMobilePhone
                    : (account.Phone != null)
                        ? account.Phone
                        : '없음';

            comment += '\n 고객 이름 : ' + account.Name;
            comment += '\n 고객 모바일 번호 : ' + accountPhone;

            comment += '\n 요청한 Product : ' + lead.ProductId__r.Name;
            if(lead.ProductId__r.Segment1__c != null) {
                comment += '(' + CommonUtilController.getPicklistLabelForLabel('Product2', 'Segment1__c', lead.ProductId__r.Segment1__c) + ')';
            }

            Map<String,String> approvalInputMap = new Map<String,String>();
            approvalInputMap.put('comment', comment);
            approvalInputMap.put('recordId', leadId);
            approvalInputMap.put('userId', newSA.Id);
            approvalInputMap.put('approvalProcess', approvalProcess);

            approvalInputList.add(approvalInputMap);


//            String resultMsg = CommonUtilCustomController.ContractAmendmentApprovalProcess(new Map<String, String> {
//                    'comment' => comment
//                    , 'recordId' => leadId
//                    , 'userId' => newSA.Id
//                    , 'approvalProcess' => approvalProcess
//            });
//            System.debug('resultMsg ::: ' + resultMsg);
//
//            returnMap.put('value', '승인 프로세스 요청 성공');
//            returnMap.put('isSuccess', true);
//
//            System.debug('callApprovalProcess return ::: ' + returnMap);
//
//            resultKeyMap.put(leadId, returnMap);
        }

        // key : leadId , value : Approval.ProcessResult
        Map<String, Object> approvalMap = CommonUtilCustomController.approvalProcessList(approvalInputList);
        for(String leadId : approvalMap.keySet()) {
            Map<String, Object> returnMap = new Map<String, Object>();
            Approval.ProcessResult appRes = (Approval.ProcessResult) approvalMap.get(leadId);
            System.debug('appRes ::: ' + JSON.serialize(appRes));

            returnMap.put('isSuccess', appRes.isSuccess());
            resultKeyMap.put(leadId, returnMap);
        }



        return resultKeyMap;
    }

//    @AuraEnabled
//    public static Map<String, Object> callApprovalProcess(Map<String, String> inputMap) {
//        System.debug('callApprovalProcess input ::: ' + inputMap);
//
//        String approvalProcess = 'LeadOwnerChange';
//        String leadId = inputMap.get('leadId');
//        Map<String, Object> returnMap = new Map<String, Object> {
//            'isSuccess' => false
//            , 'value' => '전달할 메세지'
//        };
//
//        Lead selectedLead = getLead(leadId);
//
//        Account account = [SELECT Owner.Name, Owner.Agency__c, Owner.ManagerId FROM Account WHERE Id = :inputMap.get('accountId')];
//        User requestSA = [SELECT Name, Agency__c, ManagerId FROM User WHERE Id = :selectedLead.OwnerId];
////        User requestSA = [SELECT Name, Agency__c, ManagerId FROM User WHERE Id = :UserInfo.getUserId()];
//
//        if(requestSA.ManagerId == null) {
//            returnMap.put('value', '담당 매니저가 없습니다.');
//            return returnMap;
//        }
//
//        String comment = '기존 SA : ' + account.Owner.Name;
//        if(account.Owner.Agency__c != null) {
//            comment += '(' + account.Owner.Agency__c + ')';
//        }
//
//        comment += '\n 요청한 SA : ' + requestSA.Name;
//        if(requestSA.Agency__c != null) {
//            comment += '(' + requestSA.Agency__c + ')';
//        }
//
//        comment += '\n 요청한 Product : ' + selectedLead.ProductId__r.Name;
//        if(selectedLead.ProductId__r.Segment1__c != null) {
//            comment += '(' + CommonUtilController.getPicklistLabelForLabel('Product2', 'Segment1__c', selectedLead.ProductId__r.Segment1__c) + ')';
//        }
//
//        try {
//            String resultMsg = CommonUtilCustomController.ContractAmendmentApprovalProcess(new Map<String, String> {
//                    'comment' => comment
//                    , 'recordId' => inputMap.get('leadId')
//                    , 'userId' => selectedLead.OwnerId
//                    , 'approvalProcess' => approvalProcess
//            });
//            System.debug('resultMsg ::: ' + resultMsg);
//
//            returnMap.put('value', '승인 프로세스 요청 성공');
//            returnMap.put('isSuccess', true);
//
//        } catch(Exception e) {
//            returnMap.put('value', '담당자 문의');
//
//            System.debug(e.getMessage());
//            System.debug(e.getStackTraceString());
//        }
//        System.debug('callApprovalProcess return ::: ' + returnMap);
//
//        return returnMap;
//    }

//    private static Lead getLead(String leadId) {
//        // getLead
//        String selectField = 'Id, MobilePhone, LastName, ProductId__r.Name, ProductId__r.Segment1__c, ProductId__r.Segment2__c, OwnerId';
//        String whereCondition = CommonUtilController.buildWhereConditions(new Map<String, Object>{
//                'Id' => leadId
//        });
//
//        String buildQuery = CommonUtilController.buildQuery(selectField, 'Lead', whereCondition);
//        System.debug('buildQuery ::: ' + buildQuery);
//        List<Lead> resultQuery = Database.query(buildQuery);
//
//        return resultQuery[0];
//    }

    private static List<Lead> getLeadList(List<Map<String, Object>> inputMapList) {
        System.debug('getLeadList input ::: ' + JSON.serialize(inputMapList));
        Set<String> idSet = new Set<String>();
        for(Map<String, Object> inputMap : inputMapList) {
            String leadId = String.valueOf(inputMap.get('leadId'));

            idSet.add(leadId);
        }

//        String selectField = 'Id, MobilePhone, LastName, ProductId__r.Name, ProductId__r.Segment1__c, ProductId__r.Segment2__c, OwnerId';
//        String whereCondition = 'Id IN ' + CommonUtilController.joinedString(idSet);
//        String buildQuery = CommonUtilController.buildQuery(selectField, 'Lead', whereCondition);
//
//        System.debug('getLeadList input ::: ' + JSON.serialize(buildQuery));
//        return Database.query(buildQuery);

        // 필요한 데이터
//        Account account = [SELECT Owner.Name, Owner.Agency__c, Owner.ManagerId FROM Account WHERE Id = :inputMap.get('accountId')];
//        User requestSA = [SELECT Name, Agency__c, ManagerId FROM User WHERE Id = :selectedLead.OwnerId];

        List<Lead> leadList = [
                SELECT Id, MobilePhone, LastName, ProductId__r.Name, ProductId__r.Segment1__c, ProductId__r.Segment2__c, OwnerId,
                        TYPEOF Owner WHEN User THEN Name, Agency__c, ManagerId END
                FROM Lead
                WHERE Id IN :idSet
        ];

        return leadList;
    }

//    @AuraEnabled
//    public static String convertByLead(Lead checkedLead, String productId, String campaignListString) {
//        List<CampaignWrap> campaignList = (List<CampaignWrap>) JSON.deserialize(campaignListString, List<CampaignWrap>.class);
//        System.debug('convertByLead ::: ' + checkedLead);
//        System.debug('convertByLead ::: ' + campaignList);
//        Map<String, String> inputMap = new Map<String, String>();
//        inputMap.put('leadOwnerId', checkedLead.OwnerId);
//        inputMap.put('phone', checkedLead.MobilePhone);
//        inputMap.put('name', checkedLead.Name);
//        String dupStatus = LeadAcquisitionController.doCheckDuplicate(inputMap).get('type');
//        Savepoint sp = Database.setSavepoint();
//
//        try {
//            if(dupStatus != 'noDuplicate') {
//                return 'cannotConvertLead';
//            }
//            Opportunity convertOppty;
//            OpportunityLineItem convertOpptyLineItem;
//            Quote convertQuote;
//            QuoteLineItem convertQuoteLineItem;
//
//            // 변환 대상 Lead의 convertedStatus 가져오기
//            String convertedStatus = [
//                    SELECT MasterLabel
//                    FROM LeadStatus
//                    WHERE IsConverted = true
//                    LIMIT 1
//            ].MasterLabel;
//
//            // Lead Conversion 설정
//            Database.LeadConvert leadConvert = new Database.LeadConvert();
//            leadConvert.setLeadId(checkedLead.Id);
//            leadConvert.setConvertedStatus(convertedStatus);
//
//            // Lead Conversion 실행
//            Database.LeadConvertResult result = Database.convertLead(leadConvert);
//            if (result.isSuccess()) {
//                // 변환된 레코드 ID 가져오기
//                Id convertedAccountId = result.getAccountId();
//                Id convertedContactId = result.getContactId();
//                Id convertedOpportunityId = result.getOpportunityId();
//
//                if (convertedContactId != null && convertedAccountId != null) {
//                    if(productId != null) {
//                        ProductWrap productWrap = getProductWrapList(productId);
//
////                        convertOppty = setOppty(convertedOpportunityId, campaignId, checkedLead, productWrap);
//                        convertOppty = setOppty(convertedOpportunityId, campaignList, checkedLead, productWrap);
////                        CommonUtilController.applyObject(new List<Opportunity> {convertOppty}, 'UPDATE');
//                        update convertOppty;
//
//                        convertOpptyLineItem = setOpptyLineItem(productWrap, convertOppty);
////                        CommonUtilController.applyObject(new List<OpportunityLineItem> {convertOpptyLineItem}, 'INSERT');
//                        insert convertOpptyLineItem;
//
//                        convertQuote = setQuote(productWrap, convertOppty);
////                        CommonUtilController.applyObject(new List<Quote> {convertQuote}, 'INSERT');
//                        insert convertQuote;
//
//                        convertQuoteLineItem = setQuoteLineItem(convertQuote, productWrap);
////                        CommonUtilController.applyObject(new List<QuoteLineItem> {convertQuoteLineItem}, 'INSERT');
//                        insert convertQuoteLineItem;
//
//                        QuoteDetail__c quoteDetail = new QuoteDetail__c(Quote__c = convertQuote.Id, Type__c = '차종',
//                                Name = productWrap.name, Product__c = productId);
//                        insert quoteDetail;
//
//                    }
//                }
//                return convertedOpportunityId;
//            }
//            return null;
//        } catch (Exception e) {
//            System.debug('e.getMessage() :::' + e.getMessage());
//            System.debug('e.getStackTraceString() :::' + e.getStackTraceString());
//            Database.rollback(sp);
//            return null;
//        }
//    }

//    private static Opportunity setOppty(String opportunityId, String campaignId, Lead lead, ProductWrap productWrap) {
//    private static Opportunity setOppty(String opportunityId, List<CampaignWrap> campaignList, Lead lead, ProductWrap productWrap) {
//        PricebookEntry pricebookEntry = productWrap.pricebookEntryList[0];
//
//        Opportunity returnObj = new Opportunity();
//        returnObj.Id = opportunityId;
//        returnObj.Name = lead.Name + ' ' + productWrap.name;
////        returnObj.CarAmt__c = pricebookEntry.UnitPrice;
//        returnObj.CarAmt__c = productWrap.carAmt;
////        returnObj.SalesconditionDiscountAmt__c = (productWrap.salesConditionRate != null)
////                ? pricebookEntry.UnitPrice * productWrap.salesConditionRate / 100
////                : 0;
//        returnObj.SalesconditionDiscountAmt__c = (productWrap.salesConditionRate != null)
//                ? productWrap.carAmt * productWrap.salesConditionRate / 100
//                : 0;
//        // 캠페인 할인 값은 0으로 초기화
//        returnObj.DiscountAmt__c = 0;
//
//        // 선납금, 할부금리, 할부기간은 0으로
//        returnObj.FirstAmt__c = 0;
//        returnObj.DefaultInterestRate__c = 0;
//        returnObj.MonthDivideInputMonth__c = 0;
//
//        // 중간 가격
////        Decimal tempAmt = returnObj.CarAmt__c - returnObj.SalesconditionDiscountAmt__c;
//
////        System.debug('campaignId ::: ' + campaignId);
//        System.debug('campaignList ::: ' + campaignList);
////        if(campaignId != '') {
////            CampaignMaster__c campaignMaster = getCampaignMaster(campaignId);
////            // 캠페인 할인
////            returnObj.DiscountAmt__c =  (campaignMaster.DiscountRate__c != null)
////                    ? (tempAmt * campaignMaster.DiscountRate__c) / 100
////                    : campaignMaster.DiscountPrice__c;
////        }
//        for(CampaignWrap campaignWrap : campaignList) {
//            returnObj.DiscountAmt__c += (campaignWrap.discountRate != null)
//                    ? (returnObj.CarAmt__c * campaignWrap.discountRate) / 100
//                    : campaignWrap.discountPrice;
//        }
//        return returnObj;
//    }

//    private static OpportunityLineItem setOpptyLineItem(ProductWrap productWrap, Opportunity oppty) {
//        PricebookEntry pricebookEntry = productWrap.pricebookEntryList[0];
//        Decimal realSellAmt = oppty.CarAmt__c - oppty.SalesconditionDiscountAmt__c - oppty.DiscountAmt__c;
//
//        OpportunityLineItem returnObj = new OpportunityLineItem();
//        returnObj.OpportunityId = oppty.Id;
//        returnObj.Product2Id = productWrap.id;
//        returnObj.PricebookEntryId = pricebookEntry.Id;
//        returnObj.UnitPrice = realSellAmt;
//        returnObj.Quantity = 1;
//        return returnObj;
//    }

//    private static Quote setQuote(ProductWrap productWrap, Opportunity oppty) {
//        PricebookEntry pricebookEntry = productWrap.pricebookEntryList[0];
//
//        Quote returnObj = new Quote();
//        returnObj.Name = '견적_' + oppty.Name + '_' + Date.today().format().replace('/', '-');
//        returnObj.OpportunityId = oppty.Id;
//        returnObj.Status = 'Draft';
//        returnObj.Pricebook2Id = pricebookEntry.Pricebook2Id;
////        returnObj.CarAmt__c = pricebookEntry.UnitPrice;
////        returnObj.CarAmt__c = productWrap.carAmt;
//        returnObj.CarAmt__c = oppty.CarAmt__c;
//        returnObj.Product__c = productWrap.id;
//
//        // 기회에서 가져온 할인 값 넣기
//        returnObj.SalesconditionDiscountAmt__c = oppty.SalesconditionDiscountAmt__c;
//        returnObj.DiscountAmt__c = oppty.DiscountAmt__c;
//        returnObj.FirstAmt__c = oppty.FirstAmt__c;
//        returnObj.DefaultInterestRate__c = oppty.DefaultInterestRate__c;
//        returnObj.MonthDivideInputMonth__c = oppty.MonthDivideInputMonth__c;
//        return returnObj;
//    }

//    private static QuoteLineItem setQuoteLineItem(Quote quote, ProductWrap productWrap) {
//        PricebookEntry pricebookEntry = productWrap.pricebookEntryList[0];
//        Decimal realSellAmt = quote.CarAmt__c - quote.SalesconditionDiscountAmt__c - quote.DiscountAmt__c;
//
//        QuoteLineItem returnObj = new QuoteLineItem();
//        returnObj.QuoteId = quote.Id;
//        returnObj.PricebookEntryId = pricebookEntry.Id;
//        returnObj.UnitPrice = realSellAmt;
//        returnObj.Quantity = 1;
//        return returnObj;
//    }



    // 해당 ProductId에 맞는 ProductWrap(Product에 정보, SalesCondition, PricebookEntry List) 가져오기
//    private static ProductWrap getProductWrapList(String productId) {
//        String selectFields = 'Id, Name, Segment2__c, Quantity__c, CarAmt__c, (SELECT Id, UnitPrice, pricebook2Id FROM PricebookEntries), SalesConditionMaster__r.Discount__c';
//        String whereConditions =  'Id = \'' + productId + '\'';
//        String query = CommonUtilController.buildQuery(selectFields, 'Product2', whereConditions);
//
//        List<Product2> productList = Database.query(query);
//
//        ProductWrap returnObj = new ProductWrap();
//        returnObj.id = productList[0].Id;
//        returnObj.segment = productList[0].Segment2__c;
//        returnObj.name = productList[0].Name;
//        returnObj.quantity = productList[0].Quantity__c;
//        returnObj.carAmt = productList[0].CarAmt__c;
//        returnObj.pricebookEntryList = productList[0].PricebookEntries;
//        returnObj.salesConditionRate = productList[0].SalesConditionMaster__r.Discount__c;
//        return returnObj;
//    }

    // 해당 ProductId에 맞는 ProductWrap(Product에 정보, SalesCondition, PricebookEntry List) 가져오기
    private static Map<String, ProductWrap> getProductWrapMap(Set<String> productIdSet) {

        Map<String, ProductWrap> productWrapMap = new Map<String, ProductWrap>();
        List<Product2> productList = [
                SELECT Id, Name, Segment2__c, Quantity__c, CarAmt__c,
                    (SELECT Id, UnitPrice, pricebook2Id FROM PricebookEntries), SalesConditionMaster__r.Discount__c
                FROM Product2
                WHERE Id IN :productIdSet
        ];

        for (Product2 product : productList) {
            ProductWrap wrapObj = new ProductWrap();
            wrapObj.id = product.Id;
            wrapObj.segment = product.Segment2__c;
            wrapObj.name = product.Name;
            wrapObj.quantity = product.Quantity__c;
            wrapObj.carAmt = product.CarAmt__c;
            wrapObj.pricebookEntryList = product.PricebookEntries;
            wrapObj.salesConditionRate = product.SalesConditionMaster__r != null
                    ? product.SalesConditionMaster__r.Discount__c
                    : 0;

            productWrapMap.put(product.Id, wrapObj);
        }

        return productWrapMap;

    }

    // 번호 찾아서
    public static Map<String, Map<String, String>> getAccountIdByLeadList(List<Lead> leadList) {
        System.debug('getAccountIdByLeadList input ::: ' + JSON.serialize(leadList));
        Map<String, Map<String, String>> returnMap = new Map<String, Map<String, String>>();

        // Account Query Start
        String accFields = 'Id, OwnerId, Name, PersonMobilePhone';
        String accConditions = '';
        for(Integer i = 0; i < leadList.size(); i++) {
            Lead lead = leadList.get(i);
            System.debug('lead ::: ' + lead);

            if(i != leadList.size() - 1) {
                accConditions += '(Name = \'' + lead.LastName + '\' AND PersonMobilePhone = \'' + lead.MobilePhone + '\') OR ';
            } else {
                accConditions += '(Name = \'' + lead.LastName + '\' AND PersonMobilePhone = \'' + lead.MobilePhone + '\')';
            }
        }
        String accQuery = CommonUtilController.buildQuery(accFields, 'Account', accConditions);
        System.debug('accQuery ::: ' + accQuery);
        List<Account> accountList = Database.query(accQuery);

        Map<String, Account> accKeyMap = new Map<String, Account>();
        for(Account account : accountList) {
            String key = account.Name + '^' + account.PersonMobilePhone;

            accKeyMap.put(key, account);
        }
        // Account Query End

        // Contact Query Start
        String contactFields = 'Id, OwnerId, AccountId, LastName, MobilePhone, Account.Name';
        String contactConditions = '';
        for(Integer i = 0; i < leadList.size(); i++) {
            Lead lead = leadList.get(i);

            if(i != leadList.size() - 1) {
                contactConditions += '(LastName = \'' + lead.LastName + '\' AND MobilePhone = \'' + lead.MobilePhone + '\') OR ';
            } else {
                contactConditions += '(LastName = \'' + lead.LastName + '\' AND MobilePhone = \'' + lead.MobilePhone + '\')';
            }
        }
        String contactQuery = CommonUtilController.buildQuery(contactFields, 'Contact', contactConditions);
        List<Contact> contactList = Database.query(contactQuery);

        Map<String, Contact> contactKeyMap = new Map<String, Contact>();
        for(Contact contact : contactList) {
            String key = contact.LastName + '^' + contact.MobilePhone;

            contactKeyMap.put(key, contact);
        }
        // Contact Query End

        // Return Map
        for(Integer i = 0; i < leadList.size(); i++) {
            Map<String, String> infoMap = new Map<String, String>();
            Lead lead = leadList.get(i);

            String key = lead.LastName + '^' + lead.MobilePhone;
            Account acc = accKeyMap.get(key);
            Contact contact = contactKeyMap.get(key);

            if(acc == null && contact == null) {
                infoMap.put('type', 'noDuplicate');
                returnMap.put(lead.Id, infoMap);

                continue;
            }

            String userId = lead.OwnerId;
            String accId = acc != null ? acc.Id : contact.AccountId;
            String accName = acc != null ? acc.Name : contact.Account.Name;
            String ownerId = acc != null ? acc.OwnerId : contact.OwnerId;
            String type = ownerId == userId ? 'myAcc' : 'otherAcc';

            infoMap.put('accountId', accId);
            infoMap.put('accountName', accName);
            infoMap.put('ownerId', ownerId);
            infoMap.put('type', type);
            infoMap.put('requestId', userId);

            returnMap.put(lead.Id, infoMap);
        }
        System.debug('getAccountIdByLeadList return ::: ' + JSON.serialize(returnMap));

        return returnMap;
    }
}