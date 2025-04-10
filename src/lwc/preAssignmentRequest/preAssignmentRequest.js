/*************************************************************
 * @author : th.kim
 * @date : 2024-11-12
 * @description :
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-12      th.kim          Initial Version
 **************************************************************/
import { LightningElement, api } from "lwc";

import { NavigationMixin } from "lightning/navigation";
import { componentNavigation } from "c/commonUtil";

export default class PreAssignmentRequest extends NavigationMixin(LightningElement) {

	@api recordId;

	connectedCallback() {
		// // 세션 스토리지에서 방문 여부 확인
		// const hasVisited = sessionStorage.getItem('hasVisited');
		//
		// if (!hasVisited) {
		// 	// 방문한 적이 없으면 이동
			this.redirectToPage();
			// 방문 여부 기록
		// 	sessionStorage.setItem('hasVisited', 'true');
		// }
	}

	/**
	 * @description 재고조회 화면으로 페이지 이동
	 */
	redirectToPage() {
		requestAnimationFrame(() => {
			console.log("this.recordId :: ", this.recordId);
			const state = {
				c__stockId: this.recordId
			};
			componentNavigation(this, "c__vehicleStockTable", state);
		});
	}
}