/*************************************************************
 * @author : th.kim
 * @date : 2024-11-08
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-08      th.kim          Created
 * 2.0          2024-12-19      chaebeom.do     createPreQuote 로직 수정
**************************************************************/
public without sharing class LeadAcquisitionController {

    private static final String IF_ID = 'API_BIZ_CHK';

    // TODO 송찬영 Comment : IF_DTO.cls로 통합요청
    private class InputWrap {
        public List<String> b_no;
        public InputWrap(String bNo) {
            b_no = new List<String>{
                bNo
            };
        }
    }

    private class OutputWrap {
        public Integer request_cnt;
        public String status_code;
        public List<OutputData> data;
    }

    private class OutputData {
        public String b_no;
        public String b_stt;
        public String b_stt_cd;
        public String tax_type;
        public String end_dt;
        public String utcc_yn;
        public String tax_type_change_dt;
        public String invoice_apply_dt;
    }

    //IF 관련 아님
    public class LeadWrap {
        @AuraEnabled public String id;
        @AuraEnabled public String lastName;
        @AuraEnabled public String mobilePhone;
        @AuraEnabled public String company;
        @AuraEnabled public String bizNum;
        @AuraEnabled public String roadAddress;
        @AuraEnabled public String detailAddress;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String description;
        @AuraEnabled public String productId;

        public LeadWrap(String id, String lastName, String mobilePhone, String company, String bizNum, String roadAddress, String detailAddress, String postalCode, String description, String productId) {
            this.id = id;
            this.lastName = lastName;
            this.mobilePhone = mobilePhone;
            this.company = company;
            this.bizNum = bizNum;
            this.roadAddress = roadAddress;
            this.detailAddress = detailAddress;
            this.postalCode = postalCode;
            this.description = description;
            this.productId = productId;
        }
    }

    public class ProductWrap {
        @AuraEnabled public String id;
        @AuraEnabled public String segment;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal etaQuantity;
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal salesconditionRate;

        public ProductWrap(String id, String segment, String name, Decimal quantity, Decimal etaQuantity, Decimal listPrice, Decimal salesconditionRate) {
            this.id = id;
            this.segment = segment;
            this.name = name;
            this.quantity = quantity;
            this.etaQuantity = etaQuantity;
            this.listPrice = listPrice;
            this.salesconditionRate = salesconditionRate;
        }
    }

    public class CampaignWrap {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String memo;
        @AuraEnabled public Date expireDate;
        @AuraEnabled public Decimal discountPrice;
        @AuraEnabled public Decimal discountRate;

        public CampaignWrap(String id, String name, String memo, Date expireDate, Decimal discountPrice, Decimal discountRate) {
            this.id = id;
            this.name = name;
            this.memo = memo;
            this.expireDate = expireDate;
            this.discountPrice = discountPrice;
            this.discountRate = discountRate;
        }
    }

    public class CampaignDuplicateWrap {
      @AuraEnabled public String id;
      @AuraEnabled public String name;
      @AuraEnabled public String campaign1;
      @AuraEnabled public String campaign2;
      @AuraEnabled public String campaign1Name;
      @AuraEnabled public String campaign2Name;

      public CampaignDuplicateWrap(String id, String name, String campaign1, String campaign2, String campaign1Name, String campaign2name) {
          this.id = id;
          this.name = name;
          this.campaign1 = campaign1;
          this.campaign2 = campaign2;
          this.campaign1Name = campaign1Name;
          this.campaign2Name = campaign2Name;
      }
    }

    /**
     * @author chaebeom.do
     * @description Category 데이터 및 필터 Picklist 가져오기
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> getInitData() {
        return new Map<String, Object>{
            'productList' => getProduct(''),
            'segment' => CommonUtilController.getPickList('Product2', 'Segment2__c')
        };
    }

    // @AuraEnabled
    // public static Map<String, Object> getFinancialData(String productId) {
    //     QuoteCreatorController.productId = productId;

    //     return new Map<String, Object>{
    //         'financialList' => QuoteCreatorController.getFinancialList()
    //     };
    // }

    @AuraEnabled
    public static List<Map<String, Object>> getFinancialList(String productId) {

        List<Product2> productList = [SELECT Id, Segment2__c FROM Product2 WHERE Id = :productId];
        if (productList.isEmpty()) {
            return null;
        }

        Product2 product = productList[0];

        List<Finance__c> financialList = [
            SELECT Id, Name, MinimumInterestRate__c, MaximumInterestRate__c, MinimumDuration__c, MaximumDuration__c
            FROM Finance__c
            WHERE IsActive__c = TRUE
            AND (Segment2__c = :product.Segment2__c OR AllSegment2__c = TRUE)
            ORDER BY Name
        ];
        List<Map<String, Object>> financialMapList = new List<Map<String, Object>>();
        for (Finance__c finance : financialList) {
            financialMapList.add(new Map<String, Object>{
                'label' => finance.Name,
                'value' => finance.Id,
                'minInterestRate' => finance.MinimumInterestRate__c,
                'maxInterestRate' => finance.MaximumInterestRate__c,
                'minimumDuration' => finance.MinimumDuration__c,
                'maximumDuration' => finance.MaximumDuration__c
            });
        }
        return financialMapList;
    }

    @AuraEnabled
    public static List<ProductWrap> getFilteredProduct(Map<String, String> filterMap) {
        String whereConditions = buildWhereConditions(filterMap);
        return getProduct(whereConditions);
    }

    /**
     * @author chaebeom.do 
     * @description Lead 데이터 가져오기
     * @return List<LeadWrap>
     */
    @AuraEnabled
    public static List<LeadWrap> getLead(String leadId) {
        
        String selectFields = 'Id, LastName, MobilePhone, Company, BusinessNumber__c, RoadAddress__c, DetailAddress__c, PostalCode__c, Description, ProductId__c';
        String whereConditions = 'Id = \'' + leadId + '\'';
        String query = CommonUtilController.buildQuery(selectFields, 'Lead', whereConditions);

        List<Lead> leadList = Database.query(query);

        List<LeadWrap> leadWrapList = new List<LeadWrap>();
        for(Lead lead : leadList) { 
                LeadWrap leadWrap = new LeadWrap(
                lead.Id,
                lead.LastName,
                lead.MobilePhone,
                lead.Company,
                lead.BusinessNumber__c,
                lead.RoadAddress__c,
                lead.DetailAddress__c,
                lead.PostalCode__c,
                lead.Description,
                lead.ProductId__c
                );
            leadWrapList.add(leadWrap);
        }
        return leadWrapList;
    }

    /**
     * @author chaebeom.do 
     * @description product 데이터 가져오기
     * @return List<ProductWrap>
     */
    @AuraEnabled
    public static List<ProductWrap> getProduct(String whereConditions) {
        String selectFields = 'Id, Name, Segment2__c, Quantity__c, (SELECT id FROM VehicleStock__r WHERE Status__c = \'30일 재고\' OR Status__c = \'60일 재고\'), CarAmt__c, SalesConditionMaster__r.Discount__c';
        String defaultWhereConditions = '((VehicleCategory__r.Quantity__c > 0 AND Quantity__c > 0) OR After30DaysQty__c > 0 OR After60DaysQty__c > 0) AND IsDemotest__c = false';
        String orderConditions = 'Segment2__c desc';
        if (String.isNotBlank(whereConditions)) {
            whereConditions += ' AND ' + defaultWhereConditions;
        } else {
            whereConditions = defaultWhereConditions;
        }

        String query = CommonUtilController.buildQuery(selectFields, 'Product2', whereConditions, orderConditions);
        List<Product2> productList = Database.query(query);

        List<ProductWrap> productWrapList = new List<ProductWrap>();
        for(Product2 product : productList) {
            ProductWrap productWrap = new ProductWrap(
                product.Id,
                product.Segment2__c,
                product.Name,
                product.Quantity__c,
                product.VehicleStock__r.size(),
      //          0,
                product.CarAmt__c,
                product.SalesConditionMaster__r.Discount__c
            );
            productWrapList.add(productWrap);
        }
        return productWrapList;
    }

    /**
     * @author chaebeom.do 
     * @param id product id
     * @description product에 연결된 campaign 정보 가져오기
     * @return List<CampaignWrap>
     */
    @AuraEnabled
    public static List<CampaignWrap> getCampaign(String productId) {
        
        String selectFields = 'Id, Name, Memo__c, ExpireDate__c, DiscountPrice__c, DiscountRate__c';
        String whereConditions =  'Status__c =\'진행중\' AND Id IN (SELECT CampaignMaster__c FROM CampaignJunction__c WHERE Product__c = \'' + productId + '\')';
        String query = CommonUtilController.buildQuery(selectFields, 'CampaignMaster__c', whereConditions);
        
        List<CampaignMaster__c> campaignList = Database.query(query);

        String whereConditions2 =  'Status__c =\'진행중\' AND AllModelCheck__c = true';
        String query2 = CommonUtilController.buildQuery(selectFields, 'CampaignMaster__c', whereConditions2);
        
        List<CampaignMaster__c> campaignList2 = Database.query(query2);
        
        List<CampaignWrap> campaignWrapList = new List<CampaignWrap>();
        for(CampaignMaster__c campaign : campaignList) {
            CampaignWrap campaignWrap = new CampaignWrap(
                campaign.Id,
                campaign.Name,
                campaign.Memo__c,
                campaign.ExpireDate__c,
                campaign.DiscountPrice__c,
                campaign.DiscountRate__c
            );
            campaignWrapList.add(campaignWrap);
        }

        for(CampaignMaster__c campaign : campaignList2) {
            CampaignWrap campaignWrap = new CampaignWrap(
                campaign.Id,
                campaign.Name,
                campaign.Memo__c,
                campaign.ExpireDate__c,
                campaign.DiscountPrice__c,
                campaign.DiscountRate__c
            );
            campaignWrapList.add(campaignWrap);
        }

        return campaignWrapList;
    }

    /**
     * @author chaebeom.do 
     * @param id campaign id
     * @description campaign에 연결된 중복불가 오브젝트 정보 가져오기
     * @return List<CampaignDuplicateWrap>
     */
    @AuraEnabled
    public static List<CampaignDuplicateWrap> getCampaignPreventDuplicate(String campaignId) {
        
        String selectFields = 'Id, Name, CampaignMaster__c, CampaignMaster2__c, CampaignMaster__r.Name, CampaignMaster2__r.Name';
        String whereConditions =  'IsActive__c = true';
        if (String.isNotBlank(campaignId)) {
            whereConditions += ' AND (CampaignMaster__c = \'' + campaignId + '\' OR CampaignMaster2__c = \'' + campaignId + '\')';
        }
        String query = CommonUtilController.buildQuery(selectFields, 'CampaignPreventDuplicate__c', whereConditions);
        
        List<CampaignPreventDuplicate__c> campaignDupList = Database.query(query);
        
        List<CampaignDuplicateWrap> campaignDupWrapList = new List<CampaignDuplicateWrap>();
        for(CampaignPreventDuplicate__c campaignDuplicate : campaignDupList) {
            CampaignDuplicateWrap campaignDupWrap = new CampaignDuplicateWrap(
                campaignDuplicate.Id,
                campaignDuplicate.Name,
                campaignDuplicate.CampaignMaster__c,
                campaignDuplicate.CampaignMaster2__c,
                campaignDuplicate.CampaignMaster__r.Name,
                campaignDuplicate.CampaignMaster2__r.Name
            );
            campaignDupWrapList.add(campaignDupWrap);
        }

        return campaignDupWrapList;
    }

    public static String buildWhereConditions(Map<String, String> filterMap) {

        List<String> whereClauses = new List<String>();

        // 필터 맵 순회
        for (String key : filterMap.keySet()) {
            String value = filterMap.get(key);
            if (String.isNotBlank(value)) { // 값이 비어있지 않은 경우만 처리
                if (key == 'Name') { 
                    whereClauses.add(key + ' LIKE \'%' + String.escapeSingleQuotes(value) + '%\'');
                } else {
                    whereClauses.add(key + ' = \'' + String.escapeSingleQuotes(value) + '\'');
                }
            }
        }

        // 조건이 존재하면 AND로 결합
        String whereConditions = whereClauses.isEmpty() ? '' : String.join(whereClauses, ' AND ');


        return whereConditions; // 완성된 WHERE 절 반환
    }

    /**
     * @description Account 중복 체크
     * @param inputMap Name과 Phone 정보 Map
     *
     * @return true: 중복 | false: 중복 x
     */
    @AuraEnabled
    public static Map<String, String> doCheckDuplicate(Map<String, String> inputMap) {

        Map<String, String> resultMap = new Map<String, String>();

        String selectFields = 'Id, OwnerId';
        String accWhereConditions = 'Name = \'' + inputMap.get('name') + 
                                    '\' AND PersonMobilePhone = \'' + inputMap.get('phone') + '\'';
        String query = CommonUtilController.buildQuery(selectFields, 'Account', accWhereConditions);
        List<Account> accountList = Database.query(query);
        
        selectFields += ', AccountId';
        String conWhereConditions = 'LastName = \'' + inputMap.get('name') + 
                                    '\' AND MobilePhone = \'' + inputMap.get('phone') + '\'';
        String query2 = CommonUtilController.buildQuery(selectFields, 'Contact', conWhereConditions);
        List<Contact> contactList = Database.query(query2);

        if (accountList.isEmpty() && contactList.isEmpty()) {
            resultMap.put('type', 'noDuplicate');
        } else {
            system.debug('accountList :: ' + accountList);
            system.debug('accContactList :: ' + contactList);
            String userId = (inputMap.get('leadOwnerId') == null)
                    ? UserInfo.getUserId()
                    : inputMap.get('leadOwnerId');
            System.debug('userId ::: ' + userId);
            String ownerId = accountList.isEmpty() ? contactList[0].OwnerId : accountList[0].OwnerId;
            String personId = accountList.isEmpty() ? contactList[0].Id : accountList[0].Id;
            String accId = accountList.isEmpty() ? contactList[0].AccountId : accountList[0].Id;
            if (ownerId == userId) {
                resultMap.put('type', 'myAcc');
                resultMap.put('id', accId);
            } else {
                List<Opportunity> oppList = [
                SELECT Id
                FROM Opportunity
                WHERE IsClosed = false
                AND AccountId = :accId
                ];
                if (oppList.isEmpty()) {
                    resultMap.put('type', 'oldAcc');
                    resultMap.put('id', accId);
                } else {
                    resultMap.put('type', 'ongoingAcc');
                    resultMap.put('id', accId);
                }
            }
        }
        return resultMap;
    }

    /**
     * @author th.kim
     * @description 사업자 정보 조회
     * @param bizNum 사업자 번호
     *
     * @return 'S': 정상 사업자, 'F': 휴/폐업, 'N': 등록되지 않음
     */
    @AuraEnabled
    public static String doCheckBizNum(String bizNum) {
        System.debug('businessNum :: ' + bizNum);

        String result;
        InputWrap inputWrap = new InputWrap(bizNum);

        IF_Util ifUtil = new IF_Util(IF_ID);
        HttpResponse res = ifUtil.webCallout(JSON.serialize(inputWrap));

        System.debug('JSON' + JSON.serialize(inputWrap));
        System.debug('res getBody :: ' + res.getBody());

        OutputWrap outputWrap = (OutputWrap) JSON.deserialize(res.getBody(), OutputWrap.class);
        System.debug('outputWrap :: ' + outputWrap);
        OutputData outputData = outputWrap?.data[0];

        // 등록 안됨
        if (String.isBlank(outputData.b_stt_cd)) {
            result = 'N';
        }
        // 휴/폐업
        else if (outputData.b_stt_cd != '01') {
            result = 'F';
        }
        // 정상 사업자
        else {
            result = 'S';
        }
        System.debug('result :: ' + result);

        return result;
    }
}