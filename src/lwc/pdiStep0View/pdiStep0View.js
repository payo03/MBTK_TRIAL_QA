/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-22      payo03@solomontech.net           Created
  1.1      2025-04-24      chaebeom.do@solomontech.net      핸드오버 스케줄러에서 워크넘버 클릭해 PDI 메인으로 이동해오면 단계에 맞춰 탭 이동
*/
import { LightningElement, api, track, wire } from 'lwc';
import { labelList } from "c/commonUtil";
import { CurrentPageReference } from 'lightning/navigation';

const columns = [		
    { label: '워크넘버', fieldName: 'VehicleNo__c', hideDefaultActions: 'true' },		
    { label: 'VIN', fieldName: 'Name', hideDefaultActions: 'true'},		
    { label: '모델명', fieldName: 'ProductName', hideDefaultActions: 'true', initialWidth: 400 },		
    { label: '진행 단계', fieldName: 'fm_PdiNextStep__c', hideDefaultActions: 'true'},		
    { label: 'PDI 상태', fieldName: 'VehicleStatus__c', hideDefaultActions: 'true'},		
    { label: '통관일', fieldName: 'RealArrivalDate__c', hideDefaultActions: 'true'},		
];

const bulkColumns = [
    { label: '워크넘버', fieldName: 'WorkNo', hideDefaultActions: 'true' },
    { label: '주행거리', fieldName: 'DriveDistance', hideDefaultActions: 'true' },
    { label: '처리결과', fieldName: 'RequestRes', hideDefaultActions: 'true' }
];

export default class pdiStep0View extends LightningElement {
    columns = columns;
    bulkColumns = bulkColumns;

    @track _selectedVIN;

    @track data;
    @track selectedId;
    @track searchKey;
    @track myLabel = labelList;
    isNoData = false;
    driveDistance;

    selectedStockRowList = [];

    @track bulkData = [];
	@track varIsBulk = false;
    @track myParam;

	@api
    set isBulk(value) {
        // console.log('PDI Step0 View. isBulk : ' + value);
        this.varIsBulk = value;

        if(this.varIsBulk) {
            this.selectedId = null;
        } else {
            this.bulkData = [];
        }
    }
    get isBulk() {
        return this.varIsBulk;
    }

    @api
	set selectedVin(value) {
		if (value) {
			this._selectedVIN = { ...value };
		}
	}
	get selectedVin() {
		return this._selectedVIN;
	}

    @api
    set varStockList(value) {
        if (value) {
            // console.log('PDI Step0 View : ', JSON.stringify(value));

            this.data = value.map(item => ({
                ...item,
                ProductName: item.Product__r ? item.Product__r.Name : ''
            }));
            this.isNoData = this.data.length === 0 ? true : false;
            if(this.myParam != null) {
                let selectedRow = this.data.filter(row => row.Id == this.myParam);
                console.log('핸드오버 스케줄러 체크 :: ' + JSON.stringify(selectedRow));
                this.makeRecordSelectEvent(selectedRow);
            }
        }
    }
    get varStockList() {
        return this.data;
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.myParam = currentPageReference.state?.c__stockId;
            this.selectedStockRowList = [this.myParam]
        }
    }

    connectedCallback() {
        this.selectedStockRowList = [this._selectedVIN?.Id];
    }
    
    handleRowSelection(event) {
        console.log('step0 handleRowSelection 실행됨');
        let selectedId = event.detail.selectedRows.map(row => row.Id);
        if (JSON.stringify(selectedId) === JSON.stringify(this.selectedId)) return;
        this.selectedId = selectedId;
        this.makeRecordSelectEvent(event.detail.selectedRows);
    }

    makeRecordSelectEvent(selectedRow) {
        const customEvent = new CustomEvent('recordselect', {
            detail: { selectedRows: selectedRow }
        });
        this.dispatchEvent(customEvent);
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
    }

    handleKeyDown(event) {
        if(event.key === 'Enter') {
            event.preventDefault();    // 기본 동작 막기
            event.stopPropagation();   // 이벤트 전파 막기
            this.handleSearchButton(event);
        }
    }

    handleSearchButton(event) {
        const id = event.currentTarget.dataset.id;
		// 검색 초기화
		if (id === "refresh") {
			this.searchKey = '';
		}
        const customEvent = new CustomEvent('searchvin', {
            detail: {
                searchKey: this.searchKey || ''
            }
        });
        this.dispatchEvent(customEvent);
    }

    handlePaste(event) {
        event.preventDefault();

        this.bulkData = [];    // 1. 기존 화면의 데이터 Empty

        // 2. Rows 데이터 Insert
        let clipboardData = event.clipboardData.getData('text/plain');
        let rows = clipboardData.split('\n').filter(row => row.trim() !== ''); // 행의 값이 있는 것만 추출

        rows.map(row => {
            let dataRow = row.split('\t');
            this.addBulkRow(dataRow);
        });

        const customEvent = new CustomEvent('bulkpaste', {
            detail: { bulkVIN: this.bulkData }
        });
        this.dispatchEvent(customEvent);
    }

    addBulkRow(dataRow) {
        let row = {
            id: `row-${this.bulkData.length + 1}`,
            WorkNo: dataRow[0].replace('\r', '') || '',
            DriveDistance: dataRow[1].replace('\r', '') || ''
        };

        this.bulkData = [ ...this.bulkData, row ];
    }

    @api
    fetchResultBulkRow(result){
        Object.keys(result).forEach(el => {
            this.bulkData = this.bulkData.map(row => {
                if (row.WorkNo === el) {
                    row.RequestRes = result[el].RequestRes;
                }
                return row
            });
        })
    }
}