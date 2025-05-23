/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-06
 * @description : 견적 레코드 상세 페이지에서 버튼 클릭시 기회 첨부파일 체크 후 계약서 레코드 생성
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-06      chaebeom.do     Created
 * 1.1          2025-04-30      chaebeom.do     고객 유형에 따라 필수 서류 & 계정 필드 분기
 **************************************************************/
import { api, LightningElement, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { CloseActionScreenEvent } from "lightning/actions";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";

//library
import getQuote from "@salesforce/apex/CreateContractController.getQuote";
import createContract from "@salesforce/apex/CreateContractController.createContract";
import { CurrentPageReference } from 'lightning/navigation';
import formFactor from "@salesforce/client/formFactor";

// Util
import { showToast, recordNavigation, defaultNavigation } from "c/commonUtil";

export default class CreateContract extends NavigationMixin(LightningElement) {
  @api recordId;

  curQuote = {};
  accTypeMap = {
    person: false,
    personBiz: false,
    corpBiz: false
  }

  isLoading = false;

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
      if (currentPageReference) {
          this.recordId = currentPageReference.state.recordId;
      }
      if (currentPageReference && !this.recordId) {
        this.recordId = currentPageReference.state?.c__recordId;
      }
  }

  connectedCallback(){
    this.isLoading = true;
    getQuote({quoteId: this.recordId}).then(res => {
      Object.assign(this.curQuote, {
				...res,
        vatStatus: res.vatStatus == '승인됨' ? true : false
			});

      if (this.curQuote.accType == '실차주') {
        showToast("필수 항목 누락", "실차주는 견적 대상이 될 수 없습니다.", "error");
        this.isLoading = false;
        this.handleCancel();
        return;
      } 
        
      // accType과 accTypeMap 키를 연결하는 매핑
      const accTypeKeyMap = {
        '개인': 'person',
        '개인사업자': 'personBiz',
        '법인사업자': 'corpBiz',
        '특장회사': 'corpBiz',
        '지입회사': 'corpBiz'
      };

      // accTypeMap 초기화
      Object.keys(this.accTypeMap).forEach(key => {
        this.accTypeMap[key] = false;
      });

      // 현재 accType에 해당하는 키 true로 설정
      const keyToActivate = accTypeKeyMap[this.curQuote.accType];
      if (keyToActivate) {
        this.accTypeMap[keyToActivate] = true;
      }

    }).finally(() => this.isLoading = false);
  }

  createContract(){
    this.isLoading = true;
    if (this.curQuote.contractId) {
      showToast("중복 방지", "이미 계약이 생성된 견적입니다.", "warning");
      this.isLoading = false;
      return;
    }
    if (this.curQuote.opptyContractId) {
      showToast("중복 방지", "기회에 진행 중인 계약이 있습니다. 기존 계약을 취소해주세요.", "warning");
      this.isLoading = false;
      return;
    }
    if (!this.curQuote.hopeHandoverDate) {
      showToast("필수 항목 누락", "견적의 출고희망일이 비어있습니다.", "error");
      this.isLoading = false;
      return;
    }
    switch (this.curQuote.accType) {
      case "필수선택" :
        showToast("필수 항목 누락", "계정의 계정유형 필드를 입력해주세요.", "error");
        this.isLoading = false;
        return;
      case "개인" :
        if (
          !this.curQuote.jumin || !(this.curQuote.vatStatus && this.curQuote.vat) 
          || !this.curQuote.accIDnumber || !this.curQuote.accRoadAddress
        ) {
          let oppRequired = ["", ""];
          let accRequired = ["", ""];
          if(!this.curQuote.jumin) oppRequired[0] = "주민등록증";
          if(!(this.curQuote.vatStatus && this.curQuote.vat)) oppRequired[1] = "부가세후취 서류";
          if(!this.curQuote.accIDnumber) accRequired[0] = "주민번호";
          if(!this.curQuote.accRoadAddress) accRequired[1] = "도로명 주소";
          const filteredOppRequired = oppRequired.filter(str => str && str.trim());
          const filteredAccRequired = accRequired.filter(str => str && str.trim());
          let msg = "다음 항목을 확인해주세요 : 기회 - " + filteredOppRequired.join(", ") + " /";
          msg += " 계정 - " + filteredAccRequired.join(", ");
          showToast("필수 항목 누락", msg, "error");
          this.isLoading = false;
          return;
        }
        break;
      case "개인사업자" :
        if (
          !this.curQuote.jumin || !this.curQuote.bizNo || !(this.curQuote.vatStatus && this.curQuote.vat) 
          || !this.curQuote.accIDnumber || !this.curQuote.accBizNo
          || !this.curQuote.accBizName || !this.curQuote.accRepName || !this.curQuote.accRoadAddress
        ) {
          let oppRequired = ["", "", ""];
          let accRequired = ["", "", "", "", ""];
          if(!this.curQuote.jumin) oppRequired[0] = "주민등록증";
          if(!this.curQuote.bizNo) oppRequired[1] = "사업자등록증";
          if(!(this.curQuote.vatStatus && this.curQuote.vat)) oppRequired[2] = "부가세후취 서류";
          if(!this.curQuote.accIDnumber) accRequired[0] = "주민번호";
          if(!this.curQuote.accBizNo) accRequired[1] = "사업자번호";
          if(!this.curQuote.accBizName) accRequired[2] = "사업자명";
          if(!this.curQuote.accRepName) accRequired[3] = "대표자명";
          if(!this.curQuote.accRoadAddress) accRequired[4] = "도로명 주소";
          const filteredOppRequired = oppRequired.filter(str => str && str.trim());
          const filteredAccRequired = accRequired.filter(str => str && str.trim());
          let msg = "다음 항목을 확인해주세요 : 기회 - " + filteredOppRequired.join(", ") + " /";
          msg += " 계정 - " + filteredAccRequired.join(", ");
          showToast("필수 항목 누락", msg, "error");
          this.isLoading = false;
          return;
        }
        break;
      case "법인사업자" || "특장회사" || "지입회사" :
        if (
          !this.curQuote.bizNo || !(this.curQuote.vatStatus && this.curQuote.vat) 
          || !this.curQuote.accBizNo || !this.curQuote.accCompRegNo
          || !this.curQuote.accBizName || !this.curQuote.accRepName || !this.curQuote.accRoadAddress
        ) {
          let oppRequired = ["", ""];
          let accRequired = ["", "", "", "", ""];
          if(!this.curQuote.bizNo) oppRequired[0] = "사업자등록증";
          if(!(this.curQuote.vatStatus && this.curQuote.vat)) oppRequired[1] = "부가세후취 서류";
          if(!this.curQuote.accBizNo) accRequired[0] = "사업자번호";
          if(!this.curQuote.accCompRegNo) accRequired[1] = "법인등록번호";
          if(!this.curQuote.accBizName) accRequired[2] = "사업자명";
          if(!this.curQuote.accRepName) accRequired[3] = "대표자명";
          if(!this.curQuote.accRoadAddress) accRequired[4] = "도로명 주소";
          const filteredOppRequired = oppRequired.filter(str => str && str.trim());
          const filteredAccRequired = accRequired.filter(str => str && str.trim());
          let msg = "다음 항목을 확인해주세요 : 기회 - " + filteredOppRequired.join(", ") + " /";
          msg += " 계정 - " + filteredAccRequired.join(", ");
          showToast("필수 항목 누락", msg, "error");
          this.isLoading = false;
          return;
        }
        break;
    }

    let inputMap = { 
      recordId: this.recordId, 
      accId: this.curQuote.accId, 
      stockId: this.curQuote.stockId,
      productId : this.curQuote.productId, 
      opptyId: this.curQuote.opptyId,
      segment: this.curQuote.segment,
      totalLoanAmount: this.curQuote.totalLoanAmount
    };
    createContract({inputMap: inputMap}).then(res => {
      if (res == 'noStockForSelling') {
        showToast("판매 가능 재고 없음", "선택한 모델의 차량재고 중 기본작업이 완료된 재고가 없습니다. 매니지먼트팀에 문의바랍니다.", "error", "sticky")
      } else if(res == 'approvalNotComplete') {
        showToast("대출 승인 미완료", "견적의 대출승인여부 필드 체크를 확인해주세요.", "error", "sticky");
        return;
      } else if(res == 'deliveryPriceNotValid') {
        showToast("선수금 오류", "선수금이 마이너스 금액으로 계산됩니다. 다시 확인해주세요.", "error", "sticky");
        return;
      } else {
        showToast("계약 승인 요청 완료", "승인 프로세스가 완료되면 계약 업데이트가 가능합니다.", "success");
        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
        // defaultNavigation(this, "Contract", '', res, null, null, !this.isMobile);
        defaultNavigation(this, "Contract", '', res);
      }
      if(formFactor !== "Small") this.handleCancel();
    }).catch(err => {
      showToast("계약 생성 실패", "관리자에게 문의 바랍니다.", "error");
      console.log("err createContract :: ", err)
    }).finally(() => this.isLoading = false);
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
    this.mobileReturnPage();
  }

  mobileReturnPage() {
    if(formFactor === "Small") {
      recordNavigation(this, "Quote", this.recordId);
    }
  }
}