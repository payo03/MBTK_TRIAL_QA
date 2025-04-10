/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-06
 * @description : 계약 레코드 상세 페이지에서 버튼 클릭시 deposit 사전배정요청 생성
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-12-31      chaebeom.do     Created
 **************************************************************/
import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";

//library
import getAcc from "@salesforce/apex/CreateAssignRequestController.getAcc";
import createAssignRequest from "@salesforce/apex/CreateAssignRequestController.createAssignRequest";

// Util
import { showToast } from "c/commonUtil";


export default class DepositInvoice extends LightningElement {
  @api recordId;
  @track isLoading = false;

  accName;
  vehicleName;
  opptyId;
  stockId;
  deposit = 1000000;

  @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }
  
    connectedCallback() {
      getAcc({recordId: this.recordId}).then(res => {
        console.log('res:: ' + res);
        this.accName = res[0].accName;
        this.vehicleName = res[0].vehicleName;
        this.opptyId = res[0].opportunity;
        this.stockId = res[0].vehicleId;
      });
    }

    // 향후 견적의 금융 섹션의 계약금을 계약 생성시에 자동으로 넣고
    // 계약금 요청 버튼 클릭시에는 해당 계약금을 가져와서 보여줄 수도 있음
  sendDeposit() {
    if (this.deposit == null) {
      showToast("필수 입력", "계약금을 입력해주세요.", "error");
    } else {
      this.isLoading = true;
      let inputMap = { recordId: this.opptyId, deposit: this.deposit, stockId: this.stockId, contractId: this.recordId, type: 'deposit' };
      createAssignRequest({inputMap: inputMap}).then(() => {
        // notifyRecordUpdateAvailable([{recordId: this.recordId}]);
        showToast("전송 완료", "계약금 요청을 고객에게 전송하였습니다.", "success");
      }).finally(() => {
        this.isLoading = false;
        this.handleCancel();
      })
    }
  }

  // handleChange(e) {
  //   const value = e.target.value;
  //   this.deposit = value;
  // }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}