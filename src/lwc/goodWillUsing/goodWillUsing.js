/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-03-11
 * @description :
 * @target :
 ==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-11      chaebeom.do     Initial Version
 **************************************************************/
import { LightningElement, track } from 'lwc';
import UserId from '@salesforce/user/Id';
import init from "@salesforce/apex/GoodWillUsingController.init";
import attachFiles from "@salesforce/apex/GoodWillUsingController.attachFiles";

// Util
import { showToast } from "c/commonUtil";

import { columns } from "./goodWillUsingColumns";

export default class goodWillUsing extends LightningElement {
  columns = columns;

  goodWillMasterId;
  availablePoints;
  //  vehicleStockId;
  usingHistory;
  usingMasterStatus = false;
  usingHistoryStatus = false;
  vinNo;
  usingGoodWill;
  description;
  curUserId = UserId;
  applyValidation = "";

  //파일 업로드 관련 변수
  @track fileDetails = [];
  accept = [".png", ".jpg"];

  isLoading = false;


  connectedCallback() {
    init({ userId: this.curUserId }).then(result => {
      this.goodWillMasterId = result.goodWillMaster[0].Id;
      this.availablePoints = result.goodWillMaster[0].ru_TotalGoodWillPoints__c;
      this.usingHistory = result.goodWillUsing;
      if (result.goodWillMaster.length > 0) this.usingMasterStatus = true;
      if (this.usingHistory.length > 0) this.usingHistoryStatus = true;
    }).catch(err => {
      console.log("err init :: ", err);
    });
  }

  /**
   * @description input-field 입력 시 onchange 이벤트
   */
  handleChange(e) {
    const value = e.target.value;
    const id = e.target.dataset.id;
    if (id === "UsingGoodWill") {
      this.usingGoodWill = value;
    } else if (id === "Description") {
      this.description = value;
    } else if (id === "VehicleStock") {
      this.vinNo = value;
    }
  }

  /**
   * @description 사용신청 시
   */
  handleSubmit() {
    // 굿윌 사용 신청시 요청금액이 굿윌 마스터의 사용가능액을 넘으면 토스트 발생
    if (!this.usingGoodWill) {
      showToast("필수값 확인", "사용 요청금액을 입력해주세요.", "warning");
      return;
    } else if (this.usingGoodWill > this.availablePoints) {
      showToast("필수값 확인", "굿윌 잔액이 부족합니다.", "warning");
      return;
    }
    // 굿윌 사용 차량이 'WMA'로 시작하지 않거나 텍스트가 17자리보다 작으면 토스트 발생
    if (!this.vinNo.startsWith("WMA") || this.vinNo.length < 17) {
      showToast("필수값 확인", "차량 VIN 양식이 올바르지 않습니다.", "warning");
      return;
    }
    // 굿윌 마스터가 없으면 토스트 발생
    if (!this.goodWillMasterId) {
      showToast("신청 불가", "굿윌 마스터가 없는 사용자입니다.", "warning");
      return;
    }
    this.applyValidation = "submit";
  }

  /**
   * @description 사용신청 생성 성공 시
   */
  handleSuccess(e) {
    //  this.recordId = e.detail.id;
    this.isLoading = true;
    attachFiles({ fileDetails: this.fileDetails, recordId: e.detail.id }).then(() => {
      showToast("사용신청 완료", "신청 내용이 승인되면 잔액에서 차감됩니다.", "success");
      this.clearEditForm();
    }).finally(this.isLoading = false);
  }

  /**
   * @description 사용신청 생성 실패 시
  */
  handleError(e) {
    console.log(e.detail.detail);
    showToast("신청 실패", e.detail.message, "warning");
  }

  /**
   * @description 사용신청 생성폼 리셋 onclick
  */
  clearEditForm() {
    // this.vehicleStockId = null;
    this.vinNo = null;
    this.usingGoodWill = null;
    this.description = null;
    this.fileDetails = [];
    this.applyValidation = "";
  }

  /**
   * @description 신청 목록 새로고침
  */
  handleRefresh() {
    init({ userId: this.curUserId }).then(result => {
      this.availablePoints = result.goodWillMaster[0].ru_TotalGoodWillPoints__c;
      this.usingHistory = result.goodWillUsing;
      if (this.usingHistory.length > 0) this.usingHistoryStatus = true;
    }).catch(err => {
      console.log("err init :: ", err)
    });
  }

  handleDragOver(event) {
    event.preventDefault(); // 기본 동작 방지
    // 드래그 중인 특정 영역만 선택
    const dropZone = event.target.closest('.slds-file-selector__dropzone');
    if (dropZone) {
      // 기존 드래그 오버 클래스를 모두 제거
      this.template.querySelectorAll('.slds-file-selector__dropzone').forEach(zone => {
        zone.classList.remove('slds-has-drag-over');
      });
      // 드래그 중인 특정 영역에만 클래스 추가
      dropZone.classList.add('slds-has-drag-over');
    }
  }

  handleDragLeave(event) {
    // 드래그가 떠난 특정 드롭존을 찾기
    const dropZone = event.target.closest('.slds-file-selector__dropzone');
    if (dropZone) {
      // 떠난 드롭존에서 클래스 제거
      dropZone.classList.remove('slds-has-drag-over');
    }
  }
  handleDrop(event) {
    event.preventDefault();
    const dropZone = event.target.closest('.slds-file-selector__dropzone');
    if (dropZone) {
      // 떠난 드롭존에서 클래스 제거
      dropZone.classList.remove('slds-has-drag-over');
    }
    const files = event.dataTransfer.files;
    this.handleUploadFinished({ target: { files } });
  }

  handleUploadFinished(e) {
    const filesTest = [...e.target.files];
    filesTest.forEach((file) => {
      const filetype = file.name.split('.').pop();
      const reader = new FileReader();
      reader.onload = () => {
        const base64 = reader.result.split(',')[1];
        this.fileDetails.push({
          name: file.name,
          base64: base64,
          filetype: filetype
          // recordId: this.recordId,
        });
        this.fileDetails = this.fileDetails.map((file, index) => {
          return {
            ...file,
            key: index
          };
        });
      };
      reader.readAsDataURL(file);
    });
  }

  handleChooseFile(e) {
    this.template.querySelector(`input[name="${e.target.name}"]`).click();
  }

  handleRemove(e) {
    const key = e.target.dataset.key;
    this.fileDetails = this.fileDetails.filter(el => el.key != key);
    if (this.fileDetails.length == 0) this.fileDetails = [];
  }

}