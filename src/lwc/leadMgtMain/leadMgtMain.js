/*************************************************************
 * @author : th.kim
 * @date : 2024-11-07
 * @description :
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-07      th.kim          Created
 **************************************************************/
import { LightningElement } from "lwc";

export default class leadMgtMain extends LightningElement {

	/**
	 * @description 마커 클릭 이벤트 전송
	 */
	handleMarkerClick(e) {
		const tableEl = this.template.querySelector("c-lead-table");
		tableEl.getClickDataFromParent(e.detail.data);
	}

	handleMarkerFilterEvent(e) {
		const tableEl = this.template.querySelector("c-lead-table");
		tableEl.getLeadListFromParent(e.detail.data);
	}
}