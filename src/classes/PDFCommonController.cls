/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-11
 * @description : PDF 공통 쿼리
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-11        San.Kang           Created
**************************************************************/
public without sharing class PDFCommonController {

    // 차량재고 공통 쿼리
    @AuraEnabled
    public static VehicleStock__c getVehicleStock(String vehicleStockId){

        String obj_fields = getField(Schema.SObjectType.VehicleStock__c.fields.getMap());
        String selectFields = obj_fields +
                                ' , Product__r.VehicleCategory__r.CabMark__c,Product__r.Segment2__c, SpecTypeNo__r.TypeDate__c, Product__r.SelfCertWeightLabel__c, Product__r.VehicleCategory__r.ModelType__c, ' +
                                ' Product__r.TotalWeight__c, Product__r.CabMark__c, Product__r.length__c, Product__r.width__c, Product__r.height__c, Product__r.TypeDate__c, Product__r.MaxLoad__c, Product__r.ModelYear__c, ' +
                                ' Product__r.VehicleCategory__r.Name, Product__r.Name, Product__r.ReleaseDate__c, Product__r.SupplyItem__c,' +
                                ' SpecTypeNo__r.TypeNo__c, SpecTypeNo__r.MngNo__c ';
        String whereConditions = 'Id = \'' + vehicleStockId + '\'';

        String query = CommonUtilController.buildQuery(selectFields, 'VehicleStock__c', whereConditions);
        return Database.query(query);

    }

    // 기회 공통 쿼리
    @AuraEnabled
    public static List<Opportunity> getOpportunity(String recordId){

        String objName = Id.valueOf(recordId).getSobjectType().getDescribe().getName();
        String obj_fields = getField(Schema.SObjectType.Opportunity.fields.getMap());
        String selectFields = obj_fields +
                                ' , Account.Owner.Name, Account.Owner.Department, Account.fm_TotalAddress__c, Account.CompRegNum__c, Account.Owner.Agency__c, Account.Owner.FirstName, Account.Owner.LastName, Account.PostalCode__c, Account.IDNumber__pc, Account.Name, Account.RoadAddress__c, NoMDSApprover__r.Email, Account.LastName,  Account.FirstName, Account.DetailAddress__c, Account.RecordType.Name, Account.PersonMobilePhone, RealDriverAccount__r.PersonMobilePhone,' +
                                ' RealDriverAccount__r.IDNumber__pc ,RealDriverAccount__r.PersonEmail, Account.PersonEmail, Account.BillingCity, Account.EmailTaxInvoice__c, RealDriverAccount__r.LastName, Account.BusinessNumber__c, VehicleStock__r.VehicleNo__c,  VehicleStock__r.CarColor__c, VehicleStock__r.EngineNumber__c, VehicleStock__r.WantedOutDT__c, VehicleStock__r.Product__r.ReleaseDate__c, Contract.Quote__c,' +
                                ' RealDriverAccount__r.RoadAddress__c, Contract.fm_RealSalesPrice__c, Contract.ContractNumber, VehicleStock__r.Product__c, VehicleStock__r.Length__c, VehicleStock__r.Width__c, VehicleStock__r.Height__c, VehicleStock__r.MaxLoad__c, VehicleStock__r.TotalWeight__c, VehicleStock__r.Product__r.CarAmt__c, VehicleStock__r.Product__r.MaxLoad__c, VehicleStock__r.Product__r.PurePriceWscCfx__c,VehicleStock__r.Name,VehicleStock__r.Product__r.TotalWeight__c, VehicleStock__r.Product__r.Name, VehicleStock__r.Product__r.Segment2__c,' +
                                ' VehicleStock__r.Product__r.VehicleCategory__r.Name, VehicleStock__r.Displacement__c, VehicleStock__r.TaxType__c, VehicleStock__r.EmissionLevelEu__c, VehicleStock__r.HorsePower__c, Campaign.Name, VehicleStock__r.LongtermDiscountRate__c, VehicleStock__r.OptionDiscountRate__c, VehicleStock__r.SpecialDiscountAmt__c,' +
                                ' TransferAccount__r.Name ';
        //TotOilCouponAmt__c
        String whereConditions = objName == 'Opportunity' ? ' Id =\''+ recordId + '\'' : ' VehicleStock__c = \'' + recordId + '\'';
        String query = CommonUtilController.buildQuery(selectFields, 'Opportunity', whereConditions);

        return Database.query(query);
    }

    // PaymentTracker 공통 쿼리
    @AuraEnabled
    public static List<PaymentTracker__c> getPaymentTracker(String opportunityId){
        String obj_fields = getField(Schema.SObjectType.PaymentTracker__c.fields.getMap());
        String subQueryfields = getField(Schema.SObjectType.PaymentType__c.fields.getMap());
        String selectFields = obj_fields + ' ,Account__r.Name ' +
                            ' , (SELECT ' + subQueryfields + ' FROM PaymentTypes__r ORDER BY CreatedDate ) ';
        String whereConditions = ' Opportunity__c = \'' + opportunityId + '\' AND IsValid__c = true ';
        String query = CommonUtilController.buildQuery(selectFields, 'PaymentTracker__c', whereConditions, ' CreatedDate DESC ');

        return Database.query(query);
    }

    // Account 공통 쿼리
    public static List<Account> getAccounts(String accountId){
        String obj_fields = getField(Schema.SObjectType.Account.fields.getMap());

        String selectFields = obj_fields;
        String whereConditions = ' Id = \'' + accountId + '\'';
        String query = CommonUtilController.buildQuery(selectFields, 'Account', whereConditions);

        return Database.query(query);
    }

    // Quote Detail 주유상품권 공통 쿼리
    public static List<QuoteDetail__c> getQuoteDetail(String quoteId){

        String obj_fields = getField(Schema.SObjectType.QuoteDetail__c.fields.getMap());
        String selectFields = obj_fields + ' ,CampaignMaster__r.Name ';
        String whereConditions = ' Quote__c = \'' + quoteId + '\' and Type__c = \'주유상품권\'';
        String query = CommonUtilController.buildQuery(selectFields, 'QuoteDetail__c', whereConditions);

        return Database.query(query);
    }

    // Quote 공통 쿼리
    public static Quote getQuote(String recordId) {

        Quote resultQuote;

        try {
            // 객체 타입 확인
            String objName = Id.valueOf(recordId).getSobjectType().getDescribe().getName();

            // 필드 목록 불러오기
            String obj_fields = getField(Schema.SObjectType.Quote.fields.getMap());
            String selectFields = obj_fields + ', Finance__r.StartDate__c, Finance__r.FScompany__c';

            // 조건 생성
            String whereConditions = ' Status = \'Published\' AND ';
            whereConditions += objName == 'Quote'
                    ? 'Id = \'' + recordId + '\''
                    : 'OpportunityId = \'' + recordId + '\'';

            // 쿼리 생성 및 실행
            String query = CommonUtilController.buildQuery(selectFields, 'Quote', whereConditions);


            // 결과가 존재할 경우에만 할당
            List<Quote> quotes = Database.query(query);
            if (!quotes.isEmpty()) {
                resultQuote = quotes[0];
            }
        } catch (Exception e) {
            System.debug('getQuote ERROR: ' + e.getMessage());
            resultQuote = null;
        }

        return resultQuote;
    }

    @AuraEnabled
    public static List<ProductOption__c> getProductOption(String productId, Boolean division){
        
        String obj_fields  = getField(Schema.SObjectType.ProductOption__c.fields.getMap());
        String selectFields = obj_fields + ' ,VehicleOptionMaster__r.Name, VehicleOptionMaster__r.Price__c ';
        String whereConditions = ' Product__c = \'' + productId + '\' and VehicleOptionMaster__r.Division__c ';
                whereConditions += division == true ? ' = \'' + '기본제공' + '\' ' : ' != \'' + '기본제공' +'\' ';
        String query = CommonUtilController.buildQuery(selectFields, 'ProductOption__c', whereConditions, 'VehicleOptionMaster__r.Price__c ASC');

        return Database.query(query);
    }

    // ProductOption 갯수 공통 쿼리
    public static List<AggregateResult> getProductOptionCnt(String productId){

        String selectFields = ' Count(Id) cnt, Name ';
        String whereConditions = ' Product__c = \'' + productId + '\' Group By Name ';
        String query = CommonUtilController.buildQuery(selectFields, 'ProductOption__c', whereConditions, 'Name');

        return Database.query(query);
    }

    public static Boolean isNewAddress(Date releaseDate){

        return releaseDate >= Date.newInstance(2017,2,23);
    }

    public static String getField(Map<String, Schema.SObjectField> ObjMap){

        List<String> accessibleFields = new List<String>();

        for (String fieldName : ObjMap.keySet()) {
            Schema.DescribeFieldResult fieldDesc = ObjMap.get(fieldName).getDescribe();
            // 접근 가능한 필드만 추가
            if (fieldDesc.isAccessible()) {
                accessibleFields.add(fieldName);
            }
        }
        return String.join(accessibleFields, ', ');
    }

    // User Role 공통 쿼리
    public static List<User> getUsersByRole(String roleName) {

        return [SELECT Id, Name, Street, IDNumber__c
                FROM User
                WHERE UserRole.Name = :roleName];
    }

    // PDF 날짜 별 Validate
    public static String getValidate(Date mDate){

        Date pDate = Date.newInstance(2018, 6, 1);
        String Validity = mDate >= pDate ? '90' : '60';
        return Validity;
    }

    // Document 공통 쿼리
    public static Id getDocumentId(String documentName){
        return  [SELECT Id
                FROM Document
                WHERE DeveloperName =:documentName].Id;
    }

    // PDF 다운로드
    @AuraEnabled
    public static String downloadSelectedPDFs(String vfUrl) {

        PageReference pr = new PageReference(vfUrl);
        Blob pdfBlob;
        try {
            pdfBlob = pr.getContentAsPDF();
        } catch(Exception e) {
            throw new AuraHandledException('PDF 다운로드 실패: ' + e.getMessage());
        }
        return EncodingUtil.base64Encode(pdfBlob);
    }

    // opportunityPDF Init
    @AuraEnabled
    public static Map<String, Object> getOpportunityInit(String recordId){

        return new Map<String, Object> {
                'opportunity' => getOpportunity(recordId),
                'paymentTracker' => getPaymentTracker(recordId),
                'checkSAPermission' => checkSAPermissionSet()
        };
    }
    // vehicleStockPDF Init
    @AuraEnabled
    public static Map<String, Object> getVehicleStockInit(String recordId){

        return new Map<String, Object> {
                'opportunity' => getOpportunity(recordId),
                'vehicleStock' => getVehicleStock(recordId),
                'user' => getUsersByRole('HandOver Team'),
                'mgmtUser' => profileCheck('MTBK Internal'),
                'saUser' => profileCheck('MTBK Agent')

        };
    }

    // 임시운행 PDF 데이터
    @AuraEnabled
    public static void updatedTempDriver(String recordId, Map<String,Object> tempDriverMap){

        try{
            VehicleStock__c vehicleStock = [SELECT Id, TempReqDate__c, DrivePurpose__c, DriveDays__c FROM VehicleStock__c WHERE Id =:recordId];
            if(vehicleStock != null){
                vehicleStock.TempReqDate__c = Date.valueOf(String.valueOf(tempDriverMap.get('tempReqDate')));
                vehicleStock.DrivePurpose__c = String.valueOf(tempDriverMap.get('drivePurpose'));
                vehicleStock.DriveDays__c = Integer.valueOf(tempDriverMap.get('driveDays'));

                update vehicleStock;
            }
        }catch (Exception e){
            System.debug('err =>' + e);
        }
    }

    // 현재 유저 profile 체크
    @AuraEnabled
    public static Boolean profileCheck(String profileName){

        Id profileId = [SELECT ProfileId FROM User WHERE Id = :UserInfo.getUserId()].ProfileId;
        String userProfile = [SELECT Name FROM Profile WHERE Id = :profileId].Name;
        Boolean checkProfile = userProfile == profileName ? true : false;
        return checkProfile;
    }

    // 현재 유저 SA Permission 인지 체크
    @AuraEnabled
    public static Boolean checkSAPermissionSet() {

        Id userId = UserInfo.getUserId();
        List<PermissionSetAssignment> permissionSets = [SELECT Id, PermissionSet.Name, PermissionSet.Label FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSet.Name = 'SA'];

        return !permissionSets.isEmpty();
    }

}