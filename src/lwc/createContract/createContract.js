/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-06
 * @description : 견적 레코드 상세 페이지에서 버튼 클릭시 기회 첨부파일 체크 후 계약서 레코드 생성
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-06      chaebeom.do     Created
 **************************************************************/
import { api, LightningElement, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { CloseActionScreenEvent } from "lightning/actions";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";

//library
import getQuote from "@salesforce/apex/CreateContractController.getQuote";
import createContract from "@salesforce/apex/CreateContractController.createContract";
import { CurrentPageReference } from 'lightning/navigation';

// Util
import { showToast, defaultNavigation } from "c/commonUtil";

export default class CreateContract extends NavigationMixin(LightningElement) {
  @api recordId;
  opptyId;
  accId;
  stockId;
  contractId;
  opptyContractId;
  segment;
  isJumin;
  isBizNo;
  isVAT;
  vatStatus;

  isLoading = false;

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
      if (currentPageReference) {
          this.recordId = currentPageReference.state.recordId;
      }
  }

  connectedCallback(){
    getQuote({quoteId: this.recordId}).then(res => {
      this.isJumin = res[0].jumin;
      this.isBizNo = res[0].bizNo;
      this.isVAT = res[0].vat;
      this.vatStatus = res[0].vatStatus == '승인됨' ? res[0].vat : true;
      this.opptyId = res[0].opptyId;
      this.accId = res[0].accId;
      this.stockId = res[0].stockId;
      this.contractId = res[0].contractId;
      this.opptyContractId = res[0].opptyContractId;
      this.segment = res[0].segment;
    })
  }

  createContract(){
    this.isLoading = true;
    if (this.contractId) {
      showToast("중복 방지", "이미 계약이 생성된 견적입니다.", "warning");
      this.isLoading = false;
      return;
    }
    if (this.opptyContractId) {
      showToast("중복 방지", "기회에 진행 중인 계약이 있습니다. 기존 계약을 취소해주세요.", "warning");
      this.isLoading = false;
      return;
    }
    if (!this.isJumin || !this.isBizNo || !this.vatStatus) {
      let required = ["", "", ""];
      if(!this.isJumin) required[0] = "주민등록증";
      if(!this.isBizNo) required[1] = "사업자등록증";
      if(!this.vatStatus) required[2] = "부가세후취 서류";
      const filteredRequired = required.filter(str => str && str.trim());
      let msg = "다음 항목을 기회에 업로드해주세요 : " + filteredRequired.join(", ");
      showToast("필수 항목 누락", msg, "error");
      this.isLoading = false;
      return;
    }
    if (!this.stockId) {
      showToast("", "", "warning");
      this.isLoading = false;
      return;
    }
    let inputMap = { 
      recordId: this.recordId, 
      accId: this.accId, 
      stockId: this.stockId, 
      opptyId: this.opptyId,
      segment: this.segment
    };
    console.log('inputMap :: ' + inputMap);
    createContract({inputMap: inputMap}).then(res => {
      if (res == 'noStockForSelling') {
        showToast("판매 가능 재고 없음", "선택한 모델의 차량재고 중 기본작업이 완료된 재고가 없습니다. 매니지먼트팀에 문의바랍니다.", "error", "sticky")
      } else {
        showToast("계약 승인 요청 완료", "승인 프로세스가 완료되면 계약 업데이트가 가능합니다.", "success");
        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
        defaultNavigation(this, "Contract", null, res, null, null, !this.isMobile);
      }
      this.handleCancel();
    }).catch(err => {
      showToast("계약 생성 실패", "관리자에게 문의 바랍니다.", "error");
      console.log("err init :: ", err)
    }).finally(() => this.isLoading = false);
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  onRefresh() {
    this.dispatchEvent(new RefreshEvent());
  }
}