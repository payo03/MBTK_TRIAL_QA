import { LightningElement, track, api, wire } from 'lwc';
import getInitData from '@salesforce/apex/PaymentTrackerController.getInitData';
import getFilteredPaymentTrackerList from '@salesforce/apex/PaymentTrackerController.getFilteredPaymentTrackerList';
import getPaymentTypeList from '@salesforce/apex/PaymentTrackerController.getPaymentType';
import startBatchJob from '@salesforce/apex/PaymentTrackerController.startBatchJob';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";

import { showToast, labelList } from "c/commonUtil";
import { getRecord } from "lightning/uiRecordApi";
import userId from "@salesforce/user/Id";

const filterDefault = { opportunityName : "", status : "" };

const columns = [
    { label: '입금현황관리', fieldName: 'ptUrl', initialWidth: 120, hideDefaultActions: 'true',
        type : 'url', typeAttributes: { 
            label: { fieldName: 'ptName' },
            target: '_blank',
            tooltip: '입금현황관리 상세 페이지로 이동' 
        }, 
    },
    { label: '영업인', fieldName: 'sa', initialWidth: 100, hideDefaultActions: 'true'},
    { label: '영업기회', fieldName: 'oppUrl', initialWidth: 180, hideDefaultActions: 'true', wrapText: true,
        type : 'url', typeAttributes: { 
            label: { fieldName: 'opportunityName' },
            target: '_blank',
            tooltip: '영업기회 상세 페이지로 이동' 
        }, 
    },
    {
        label: "계약",
        fieldName: "contractUrl",
        type: "url",
        hideDefaultActions: true,
        initialWidth: 150,
        typeAttributes: {
            label: { fieldName: "contractNumber" }
        }
    },
    { label: '차종', fieldName: 'productUrl', initialWidth: 350, hideDefaultActions: 'true', wrapText: true,
        type: 'url', typeAttributes: {
            label: { fieldName: 'product' },
            target: '_blank',
            tooltip: '차종 상세 페이지로 이동'
        }
    },
    { label: '매출번호', fieldName: 'saleNumber', initialWidth: 150, hideDefaultActions: 'true'},
    { label: '결제 상태', fieldName: 'status', initialWidth: 120, hideDefaultActions: 'true'},
    { label: '진행상황', fieldName: 'progress', initialWidth: 100, hideDefaultActions: 'true',
        type: 'button', typeAttributes: {
            label: { fieldName: 'progressLabel' },
            name: 'paymentProgress',
            variant: 'base'
        }
    },
    { label: '부가세후취 여부', fieldName: 'isVat', initialWidth: 150, hideDefaultActions: 'true', type: 'boolean', cellAttributes: { alignment: 'center' },},
    { label: '인도금 유예 여부', fieldName: 'isPayment', initialWidth: 150, hideDefaultActions: 'true', type: 'boolean', cellAttributes: { alignment: 'center' },},
    { label: '비고', fieldName: 'remark', initialWidth: 200, hideDefaultActions: 'true', wrapText: true},
    { label: '세금계산서 발행일', fieldName: 'taxDate', initialWidth: 130, hideDefaultActions: 'true'},
];

const paymentColumns = [
    { label: '입금현황종류 이름', fieldName: 'name', hideDefaultActions: 'true'},
    { label: '내역', fieldName: 'status', hideDefaultActions: 'true'},
    { label: '요청금액', fieldName: 'requestAmount', type: 'number', hideDefaultActions: 'true'},
    { label: '입금금액', fieldName: 'depositAmount', type: 'number', hideDefaultActions: 'true'},
    { label: '진행상황', fieldName: 'progressLabel', hideDefaultActions: 'true'},
];

export default class PaymentTracker extends NavigationMixin(LightningElement) {

    recordId;
    columns = columns;
    paymentColumns = paymentColumns;
    filterMap = { ...filterDefault }; // 적용할 필터 맵
    masterData = [];   
    filteredData = []; // 필터링된 데이터
    @track myLabel = labelList;
    @track paymentData = []; // paymenent를 가져오기위한 빈 배열
    @track currentlySelectedRows = [];
    // @track selectedRowIds = [];
    filterOptions = { status: []}; // 필터 옵션 맵
    isNoData = false;
    isModalOpen = false;
    profileName;

    get isSA() {
		return this.profileName === "MTBK Agent";
	}

    @wire(getRecord, { recordId: userId, fields: ["User.Profile.Name"] })
	currentUserInfo({ error, data }) {
		this.profileName = data?.fields?.Profile?.displayValue;
		if (this.profileName === "MTBK Agent") {
			this.columns = columns;
		}
	}

    connectedCallback() {
        
        getInitData().then(res => {

            let styleEl = document.querySelector(".payment-custom-style");
			// 첫 로드 시
			if (!styleEl) {
				if (this.template.querySelector("lightning-datatable")) {
					styleEl = document.createElement("style");
					styleEl.className = "payment-custom-style";
					// 테이블 버튼 넓이 조정
					styleEl.innerText = ".box-wrap lightning-datatable table tbody .slds-button { line-height: 100%; }"
						+ " .box-wrap .button-wrap lightning-datepicker .slds-form-element__help { display: none; }";
					document.body.appendChild(styleEl);
				}
			}

            this.masterData = res.paymentTrackerList;
            this.filterOptions.status = [{ label: "선택안함", value: "" }].concat(res.status);
            
            this.masterData = this.masterData.map(opp => {
                
                return {
                    ...opp, // 기존의 opp 데이터 필드를 모두 유지
                    ptUrl: `/lightning/r/Opportunity/${opp.id}/view`,
                    productUrl: opp.productUrl ? `/lightning/r/Opportunity/${opp.productUrl}/view` : "",
                    oppUrl: opp.oppUrl ? `/lightning/r/Opportunity/${opp.oppUrl}/view` : "",
                    currentPath: opp.status, // 현재 Path
                };
            });
           
        }).catch(err => {
            console.log('err ::: ', err );
        });
    }
   
    handleChange(e) {

        const id = e.target.dataset.id;
		const value = e.target.value;

        switch (id) {
			case "sa" :
                this.filterMap.opportunityName = value;
				break;
            case "status" :
                this.filterMap.status = value;
                this.handleSearch(e);
                break;
		}
    }

    handleSearch(e) {
        const id = e.currentTarget.dataset.id;
		if (id === "refresh") {
            this.currentlySelectedRows = [];
			this.filterMap = { ...filterDefault };
		} 
        // else if (id === "search") {
            
            getFilteredPaymentTrackerList({ filterMap: this.filterMap }).then(res => {
                this.masterData = res;
                this.masterData = this.masterData.map(opp => {
                    return {
                        ...opp, // 기존의 opp 데이터 필드를 모두 유지
                        ptUrl: `/lightning/r/Opportunity/${opp.id}/view`,
                        productUrl: opp.productUrl ? `/lightning/r/Opportunity/${opp.productUrl}/view` : "",
                        oppUrl: opp.oppUrl ? `/lightning/r/Opportunity/${opp.oppUrl}/view` : "",
                        currentPath: opp.status, // 현재 Path
                    };
                });

                if (this.masterData.length === 0) {
                    this.isNoData = true;
                } else {
                    this.isNoData = false;
                }
            }).catch(err => {
                console.error('error  ::: ', err);
            });
        // }
    }

    handleRowAction(e) {
        const currentRow = e.detail.row;
        getPaymentTypeList({recordId : currentRow.id}).then(res => {
            this.paymentData = res;
            this.paymentData = this.paymentData.filter(el => {
                return el.status !== '대출금 할인금액' && el.status !== 'MFS 캠페인 할인금액' && (el.status !== '초과금' || el.depositAmount > 0)
            });

            this.paymentData.forEach(el => {
                if (el.status === '초과금' && el.depositAmount > 0) {
                    el.progressLabel = '';
                }
            });

            this.isModalOpen = true;

            if (this.paymentData.length === 0) {
                this.isNoData = true;
            } else {
                this.isNoData = false;
            }

        }).catch(err => {
            console.log('err ::: ', err);
        });
    }

    handleRowSelection(e) {
        const selectedRows = e.detail.selectedRows;
        const validRows = selectedRows.filter(row => row.saleNumber);
    
        if (validRows.length !== selectedRows.length) {
            showToast('매출번호 선택 오류', '매출번호가 없는 행은 선택할 수 없습니다.', 'error');
        }

        this.currentlySelectedRows = validRows.map(row => row.oppId);
        
    }

    handleButtonClick(e) {
        if(this.currentlySelectedRows.length > 0) {
            startBatchJob({ oppIdList: this.currentlySelectedRows }).then(res => {
                showToast("반제 요청 성공", '반제 요청 진행됐습니다', "success");
                setTimeout(() => {
                    window.location.reload();   // 새로고침
                }, 1500);
            }).catch(err => {
                console.log('err ::: ', err);
            });
        } else {
            showToast('매출번호 유무 확인', '매출번호가 있는 레코드를 선택해주세요', 'error');
            console.log('err ::: ', err);
        }
    }

    closeModal() {
        this.isModalOpen = false;
    }

}