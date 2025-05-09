/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-05-08      payo03@solomontech.net           Created
*/
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from "lightning/navigation";
import { CloseActionScreenEvent } from "lightning/actions";
import { showToast } from "c/commonUtil";
import sendLoanApproval from '@salesforce/apex/InterfaceMFS.sendLoanApproval';

export default class loanRequestMFS extends LightningElement {

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        sendLoanApproval({ recordId: this.pageRef.state.recordId })
            .then(() => {
				showToast("Success", "대출심사 승인 요청이 완료되었습니다", "success", "dismissable");

				setTimeout(() => {
					this.dispatchEvent(new CloseActionScreenEvent());
				}, 1000);
            })
            .catch((error) => {
				showToast("Error", error.body?.message || error.message, "error", "dismissable");
            });
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
