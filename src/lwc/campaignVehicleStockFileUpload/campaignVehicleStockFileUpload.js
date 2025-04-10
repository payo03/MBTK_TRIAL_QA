/*************************************************************
 * @author : Choi Taewook
 * @date : 2024-11-25
 * @description : 캠페인 퀵액션 버튼 VIN
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-25      Choi Taewook    Created
**************************************************************/

import { LightningElement, track, api, wire } from 'lwc';
import stockUploadedFile from "@salesforce/apex/CampaignFileUploadController.stockUploadedFile";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { CloseActionScreenEvent } from "lightning/actions";
import { showToast } from "c/commonUtil";

export default class CampaignVehicleStockFileUpload extends NavigationMixin(LightningElement) {

    @track filesUploaded = [];
    @track fileDetails = null;
    file;
    fileReader;
    fileContents;
    @wire(CurrentPageReference) pageRef;
    campaignId;

    handleFilesChange(event) {
        this.campaignId = this.pageRef.state.recordId;
        this.filesUploaded = event.target.files;
        console.log('this.filesUploaded :: ', this.filesUploaded);

        if (this.filesUploaded.length > 0) {
            this.file = this.filesUploaded[0]; // 첫 번째 파일 선택
            console.log('this.file ::: ', this.file);
            console.log('this.file ::: ', this.file.name);

            this.fileDetails = {
                name: this.file.name,                        // 파일 이름
                size: this.formatFileSize(this.file.size),  // 파일 크기 (읽기 쉬운 형식으로 변환)
            };
            
            console.log('this.fileDetails ::: ', JSON.stringify(this.fileDetails));

            this.readFile();
        } else {
            this.fileDetails = null;
            showToast('Error', '파일을 선택해주세요.', 'error');
        }
    }

    uploadFile(e) {
        console.log('클릭 테스트');
        this.saveStockData();
    }

    // 파일 크기 변환 함수
    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    readFile() {
        const fileReader = new FileReader();

        fileReader.onloadend = (() => {
            const csvData = fileReader.result;
            // console.log('csvData ::: ', csvData);
            // this.fileContents = btoa(csvData); // Base64 인코딩 처리
            this.fileContents = this.encodeToBase64(csvData)
            // console.log('this.fileContents ::: ', this.fileContents);
            // this.saveAccountData();
        });

        fileReader.onerror = (() => {
            showToast('Error', '파일 읽기에 실패했습니다.', 'error');
        });

        fileReader.readAsText(this.file, 'UTF-8'); // UTF-8로 읽기
    }

    encodeToBase64(input) {
        // UTF-8 데이터를 Base64로 안전하게 변환
        const textEncoder = new TextEncoder();
        const utf8Array = textEncoder.encode(input); // UTF-8로 변환
        const uint8Array = new Uint8Array(utf8Array);
        let binaryString = '';

        for (let i = 0; i < uint8Array.length; i++) {
            binaryString += String.fromCharCode(uint8Array[i]);
        }

        return btoa(binaryString); // Base64로 인코딩
    }

    saveStockData() {
        stockUploadedFile({campaignId: this.campaignId, base64Data: this.fileContents})
        .then(result => {
            console.log('save타나?');
            console.log('result :::' , result);
            if(!result || result.length === 0) {
                showToast('Error', '차량재고관리 파일을 확인해 주세요.', 'error', 'dismissable');
                return;
            } 
            showToast('Success', 'Create Successfully', 'success', 'dismissable');
            
            this.dispatchEvent(new CloseActionScreenEvent());   // Panel 닫기
            setTimeout(() => {
                window.location.reload();   // 새로고침
            }, 1500);
        })
        .catch(err=> {
            showToast('Error', '차량재고관리 관련 CSV 파일을 넣어주세요', 'error', 'dismissable');
        })
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }


    // 드래그 영역에 파일이 드래그될 때
    handleDragOver(event) {
        event.preventDefault();
        this.template.querySelector('.slds-file-selector__dropzone').classList.add('slds-has-drag-over');
    }

    // 드래그 영역에서 파일이 나갔을 때
    handleDragLeave() {
        this.template.querySelector('.slds-file-selector__dropzone').classList.remove('slds-has-drag-over');
    }

    // 드래그한 파일이 드롭되었을 때
    handleDrop(event) {
        event.preventDefault();
        this.template.querySelector('.slds-file-selector__dropzone').classList.remove('slds-has-drag-over');
        
        const files = event.dataTransfer.files;

        if (files.length > 1) {
            alert('한 번에 하나의 파일만 드래그할 수 있습니다.');
            return;  // 여러 파일이 드래그되면 처리하지 않음
        }

        this.handleFilesChange({ target: { files } });
    }

    handleChooseFile() {
        this.template.querySelector('input[type="file"]').click();
        // console.log('이건 뭐라고 찍히냐?');
    }

}