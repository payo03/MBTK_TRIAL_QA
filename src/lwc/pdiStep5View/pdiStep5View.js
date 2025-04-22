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
  { label: '처리결과', fieldName: 'RequestRes', hideDefaultActions: 'true' }
];

export default class PdiStep5View extends LightningElement {
    bulkColumns = bulkColumns;

    @track _selectedVIN;
    @track searchKey;
    @track bulkData = [];
    @track varIsBulk = false;

    @api
    set isBulk(value) {
        console.log('PDI Step5 View. isBulk : ' + value);
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
        }
    }
    get selectedVin() {
        return this._selectedVIN;
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
            console.log('datarow: ', dataRow);
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
            Name: dataRow[0].replace('\r', '') || ''
        };

        this.bulkData = [ ...this.bulkData, row ];
    }

    @api
    fetchResultBulkRow(result){
        Object.keys(result).forEach(el => {
            this.bulkData = this.bulkData.map(row => {
                if (row.Name === el) {
                    row.RequestRes = result[el];
                }
                return row
            });
        })
    }
}