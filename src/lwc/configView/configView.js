/**
* @Author            : ccy2010@solomontech.net
* @Description 		 : 공통 Config파일 화면
* @Target            : CustomConfig App Page
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-10-31      ccy2010@solomontech.net          Create
  1.1      2024-11-02      payo03@solomontech.net           각 Grid별 기능 활성화 및 데이터 Load
*/

import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { showToast, resourceList } from "c/commonUtil";
import jqueryTest from '@salesforce/resourceUrl/jQuery';
import { loadScript } from 'lightning/platformResourceLoader';
import selectConfigMaster from '@salesforce/apex/ConfigMasterController.selectConfigMaster';
import selectConfigDetailById from '@salesforce/apex/ConfigMasterController.selectConfigDetailById';
import upsertConfigMaster from '@salesforce/apex/ConfigMasterController.upsertConfigMaster';
import upsertConfigDetail from '@salesforce/apex/ConfigMasterController.upsertConfigDetail';
import deleteConfigDetail from '@salesforce/apex/ConfigMasterController.deleteConfigDetail';

// Test용 함수
import signRequestByTemplate from '@salesforce/apex/InterfaceModuSign.doCallOutSignRequestByTemplate';
import kakaoAlimTalk from '@salesforce/apex/InterfaceKakao.doCallOutKakaoAlimTalk';

const LCOLUMNS = [
    { label: 'Code', fieldName: 'code' },
    { label: 'Value', fieldName: 'value' },
    { label: 'Parent Code', fieldName: 'pCode' }
];

const RCOLUMNS = [
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'View', name: 'view' }
            ],
        },
    },
    { 
        label: 'Code', fieldName: 'Name', editable: true,
        cellAttributes: {
            style: { fieldName: 'codeStyle' }
        } 
    },
    { label: 'Value', fieldName: 'Value__c', editable: true },
    { label: 'Parent Code', fieldName: 'parentName', editable: true },
    { label: 'Description', fieldName: 'Description__c', editable: true }
];

const RECORDTYPE_COLUMNS = {
    DEFAULT: [
        { label: 'Code', fieldName: 'masterCode' },
        { label: 'Key', fieldName: 'Name', editable: true, },
        { label: 'Attr1', fieldName: 'Attribute1__c', editable: true },
        { label: 'Attr2', fieldName: 'Attribute2__c', editable: true },
        { label: 'Attr3', fieldName: 'Attribute3__c', editable: true },
        { label: 'Attr4', fieldName: 'Attribute4__c', editable: true },
        { label: 'Attr5', fieldName: 'Attribute5__c', editable: true },
        { label: 'Attr6', fieldName: 'Attribute6__c', editable: true },
        { label: 'Attr7', fieldName: 'Attribute7__c', editable: true },
        { label: 'Attr8', fieldName: 'Attribute8__c', editable: true },
        { label: 'Attr9', fieldName: 'Attribute9__c', editable: true },
        { label: 'Attr10', fieldName: 'Attribute10__c', editable: true }
    ],
    SALES_CONDITION: [
        { label: 'Code', fieldName: 'masterCode' },
        { label: 'Model', fieldName: 'Name', editable: true, },
        { label: 'Generation', fieldName: 'Attribute1__c', editable: true },
        { label: 'Segment', fieldName: 'Attribute2__c', editable: true },
        { label: 'LMY', fieldName: 'Attribute3__c', editable: true },
        { label: 'VIN MY', fieldName: 'Attribute4__c', editable: true },
        { label: 'Emission', fieldName: 'Attribute5__c', editable: true },
        { label: 'List Price', fieldName: 'Attribute6__c', editable: true },
        { label: 'No CF DC (%)', fieldName: 'Attribute7__c', editable: true },
        { label: 'StartDate', fieldName: 'Attribute8__c', editable: true },
        { label: 'EndDate', fieldName: 'Attribute9__c', editable: true },
        { label: 'YM', fieldName: 'Attribute10__c', editable: true }
    ],
    EMAIL_TARGET: [
        { label: 'Code', fieldName: 'masterCode' },
        { label: 'Email Info', fieldName: 'Name', editable: true, },
        { label: 'Sender', fieldName: 'Attribute1__c', editable: true },
        { label: 'Subject', fieldName: 'Attribute2__c', editable: true },
        { label: 'EmailBody', fieldName: 'Attribute3__c', editable: true },
        { label: 'EmailBodyEnd', fieldName: 'Attribute4__c', editable: true },
        { label: 'FileName', fieldName: 'Attribute5__c', editable: true },
        { label: 'CSV Header', fieldName: 'Attribute6__c', editable: true },
        { label: 'CSV Body', fieldName: 'Attribute7__c', editable: true },
        { label: 'toAddress', fieldName: 'Attribute20__c', editable: true }
    ],
    MODUSIGN: [
        { label: 'Code', fieldName: 'masterCode' },
        { label: 'Key', fieldName: 'Name', editable: true, },
        { label: 'Label', fieldName: 'Attribute1__c', editable: true },
        { label: 'Attr2', fieldName: 'Attribute2__c', editable: true },
        { label: 'Attr3', fieldName: 'Attribute3__c', editable: true },
        { label: 'Attr4', fieldName: 'Attribute4__c', editable: true },
        { label: 'Attr5', fieldName: 'Attribute5__c', editable: true }
    ],
    HANDOVER: [
        { label: 'Code', fieldName: 'masterCode' },
        { label: 'Key(Field)', fieldName: 'Name', editable: true, },
        { label: 'Label', fieldName: 'Attribute1__c', editable: true },
        { label: 'Value', fieldName: 'Attribute2__c', editable: true },
        { label: 'Condition List', fieldName: 'Attribute20__c', editable: true }
    ],
    MFS_CODE: [
        { label: 'Code', fieldName: 'masterCode' },
        { label: 'Vehicle Model Code', fieldName: 'Name', editable: true, },
        { label: 'Vehicle Category', fieldName: 'Attribute1__c', editable: true },
        { label: 'Vehicle Case', fieldName: 'Attribute2__c', editable: true },
        { label: 'Sales Price', fieldName: 'Attribute3__c', editable: true },
        { label: 'Supply Price', fieldName: 'Attribute4__c', editable: true },
        { label: 'Tax(VAT)', fieldName: 'Attribute5__c', editable: true },
        { label: 'Vehicle Model Name', fieldName: 'Attribute20__c', editable: true }
    ],
    MAN_CODE: [
        { label: 'Code', fieldName: 'masterCode' },
        { label: 'Key(Field)', fieldName: 'Name', editable: true, },
        { label: 'Value', fieldName: 'Attribute1__c', editable: true },
        { label: 'Attr1', fieldName: 'Attribute2__c', editable: true },
        { label: 'Attr2', fieldName: 'Attribute3__c', editable: true },
        { label: 'Attr3', fieldName: 'Attribute4__c', editable: true },
        { label: 'Attr4', fieldName: 'Attribute5__c', editable: true },
        { label: 'Attr5', fieldName: 'Attribute20__c', editable: true }
    ],
    PL_CAL_INFO: [
        { label: 'Code', fieldName: 'masterCode' },
        { label: 'Report Spec', fieldName: 'Name', editable: true, },
        { label: 'Local cost', fieldName: 'Attribute1__c', editable: true },
        { label: 'PDI costs', fieldName: 'Attribute2__c', editable: true },
        { label: 'Other costs', fieldName: 'Attribute3__c', editable: true },
        { label: 'Active', fieldName: 'Attribute4__c', editable: true, type: 'boolean' },
    ]
};

export default class configView extends LightningElement {
    @track lData = [];
    @track rData = [];
    @track dData = [];
    @track currentRow = {};
    @track showUpperGrid = true;
    @track detailTitle = 'Custom 시스템 설정';

    @wire(CurrentPageReference) pageRef;

    lColumns = LCOLUMNS;
    rColumns = RCOLUMNS;
    dColumns = RECORDTYPE_COLUMNS.DEFAULT;
    recordTypeColumns = RECORDTYPE_COLUMNS;

    draftMasterValues = [];
    draftDetailValues = [];
    selectedRows = [];
    deleteTempRows = [];
    preventRecordType = ['SALES_CONDITION', 'PL_CAL_INFO'];

    jquery;

    connectedCallback() {
        let configCode = '';

        let apiName = this.pageRef.attributes.apiName;
        if('ConditionUpload' == apiName) {
            this.showUpperGrid = false;
            this.detailTitle = '판매조건 Excel 대량Upload';
            configCode = 'MAN1000';
        } else if ('LocalCost' == apiName) {
            this.showUpperGrid = false;
            this.detailTitle = '리포트스펙 평균 Local Cost';
            configCode = 'MAN6000';
        }

        this.viewConfigMaster(configCode);
    }

    renderedCallback() {
        if(this.showUpperGrid) {
            // Expand All
            let treeGrid = this.template.querySelector('lightning-tree-grid[data-id="treeGrid"]');
            treeGrid.expandAll();
        }

        // 중복로드 방지
        if (this.jquery) return;
      
        // loadScript로 jQuery를 로드하고, 완료 후 후속 작업을 실행
        loadScript(this, jqueryTest).then(() => {
            this.jquery = window.jQuery;
            console.log('jQuery loaded successfully!');

            this.afterJQueryLoaded();
        }).catch(error => {
            console.error('Error loading jQuery:', error);
        });
    }

    afterJQueryLoaded() {
        // jQuery로 데이터테이블 열 너비 설정
        /*
        const $datatable = this.template.querySelector('lightning-datatable');

        // 'lightning-datatable'의 Shadow DOM 내부에서 <th>와 <td> 선택
        const shadowRoot = $datatable.shadowRoot;
        if (shadowRoot) {
            // 첫 번째 열 너비를 17%로 설정
            this.jquery(shadowRoot.querySelector('th:nth-child(1)')).css('width', '17%');
            this.jquery(shadowRoot.querySelector('td:nth-child(1)')).css('width', '17%');

            // 두 번째 열 너비를 25%로 설정
            this.jquery(shadowRoot.querySelector('th:nth-child(2)')).css('width', '25%');
            this.jquery(shadowRoot.querySelector('td:nth-child(2)')).css('width', '25%');

            // 세 번째 열 너비를 17%로 설정
            this.jquery(shadowRoot.querySelector('th:nth-child(3)')).css('width', '17%');
            this.jquery(shadowRoot.querySelector('td:nth-child(3)')).css('width', '17%');

            // 네 번째 열 너비를 31%로 설정
            this.jquery(shadowRoot.querySelector('th:nth-child(4)')).css('width', '31%');
            this.jquery(shadowRoot.querySelector('td:nth-child(4)')).css('width', '31%');
        }
        */
    }

    // Master Row Click
    handleClick(event) {
        this.currentRow = event.detail.row;
        this.viewConfigDetailById(this.currentRow.Id);
    }

    handleMasterCellChange(event) {
        let updatedFields = event.detail.draftValues;

        // 데이터 업데이트
        this.rData = this.rData.map(row => {
            let updatedField = updatedFields.find(item => item.id == row.id);

            if (updatedField) {
                return { ...row, ...updatedField, edit: true };
            }
            return row;
        });
    }

    handleMasterSave() {
        let filterList = this.rData.filter(item => item.edit == true);

        upsertConfigMaster({ paramMList : filterList }).then(() => {

            this.draftMasterValues = [];
            this.viewConfigMaster('');
            showToast('Success', 'Master Row updated successfully', 'success', 'dismissable');
        }).catch(error => {
            showToast('Error', 'Error Upsert Master', 'error', 'dismissable');
            console.log(error);
        });
    }

    handleMasterCancel() {
        this.viewConfigMaster('');
    }

    // Detail Row Checkbox
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    handleDetailCellChange(event) {
        let updatedFields = event.detail.draftValues;

        this.updateDetailRow(updatedFields);
    }

    handleDetailSave() {
        // Copy & Paste를 통해 데이터를 저장할 경우, 기존 Row를 삭제처리
        console.log('this.currentRow.RecordType.DeveloperName ::: ' + this.currentRow.RecordType.DeveloperName);
        console.log(this.currentRow.RecordType.DeveloperName === 'PL_CAL_INFO');

        let activeTruncate = true;
        if(this.currentRow.RecordType.DeveloperName === 'PL_CAL_INFO') {
            activeTruncate = false;
        }

        if(this.deleteTempRows.length > 0 && activeTruncate) {
            this.deleteDetailRow(this.deleteTempRows);
            // this.deleteTempRows = [];
        }
        this.deleteTempRows = [];

        let upsertList = this.dData
            .filter(item => item.edit == true)
            .map(item => {
                let { id, ...detailObj } = item;
                // 3/18 저장시
                if(this.currentRow.RecordType.DeveloperName === 'PL_CAL_INFO') {
                    detailObj.Attribute4__c = String(detailObj.Attribute4__c);
                }
                return detailObj;
            });

        // console.log(upsertList);
        console.log(JSON.stringify(upsertList));

        upsertConfigDetail({ paramDList : upsertList }).then(() => {

            this.draftDetailValues = [];
            this.viewConfigDetailById(this.currentRow.Id);
            showToast('Success', 'Detail Row updated successfully', 'success', 'dismissable');
        }).catch(error => {
            showToast('Error', 'Error Upsert Detail', 'error', 'dismissable');
            console.log(error);
        });
    }

    handleDetailCancel() {
        this.viewConfigDetailById(this.currentRow.Id);
    }

    handlePaste(event) {
        if(this.preventRecordType.includes(this.currentRow.RecordType.DeveloperName)) {

            event.preventDefault();
            this.deleteTempRows = this.deleteTempRows.length > 0 ? this.deleteTempRows : this.dData.map(row => row.Id);    // 1. 변수에 기존Row들 저장
            this.dData = [];    // 2. 기존 화면의 데이터 Empty

            // 3. Rows 데이터 Insert
            let clipboardData = event.clipboardData.getData('text/plain');
            let rows = clipboardData.split('\n').filter(row => row.trim() !== ''); // 행의 값이 있는 것만 추출
            rows.map(row => {
                let dataRow = row.replace('\r', '').split('\t');
                this.addDetailRow(dataRow);
            });

            // 4. 수정된 행으로 간주
            this.updateDetailRow(this.dData);
            this.draftDetailValues = [...this.dData];
        }
    }

    addMasterRow() {
        let row = {
            id: `row-${this.rData.length + 1}`,
            Name: '',
            Value__c: '',
            parentName: '',
            Description__c: ''
        };

        this.rData = [ ...this.rData, row ];
    }

    addDetailRow(dataRow) {
        // Test용 함수
//        this.callModuSignRequest();
//        this.callKakaoAlimTalk();
        let row = {
            id: `row-${this.dData.length + 1}`,
            masterCode: this.currentRow.Name,
            Name: dataRow[0] || '',
            Attribute1__c: dataRow[1] || '',
            Attribute2__c: dataRow[2] || '',
            Attribute3__c: dataRow[3] || '',
            Attribute4__c: dataRow[4] || '',
            Attribute5__c: dataRow[5] || '',
            Attribute6__c: dataRow[6] || '',
            Attribute7__c: dataRow[7] || '',
            Attribute8__c: dataRow[8] || '',
            Attribute9__c: dataRow[9] || '',
            Attribute10__c: dataRow[10] || '',
            Attribute11__c: dataRow[11] || '',
            Attribute12__c: dataRow[12] || '',
            Attribute13__c: dataRow[13] || '',
            Attribute14__c: dataRow[14] || '',
            Attribute15__c: dataRow[15] || '',
            Attribute16__c: dataRow[16] || '',
            Attribute17__c: dataRow[17] || '',
            Attribute18__c: dataRow[18] || '',
            Attribute19__c: dataRow[19] || '',
            Attribute20__c: dataRow[20] || ''
        };

        // paste할 시
        if(this.currentRow.RecordType.DeveloperName === 'PL_CAL_INFO') {
            row.Attribute4__c = row.Attribute4__c.toLowerCase() === 'true';
        }

        this.dData = [ ...this.dData, row ];
    }

    viewConfigMaster(configCode) {
        selectConfigMaster({configCode : configCode}).then(res => {
            this.lData = res.Hierarchy;
            this.rData = res.List;
            this.currentRow = this.rData[0];

            this.lData = res.Hierarchy.map(item => {
                return {
                    ...item,
                    expanded: true,
                    _children: item.children || []
                }
            });

            this.rData = this.rData.map((item, index) => {
                return {
                    ...item,
                    id: `row-${index + 1}`,
                    edit: false,
                    parentName: item.Parent__c ? item.Parent__r.Name : '',
                    codeStyle: item.Parent__c ? '' : 'background-color: #dbfac9; color: #ce2034;'
                };
            });
            this.viewConfigDetailById(this.currentRow.Id);
        }).catch(error => {
            showToast('Error', 'Error Loading Config L', 'error', 'dismissable');
            console.log(error);
        });
    }

    viewConfigDetailById(masterId) {
        this.draftDetailValues = [];
        this.dColumns = this.recordTypeColumns[this.currentRow.RecordType.DeveloperName] || this.recordTypeColumns.DEFAULT;

        selectConfigDetailById({ paramId : masterId }).then(res => {
            this.dData = res.map((item, index) => {

                // 첫 화면 읽기
                if(this.currentRow.RecordType.DeveloperName === 'PL_CAL_INFO') {
                    if(item.Attribute4__c === undefined || item.Attribute4__c === '') { item.Attribute4__c = 'false'; }
                    item.Attribute4__c = item.Attribute4__c.toLowerCase() === 'true';
                }
                return {
                    ...item,
                    id: `row-${index + 1}`,
                    edit: false,
                    masterCode: item.ConfigMaster__r.Name
                };
            });
        }).catch(error => {
            showToast('Error', 'Error Loading Config Detail', 'error', 'dismissable');
            console.log(error.message);
        });
    }

    updateDetailRow(updatedFields) {

        // 데이터 업데이트
        this.dData = this.dData.map(row => {
            let updatedField = updatedFields.find(item => item.id === row.id);

            if (updatedField) {
                return { ...row, ...updatedField, ConfigMaster__c: this.currentRow.Id, edit: true };
            }
            return row;
        });
    }

    removeDetailRow() {
        // deleteIds : Object Record 삭제목록, clearIds : 화면 삭제목록
        let { deleteIds, clearIds } = this.selectedRows.reduce((acc, row) => {
            if (row.Id) acc.deleteIds.push(row.Id);
            acc.clearIds.push(row.id);

            return acc;
        }, { deleteIds: [], clearIds: [] });

        // Id가 있는 항목들은 Delete SOQL
        if(deleteIds.length > 0) this.deleteDetailRow(deleteIds);

        // dData 화면 삭제처리
        this.dData = this.dData.filter(row => !clearIds.includes(row.id));
        this.selectedRows = [];
    }

    deleteDetailRow(deleteIds) {
        deleteConfigDetail({ idList : deleteIds }).then(() => {

            showToast('Success', 'Detail Row Delete successfully', 'success', 'dismissable');
        }).catch(error => {
            showToast('Error', 'Error Delete Detail Row', 'error', 'dismissable');
            console.log(error);

            return;
        });
    }

    // Test용 함수
    callModuSignRequest() {
        let infoMapList = [
             {
                 objectName : 'Account',             // 조회할 Object
                 recordId: '001H200001Z0BDQIA3',     // [v] Object의 RecordId
                 validDuration: 4,                   // 문서 서명유효기간(기준 : 일). Default 14일
                 sendType: 'kakao',                  // 문서 서명요청 Type(email, kakao). Default kakao
                 role: '근로자',                      // [v] 문서 사용자 역할
                 locale: 'en',                       // 서명자의 문서 Locale 설정(ko, en, zh-CN, ja, vi)
             },
             {
                 objectName : 'User',
                 recordId: '005IU00000BhGQdYAN',
                 validDuration: 4,
                 sendType: 'email',
                 role: '을',
             },
             {
                 objectName : 'User',
                 recordId: '005H2000006e4v7IAA',
                 validDuration: 4,
                 sendType: 'kakao',
                 role: 'SA',
             },
        ];

        let infoMap = {
            templateTitle: '[샘플] 개인정보 수집 이용 동의서',
            object: 'Quote',
            recordId: '0Q0H2000000E2YOKA0',
            documentTitle: '[Test] 개인정보 수집 이용 동의서',
            infoMapList: infoMapList
        };

        signRequestByTemplate({ paramMap : infoMap }).then(response => {
            let result = response;

            let code = result.code;
            let url = result.url;
        }).catch(error => {
            console.log(error);
        });
    }

    // Test용 함수
    callKakaoAlimTalk() {
        // 수신자의 데이터 Record
        let infoMapList = [
            {
                objectName : 'Account',
                recordId: '001H200001Z0BDQIA3',
                type: '고객'
            }
        ];

        let buttonMap = {
            동의하기: {
                Id: '001H200001Z0BDQIA3'
            }
        };

        let infoMap = {
            templateTitle: '개인정보 고객 동의2',
            recordId: '001H200001Z0BDQIA3',
            externalId: '001H200001Z0BDQIA3',
            infoMapList: infoMapList,
            buttonMap: buttonMap
        };

        kakaoAlimTalk({paramMap : infoMap}).then(response => {
            let result = response;

            console.log(result);
        }).catch(error => {
           console.log(error);
        });
    }
}