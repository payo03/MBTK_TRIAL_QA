/*************************************************************
 * @author : th.kim
 * @date : 2024-11-11
 * @description : 현재 사용 안함 XX
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-11      th.kim          Initial Version
 **************************************************************/
import { LightningElement, wire } from "lwc";

// Library
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";

import createOppty from "@salesforce/apex/NewOpptyController.createOppty";
import { defaultNavigation, showToast } from "c/commonUtil";

export default class newOppty extends NavigationMixin(LightningElement) {

	@wire(CurrentPageReference) pageRef;
	recordId;
	isLoading;

	connectedCallback() {
		this.recordId = this.pageRef.state.c__recordId;
		console.log("recordId :: ", this.recordId);
	}

	handleSave() {
		this.isLoading = true;
		const inputEl = this.template.querySelector("lightning-input-field");
		const accountId = inputEl?.value;
		console.log("accountId :: ", accountId);
		if(accountId) {
			const dataParams = { recordId: this.recordId, accountId: accountId };
			createOppty({ dataParams: dataParams }).then(res => {
				console.log("res :: ", res);
				defaultNavigation(this, "Opportunity", null, res);
				this.isLoading = false;
			}).catch(err => {
				console.log("err :: ", err);
				showToast("", err.body.message, "warning");
				this.isLoading = false;
			});
		}
	}

	handleCancel() {
		window.history.back();
	}
}