/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-06
 * @description : 계약 레코드 상세 페이지에서 버튼 클릭시 deposit 사전배정요청 생성
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-12-31      chaebeom.do     Created
 * 1.1          2025-04-07      chaebeom.do     요청시 고객코드/사업자명/사업자번호 체크
 * 1.2          2025-04-18      chaebeom.do     사업자번호 체크 주민등록번호와 OR 조건으로 수정
 **************************************************************/
import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";

//library
import getAcc from "@salesforce/apex/CreateAssignRequestController.getAcc";
import createAssignRequest from "@salesforce/apex/CreateAssignRequestController.createAssignRequest";
import formFactor from "@salesforce/client/formFactor";

// Util
import { showToast, recordNavigation } from "c/commonUtil";


export default class DepositInvoice extends LightningElement {
  @api recordId;
  @track isLoading = false;

  accName;
  accPhone;
  accBpCode;
  accBusinessName;
  accBusinessNo;
  accIdNo;
  vehicleName;
  opptyId;
  stockId;
  deposit = 1000000;

  @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
        if (currentPageReference && !this.recordId) {
          this.recordId = currentPageReference.state?.c__recordId;
        }
    }
  
    connectedCallback() {
      getAcc({recordId: this.recordId}).then(res => {
        this.accName = res[0].accName;
        this.accPhone = res[0].accPhone;
        this.accBpCode = res[0].bpCode;
        this.accBusinessName = res[0].businessName;
        this.accBusinessNo = res[0].businessNumber;
        this.accIdNo = res[0].idNumber;
        this.vehicleName = res[0].vehicleName;
        this.opptyId = res[0].opportunity;
        this.stockId = res[0].vehicleId;
      });
    }

    // ver 1.1 요청시 account의 고객코드/사업자명/사업자 번호 필드가 없으면 에러 토스트 발생 및 어떤 필드 값이 비었는지 표시
  sendDeposit() {
    this.isLoading = true;
    if (!this.accBpCode || !this.accBusinessName || (!this.accBusinessNo && !this.accIdNo)) { //ver 1.2
      let required = ["", "", ""];
      if(!this.accBpCode) required[0] = "고객코드";
      if(!this.accBusinessName) required[1] = "사업자명";
      if(!this.accBusinessNo && !this.accIdNo) required[2] = "사업자번호 또는 주민등록번호";
      const filteredRequired = required.filter(str => str && str.trim());
      let msg = "계정의 다음 필드를 입력해주세요. : " + filteredRequired.join(", ");
      showToast("필수 항목이 빈 값입니다.", msg, "error");
      this.isLoading = false;
      return;
    }
    if (this.deposit == null) {
      showToast("필수 입력", "계약금을 입력해주세요.", "error");
      this.isLoading = false;
    } else {
      let inputMap = { recordId: this.opptyId, deposit: this.deposit, stockId: this.stockId, contractId: this.recordId, type: 'deposit' };
      createAssignRequest({inputMap: inputMap}).then(() => {
        showToast("전송 완료", "계약금 요청을 고객에게 전송하였습니다.", "success");
      }).finally(() => {
        this.isLoading = false;
        this.handleCancel();
      })
    }
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
    this.mobileReturnPage();
  }

  mobileReturnPage() {
    if(formFactor === "Small") {
      recordNavigation(this, "Contract", this.recordId);
    }
  }
}