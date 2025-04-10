/*************************************************************
 * @author : th.kim
 * @date : 2025-01-21
 * @description :
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-21      th.kim          Initial Version
 **************************************************************/
import { LightningElement, track } from "lwc";

import getInit from "@salesforce/apex/SchedulerMainController.getInit";

export default class schedulerMain extends LightningElement {

	@track parentData;
	isLoading;

	connectedCallback() {

		// 브라우저 title 설정
		document.title = "스케줄 관리";

		this.isLoading = true;
		getInit().then(res => {
			console.log("res :: ", res);
			this.parentData = res;
		}).catch(err => {
			console.log("err :: ", err);
		}).finally(() => this.isLoading = false);
	}
}