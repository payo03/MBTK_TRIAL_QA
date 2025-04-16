/**
* @Author            : payo03@solomontech.net
* @Description 		 : AvisOrderInfo > VehicleStock 생성
* @Target            : CreateVehicleController.cls
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-20      payo03@solomontech.net           Created
  1.1      2024-11-27      payo03@solomontech.net           ListView의 idList값 VF Page로부터 수신
  1.2      2025-04-15      payo03@solomontech.net           Interface기능 분리
*/
import { LightningElement, wire, track, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';

import { showToast, defaultNavigation } from "c/commonUtil";

import styles from '@salesforce/resourceUrl/removeDataFormat';

import screenInit from '@salesforce/apex/CreateVehicleController.screenInit';
import selectInfoList from "@salesforce/apex/CreateVehicleController.selectInfoList";
import selectLogList from "@salesforce/apex/CreateVehicleController.selectLogList";
import createVehicleStock from "@salesforce/apex/CreateVehicleController.createVehicleStock";
import handleIFAction from "@salesforce/apex/CreateVehicleController.handleIFAction";

export default class createVehicle extends LightningElement  {

    @track data;
    @track selectFilterId;
    @track paramFilterName;
    @track filterListViews = [];
    @track draftValues = [];

    @track inputVisible = true;
    @track pageOrder = true;
    @track BLDocumentNo__c = '';
    @track BLDate__c = '';
    @track RealArrivalDate__c = '';
    @track IsMail__c = false;
    /*
    @track RealSailingDate__c = '';
    @track SendTo__c = '';
    @track Suffix__c = '';
    */

    @track modalClass = 'slds-modal slds-fade-in-open';

    @api paramFilterId;

    columns = [];
    listViews = [];
    pickListMap = {};       // Value 기준으로 Label Return하기 위함

    cabMarkPickList = [];
    segment1PickList = [];
    wheelBasePickList = [];
    carColorPickList = [];
    arrivalHarborCodePickList = [];
    /*
    sendToPickList = [];
    suffixPickList = [];
    */
    valueMap = {            // Label 기준으로 필드명 Return
        CabMarkLabel : 'CabMark__c',
        WheelBaseLabel : 'WheelBase__c',
        CarColorLabel : 'CarColor__c',
        ArrivalHarborLabel : 'ArrivalHarborCode__c',
        /*
        SendToLabel : 'SendTo__c',
        SuffixLabel : 'Suffix__c',
        */
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, styles)
        ]).then(() => {
            console.log('Help Text Remove CSS Files loaded.');
        }).catch(error => {
            console.log("Error " + error.body.message);
        });
    }

    connectedCallback() {
        this.init();
        this.selectFilterId = this.paramFilterId;

        // Handle LWC - VF
        window.addEventListener('message', (event) => {
            console.log('LWC Receive : ', event.data.type);
            // Select AvisOrderInfo
            if (event.data.type === 'SELECT_ORDER_VF') {
                this.pageOrder = true;
                this.moveNextPageOrder(event.data.records);
            }
            // ver1.2 Interface기능 분리
            if (event.data.type === 'SELECT_LOG_VF') {
                this.pageOrder = false;
                this.moveNextPageLog(event.data.records);
            }
        });
    }

    closeModal() {
        // 팝업 닫기
        if(!this.inputVisible) this.changePopup();

        this.modalClass = 'slds-modal slds-fade-in-hide'; // 모달 닫힘 클래스 설정
        window.postMessage({
            type: 'POPUP_CLOSE_LWC',
            targetURL: '/lightning/o/AvisOrderInfo__c/home',
            debug: 'AvisOrderInfo Popup Close'
        }, '*');
    }

    // 입력값 Setting 공통
    handleInputChange(event) {
        try {
            let fieldName = event.target.name; // 입력 필드의 name 속성
            this[fieldName] = event.target.value; // 해당 필드 값 업데이트
        } catch(error){
            console.log(error);
        }
    }

    handleInputCheckboxChange(event) {
        this.IsMail__c = event.target.checked;
    }

    handleListViewChange(event) {
        this.selectFilterId = event.target.value;
    }

    handlePrevious() {
        this.changePopup();
    }

    // 팝업창 데이터 변경
    handleChange(event) {
        let rowId = event.target.dataset.id;
        let fieldLabelName = event.target.name;
        let value = event.target.value;

        let fieldValueName = this.valueMap[fieldLabelName];
        let fieldValue = this.pickListMap[fieldValueName]?.find(item => item.value === value).label || null;

        let logVar;
        this.data = this.data.map(row => {
            if (row.Id === rowId) {
                logVar = row;
                if(fieldValueName != undefined) {
                    // combobox 수정
                    return { ...row, [fieldLabelName]: value, [fieldValueName]: fieldValue };
                } else {
                    // Date, Input 수정
                    return { ...row, [fieldLabelName]: value };
                }
            }
            return row;
        });

        console.log(JSON.parse(JSON.stringify(logVar)));
    }

    // ver1.2 Interface기능 분리
    handleIF(event) {
        let rowId = event.target.dataset.id;
        let buttonName = event.target.name;
        console.log(buttonName);

        let infoMap = {
            infoIdList: [...new Set(this.data.map(item => item.ExternalId__c))],
            type: buttonName
        };

        handleIFAction({ paramMap : infoMap }).then(() => {
            setTimeout(() => {
//                this.closeModal();
                showToast('Success', 'Success Interface Call', 'success', 'dismissable');
            }, 1000);
        }).catch(error => {
            showToast('Error', 'Error Interface Call', 'error', 'dismissable');
            console.log(error);
        });
    }

    handleCheckboxChange(event) {
        let rowId = event.target.dataset.id;
        let isChecked = event.target.checked;

        // data 배열에서 특정 레코드 업데이트
        this.data = this.data.map((row) => {
            if (row.Id === rowId) {
                return { ...row, IsMail__c: isChecked };
            }
            return row;
        });
    }

    handleSave() {
        createVehicleStock({ orderList: this.data }).then(() => {
            setTimeout(() => {
                this.closeModal();
                showToast('Success', 'Success Vehicle Stock Call Batch', 'success', 'dismissable');
            }, 1000);
        }).catch(error => {
            showToast('Error', 'Error Vehicle Stock Call Batch', 'error', 'dismissable');
            console.log(error);
        });
    }

//    handleCancel() {
//        this.draftValues = [];
//    }

    setCurrentDate(event) {
        try {
            let fieldId = event.target.dataset.field;
            let today = new Date().toISOString().split('T')[0]; // 오늘 날짜 (YYYY-MM-DD 형식)

            this[fieldId] = today;

            // UI 업데이트
            let inputElement = this.template.querySelector(`[value=${fieldId}]`);
            if (inputElement) inputElement.value = today;
        } catch(error) {
            console.log(error);
        }
    }

    init() {
        screenInit().then(res => {
            // console.log(JSON.stringify(res));
            this.listViews = res.listViews;

            this.cabMarkPickList = res.cabMark__c;
            this.segment1PickList = res.segment1__c;
            this.wheelBasePickList = res.wheelBase__c;
            this.carColorPickList = res.carColor__c;
            this.arrivalHarborCodePickList = res.arrivalHarborCode__c;
            /*
            this.sendToPickList = res.sendTo__c;
            this.suffixPickList = res.suffix__c;
            */

            this.pickListMap = {
                CabMark__c : this.cabMarkPickList,
                WheelBase__c : this.wheelBasePickList,
                CarColor__c : this.carColorPickList,
                ArrivalHarborCode__c : this.arrivalHarborCodePickList,
                /*
                SendTo__c : this.sendToPickList,
                Suffix__c : this.suffixPickList,
                */
            };

            // ListView Setting
            if(!this.listViews.find(view => view.Id === this.selectFilterId)) this.selectFilterId = this.listViews[0].Id;
            this.paramFilterName = this.listViews.find(view => view.Id === this.selectFilterId).Name;
            this.filterListViews = this.listViews.filter(view => view.Id !== this.selectFilterId);
        }).catch(error => {
            showToast('Error', 'Error Loading PickList', 'error', 'dismissable');
            console.log(error);
        });
    }

    // ver1.2 Interface기능 분리
    nextButtonLog() {
        window.postMessage({
            type: 'SELECT_LOG_LWC',
            filterId: this.selectFilterId,
            debug: 'Select IFAuditLogDetail FROM ' + this.selectFilterId
        }, '*');
    }

    nextButtonOrder() {
        window.postMessage({
            type: 'SELECT_ORDER_LWC',
            filterId: this.selectFilterId,
            debug: 'Select AvisOrderInfo FROM ' + this.selectFilterId
        }, '*');
    }

    moveNextPageOrder(records) {
        selectInfoList({ idList: records }).then(res => {
            let data = res;
            data.forEach(item => {
                item.BLDocumentNo__c = this.BLDocumentNo__c || item.BLDocumentNo__c;
                item.BLDate__c = this.BLDate__c || item.BLDate__c;
                item.RealArrivalDate__c = this.RealArrivalDate__c || item.RealArrivalDate__c;
                item.IsMail__c = this.IsMail__c || item.IsMail__c;
                /*
                item.RealSailingDate__c = this.RealSailingDate__c || item.RealSailingDate__c;
                item.SendTo__c = this.SendTo__c || item.SendTo__c;
                item.Suffix__c = this.Suffix__c || item.Suffix__c;
                */

                // PickList 표시
                item.CabMarkLabel = this.cabMarkPickList.find(obj => obj.label === item.CabMark__c)?.value || null;
                item.SegmentLabel = this.segment1PickList.find(obj => obj.label === item.fm_Segment1__c)?.value || null;
                item.WheelBaseLabel = this.wheelBasePickList.find(obj => obj.label === item.WheelBase__c)?.value || null;
                item.CarColorLabel = this.carColorPickList.find(obj => obj.label === item.CarColor__c)?.value || null;
                item.ArrivalHarborLabel = this.arrivalHarborCodePickList.find(obj => obj.label === item.ArrivalHarborCode__c)?.value || null;
                /*
                item.SendToLabel = this.sendToPickList.find(obj => obj.label === item.SendTo__c)?.value || null;
                item.SuffixLabel = this.suffixPickList.find(obj => obj.label === item.Suffix__c)?.value || null;
                */
            });

            this.data = data;
            this.changePopup();
        }).catch(error => {
            showToast('Error', 'Error SOQL', 'error', 'dismissable');
            console.log(error);
        });
    }

    moveNextPageLog(records) {
        selectLogList({ idList: records }).then(res => {

            let data = res;
            this.data = data;
            this.changePopup();
        }).catch(error => {
            showToast('Error', 'Error SOQL', 'error', 'dismissable');
            console.log(error);
        });
    }

    changePopup() {
        this.inputVisible = !this.inputVisible;
        this.modalClass = this.inputVisible ? 'slds-modal slds-fade-in-open' : 'slds-modal slds-fade-in-open slds-modal_large';
    }
}