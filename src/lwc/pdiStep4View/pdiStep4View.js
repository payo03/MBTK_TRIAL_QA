/**
 * @Author            : payo03@solomontech.net
 * @Description 		 :
 * @Target            :
 * @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-22      payo03@solomontech.net           Created
 */
import { api, track, LightningElement } from "lwc";

import step4Init from "@salesforce/apex/PdiController.step4Init";
import installSpoilerToVehicleStock from "@salesforce/apex/PdiController.installSpoilerToVehicleStock";
import spoilerDropoffSAP from "@salesforce/apex/PdiController.spoilerDropoffSAP";

// Util
import { showToast } from "c/commonUtil";

import {
	columns,
	optionColumns,
	detailColumns,
	installColumns
} from "./pdiStep4ViewColumns";


export default class PdiStep4View extends LightningElement {

	groupColumns = columns;
	groupDetailColumns = detailColumns;
	optionColumns = optionColumns;
	installColumns = installColumns;
	selectedRows;

	@track _selectedVIN;
	@track selectedOptionData = [];
	@track groupList;
	@track groupDetailList = [];
	@track installList = [];
	initialInstallStatus = 0; // 스포일러 장착 여부의 초기 상태 기록
	@track varStepList;

	paramMapList= [];

	// 모달
	isModalOpen;
	modalMap = { add: false, remove: false, viewVIN: false };
	isLoading = false;

	connectedCallback() {
		this.init();
	}

	init() {
		this.isLoading = true;
		step4Init({ selectVIN: this._selectedVIN.Id, installedSpoiler: this._selectedVIN.SpoilerPart__c }).then(response => {
			console.log("### response : ", response);

			this.selectedOptionData = response?.selectedOption;
			this.installList = response?.installList;
			if(this.installList.length) this.installList[0].installDate = this.varStepList[3].StepEnd__c;
			this.groupList = response?.spoilerPartsJuntion;
		}).catch(error => {
			showToast("Error", "Error Loading step4 Init", "error", "dismissable");
			console.log(error);
		}).finally(this.isLoading = false);
	}

	/**
	 * @description 옵션 선택 여부 체크
	 */
	get isSelectedOptionData() {
		return this.selectedOptionData?.length;
	}

	/**
	 * @description 부모에서 데이터 받아오는 setter
	 * @param value 부모 데이터
	 */
	@api
	set selectedVin(value) {
		if (value) {
			this._selectedVIN = { ...value };
		}
	}

	/**
	 * @description 부모 데이터 getter
	 */
	get selectedVin() {
		return this._selectedVIN;
	}

	@api
	set stepList(value) {
			if(value) {
					this.varStepList = value;
			}
	}
	get stepList() {
			return this.varStepList;
	}

	handleRowAction(event) {
		const recId = event.detail.row.SpoilerParts__c;
		const actionName = event.detail.action.name;
		let inputMap = {
			stockId: this._selectedVIN.Id,
			spoilerId: recId,
			Name: event.detail.row.SpoilerParts__r.Name,
			SpoilerCode__c: event.detail.row.SpoilerParts__r.SpoilerCode__c,
			P11: event.detail.row.SpoilerParts__r.P11,
			P21: event.detail.row.SpoilerParts__r.P21,
		};
		this.groupDetailList = [inputMap];
		if (actionName === 'Add') {
			this.toggleModal('add');
		} else if (actionName === "View") {
			this.toggleModal('viewVIN');
		}
	}

	/**
	 * @description 모달 on/off
	*/
	toggleModal(type) {
		this.selectedRows = null;
		this.isModalOpen = !this.isModalOpen;
		if (this.isModalOpen) {
			Object.keys(this.modalMap).forEach(el => this.modalMap[el] = (el === type));
		}
	}

	/**
	 * @description Pdi Main 모달 on
	 */
	handleMainModal() {
		if(this.varStepList[2].IsPass__c == false) {
			showToast('Warning', 'Step 3를 먼저 완료해주세요.', 'warning');
			return;
		}
		const customEvent = new CustomEvent('step4open');
		this.dispatchEvent(customEvent);
	}
	
	/**
	 * @description 스포일러 추가
	*/
	handleAdd() {
			this.isLoading = true;
			if(this.installList.length != 0) {
				showToast('장착된 스포일러가 있음', '장착되어있는 스포일러를 먼저 제거해주세요.', 'warning');
				this.isLoading = false;
				return;
			}
			installSpoilerToVehicleStock({inputMap: this.groupDetailList[0]}).then(() => {
				this.installList = [this.groupDetailList[0]];
				let paramMap = {
					stockId: this._selectedVIN.Id,
					spoilerCode: this.groupDetailList[0].SpoilerCode__c,
					isAttach: true
				};
				this.paramMapList = [paramMap];
				this.callSAP();
			}).catch(error => {
				showToast('Error', 'Error SF Spoiler Update', 'error', 'dismissable');
				console.log(error);
			}).finally(() => {
				this.isLoading = false;
				this.toggleModal();
			});
	}
	
	handleRemove() {
		this.toggleModal('remove');
	}

	/**
	 * @description 스포일러 제거
	*/
	removeSpoiler() {
		let inputMap = {
			stockId: this._selectedVIN.Id,
			spoilerId: null,
		};
		let paramMap = {
			stockId: this._selectedVIN.Id,
			spoilerCode: this.installList[0].SpoilerCode__c,
			isAttach: false
		};
		this.paramMapList = [paramMap];
		this.isLoading = true;
		installSpoilerToVehicleStock({inputMap: inputMap}).then(() => {
			showToast('스포일러 제거 완료', '제거 처리가 완료되었습니다.', 'success');
			this.installList = [];
			this.callSAP();
		}).catch(error => {
			showToast('Error', 'Error Update', 'error', 'dismissable');
			console.log(error);
		}).finally(() => {
			this.isLoading = false;
			this.toggleModal();
		});
	}
	
	async callSAP(){
		await spoilerDropoffSAP({inputMapList: this.paramMapList}).then(() => {
			// this.updateStep();
		}).catch(error => {
			showToast('Error', 'Error SAP Update', 'error', 'dismissable');
			console.log(error);
		});
	}

	// pdi 스포일러 재고이동 타이밍 수정으로 안씀(250326)
	// /**
	//  * @description 스포일러 추가(SAP 인터페이스)
	//  */
	// // 	결과 PASS여부가 TRUE일때(화면단에서 완료 누를때) 2개 IF 진행
	// // 	1. 스포일러 재고이동요청
	// // 	2. 차량 재고이동요청


	// // # 초기상태 시작 pdi step 4 not completed (0,1은 스포일러 장착 여부)
	// // 0 -> 1 / API 호출 
	// // 0 -> 0 / API 호출 x
	// // 1 -> 1 / API 호출
	// // 1 -> 0 / API 호출 x

	// // # 수정 변경시 pdi step 4 completed
	// // 0 -> 1 / API 호출
	// // 0 -> 0 / API 호출 x
	// // 1 -> 0 / API 호출 
	// // 1 -> 1 / API 호출 x
	// @api
	// handleSAPInstall(){
	// 	let msg = '';
	// 	if (
	// 		(this.varStepList[3].IsPass__c == false && this.installList.length == 0) ||
	// 		(this.varStepList[3].IsPass__c == true && this.installList.length == this.initialInstallStatus)
	// 	) {
	// 		msg = '스포일러를 변경하지 않고 단계를 완료하였습니다.';
	// 		updateStep4({stockId: this._selectedVIN.Id}).then(() => {
	// 			this.updateStep();
	// 		}).catch(error => {
	// 			showToast('Error', 'Error Update', 'error', 'dismissable');
	// 			console.log(error);
	// 		});
	// 	} else {
	// 		msg = '스포일러 변경이 SAP에 반영되었습니다.';
			// spoilerDropoffSAP({inputMapList: this.paramMapList}).then(() => {
			// 	this.updateStep();
			// }).catch(error => {
			// 	showToast('Error', 'Error Update', 'error', 'dismissable');
			// 	console.log(error);
			// });
	// 	}
	// 	showToast('Success', msg, 'success');
	// }

	// updateStep() {
	// 	fetchStatus({workNo: [this._selectedVIN.Name]}).then(response => {
	// 		console.log('pdi step4 :: ', response);
	// 		const customEvent = new CustomEvent('step4complete', {
	// 				detail: { updatedStep: response }
	// 		});
	// 		this.dispatchEvent(customEvent);
	// 	}).catch(error => {
	// 		showToast('Error', 'Error Fetch Status', 'error', 'dismissable');
	// 		console.log(error);
	// 	});
	// }
}