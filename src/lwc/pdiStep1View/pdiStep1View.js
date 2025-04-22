/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-22      payo03@solomontech.net           Created
*/
import { LightningElement, api, track } from 'lwc';

const bulkColumns = [
    { label: '워크넘버', fieldName: 'WorkNo', hideDefaultActions: 'true' },
    // { label: '주행거리', fieldName: 'DriveDistance', hideDefaultActions: 'true' },
    { label: '처리결과', fieldName: 'RequestRes', hideDefaultActions: 'true' }
];

export default class pdiStep1View extends LightningElement {
    bulkColumns = bulkColumns;

    @track _selectedVIN;

    @track searchKey;
    driveDistance;
    vehicleIssue;

    @track bulkData = [];
    @track varIsBulk = false;

    @api
    set isBulk(value) {
        this.varIsBulk = value;
        this.bulkData = [];
    }
    get isBulk() {
        return this.varIsBulk;
    }

    @api
	set selectedVin(value) {
		if (value) {
			this._selectedVIN = { ...value };
            this.driveDistance = this._selectedVIN.DriveDistance__c
		}
	}
	get selectedVin() {
		return this._selectedVIN;
	}

    handleDriveDistance(event) {
        this.driveDistance = event.target.value;
        const customEvent = new CustomEvent('changedrivedistance', {
            detail: {
                driveDistance: this.driveDistance
            }
        });
        this.dispatchEvent(customEvent);
    }

    @api
    handleUpdateIssue() {
        const currentIssue = this.template.querySelector('.vehicleIssue');
        currentIssue.submit();
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