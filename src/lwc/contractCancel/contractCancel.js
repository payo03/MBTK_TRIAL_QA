/*************************************************************
 * @author : San.Kang
 * @date : 2025-01-10
 * @description : 계약서 취소 승인 프로세스 버튼
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-01-10        San.Kang           Created
 * 2.0       2025-03-21        chaebeom.do        계약 취소 프로세스 변경으로 신규 작성
**************************************************************/
import { LightningElement, track, wire, api } from "lwc";
import { showToast} from "c/commonUtil";
import { CloseActionScreenEvent } from "lightning/actions";

import init from "@salesforce/apex/ContractCancelController.init";
import cancelByCase from "@salesforce/apex/ContractCancelController.cancelByCase";

export default class ContractCancel extends LightningElement {
     @api recordId;
     value = '';
     selectedType = '';
     isSelectType = true;
     isConfirm = false;
     contractNo;
     
     isLoading = false;

    get options(){
        return [
            { label: '실주', value: 'closedLost' },
            { label: '반품', value: 'returnVehicle' },
        ];
    }

     connectedCallback(){

     }

     handleChange(event){
        this.value = event.detail.value;
        this.selectedType = event.detail.value == 'closedLost' ? '실주' : '반품';
    }

     handleCheckType(){
        this.isSelectType = !this.isSelectType;
        this.isConfirm = !this.isConfirm;
        init({recordId: this.recordId}).then(result => {
            this.contractNo = result.Contract.ContractNumber;
        }).catch(error => {
            showToast('Error', 'Error init()', 'error', 'dismissable');
            console.log(error);
        });
     }

     //선택 취소
     handleCancel(){
        this.isSelectType = true;
        this.isConfirm = false;
        this.dispatchEvent(new CloseActionScreenEvent());
     }

     //계약 취소 실행
     handleCancelContract(){
        this.isLoading = true;
        cancelByCase({type: this.value, opptyId: this.recordId}).then(result => {
            console.log('result :: ', result);
            showToast('취소 완료', '.', 'success');
        }).catch(error => {
            showToast('Error', 'Error cancelContract', 'error', 'dismissable');
            console.log('error :: ', error);
        }).finally(() => {
            this.handleCancel();
            this.isLoading = false;
        });
     }
 }