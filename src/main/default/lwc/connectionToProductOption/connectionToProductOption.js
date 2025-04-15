import { LightningElement, track, api } from 'lwc';
import getInitData from '@salesforce/apex/ConnectionToProductOptionController.getInitData';
import getFilteredProductList from "@salesforce/apex/ConnectionToProductOptionController.getFilteredProductList";
import saveProductsToOption from "@salesforce/apex/ConnectionToProductOptionController.saveProductsToOption";
import { CloseActionScreenEvent } from "lightning/actions";
import modal from "@salesforce/resourceUrl/custommodalcss";
import { loadStyle } from "lightning/platformResourceLoader";
// Util
import {showToast } from "c/commonUtil";

const filterDefault = { Segment2__c: "" };

const columns = [
    { label: '세그먼트2', fieldName: 'segment', initialWidth: 80, hideDefaultActions: 'true'},
    { label: '모델명', fieldName: 'name', initialWidth: 400, hideDefaultActions: 'true'},
    { label: '구분', fieldName: 'specShort', hideDefaultActions: 'true'},
];

export default class ConnectionToProductOption extends LightningElement {

    @api recordId;

    masterData = [];
    isLoading = false;
    isNoData = false;
    selectedRows = [];
    filterMap = { ...filterDefault }; // 적용할 필터 맵
    filteredData = []; // 필터링된 데이터
    filterOptions = { segment: []}; // 필터 옵션 맵
    columns = columns;

    connectedCallback() {
        
        loadStyle(this, modal);
        this.isLoading = true;
        
        getInitData().then(res => {
			this.masterData = res.pList;
			this.filterOptions.segment = [{ label: "선택안함", value: "" }].concat(res.segment);
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
                    break;
                case "name" :
                    this.filterMap.Name = value;
                    break;
                // case "specShort" :
                //     this.filterMap.SpecShort__c = value;
                //     break;
            }
        }
    
        handleRowAction(e) {
            this.selectedRows = e.detail.selectedRows; // 선택된 행들
        }
    
        saveProductsToOption(productIds) {
            this.isLoading = true;
            saveProductsToOption({ productIds: productIds, optionId: this.recordId })
                .then(() => {
                    // console.log("Products successfully linked to Option");
                    this.isLoading = false;
                })
                .catch(error => {
                    console.error("Error saving products to Option:", error);
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
                
                this.saveProductsToOption(productIds);
                showToast("Success", 'Successfully', "success");
                this.dispatchEvent(new CloseActionScreenEvent());   // Panel 닫기
                setTimeout(() => {
                    window.location.reload();   // 새로고침
                }, 1500);
    
            } else {
                showToast("Save Error", 'Product를 선택하고 저장을 눌러주세요', "error");
            }
    
        }
    
        handleCancel() {
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    
        handleSearch(e) {
            // console.log('search!!');
            const id = e.currentTarget.dataset.id;
            if (id === "refresh") {
                this.filterMap = { ...filterDefault };
            }
            // 선택된 필터로 검색
            else if (id === "search") {
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
            }
        }



}