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
import { CurrentPageReference } from "lightning/navigation";
import { showToast } from "c/commonUtil";
import { CloseActionScreenEvent } from "lightning/actions";

import init from "@salesforce/apex/ContractCancelController.init";
import cancelByCase from "@salesforce/apex/ContractCancelController.cancelByCase";

export default class ContractRenegotiation extends LightningElement {
    @api recordId;
    isLoading= false;
    contractNo;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
      if (currentPageReference) {
        this.recordId = currentPageReference.state.recordId;
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
    handleCancel(){
      this.dispatchEvent(new CloseActionScreenEvent());
    }

    //계약 취소 실행
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
      });
    }
}