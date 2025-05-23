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
import getInitData from "@salesforce/apex/PdiController.getInitData";
import getFilteredSpoilerPartsList from "@salesforce/apex/PdiController.getFilteredSpoilerPartsList";
import spoilerDropoffSAP from "@salesforce/apex/PdiController.spoilerDropoffSAP";

// Util
import { showToast, labelList } from "c/commonUtil";

import {
	columns,
	optionColumns,
	detailColumns,
	installColumns,
	spoilerColums
} from "./pdiStep4ViewColumns";

const filterDefault = { opportunityName : "", status : "" };

export default class PdiStep4View extends LightningElement {

	groupColumns = columns;
	groupDetailColumns = detailColumns;
	optionColumns = optionColumns;
	installColumns = installColumns;
	spoilerColums = spoilerColums;
	selectedRows;

	@track _selectedVIN;
	@track selectedOptionData = [];
	@track groupList;
	@track spoilerData;
	@track groupDetailList = [];
	@track installList = [];
	initialInstallStatus = 0; // 스포일러 장착 여부의 초기 상태 기록
	@track varStepList;
	@track myLabel = labelList;
	isNoData = false;

	paramMapList= [];

	// 모달
	isModalOpen;
	modalMap = { add: false, remove: false, viewVIN: false };
	// 스포일러코드 필터
	filterMap = { ...filterDefault };
	isLoading = false;

	connectedCallback() {
		this.init();
		this.spoilerInint();
	}

	init() {
		this.isLoading = true;
		step4Init({ selectVIN: this._selectedVIN.Id}).then(response => {
			this.selectedOptionData = response?.selectedOption;
			this.installList = response?.installList;
			if(this.installList.length) this.installList[0].installDate = this.varStepList[3].StepEnd__c;
			this.groupList = response?.spoilerPartsJuntion;
		}).catch(error => {
			showToast("불러오기 실패", "옵션장착을 위한 정보를 불러오는 중 에러가 발생했습니다.", "error", "dismissable");
			console.log(error);
		}).finally(this.isLoading = false);
	}

	spoilerInint() {
		this.isLoading = true;
		getInitData().then(res => {
			this.spoilerData = res?.spoilerPartsJuntion;
			// console.log('this.spoilerData ::: ', JSON.stringify(this.spoilerData));
		}).catch(err => {
			console.log(err);
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
	 * @description 스포일러 추가
	*/
	// handleAdd() {
	// 		this.isLoading = true;
	// 		if(this.installList.length != 0) {
	// 			showToast('장착된 스포일러가 있음', '장착되어있는 스포일러를 먼저 제거해주세요.', 'warning');
	// 			this.isLoading = false;
	// 			return;
	// 		}
	// 		installSpoilerToVehicleStock({inputMap: this.groupDetailList[0]}).then(() => {
	// 			this.installList = [this.groupDetailList[0]];
	// 			let paramMap = {
	// 				stockId: this._selectedVIN.Id,
	// 				spoilerCode: this.groupDetailList[0].SpoilerCode__c,
	// 				isAttach: true
	// 			};
	// 			this.paramMapList = [paramMap];
	// 			this.callSAP();
	// 		}).catch(error => {
	// 			showToast('스포일러 장착 에러', '스포일러 장착 중 에러가 발생했습니다.', 'error', 'dismissable');
	// 			console.log(error);
	// 		}).finally(() => {
	// 			this.isLoading = false;
	// 			this.toggleModal();
	// 		});
	// }

	/**
	 * @description 스포일러 테스트 지울겁니다
	*/
	handleAdd(showModal) {
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
			showToast('스포일러 장착 에러', '스포일러 장착 중 에러가 발생했습니다.', 'error', 'dismissable');
			console.log(error);
		}).finally(() => {
			this.isLoading = false;
			if (showModal) {
				this.toggleModal();
			}
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
			showToast('스포일러 제거 에러', '스포일러 제거 중 에러가 발생했습니다.', 'error', 'dismissable');
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
			showToast('SAP 반영 에러', 'SAP에 스포일러 재고 전송 요청 중 에러가 발생했습니다.', 'error', 'dismissable');
			console.log(error);
		});
	}

	/**
	 * @description 스포일러 코드 검색 
	*/

	handleChange(e) {
		const id = e.target.dataset.id;
		const value = e.target.value;

        switch (id) {
			case "ml" :
                this.filterMap.spoilerCode = value;
				break;
		}
	}

	handleSearch(e) {
		const id = e.currentTarget.dataset.id;
		if (id === "refresh") {
			const datatable = this.template.querySelector('[data-id="spoiler"]');

            if (datatable) {
                datatable.selectedRows = [];
            }
			this.filterMap = { ...filterDefault };

		}
		getFilteredSpoilerPartsList({ filterMap: this.filterMap }).then(res => {
			this.spoilerData = res;
			if (this.spoilerData.length === 0) {
				this.isNoData = true;
			} else {
				this.isNoData = false;
			}
			this.isLoading = false;
		}).catch(err => {
			this.isLoading = false;
			console.log('err ::: ', err);
		});

	}

	handleRowSelection(e) {
		console.log('handleRowSelection 이벤트');
		const recId = e.detail.row.id;
		const actionName = e.detail.action.name;

		let inputMap = {
			stockId: this._selectedVIN.Id,
			spoilerId: recId,
			Name: e.detail.row.name,
			SpoilerCode__c: e.detail.row.spoilerCode,
		};

		this.groupDetailList = [inputMap];
		if (actionName === 'Add') {
			this.handleAdd(false);
		}
	}

}