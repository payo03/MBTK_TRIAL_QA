/*************************************************************
 * @author : Choi Taewook
 * @date : 2024-11-14
 * @description : 캠페인 퀵액션 버튼
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-14      Choi Taewook    Created
 **************************************************************/

import { LightningElement, track, api, wire } from 'lwc';

import getInitData from '@salesforce/apex/CampaignProductController.getInitData';
import getFilteredProductList from "@salesforce/apex/CampaignProductController.getFilteredProductList";
import saveProductsToCampaign from "@salesforce/apex/CampaignProductController.saveProductsToCampaign";
import { CloseActionScreenEvent } from "lightning/actions";
import modal from "@salesforce/resourceUrl/custommodalcss";
import { loadStyle } from "lightning/platformResourceLoader";
// Util
import {showToast, labelList } from "c/commonUtil";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";

const filterDefault = { Segment2__c: "", WheelBase__c: "", "VehicleCategory__r.AxleConfiguration__c": "", "VehicleCategory__r.HorsePower__c": "", SpecShort__c:"" };

const columns = [
    { label: '세그먼트2', fieldName: 'segment', initialWidth: 80, hideDefaultActions: 'true'},
    { label: '모델명', fieldName: 'specShort', initialWidth: 300, hideDefaultActions: 'true'},
    { label: '차대 각자', fieldName: 'modelYear', hideDefaultActions: 'true'},
    { label: 'Cab', fieldName: 'cabMark', hideDefaultActions: 'true'},
    { label: '휠베이스', fieldName: 'wheelBase', hideDefaultActions: 'true'},
    { label: '배출레벨', fieldName: 'emissionLevel', hideDefaultActions: 'true'},
];

export default class CampaignProduct extends NavigationMixin(LightningElement) {

    @wire(CurrentPageReference) pageRef;

    @api recordId;
    campaignId;

    masterData = [];
    isLoading = false;
    isNoData = false;
    selectedRows = [];
	filterMap = { ...filterDefault }; // 적용할 필터 맵
    filteredData = []; // 필터링된 데이터
    filterOptions = { segment: []}; // 필터 옵션 맵
    columns = columns;

    @track myLabel = labelList;
    
    connectedCallback() {

        this.campaignId = this.pageRef.state.recordId;
        
        loadStyle(this, modal);
        this.isLoading = true;
        
        getInitData().then(res => {
			this.masterData = res.pList;
			this.filterOptions.segment = [{ label: "선택안함", value: "" }].concat(res.segment);
            this.filterOptions.axle = [{ label: "선택안함", value: "" }].concat(res.axle);
            this.isLoading = false;
		}).catch(err => {
            this.isLoading = false;
		});
	}

    handleChange(e) {
        const id = e.target.dataset.id;
		const value = e.target.value;

        switch (id) {
			case "segment" :
				this.filterMap.Segment2__c = value;
                this.handleSearch(e);
				break;
            case "axle" :
                this.filterMap['VehicleCategory__r.AxleConfiguration__c'] = value;
                this.handleSearch(e);
				break;
			case "specShort" :
				this.filterMap.SpecShort__c = value;
				break;
			case "wheelbase" :
				this.filterMap.WheelBase__c = value;
				break;
            case "power" :
                this.filterMap['VehicleCategory__r.HorsePower__c'] = value;
                break;
		}
    }

    handleRowAction(e) {
        this.selectedRows = e.detail.selectedRows; // 선택된 행들
    }

    saveProductsToCampaign(productIds) {
        this.isLoading = true;
        saveProductsToCampaign({ productIds: productIds, campaignId: this.campaignId })
            .then(() => {
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
            });
    }

    clearSelectedRows() {
        this.selectedRows = []; // 선택된 행 초기화
        const datatable = this.template.querySelector('[data-id="master"]');
        if (datatable) {
            datatable.selectedRows = []; // 선택 상태 초기화
        }
    }

    handleSave(e) {
        const productIds = this.selectedRows.map(row => row.id);
        if(productIds && productIds.length > 0) {
            
            this.saveProductsToCampaign(productIds);
            showToast("차종 연결 성공", '차종 연결에 성공했습니다', "success");
            this.dispatchEvent(new CloseActionScreenEvent());   // Panel 닫기
            setTimeout(() => {
                window.location.reload();   // 새로고침
            }, 1500);

        } else {
            showToast("차종 연결 저장 실패", '차종을 선택하고 저장을 눌러주세요', "error");
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSearch(e) {
        const id = e.currentTarget.dataset.id;
		if (id === "refresh") {
			this.filterMap = { ...filterDefault };

            this.template.querySelectorAll("lightning-input, lightning-combobox").forEach(element => {
                element.value = ""; // 각 UI 요소 값 초기화
            });
		}
		// 선택된 필터로 검색
		// else if (id === "search") {
			this.isLoading = true;
            this.clearSelectedRows();
			getFilteredProductList({ filterMap: this.filterMap }).then(res => {
				this.masterData = res;
				this.filteredData = res;
                if (this.masterData.length === 0 || this.filteredData.length === 0) {
                    this.isNoData = true;
                } else {
                    this.isNoData = false;
                }
				this.isLoading = false;
			}).catch(err => {
				this.isLoading = false;
			});
		// }
    }
    
}