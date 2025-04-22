/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-22      payo03@solomontech.net           Created
*/
import { api, track, LightningElement } from 'lwc';

import step3Init from "@salesforce/apex/PdiController.step3Init";
import getFilteredHandoverList from "@salesforce/apex/HandoverSchedulerController.getFilteredHandoverList";
import getVehicleStockList from "@salesforce/apex/HandoverSchedulerController.getVehicleStockList";
import updateHandoverStockList from "@salesforce/apex/HandoverSchedulerController.updateHandoverStockList";

// Util
import { showToast } from "c/commonUtil";
import {
	columns,
	stockColumns
} from "./pdiStep3ViewColumns";

export default class PdiStep3View extends LightningElement {
  @track _selectedVIN;
	@track varStepList;

  columns = columns;
	opportunityList = [];

	isLoading;

	// 모달
	isModalOpen;
	stockColumns = stockColumns;
	stockList = [];
	selectedStockRowList = [];
	selectedRowMap = [];
	selectedRowIdList = [];
	currentHandover = {};

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

	connectedCallback() {
		this.init();
	}

	init() {
		this.isLoading = true;
		step3Init({ vinId: this._selectedVIN.Id}).then(res => {
			const filterMap = {"Opportunity__r.VehicleStock__r.Product__c" : res};
			// filterMap.Opportunity__r.IsClosed = false;
			getFilteredHandoverList({ filterMap: filterMap }).then(res => {
				this.opportunityList = res;
				for (let el of this.opportunityList) {
					if(el.stockId == this._selectedVIN.Id) {
						this.selectedRowIdList = [el.id];
						console.log(el.id);
					}
				}
			}).catch(err => {
				console.log("err getFilteredHandoverList :: ", err);
			});
		}).catch(err => {
			console.log("err step3Init :: ", err);
		}).finally(() => this.isLoading = false);
	}

	/**
	 * @description 핸드오버 선택 함수
	 */
	handleSelection(e) {
		this.selectedRowMap = e.detail.selectedRows;
		this.selectedRowIdList = this.selectedRowMap.map(row => row.id);
		console.log('step3 확인 :: ', this.selectedRowMap);
		console.log('step3 확인 :: ', JSON.stringify(this.selectedRowIdList));
		const customEvent = new CustomEvent('step3open', {
			detail: { matchRow: this.selectedRowMap }
		});
		this.dispatchEvent(customEvent);
	}

	/**
	 * @description VIN 클릭 시 해당 차종의 차량 보여주기
	 */
	handleRowAction(e) {
		this.isLoading = true;
		const currentRow = e.detail.row;
		const productId = currentRow.vehicleStock.Product__c;
		getVehicleStockList({ filterMap: { Product__c: productId } }).then(res => {
			this.stockList = res?.map(el => ({
				...el,
				product: el.Product__r.Name
			}));
			this.isModalOpen = !this.isModalOpen;
			this.selectedStockRowList = [currentRow.stockId];
			// this.stockFilterMap.Product__c = productId;
			this.currentHandover = currentRow;
		}).catch(err => {
			console.log("err :: ", err);
		}).finally(() => this.isLoading = false);
	}

	/**
	 * @description 모달에서 차량 선택 함수
	 */
	handleModalRowSelection(e) {
		this.selectedStockRowList = e.detail.selectedRows?.map(el => el.Id);
	}
	
	/**
	 * @description 차량 변경 함수
	 */
	handleSave() {
		this.isLoading = true;

		const setDataList = (stockId, opportunity, previousVIN, currentVIN) => {
			return {
				stockId: stockId,
				opportunityId: opportunity.Id,
				oppName: opportunity.Name,
				ownerId: opportunity.OwnerId,
				contractId: opportunity.ContractId,
				previousVIN: previousVIN,
				currentVIN: currentVIN
			};
		};
		let dataList;
		const stockId = this.selectedStockRowList.length > 0 ? this.selectedStockRowList[0] : null;
		if (!stockId) {
			showToast("차량을 선택해주세요.", "", "warning");
			this.isLoading = false;
			return;
		}
		const currentStock = this.stockList.find(el => el.Id === stockId);
		if (this.currentHandover.VIN === currentStock.Name) {
			// showToast("차량을 변경해주세요.", "", "warning");
			this.isLoading = false;
			this.toggleModal();
			return;
		}
		dataList = [setDataList(currentStock.Id, this.currentHandover.opp, this.currentHandover.VIN, currentStock.Name)];
		updateHandoverStockList({ dataList: dataList }).then(() => {
			showToast("차량 변경 완료", "", "success");
			this.toggleModal();
			this.init();
		}).catch(err => {
			console.log("err :: ", err);
		}).finally(() => this.isLoading = false);
	}

	/**
	 * @description 모달 on/off
	 */
	toggleModal() {
		this.isModalOpen = !this.isModalOpen;
	}
}