import { LightningElement, track, api, wire } from 'lwc';
import getInitData from '@salesforce/apex/ConnectionToProductOptionController.getInitData';
import getFilteredProductList from "@salesforce/apex/ConnectionToProductOptionController.getFilteredProductList";
import saveProductsToOption from "@salesforce/apex/ConnectionToProductOptionController.saveProductsToOption";
import { CloseActionScreenEvent } from "lightning/actions";
import modal from "@salesforce/resourceUrl/custommodalcss";
import { loadStyle } from "lightning/platformResourceLoader";
// Util
import {showToast, labelList } from "c/commonUtil";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";

const filterDefault = { Segment2__c: "" };

const columns = [
    { label: '세그먼트2', fieldName: 'segment', initialWidth: 80, hideDefaultActions: 'true'},
    { label: '모델명', fieldName: 'name', initialWidth: 400, hideDefaultActions: 'true'},
    { label: '구분', fieldName: 'specShort', hideDefaultActions: 'true'},
];

export default class ConnectionToProductOption extends NavigationMixin(LightningElement) {

    @api recordId;
    @wire(CurrentPageReference) pageRef;
    @track myLabel = labelList;
    optionId;
    masterData = [];
    isLoading = false;
    isNoData = false;
    selectedRows = [];
    filterMap = { ...filterDefault }; // 적용할 필터 맵
    filteredData = []; // 필터링된 데이터
    filterOptions = { segment: []}; // 필터 옵션 맵
    columns = columns;
    errorMessage;

    connectedCallback() {
        
        loadStyle(this, modal);
        this.isLoading = true;
        this.optionId = this.pageRef.state.recordId;
        
        getInitData({ optionId: this.optionId }).then(res => {
            if (res.hasOptionCode) {
                this.masterData = [];
                this.errorMessage = '옵션코드가 존재하는 경우, 차종 옵션을 연결할 수 없습니다.';
            } else {
                this.masterData = res.pList;
                this.filterOptions.segment = [{ label: "선택안함", value: "" }].concat(res.segment);
                this.errorMessage = null;
            }
        })
        .catch(err => {
            console.log('err :::: ', err);
            this.errorMessage = '데이터를 불러오는 중 오류가 발생했습니다.';
        })
        .finally(() => {
            this.isLoading = false;
        });
        // getInitData().then(res => {
		// 	this.masterData = res.pList;
		// 	this.filterOptions.segment = [{ label: "선택안함", value: "" }].concat(res.segment);
        //     this.isLoading = false;
		// }).catch(err => {
        //     this.isLoading = false;
		// });
	}

    handleChange(e) {
        const id = e.target.dataset.id;
        const value = e.target.value;

        switch (id) {
            case "segment" :
                this.filterMap.Segment2__c = value;
                this.handleSearch(e);
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
        saveProductsToOption({ productIds: productIds, optionId: this.optionId })
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
            showToast("차종 옵션 저장 성공", '차종 옵션 연결이 성공했습니다.', "success");
            this.dispatchEvent(new CloseActionScreenEvent());   // Panel 닫기
            setTimeout(() => {
                window.location.reload();   // 새로고침
            }, 1500);

        } else {
            showToast("차종 선택 유무 오류", '차종을 선택하고 저장을 눌러주세요', "error");
        }

    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSearch(e) {
        const id = e.currentTarget.dataset.id;
        if (id === "refresh") {
            this.filterMap = { ...filterDefault };
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