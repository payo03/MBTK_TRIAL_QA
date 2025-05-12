/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-05-12      payo03@solomontech.net           Created
*/
import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { CurrentPageReference } from "lightning/navigation";

import { showToast } from "c/commonUtil";

import sendMail from '@salesforce/apex/OpportunityPDFController.sendMail';

export default class LoanPdfSend extends LightningElement {

    @wire(CurrentPageReference) pageRef;
    @api isModalOpen = false;
    @api vfPageURL = '';
    @api recordId;

    connectedCallback() {
        this.recordId = this.pageRef.state.recordId;
        this.vfPageURL = '/apex/InvoicePDF?id=' + this.recordId;

        this.isModalOpen = true;
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSendMail() {
        sendMail().then(res => {
            console.log(res);
        }).catch(error => {
            showToast('Error', 'Error Send Mail', 'error', 'dismissable');
            console.log(error);
        });
    }
}