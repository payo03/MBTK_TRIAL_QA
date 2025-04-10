/*************************************************************
 * @author : th.kim
 * @date : 2025-01-08
 * @description : 현재 사용안함
 * @target : 사용안함
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-08      th.kim          Initial Version
 **************************************************************/
import { LightningElement, wire } from "lwc";
import { componentNavigation } from "c/commonUtil";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";

export default class navigateToComponent extends NavigationMixin(LightningElement) {

	@wire(CurrentPageReference)
	getStateParameters(pageRef) {
		if (pageRef) {
			componentNavigation(this, pageRef.state.componentName, pageRef.state);
		}
	}
}