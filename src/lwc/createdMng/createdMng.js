/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-10
 * @description :
 * @target :
 ==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-10        San.Kang           Created
 **************************************************************/
import {LightningElement, track, wire} from 'lwc';

import { mngNoColumns,typeNoColumns } from './createdMngColumns';
import { showToast, sortData, resourceList } from "c/commonUtil";

import getInitData from "@salesforce/apex/CreatedMngController.getInitData";
import searchSpecTypeNo from "@salesforce/apex/CreatedMngController.searchSpecTypeNo";
import saveSpecTypeNo from "@salesforce/apex/CreatedMngController.saveSpecTypeNo";
import {CloseActionScreenEvent} from "lightning/actions";
import {CurrentPageReference} from "lightning/navigation";
import formFactor from "@salesforce/client/formFactor";


const filterDefault = { ModelYear__c: "", EngineType__c: "", Remark__c: "", Remark2__c: "", Remark3__c: "" };
// const initDataMap = {
//     this.resultList: [],
//     selectedRows:[],
//     sortBy: [],
//     sortDirection: []
// }
//

export default class createdMng extends LightningElement {

    // @track specTypeNoMap  = {
    //     mngNoMap: { ...initDataMap,, selectedMngNo: '' },
    //     ,
    //     type: ''
    // }
    //
    @track filterMap = { ...filterDefault };
    @track categoryOptions = [''];
    @track resultList = [];
    selectedRows = [];
    selectedRowIds = [];
    
    selectedNo;
    columns;
    recordId;
    sortBy;
    sortDirection;
    isLoading = false;
    mngNoFlag = false;
    dataFlag = false;
    type = '';

    get cardTitle() {
        return (this.selectedRowIds?.length > 0) ? `${this.type} : ${this.selectedNo}` : this.type;
    }

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state) {
            if (formFactor === "Large") {
                this.recordId = pageRef.state.recordId;
            } else {
                this.recordId = pageRef.state.c__recordId;
            }
        }
    }

    connectedCallback() {
        this.isLoading = true;
        this.resizePop();
        this.doInit();
    }

    resizePop() {
        requestAnimationFrame(() => {
            const modalContainerEl = document.querySelector(".slds-p-around_medium");

            if (modalContainerEl) {
                let modalWidth = 1500;

                modalContainerEl.style.width = `${modalWidth}px`;
                modalContainerEl.style.position = "fixed";
                modalContainerEl.style.left = "50%";
                modalContainerEl.style.transform = "translateX(-50%)";
                modalContainerEl.style.maxWidth = "90vw";
            }
        });

    }

    doInit(){
        getInitData({vehicleStockId : this.recordId}).then(res => {
            if (res && res.specTypeNoList && res.specTypeNoList.length > 0) {
                this.type = res.specTypeNoList[0].type || '';
                this.mngNoFlag = this.type === '제원관리번호';
                this.resultList = res.specTypeNoList;
                this.dataFlag = true;
            } else {
                this.type = '';
                this.mngNoFlag = false;
                this.resultList = [];
                this.dataFlag = false;
            }

            this.categoryOptions = res && res.modelYear ? res.modelYear : [];
            this.columns = this.mngNoFlag ? mngNoColumns : typeNoColumns;
        }).catch(err => {
            console.log("err :: ", err);
            showToast("", err.body.message, "warning");
            this.isLoading = false;
        }).finally(() => {
            this.isLoading = false;
            this.adjustTableHeight();
        });
    }

    handleChange(e) {
        const id = e.target.dataset.id;
        const value = e.target.value;
        const setFilterValue = (field, value) => {
            const filterMap = this.filterMap;
            filterMap[field] = value;
        };
        switch (id) {
            case "modelYear" :
                setFilterValue("ModelYear__c", value);
                break;
            case "engineType" :
                setFilterValue("EngineType__c", value);
                break;
            case "remark" :
                setFilterValue("Remark__c", value);
                break;
            case "remark2" :
                setFilterValue("Remark2__c", value);
                break;
            case "remark3" :
                setFilterValue("Remark3__c", value);
                break;
        }
    }

    adjustTableHeight() {
        const tableWrapEl = this.template.querySelector(`.master-table-wrap[data-tab='${this.activeTab}']`);
        let lightningTableEl = this.template.querySelector(`lightning-datatable[data-tab='${this.activeTab}']`);
        console.log('window.outerHeight :: ', window.outerHeight);
        const vh25 = window.outerHeight * 0.25;

        if (lightningTableEl && tableWrapEl) {
            let tableHeight = lightningTableEl.offsetHeight;
            // 테이블 전체 높이 가져오기 위한 높이 초기화
            tableWrapEl.style.height = "auto";
            requestAnimationFrame(() => {
                // 테이블 변경 후 다시 호출
                lightningTableEl = this.template.querySelector(`lightning-datatable[data-tab='${this.activeTab}']`);
                tableHeight = lightningTableEl.offsetHeight;
                tableWrapEl.style.height = tableHeight > vh25 ? `${vh25}px` : `auto`;
                this.isLoading = false;
            });
        }
    }

    handleRefresh() {
        this.filterMap = { ...filterDefault };
        this.handleSearch();
    }

    handleSearch(){
        this.isLoading = true;
        this.selectedRowIds = [];
        searchSpecTypeNo({ type: this.type, vehicleStockId : this.recordId, filterMap: this.filterMap}).then(res => {
            console.log(res?.length);
            this.resultList = res;
            this.selectedRows = [];
        }).catch(err => {
            console.log("err :: ", err);
            showToast("", err.body.message, "warning");
        }).finally(() => {
            this.isLoading = false;
            // this.adjustTableHeight();
        });
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if(selectedRows?.length > 0){
            this.selectedRows = selectedRows;
            this.selectedRowIds = selectedRows?.map(el => el.id) || [];
            this.selectedNo = this.mngNoFlag ? selectedRows?.[0].mngNo : selectedRows?.[0].typeNo;
        }
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;

        let sortedData;
        sortedData = [...this.resultList];
        sortedData.sort((a, b) => {
            let aValue = a[sortedBy];
            let bValue = b[sortedBy];

            if (typeof aValue === "number" && typeof bValue === "number") {
                return sortDirection === "asc" ? aValue - bValue : bValue - aValue;
            } else if (aValue && bValue && aValue.localeCompare) {
                return sortDirection === "asc"
                    ? aValue.localeCompare(bValue)
                    : bValue.localeCompare(aValue);
            }
            return 0;
        });
        this.resultList = sortedData;
        this.sortBy = sortedBy;
        this.sortDirection = sortDirection;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSave(){
        this.isLoading = true;
        const specTypeNoId = this.selectedRows?.[0]?.id === null ? null : this.selectedRows?.[0]?.id;
        if (this.selectedRows?.length === 0) {
            showToast("", this.type + "를 하나 이상 선택해주세요.", "warning");
            this.isLoading = false;
            return;
        }

        saveSpecTypeNo({ specTypeNoId: specTypeNoId, vehicleStockId : this.recordId}).then(res => {
            showToast("",this.type + '가 저장되었습니다.', "Success");
            this.isLoading = false;
            this.handleCancel();
        }).catch(err => {
            console.log("err :: ", err);
            showToast("", err.body.message, "warning");
        }).finally(() => {
            this.isLoading = false;
            this.handleCancel();
        });

    }
}