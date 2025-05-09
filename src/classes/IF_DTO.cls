/**
* @Author            : payo03@solomontech.net
* @Description 		 : Interface를 위한 Custom DTO 객체
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-13      payo03@solomontech.net           Created
*/
global without sharing class IF_DTO {

    private static final Map<String, String> SEGMENT1_MAP = CommonUtilController.getPickListMap('Product2', 'Segment1__c');
    private static final Map<String, String> CAB_MARK_MAP = CommonUtilController.getPickListMap('Product2', 'CabMark__c');
    private static final Map<String, String> INTARDER_MAP = CommonUtilController.getPickListMap('Product2', 'Intarder__c');
    private static final Map<String, String> WHEEL_BASE_MAP = CommonUtilController.getPickListMap('Product2', 'WheelBase__c');
    private static final Map<String, String> TRIM_LEVEL_MAP = CommonUtilController.getPickListMap('Product2', 'TrimLevel__c');
    private static final Map<String, String> EMISSION_LEVEL_MAP = CommonUtilController.getPickListMap('Product2', 'EmissionLevel__c');
    private static final Map<String, String> CAR_COLOR_MAP = CommonUtilController.getPickListMap('VehicleStock__c', 'CarColor__c');

    private static final String RECORDTYPE_ACC_CORPORATE = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACCOUNT_CORPORATE').getRecordTypeId();
    private static final String RECORDTYPE_ACC_PERSON = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACCOUNT_PERSON').getRecordTypeId();

    /* ------------------------------------------------------------------------------------------ */
    /*                                          Response                                          */
    /* ------------------------------------------------------------------------------------------ */
    /* ------------------------------------------- SAP ------------------------------------------- */
    // 공통 Response
    public virtual class CommonResult {
        public String Code {get; set;}                  // 응답 코드 (TRUE : '0')
        public String Message {get; set;}               // 응답 메시지
    }

    public class WarehouseInfo {
        public String QTY {get; set;}
        public String WHSCD {get; set;}
        public String WHSNM {get; set;}
    }
    // 공통 Response

    // 스포일러 재고 조회 정보(SMS001)
    public class PartStock extends CommonResult {
        public List<PartStockInfo> ResultData {get; set;} // 결과 데이터 리스트

        public PartStock() {
            ResultData = new List<PartStockInfo>();
        }
    }
    public class PartStockInfo {
        public String ITEMCD {get; set;}        // 품목코드
        public String ITEMNM {get; set;}        // 품목명
        public String SPEC {get; set;}          // SPEC
        public String INVUOM {get; set;}        // 재고단위
        public List<WarehouseInfo> STK {get; set;}
        public Map<String, Integer> WHMAP {get; set;}

        public PartStockInfo(){
            STK = new List<WarehouseInfo>();
            WHMAP = new Map<String, Integer>();
        }
    }

    // 차량 재고 조회 정보(SMS002)
    public class VehicleStock extends CommonResult {
        public List<VehicleStockInfo> ResultData {get; set;} // 결과 데이터 리스트

        public VehicleStock() {
            ResultData = new List<VehicleStockInfo>();
        }
    }
    public class VehicleStockInfo {
        public String ITEMCD {get; set;}
        public String DISNUM {get; set;}
        public String ITEMNM {get; set;}
        public String SPEC {get; set;}
        public String INVUOM {get; set;}
        public List<WarehouseInfo> STK {get; set;}
        public Map<String, Integer> WHMAP {get; set;}

        public VehicleStockInfo(){
            STK = new List<WarehouseInfo>();
            WHMAP = new Map<String, Integer>();
        }
    }

    // 세금계산서 발행 정보(SMS017)
    public class TaxInvoice extends CommonResult {
        public List<TaxInvoiceInfo> ResultData {get; set;} // 결과 데이터 리스트

        public TaxInvoice() {
            ResultData = new List<TaxInvoiceInfo>();
        }
    }
    public class TaxInvoiceInfo {
        public String IFID {get; set;}          // Interface File ID
        public String ISREQNO {get; set;}       // Vehicle Issue Request No.(차량출고요청번호)
        public String ISSUETYPE {get; set;}     // Vehicle Issue Type
        public String DISNUM {get; set;}        // VIN (차대번호)
        public String CARDCD {get; set;}        // Sold to Party Code (주문처)
        public String BCARDCD {get; set;}       // Bill to Party Code (세금계산서발행처)
        public String SLPCD {get; set;}         // Sales Group Code (영업그룹(담당자))
        public String DREQDT {get; set;}        // Delivery Date (납기일)
        public String ISSUDT {get; set;}        // Issue Date (실제출고일)
        public String PAYTP {get; set;}         // Payment Type(결제방법)
        public String SALEPRICE {get; set;}     // Sales Unit Price(세전단가)
        public String SALEAMT {get; set;}       // Sales Amount
        public String VATGRP {get; set;}        // VAT Type(세금그룹)
        public String BPLID {get; set;}         // Tax Report Biz. Area (세금신고사업장)
        public String REVNO {get; set;}         // 제작양도증번호
        public String MVTP {get; set;}          // 원동기형식
        public String MANO {get; set;}          // 제원관리번호
        public String TPAPNO {get; set;}        // 형식승인번호
        public String TPAPYM {get; set;}        // 형식승인년월일
        public String CARNO {get; set;}         // 원동기번호
        public String ERRCOD {get; set;}        // 에러코드
        public String ERRMSG {get; set;}        // 에러메시지
        public String ARNO {get; set;}          // ERP매출번호
        public String ARYN {get; set;}          // ERP 매출내역 생성여부
        public String ARDT {get; set;}          // ERP 매출내역 생성일
        public String TAXNO {get; set;}         // ERP 세금계산서번호
    }
    
    // 계좌 입금정보(SMS019). SFDC > SAP 방식
    public class PaymentInfo extends CommonResult {
        public List<PaymentDetailInfo> ResultData {get; set;} // 결과 데이터 리스트

        public PaymentInfo() {
            ResultData = new List<PaymentDetailInfo>();
        }
    }
    // 계좌 입금정보(SMS019). SAP > SFDC 방식
    public class PaymentDetailInfo {
        public String doc_entry {get; set;}     // 문서 엔트리 번호
        public String doc_num {get; set;}       // 문서 번호
        public String card_cd {get; set;}       // 고객 코드
        public String acc_no {get; set;}        // 계좌 번호
        public String crncy {get; set;}         // 통화 단위
        public String doc_total {get; set;}     // 총 금액
        public String doc_total_fc {get; set;}  // 외화 총 금액
    }

    /* ------------------------------------------- MFS ------------------------------------------- */
    public class LoanResponseInfo {
        public String opp_id { get; set; }          // 영업기회 Id (Primary Key)
        public String quote_id { get; set; }        // 견적ID (Primary Key)
        public String sale_agent_id { get; set; }   // 판매에이전트ID
        public String loan_result { get; set; }     // 대출결과 (승인, 거절, 보완요청, 실행)
        public String comment { get; set; }         // 대출결과에 대한 Underwriting팀에 Comment
        public String apply_rate { get; set; }      // 적용금리
        public String loan_amt { get; set; }        // 여신금액
        public String loan_term { get; set; }       // 원금상환기간개월수
        public String mfs_vat_amt { get; set; }     // 부가세 유예 금액
        public String mfs_vat_dt { get; set; }      // 부가세 유예 만기일
        public String exct_dt { get; set; }         // 실행일자
        public String cntr_no { get; set; }         // TFS 계약번호
        public String mtbk_cnsn_no { get; set; }    // MTBK 품의번호
        public String subsidy_amt { get; set; }     // Subsidy (보조금. Subvention 금액)
        public String mfs_camp_amt { get; set; }    // MFS 캠페인 금액
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                          Request                                           */
    /* ------------------------------------------------------------------------------------------ */

    /* ------------------------------------------ SAP ------------------------------------------ */
    // 재고이동요청 전송 Detail(SMS004)
    public class StockDetailInfo {
        public String STQTY = '1';              // Spoiler수량은 1개
        public String DISNUM {get; set;}        // VIN Number
        public String DOCNO {get; set;}
        public String ITEMCD {get; set;}
        public String SEQ {get; set;}
        public String RMK {get; set;}

        public StockDetailInfo(String docNo, String itemCode, String seq, String vin, String remark){
            this.DOCNO = docNo;
            this.ITEMCD = itemCode;
            this.SEQ = seq;
            this.DISNUM = vin;
            this.RMK = remark;
        }
    }

    // 재고이동요청 전송 Master(SMS004)
    public class StockInfo {
        public String CRTP = 'C';
        public String CRUS = UserInfo.getName();
        public String CRDT = String.valueOf(Datetime.now());
        public String DOCDT = String.valueOf(Date.today());
        public String REQDT = String.valueOf(Date.today());

        public String ODTYPE = 'S00';           // 주문유형(ParsOrder 사라짐)   | 정기가 : S01, 수시가 : S02, 긴급가 : S03, 소매가 : S04
        public String FWHSCD = 'P11';           // 출고창고
        public String TWHSCD = 'P21';           // 입고창고

        public String PTMOVTP {get; set;}       // 부품재고 Transfer Type      | 내부창고이동 : A, MTBK재고이동요청 : P
        public String DOCNO {get; set;}         // 주문번호                    | InterfaceId
        public String IFID {get; set;}          // 주문번호                    | InterfaceId
        public String MOVTP {get; set;}         // 재고 Transfer Type          | Vehicle(원재료) : A, Parts : P
        public String RMK {get; set;}           // 주석

        public List<StockDetailInfo> DETAILS {get; set;}
        public StockInfo(Boolean isCreate, Boolean isAttach, List<StockDetailInfo> detailInfos) {
            if(isCreate) this.CRTP = 'A';
            // true : 재고이동, false : 재고이동 취소
            if(!isAttach) {
                this.FWHSCD = 'P21';
                this.TWHSCD = 'P11';
            }

            this.DETAILS = detailInfos;
        }
    }

    // 고객코드 전송(SMS007)
    public class CustomerInfo {
        public String CRTP = 'U';           // [v]
        public String BPTP = 'C';           // [v]
        public String BPSTP = 'ST01';
        public String COUNCD = 'KR';
        public String CURCD = 'KRW';
        public String VATTP = 'A';
        public String CNTNM = '담당자';
        public String CRUS = UserInfo.getName();
        public String CRDT = String.valueOf(Datetime.now());

        // 필드 필수값
        public String CARDCD {get; set;}    // [v] BP코드      | Account.BPCode__c (자동채번)
        public String CARDNM {get; set;}    // [v] 사업명      | Account.BusinessName__c
        public String VATRENO {get; set;}   // [v] 사업자 번호  | Account.IDNumber__pc
        public String RRNYN {get; set;}     // [v] 주민번호 기입여부

        // Recommend 필드
        public String IFID {get; set;}      // Interface ID (CommonUtilCustomController.parseIFId)
        public String RRN {get; set;}       // 주민번호
        public String REPNM {get; set;}     // 이름            | type == 'B' ? Represent__c : Name__c
        public String EMAIL {get; set;}     // 이메일          | opportunity.TaxEmail__c
        public String INDUSNM {get; set;}   // 사업명          | type == 'P' ? '운수업' : BizCon__r.Name
        public String BPFLNM {get; set;}    // 사업명          | type == 'G' ? BizName__c : Name__c
        public String ZIPCD {get; set;}     // 우편번호         | bAddr__r.PostNo__c
        public String ADDR1 {get; set;}     // 주소1           | bAddr__r.Name
        public String ADDR2 {get; set;}     // 주소2           | bAddrDetail__c != null ? bAddrDetail__c : ''
        public String BUSNM {get; set;}     // type == 'P' ? '특수화물' : BizType__r.Name

        // 필드 필수값 x
        public String EADDRES {get; set;}   // 영어주소         | bAddr__r.FullAddress_En__c
        public String TELNO1 {get; set;}    // 핸드폰 번호
        public String TELNO2 {get; set;}
        public String CELNO {get; set;}     // 대표자 번호      | type == 'B' ? RepresentPhone__c : Phone
        public String FAXNO {get; set;}

        public CustomerInfo(Account acc, Boolean isCreate) {
            Opportunity oppty = acc.Opportunities.get(0);
            if(isCreate) this.CRTP = 'A';

            // 필수값 데이터
            this.CARDCD = acc.BPCode__c;
            this.CARDNM = acc.BusinessName__c;
            this.BPFLNM = acc.Name;

            /*
                사업자번호 조건
                1. 사업자 번호 != NULL일때
                    1-1. 주민등록번호 발행여부 TRUE
                        => [Field] = 주민등록번호
                    1-2. 주민등록번호 발행여부 FALSE
                        => [Field] = 사업자번호
                2. 사업자 번호 NULL일때
                    => [Field] = 주민등록번호
            */
            this.VATRENO = acc.BusinessNumber__c != null
                    ? oppty.IsTaxIDNumber__c
                            ? acc.IDNumber__pc
                            : acc.BusinessNumber__c
                    : acc.IDNumber__pc;
            this.RRNYN = acc.IDNumber__pc != null ? 'Y' : 'N';

            // AS_IS. [개인 : P, 개인사업자 : G, 그외 : B] / TO_BE [개인 - 법인]
            Boolean isPersonal = '개인'.equals(acc.AccountType__c);
            // 권장 필드들
            this.RRN = acc.IDNumber__pc;
            this.REPNM = acc.Name;
            this.EMAIL = acc.PersonEmail != null ? acc.PersonEmail : '';
            this.ZIPCD = acc.PostalCode__c != null ? acc.PostalCode__c : '';
            this.ADDR1 = acc.RoadAddress__c != null ? acc.RoadAddress__c : '';
            this.ADDR2 = acc.DetailAddress__c != null ? acc.DetailAddress__c : '';
            this.INDUSNM = isPersonal ? '운수업' : '';
            this.BUSNM = isPersonal ? '특수화물' : '';

            // 필드 필수값 x
            this.EADDRES = '';          // 수정필요
            this.TELNO1 = acc.Phone;
            this.CELNO = acc.Phone;
        }
    }

    // 차종모델 전송(SMS009)
    public class ERPModel {
        public String CRTP = 'U';
        public String CRUS = UserInfo.getName();
        public String CRDT = String.valueOf(Datetime.now());

        public String IFID {get; set;}
        public String TRP {get; set;}
        public String ITEMCD {get; set;}
        public String SPEC {get; set;}
        public String SPECNM {get; set;}
        public String PERWGT {get; set;}
        public String PERWGTNM {get; set;}

        public String ITEMNM {get; set;}
        public String VALDT {get; set;}
        public String HSCD {get; set;}

        public String SEG {get; set;}
        public String SEGNM {get; set;}
        public String CAB {get; set;}
        public String CABNM {get; set;}
        public String INTARD {get; set;}
        public String INTARDNM {get; set;}
        public String WBASE {get; set;}
        public String WBASENM {get; set;}
        public String TRIMLVL {get; set;}
        public String TRIMLVLNM {get; set;}
        public String EMMIS {get; set;}
        public String EMMISNM {get; set;}

        public ERPModel(Product2 obj, Boolean isCreate) {
            if(isCreate) CRTP = 'A';

            this.ITEMNM = obj.Name;
            this.VALDT = String.valueOf(Date.valueOf(obj.CreatedDate));
            this.HSCD = obj.fm_HSCode__c;

            this.SEG = CommonUtilController.sliceUBarBefore(obj.Segment1__c);
            this.CAB = CommonUtilController.sliceUBarBefore(obj.CabMark__c);
            this.INTARD = CommonUtilController.sliceUBarBefore(obj.Intarder__c);
            this.WBASE = CommonUtilController.sliceUBarBefore(obj.WheelBase__c);
            this.TRIMLVL = CommonUtilController.sliceUBarBefore(obj.TrimLevel__c);
            this.EMMIS = CommonUtilController.sliceUBarBefore(obj.EmissionLevel__c);

            this.SEGNM = CommonUtilController.getPicklistLabelForLabel('Product2', 'Segment1__c', obj.Segment1__c);
            this.CABNM = CommonUtilController.getPicklistLabelForLabel('Product2', 'CabMark__c', obj.CabMark__c);
            this.INTARDNM = CommonUtilController.getPicklistLabelForLabel('Product2', 'Intarder__c', obj.Intarder__c);
            this.WBASENM = CommonUtilController.getPicklistLabelForLabel('Product2', 'WheelBase__c', obj.WheelBase__c);
            this.TRIMLVLNM = CommonUtilController.getPicklistLabelForLabel('Product2', 'TrimLevel__c', obj.TrimLevel__c);
            this.EMMISNM = CommonUtilController.getPicklistLabelForLabel('Product2', 'EmissionLevel__c', obj.EmissionLevel__c);
        }
    }

    // 구매Order 확정 전송(SMS010)
    public class OrderConfirm {
        public String CRTP = 'C';
        public String CRUS = UserInfo.getName();
        public String CRDT = String.valueOf(Datetime.now());
        public String VMNM = '';
        public String CARDCD = 'V000000';
        public String CURRCD = 'EUR';
        public String ITEMQTY = '1';
        public String VEHICTP = 'L';    // Segment코드값이 Bus일경우 B, Truck일경우 L이였음. Bus사업은 철수하였음으로 L로 고정

        public String IFID {get; set;}
        public String ITEM_TYPE {get; set;}
        public String ITEMCD {get; set;}

        public String ORDNO {get; set;}
        public String DISNUM {get; set;}
        public String DOCDT {get; set;}
        public String ETD {get; set;}
        public String ETA {get; set;}
        public String PRCAMT {get; set;}
        public String ITEMAMT {get; set;}
        public String HORPW {get; set;}
        public String ENGNO {get; set;}
        public String ENGTP {get; set;}
        public String WEGHT {get; set;}
        public String VECNO {get; set;}
        public String ESTLTP {get; set;}

        public OrderConfirm(AvisOrderInfo__c info, Boolean isCreate) {
            if(isCreate) this.CRTP = 'A';
            this.ORDNO = info.OrderIntakeNo__c;
            this.DISNUM = info.ChassisFrameNo__c;
            this.HORPW = info.HorsePower__c;
            this.ENGNO = info.EngineNumber__c;
            this.ENGTP = info.EngineType__c;
            this.WEGHT = info.WeightKg__c;
            this.VECNO = info.VehicleNo__c;
            this.ESTLTP = info.EmissionLevelEu__c;

            this.DOCDT = String.valueOf(info.OrderDate__c); // SAP. 날짜 Validation
            this.ETD = String.valueOf(info.Etd__c);
            this.ETA = String.valueOf(info.ETA__c);
            this.ITEMAMT = String.valueOf(info.BuyingPrice__c);
            this.PRCAMT = String.valueOf(info.BuyingPrice__c);

            String isDeck = '00';
            this.ITEMCD = CommonUtilCustomController.parseCarCode(
                    info.fm_Segment1__c,
                    info.fm_SpecShort__c,
                    info.CabMark__c,
                    info.IntarderOption__c,
                    info.WheelBase__c,
                    info.TrimLevel__c,
                    info.EmissionLevelEu__c
            );
            if(info.fm_IsDeck__c) isDeck = '01';
            this.ITEMCD += isDeck;
        }
    }
    
    // 구매Invoice 확정 전송(SMS011)
    public class PurchaseInvoice {
        public String CRTP = 'C';
        public String CRUS = UserInfo.getName();
        public String CRDT = String.valueOf(Datetime.now());
        public String CURRCD = 'EUR';
        public String ITEMQTY = '1';

        public String IFID {get; set;}
        public String ITEM_TYPE {get; set;}
        public String ITEMCD {get; set;}
        public String WEGHT{get; set;}
        public String DISNUM {get; set;}
        public String INVNO {get; set;}
        public String INVDT {get; set;}
        public String BLNO {get; set;}
        public String BLDT {get; set;}
        public String ORDNO {get; set;}
        public String VESSEL {get; set;}
        public String ETD {get; set;}
        public String ETA {get; set;}
        public String PORTCD {get; set;}
        public String PORTNM {get; set;}
        public String DESTPT {get; set;}
        public String PRCAMT {get; set;}
        public String ITEMAMT {get; set;}
        public String TROS {get; set;}

        public PurchaseInvoice(AvisOrderInfo__c info, Boolean isCreate) {
            if(isCreate) this.CRTP = 'A';
            this.DISNUM = info.ChassisFrameNo__c;
            this.INVNO = info.InvoiceNumber__c;
            this.BLNO = info.BLDocumentNo__c;
            this.ORDNO = info.OrderIntakeNo__c;
            this.VESSEL = info.Ship__c;
            this.PORTCD = info.HarbourShort__c;
            this.PORTNM = info.Harbour__c;
            this.DESTPT = info.Destination__c;

            this.PRCAMT = String.valueOf(info.BuyingPrice__c);
            this.ITEMAMT = String.valueOf(info.BuyingPrice__c);
            this.TROS = String.valueOf(info.AdjustTargetRos__c);

            this.INVDT = String.valueOf(info.InvoiceDateLastAdjusted__c);   // SAP. 날짜 Validation
            this.BLDT = String.valueOf(info.BLDate__c);
            this.ETD = String.valueOf(info.Etd__c);
            this.ETA = String.valueOf(info.ETA__c);

            String isDeck = '00';
            this.ITEMCD = CommonUtilCustomController.parseCarCode(
                    info.fm_Segment1__c,
                    info.fm_SpecShort__c,
                    info.CabMark__c,
                    info.IntarderOption__c,
                    info.WheelBase__c,
                    info.TrimLevel__c,
                    info.EmissionLevelEu__c
            );
            if(info.fm_IsDeck__c) isDeck = '01';
            this.ITEMCD += isDeck;
        }
    }

    // 통관정보 전송(SMS012)
    public class CustomsInfo {
        public String CRTP = 'C';
        public String CRUS = UserInfo.getName();
        public String CRDT = String.valueOf(Datetime.now());
        public String CURRCD = 'EUR';
        public String ITEMQTY = '1';
        public String EXCRT = '0';
        public String ITEM_TYPE = 'V';
        public String UNIT = 'EA';
        public String VMNM = '';
        public String RMK = '';

        public String IFID {get; set;}
        public String ITEMCD {get; set;}

        public String DOCDT {get; set;}
        public String DISNUM {get; set;}
        public String PORTCD {get; set;}
        public String PORTNM {get; set;}
        public String DESTPT {get; set;}
        public String ORDERNO {get; set;}
        public String VECTP {get; set;}
        public String HORPW {get; set;}
        public String EMLTP {get; set;}
        public String ENGNO {get; set;}
        public String ENGTP {get; set;}
        public String WEGHT {get; set;}
        public String VECNO {get; set;}
        public String COLORCD {get; set;}
        public String COLORNM {get; set;}
        public String PRCAMT {get; set;}
        public String TROS {get; set;}
        public String ITEMAMT {get; set;}
        public String BLNO {get; set;}
        public String BLDT {get; set;}

        public CustomsInfo(AvisOrderInfo__c info, Boolean isCreate) {
            if(isCreate) this.CRTP = 'A';
            this.DOCDT = String.valueOf(info.RealArrivalDate__c);
            this.DISNUM = info.ChassisFrameNo__c;
            this.PORTCD = info.HarbourShort__c;
            this.PORTNM = info.Harbour__c;
            this.DESTPT = info.Destination__c;
            this.ORDERNO = info.OrderIntakeNo__c;
            this.HORPW = info.HorsePower__c;
            this.EMLTP = info.EmissionLevelEu__c;
            this.ENGNO = info.EngineNumber__c;
            this.ENGTP = info.EngineType__c;
            this.WEGHT = info.WeightKg__c;
            this.VECNO = info.VehicleNo__c;
            this.COLORNM = info.CarColor__c;

            this.PRCAMT = String.valueOf(info.BuyingPrice__c);
            this.ITEMAMT = String.valueOf(info.BuyingPrice__c);
            this.TROS = String.valueOf(info.AdjustTargetRos__c);
            this.BLNO = String.valueOf(info.BLDocumentNo__c);
            this.BLDT = String.valueOf(info.BLDate__c);

            this.COLORCD = CommonUtilController.sliceUBarBefore(CAR_COLOR_MAP.get(info.CarColor__c));
            this.VECTP = CommonUtilController.sliceUBarBefore(SEGMENT1_MAP.get(info.fm_Segment1__c));

            String isDeck = '00';
            this.ITEMCD = CommonUtilCustomController.parseCarCode(
                    info.fm_Segment1__c,
                    info.fm_SpecShort__c,
                    info.CabMark__c,
                    info.IntarderOption__c,
                    info.WheelBase__c,
                    info.TrimLevel__c,
                    info.EmissionLevelEu__c
            );
            if(info.fm_IsDeck__c) isDeck = '01';
            this.ITEMCD += isDeck;
        }
    }

    // 매출확정정보 Master(SMS013)
    public class SalesInfo{
        public String CRUS = UserInfo.getName();
        public String CRDT = String.valueOf(Datetime.now());
        public String CRTP = 'C';

        public String BPLID = 'G100';           // Tax Report Biz. Area (세금신고사업장) |	G100 : 금산사업장
        public String ISSUETYPE = 'A';          // Vehicle Issue Type |	A : Vehicle, B : PDI Warranty
        public String PAYTP = 'CH';             // Payment Type(결제방법) | CH : 현금
        public String SALEPRICE = '0';          // Sales Unit Price(세전단가)
        public String SALEVAT = '0';            // Sales Unit Vat(부가세액)
        public String REVNO = '';               // 제작양도증번호
        public String MVTP = '';                // 원동기형식
        public String MANO = '';                // 제원관리번호
        public String TPAPNO = '';              // 형식승인번호
        public String TPAPYM = '';              // 형식승인년월일
        public String CARNO = '';               // 원동기번호
        public String gear = '';
        public String rmc_type = '';

        public String ISREQNO{get; set;}        // Vehicle Issue Request No.(차량출고요청번호) | 차량1대 단위로 I/F
        public String DISNUM{get; set;}         // VIN (차대번호)
        public String CARDCD{get; set;}         // Sold to Party Code (주문처) | 고객
        public String BCARDCD{get; set;}        // Bill to Party Code (세금계산서발행처) | 고객
        public String BRANCH{get; set;}         // 딜러 지점 | 딜러지점
        public String SLPCD{get; set;}          // Sales Group Code (영업그룹_담당자) | 영업지점 (ERP영업그룹)
        public String DREQDT{get; set;}         // Delivery Date (납기일) | 희망출고예정일
        public String ISSUDT{get; set;}         // Issue Date (실제출고일) | 세금계산서발행일자
        public String SALEAMT{get; set;}        // Sales Amount
        public String IFID{get; set;}           // Interface File ID
        public String VATGRP{get; set;}         // VAT Type(세금그룹) | A : 일반과세(10%), B : 영세, C: 면세
        public String VATGRPD{get; set;}        // VAT Type

        public String emission {get; set;}
        public String model_type {get; set;}
        public String model_detail1 {get; set;}
        public String model_detail2 {get; set;}
        public String model_detail3 {get; set;}
        public String engine_type {get; set;}
        public String hp {get; set;}
        public String cap {get; set;}
        public String sales_agency {get; set;}
        public String sales_people {get; set;}
        public String hand_over_date {get; set;}

        public List<SalesDetailInfo> DETAILS_1{get; set;}
        public SalesInfo(Boolean isCreate, List<SalesDetailInfo> detailInfos) {
            if(isCreate) CRTP = 'A';

            DETAILS_1 = detailInfos;
        }
    }
    
    // 매출확정정보 Detail(SMS013)
    public class SalesDetailInfo {
        public String WHSCD = 'P21';            // 출고창고 | P21 : Fixed
        public String QTY = '1';                // Quantity (수량)
        public String AMT = '0';                // 금액
        public String VAT = '0';                // 부가세액
        public String LINETOTAL = '0';
        public String FPRICE = '';              // 외화단가
        public String DISCAMT = '';             // Vehicle 할인금액
        public String RMK = '';                 // 비고

        public String ISREQNO {get; set;}       // Vehicle Issue Request No.(차량출고요청번호) | 차량1대 단위로 I/F
        public String ROWNO {get; set;}         // 순번
        public String ITEMTP {get; set;}        // Item Type (품목유형) | (V.차량 / P.PDI장착품/ M.작업자실수/ O.출고기념품/ E.EW/R.RMC/ C.주유상품권/ J.인도후장착품)
        public String PRICE {get; set;}         // 단가
        public String ITEMCD {get; set;}        // Item Code (품목코드)
    }

    // BP코드 - 가상계좌번호 전송(SMS018)
    public class AccountVAInfo {
        public String CRTP = 'U';

        public String U_CardCD {get; set;}
        public String U_ACCNO {get; set;}
        public String TYPE {get; set;}
        public String TOTAL_AMT {get; set;}
        public String NOTARY_FEE {get; set;}
        public String CAMPAIGN_FEE {get; set;}

        public AccountVAInfo(Boolean isCreate) {
            if(isCreate) CRTP = 'A';
        }
    }

    // 입금-송장 정보(반제처리) 전송(SMS020)
    public class OffsetProcess {
        public List<String> ORCT_LIST {get; set;}       // 입금 문서번호
        public String OINV_DOCNO {get; set;}            // AR송장 번호
        public String ORCT_PRICE {get; set;}            // 반제 금액
    }

    /* ------------------------------------------ MFS ------------------------------------------ */
    // Loan 요청 정보
    public class LoanRequestInfo {
        public String opp_id {get; set;}                // 영업기회 ID. 모든 차량에 대해 영업기회는 1개
        public String quote_id {get; set;}              // 견적 ID
        public String sale_agent_id {get; set;}         // 판매에이전트 ID
        public String bsn_nm {get; set;}                // 사업자명
        public String bsn_no {get; set;}                // 사업자번호
        public String bsn_tel {get; set;}               // 사업자 전화번호
        public String bsn_add {get; set;}               // 사업자 주소
        public String rrn {get; set;}                   // 주민등록번호
        public String cs_nm {get; set;}                 // 고객명
        public String tel_no {get; set;}                // 전화번호
        public String email_add {get; set;}             // 이메일 주소
        public String apply_rate {get; set;}            // 적용 금리
        public String loan_amt {get; set;}              // 여신 금액
        public String loan_term {get; set;}             // 원금상환 기간(개월)
        public String model_cd {get; set;}              // 모델 코드
        public String vhc_dc {get; set;}                // 차량 할인 금액
        public String vhc_model_nm {get; set;}          // 차량 모델명
        public String vhc_price {get; set;}             // 차량 가격(Total)
        public String vhc_exp {get; set;}               // 차량 부대 비용
        public String spc_vhc {get; set;}               // 특장
        public String spc_vhc_price {get; set;}         // 특장 가격
        public String campaign {get; set;}              // 만트럭 할인 캠페인
        public String o_coupon_price {get; set;}        // 주유 쿠폰 총액
        public String option_price {get; set;}          // 옵션 가격
        public String reg_tax {get; set;}               // 취등록세 비용
        public String mfs_vat_amt {get; set;}           // MFS 부가세 유예 금액
        public String virtual_acc {get; set;}           // 가상계좌 번호
        public String invoice_dt {get; set;}            // 세금계산서 발행일
        public String stock_no {get; set;}              // 차량 VIN 넘버
        public String virtual_acc_nm {get; set;}        // 가상계좌 예금주명
        public String virtual_acc_cd {get; set;}        // 가상계좌 은행 코드
        public String mfs_vat_request {get; set;}       // MFS 부가세 유예 신청 여부
        public String sale_agent_nm {get; set;}         // 판매에이전트 이름
        public String sale_agent_tel {get; set;}        // 판매에이전트 전화번호
        public String loan_request_dt {get; set;}       // 최초 대출 요청일자
        public String campaign_dc_amt {get; set;}       // 캠페인 할인금액
        public String pre_amt {get; set;}               // 선수금 정보

        public LoanRequestInfo() {
            if(this.bsn_no == null) this.bsn_no = '(개인)';
            if(this.spc_vhc == null) this.spc_vhc = 'N';
        }
    }

    /* ------------------------------------------ LOG ------------------------------------------ */
    public enum LOG_TYPE {
        HEROKU_KAKAO_OUT, KAKAO_IN, HEROKU_SAP_OUT, HEROKU_SAP_IN, HEROKU_WSMOKA, HEROKU_SFDC,
        MODUSIGN_OUT, MODUSIGN_IN, PUBLIC_API, AWS_OUT, AWS_IN
    }
    public class LogWrapper {
        public String status;
        public String ifId;
        public String errorCode;
        public String errorMessage;
        public Datetime requestTime;
        public String requestBody;
        public Datetime responseTime;
        public String responseBody;
        public LOG_TYPE logType;
    }

    /* ------------------------------------------ MODUSIGN ------------------------------------------ */
    // Modusign PDF Request Wrapper Start
    // 참조. https://developers.modusign.co.kr/reference/documentcontroller_create
    public enum FieldType {
        TEXT, CHECKBOX, SIGNATURE, SIGNING_DATE
    }
    public enum FontType {
        NOTO_SANS, NOTO_SERIF
    }
    public enum SignatureType {
        SIGN, STAMP
    }

    public class SigningRequestByPDF {
        public File file { get; set; }                      // [v]
        public List<Participant> participants { get; set; } // [v]
        public String title { get; set; }                   // [v]
        public String fileOpenPassword { get; set; }
        public List<RequesterInput> requesterInputs { get; set; }
    }
    // 1. File
    public class File {
        public String extension { get; set; }   // [v]
        public String base64 { get; set; }      // [v]
    }
    // 2. Participant
    public class Participant {
        public String name { get; set; }                    // [v]
        public Integer signingOrder { get; set; }           // [v]
        public SigningMethod signingMethod { get; set; }    // [v]
        public List<Field> fields { get; set; }
        public List<CheckboxFieldGroup> checkboxFieldGroups { get; set; }
        public Integer signingDuration { get; set; }
        public String locale { get; set; }
        public String role { get; set; }
        public Verification verification { get; set; }    // 모두싸인 서명시 본인인증 추가
    }
    // 2-1. Field
    public class Field {
        public FieldType type { get; set; }         // [v]
        public Size size { get; set; }              // [v]
        public Position position { get; set; }      // [v]
        public TextStyle textStyle { get; set; }
        public List<String> allowedGenerationMethods { get; set; }
        public Boolean required { get; set; }
        public String groupLabel { get; set; }
        public List<SignatureType> signatureTypes { get; set; }     // [v. SIGNATURE Type]
        public String displayFormat { get; set; }                   // [v. SIGNING_DATE Type]
    }
    // 2-1-1. Size
    public class Size {
        public Double width { get; set; }   // [v]
        public Double height { get; set; }  // [v]
    }
    // 2-1-2. Position. https://modusign.github.io/pdf-position-tool/ 참조
    public class Position {
        public Double x { get; set; }       // [v]
        public Double y { get; set; }       // [v]
        public Integer page { get; set; }   // [v]

        public Position() {}
        public Position(Decimal x, Decimal y, Integer page) {
            this.x = Double.valueOf(x);
            this.y = Double.valueOf(y);
            this.page = page;
        }
    }
    // 2-1-3. TextStyle
    public class TextStyle {
        public Integer size { get; set; }   // [v]
        public FontType font { get; set; }  // [v]
    }
    // 2-2. SigningMethod
    public class SigningMethod {
        public String type { get; set; }    // [v]
        public String value { get; set; }   // [v]
    }
    // 2-3. CheckboxFieldGroup
    public class CheckboxFieldGroup {
        public String groupLabel { get; set; }          // [v]
        public Integer minCheckRequired { get; set; }   // [v]
    }
    // 2-4. Verification
    public class Verification {
        public MobileIdentification mobileIdentification { get; set; }
    }
    // 2-4-1. Verification
    public class MobileIdentification {
        public String name { get; set; }
        public String phoneNumber { get; set; }
    }
    // 3.
    public class RequesterInput {
        public FieldType type { get; set; }         // [v]
        public Size size { get; set; }              // [v]
        public Position position { get; set; }      // [v]
        public TextStyle textStyle { get; set; }    // [v]
        public String value { get; set; }           // [v]
    }
    // Modusign PDF Request Wrapper End

    // ModuSign Webhook Wrapper
    global class ModuSign {
        public EventType event { get; set; }
        public DocumentInfo document { get; set; }
    }
    global class EventType {
        public String type { get; set; }
    }
    global class DocumentInfo {
        public String id { get; set; }
        public Requester requester { get; set; }
    }
    global class Requester {
        public String email { get; set; }
    }

    @TestVisible
    private void test() {
        String str = '1';

        // SAP
        StockDetailInfo detailInfo = new StockDetailInfo(str, str, str, str, str);
        List<StockDetailInfo> detailInfos = new List<StockDetailInfo>{detailInfo};

        StockInfo stockInfo = new StockInfo(true, false, detailInfos);
        stockInfo.PTMOVTP = str;
        stockInfo.DOCNO = str;
        stockInfo.IFID = str;
        stockInfo.MOVTP = str;
        stockInfo.RMK = str;

        List<AvisOrderInfo__c> infos = [
                SELECT Id, OrderIntakeNo__c, ChassisFrameNo__c, HorsePower__c, EngineNumber__c, EngineType__c, WeightKg__c, VehicleNo__c, EmissionLevelEu__c,
                        OrderDate__c, Etd__c, ETA__c, BuyingPrice__c, InvoiceNumber__c, BLDocumentNo__c, Ship__c, HarbourShort__c, Harbour__c, Destination__c,
                        AdjustTargetRos__c, InvoiceDateLastAdjusted__c, BLDate__c, CabMark__c, IntarderOption__c, WheelBase__c, TrimLevel__c, RealArrivalDate__c,
                        CarColor__c,
                        fm_Segment1__c, fm_SpecShort__c, fm_IsDeck__c
                FROM AvisOrderInfo__c
        ];

        List<Product2> p2List = [
                SELECT Id, Name, CreatedDate, fm_HSCode__c, Segment1__c, CabMark__c, Intarder__c, WheelBase__c, TrimLevel__c, EmissionLevel__c
                FROM Product2
        ];

        ERPModel model = new ERPModel(p2List.get(0), true);
        model.IFID = str;
        model.TRP = str;
        model.ITEMCD = str;
        model.SPEC = str;
        model.SPECNM = str;
        model.PERWGT = str;
        model.PERWGTNM = str;

        OrderConfirm confirm = new OrderConfirm(infos.get(0), true);
        confirm.IFID = str;
        confirm.ITEM_TYPE = str;
        confirm.ITEMCD = str;
        confirm.CRTP = str;
        confirm.CRDT = str;

        PurchaseInvoice invoice = new PurchaseInvoice(infos.get(0), true);
        invoice.WEGHT = str;
        invoice.IFID = str;
        invoice.ITEM_TYPE = str;
        invoice.ITEMCD = str;
        invoice.CRTP = str;
        invoice.CRDT = str;

        CustomsInfo info = new CustomsInfo(infos.get(0), true);
        info.IFID = str;

        SalesDetailInfo detail = new SalesDetailInfo();
        detail.ISREQNO = str;
        detail.ROWNO = str;
        detail.ITEMTP = str;
        detail.PRICE = str;
        detail.ITEMCD = str;

        SalesInfo salesInfo = new SalesInfo(true, new List<SalesDetailInfo>{detail});
        salesInfo.ISREQNO = str;
        salesInfo.DISNUM = str;
        salesInfo.CARDCD = str;
        salesInfo.BCARDCD = str;
        salesInfo.BRANCH = str;
        salesInfo.SLPCD = str;
        salesInfo.DREQDT = str;
        salesInfo.ISSUDT = str;
        salesInfo.SALEAMT = str;
        salesInfo.IFID = str;
        salesInfo.VATGRPD = str;
        salesInfo.emission = str;
        salesInfo.model_type = str;
        salesInfo.model_detail1 = str;
        salesInfo.model_detail2 = str;
        salesInfo.model_detail3 = str;
        salesInfo.engine_type = str;
        salesInfo.hp = str;
        salesInfo.cap = str;
        salesInfo.sales_agency = str;
        salesInfo.sales_people = str;

        AccountVAInfo VAinfo = new AccountVAInfo(true);
        VAinfo.U_CardCD = str;
        VAinfo.U_ACCNO = str;
        VAinfo.TYPE = str;
        VAinfo.TOTAL_AMT = str;
        VAinfo.NOTARY_FEE = str;
        VAinfo.CAMPAIGN_FEE = str;

        OffsetProcess process = new OffsetProcess();
        process.ORCT_LIST = new List<String>();
        process.OINV_DOCNO = str;
        process.ORCT_PRICE = str;

        WarehouseInfo whInfo = new WarehouseInfo();
        whInfo.QTY = str;
        whInfo.WHSCD = str;
        whInfo.WHSNM = str;

        PartStockInfo pStockInfo = new PartStockInfo();
        pStockInfo.ITEMCD = str;
        pStockInfo.ITEMNM = str;
        pStockInfo.SPEC = str;
        pStockInfo.INVUOM = str;
        pStockInfo.STK = new List<WarehouseInfo>{whInfo};
        pStockInfo.WHMAP = new Map<String, Integer>();

        PartStock pStock = new PartStock();
        pStock.ResultData = new List<PartStockInfo>{pStockInfo};

        VehicleStockInfo vStockInfo = new VehicleStockInfo();
        vStockInfo.ITEMCD = str;
        vStockInfo.DISNUM = str;
        vStockInfo.ITEMNM = str;
        vStockInfo.SPEC = str;
        vStockInfo.INVUOM = str;
        vStockInfo.STK = new List<WarehouseInfo>{whInfo};
        vStockInfo.WHMAP = new Map<String, Integer>();

        VehicleStock vStock = new VehicleStock();
        vStock.ResultData = new List<VehicleStockInfo>{vStockInfo};

        TaxInvoiceInfo taxInvoiceInfo = new TaxInvoiceInfo();
        taxInvoiceInfo.IFID = str;
        taxInvoiceInfo.ISREQNO = str;
        taxInvoiceInfo.ISSUETYPE = str;
        taxInvoiceInfo.DISNUM = str;
        taxInvoiceInfo.CARDCD = str;
        taxInvoiceInfo.BCARDCD = str;
        taxInvoiceInfo.SLPCD = str;
        taxInvoiceInfo.DREQDT = str;
        taxInvoiceInfo.ISSUDT = str;
        taxInvoiceInfo.PAYTP = str;
        taxInvoiceInfo.SALEPRICE = str;
        taxInvoiceInfo.SALEAMT = str;
        taxInvoiceInfo.VATGRP = str;
        taxInvoiceInfo.BPLID = str;
        taxInvoiceInfo.REVNO = str;
        taxInvoiceInfo.MVTP = str;
        taxInvoiceInfo.MANO = str;
        taxInvoiceInfo.TPAPNO = str;
        taxInvoiceInfo.TPAPYM = str;
        taxInvoiceInfo.CARNO = str;
        taxInvoiceInfo.ERRCOD = str;
        taxInvoiceInfo.ERRMSG = str;
        taxInvoiceInfo.ARNO = str;
        taxInvoiceInfo.ARYN = str;
        taxInvoiceInfo.ARDT = str;
        taxInvoiceInfo.TAXNO = str;

        TaxInvoice taxInvoice = new TaxInvoice();
        taxInvoice.ResultData = new List<TaxInvoiceInfo>{taxInvoiceInfo};

        PaymentDetailInfo paymentDetailInfo = new PaymentDetailInfo();
        paymentDetailInfo.doc_entry = str;
        paymentDetailInfo.doc_num = str;
        paymentDetailInfo.card_cd = str;
        paymentDetailInfo.acc_no = str;
        paymentDetailInfo.crncy = str;
        paymentDetailInfo.doc_total = str;
        paymentDetailInfo.doc_total_fc = str;

        PaymentInfo paymentInfo = new PaymentInfo();
        paymentInfo.ResultData = new List<PaymentDetailInfo>{paymentDetailInfo};

        CommonResult result = new CommonResult();
        result.Code = str;
        result.Message = str;


        // ModuSign
        Size size = new Size();
        size.width = 100;
        size.height = 100;
        TextStyle style = new TextStyle();
        style.size = 100;
        style.font = FontType.NOTO_SANS;
        Position position = new Position(100, 100, 100);
        SigningMethod method = new SigningMethod();
        method.type = '100';
        method.value = '100';
        Field field = new Field();
        field.type = FieldType.TEXT;
        field.size = size;
        field.position = position;
        field.signatureTypes = new List<SignatureType>();
        CheckboxFieldGroup fieldGroup = new CheckboxFieldGroup();
        fieldGroup.groupLabel = '100';
        fieldGroup.minCheckRequired = 100;

        RequesterInput input = new RequesterInput();
        input.type = FieldType.TEXT;
        input.size = size;
        input.position = position;
        input.textStyle = style;
        input.value = '100';
        Participant participant = new Participant();
        participant.name = '100';
        participant.signingOrder = 100;
        participant.signingMethod = method;
        participant.fields = new List<Field>{field};
        participant.checkboxFieldGroups = new List<CheckboxFieldGroup>{fieldGroup};
        participant.signingDuration = 100;
        participant.locale = '100';
        participant.role = '100';
        File file = new File();
        file.extension = '100';
        file.base64 = '100';

        SigningRequestByPDF requestByPDF = new SigningRequestByPDF();
        requestByPDF.file = file;
        requestByPDF.participants = new List<Participant>{participant};
        requestByPDF.title = '100';
        requestByPDF.fileOpenPassword = '100';
        requestByPDF.requesterInputs = new List<RequesterInput>{input};
        
        LoanRequestInfo loanRequestInfo = new LoanRequestInfo();
        loanRequestInfo.quote_id = str;
        loanRequestInfo.sale_agent_nm = str;
        loanRequestInfo.apply_rate = str;
        loanRequestInfo.loan_term = str;
        loanRequestInfo.vhc_price = str;
        loanRequestInfo.vhc_dc = str;
        loanRequestInfo.vhc_exp = str;
        loanRequestInfo.loan_amt = str;
        loanRequestInfo.reg_tax = str;
        loanRequestInfo.spc_vhc_price = str;
        loanRequestInfo.pre_amt = str;
        loanRequestInfo.mfs_vat_amt = str;
        loanRequestInfo.mfs_vat_request = str;
        loanRequestInfo.opp_id = str;
        loanRequestInfo.invoice_dt = str;
        loanRequestInfo.virtual_acc = str;
        loanRequestInfo.bsn_no = str;
        loanRequestInfo.rrn = str;
        loanRequestInfo.bsn_nm = str;
        loanRequestInfo.bsn_tel = str;
        loanRequestInfo.bsn_add = str;
        loanRequestInfo.email_add = str;
        loanRequestInfo.tel_no = str;
        loanRequestInfo.cs_nm = str;
        loanRequestInfo.stock_no = str;
        loanRequestInfo.vhc_model_nm = str;
        loanRequestInfo.spc_vhc = str;
        loanRequestInfo.o_coupon_price = str;
        loanRequestInfo.campaign = str;
        loanRequestInfo.campaign_dc_amt = str;
        loanRequestInfo.option_price = str;
        loanRequestInfo.model_cd = str;
        loanRequestInfo.sale_agent_id = str;
        loanRequestInfo.sale_agent_tel = str;
        loanRequestInfo.virtual_acc_nm = str;
        loanRequestInfo.virtual_acc_cd = str;
        loanRequestInfo.loan_request_dt = str;
    }
}