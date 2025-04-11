/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-03-21
 * @description : 계약서 재협상 버튼
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-21        chaebeom.do        Created
**************************************************************/
import { LightningElement, track, wire, api } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { showToast, recordNavigation } from "c/commonUtil";
import { CloseActionScreenEvent } from "lightning/actions";

import init from "@salesforce/apex/ContractCancelController.init";
import cancelByCase from "@salesforce/apex/ContractCancelController.cancelByCase";
import formFactor from "@salesforce/client/formFactor";

export default class ContractRenegotiation extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading= false;
    contractNo;

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
      init({recordId: this.recordId}).then(result => {
        this.contractNo = result.Contract.ContractNumber;
      }).catch(error => {
        showToast('Error', 'Error init()', 'error', 'dismissable');
        console.log('error :: ', error);
      });
    }

    //선택 취소
    handleCancel() {
      this.dispatchEvent(new CloseActionScreenEvent());
      this.mobileReturnPage();
    }
  
    mobileReturnPage() {
      if(formFactor === "Small") {
        recordNavigation(this, "Contract", this.recordId);
      }
    }

    //계약 재협상상 실행
    handleCancelContract(){
      this.isLoading = true;
      cancelByCase({type: 'renegotiation', opptyId: this.recordId}).then(result => {
        console.log('result :: ', result);
        showToast('취소 완료', '변경된 견적에서 새 계약을 생성하세요.', 'success');
      }).catch(error => {
        showToast('Error', 'Error cancelContract', 'error', 'dismissable');
        console.log('error :: ', error);
      }).finally(() => {
        this.handleCancel();
        this.isLoading = false;
        setTimeout(() => {
          location.reload();
        }, 1000);
      });
    }
}