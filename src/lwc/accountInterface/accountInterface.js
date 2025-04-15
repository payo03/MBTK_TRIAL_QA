/**
* @Author            : payo03@solomontech.net
* @Description 		 :
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-26      payo03@solomontech.net           Created
*/
import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from "lightning/navigation";
import { showToast } from "c/commonUtil";

import fetchRecord from "@salesforce/apex/AccountInterface.fetchRecord";
import updateRecord from "@salesforce/apex/AccountInterface.updateRecord";
import sendCustomerInfo from "@salesforce/apex/AccountInterface.sendCustomerInfo";

export default class accountInterface extends LightningElement {
    @wire(CurrentPageReference) pageRef;

    recordId;
    @track account = {};

    connectedCallback() {
        this.recordId = this.pageRef.state.recordId;
        console.log(this.recordId);

        this.resizePop();
        this.fetchRecord();
    }

    resizePop() {

        requestAnimationFrame(() => {
            const modalContainerEl = document.querySelector(".slds-modal__container");

            if(modalContainerEl) {
                let modalWidth = 600;
                modalContainerEl.style.width = `${modalWidth}px`;
            }
        });
    }

    fetchRecord() {
        fetchRecord({ recordId: this.recordId }).then(res => {
            this.account = res;

        }).catch(error => {
            showToast('Error', 'Error Fetch Record', 'error', 'dismissable');
            console.log(error);
        });
    }

    // 입력값 Setting 공통
    handleInputChange(event) {
        try {
            let fieldName = event.target.name;

            this.account[fieldName] = event.target.value;
        } catch(error){
            console.log(error);
        }
    }
    
    handleSave() {
        updateRecord({ account: this.account }).then(res => {

            showToast('Success', 'Update Record', 'success', 'dismissable');
        }).catch(error => {
            showToast('Error', 'Error Update Record', 'error', 'dismissable');
            console.log(error);
        });
    }

    handleSendInfo() {
        sendCustomerInfo({ recordId: this.recordId }).then(res => {

            showToast('Success', 'Send Customer Info', 'success', 'dismissable');
        }).catch(error => {
            showToast('Error', 'Error Send Customer Info', 'error', 'dismissable');
            console.log(error);
        });
    }
}