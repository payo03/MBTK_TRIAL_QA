/*************************************************************
 * @author : San.Kang
 * @date : 2025-01-09
 * @description : 계약서 변경 승인 프로세스 버튼
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-01-09        San.Kang           Created
**************************************************************/
import { LightningElement, track, wire,api } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import userId from "@salesforce/user/Id";
import { showToast, sortData, resourceList } from "c/commonUtil";
import { CloseActionScreenEvent } from "lightning/actions";

import ContractAmendmentApprovalProcess from "@salesforce/apex/CommonUtilCustomController.ContractAmendmentApprovalProcess";

export default class ContractAmendment extends LightningElement {
    @api recordId;
    inputValue = '';

    connectedCallback() {

    }

    //코멘트 작성
    handleInputChange(e){
      this.inputValue = event.target.value;
    }

    //확인 눌렀을 시 승인프로세스 실행
    handleSubmit(e) {
         let InfoMap = {recordId: this.recordId,userId: userId, comment: this.inputValue, approvalProcess: 'ContractAmendmentProcess'};
         console.log(userId);
         console.log(this.recordId);
         ContractAmendmentApprovalProcess({InfoMap: InfoMap}).then(res => {
                showToast("", "계약서 변경 "+ res, "success");
                this.handleCancel();
            }).catch(err => {
                showToast("관리자에게 문의바랍니다.", err, "error");
            });
    }

    //취소
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}