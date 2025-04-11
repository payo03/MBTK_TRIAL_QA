/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2024-12-18      jh.jung           Created
 */
import {LightningElement, track, wire} from 'lwc';
import {recordNavigation, showToast} from "c/commonUtil";
import {notifyRecordUpdateAvailable} from "lightning/uiRecordApi";
import {CloseActionScreenEvent} from "lightning/actions";
import formFactor from "@salesforce/client/formFactor";

import getBizNum from "@salesforce/apex/UpdateBusinessNumberField.getBizNum";
import updateBizNum from "@salesforce/apex/UpdateBusinessNumberField.updateBizNum";
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";

export default class UpdateBizNum extends NavigationMixin(LightningElement) {

  recordId;
  objectApiName;
  @track bizNum;
  // @wire(CurrentPageReference) pageRef;
  //
  // connectedCallback() {
  //   this.recordId = this.pageRef.state.recordId;
  //   this.getBusinessNumber();
  //   console.log('recordId ::: ' + this.recordId);
  // }

  // URL에서 recordId 가져오기
  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    this.recordId = currentPageReference.state.recordId;
    if (currentPageReference && !this.recordId) {
      this.recordId = currentPageReference.state?.c__recordId;
    }
    if(this.recordId) {
      this.objectApiName = this.getObjectApiNameFromId(this.recordId);
      console.log('BizNum ::: currentPageReference ::: ' + JSON.stringify(currentPageReference))
      console.log('BizNum ::: this.recordId ::: ' + this.recordId)
      console.log('BizNum ::: this.objectApiName ::: ' + this.objectApiName)
      this.getBusinessNumber();
    }
  }

  getObjectApiNameFromId(recordId) {
    const prefixMap = {
      '001': 'Account',
      '003': 'Contact',
      '00Q': 'Lead',
      '500': 'Case',
      '006': 'Opportunity'
      // 필요한 객체 추가 가능
    };

    const prefix = recordId.substring(0, 3);
    return prefixMap[prefix] || 'Unknown';
  }

  getBusinessNumber() {
    getBizNum({recordId : this.recordId})
      .then(res => {
        if(res === 'fail') {
          showToast("Error", "사업자번호 조회 실패", "warning");
          return;
        }
        this.bizNum = res;
      })
      .catch(err => {
        console.log("getBizNum error ::: " + JSON.stringify(err));
      });
  }
  updateBizNum() {
    console.log('this.bizNum ::: ' + this.bizNum)
    // 자리 값 확인
    if(this.bizNum.length !== 12 || this.bizNum === null) {
      // showToast("Error", "사업자번호를 다시 입력해 주세요", "warning");
      showToast("10자리 입력이 안되었습니다.", "사업자번호를 다시 입력해 주세요", "warning");
      return;
    }
    updateBizNum({recordId : this.recordId, bizNum : this.bizNum.replace(/\D/g, "")})
      .then(res => {
        console.log('updateBizNum ::: ' + res);
        let title = "업데이트 실패";
        let msg;
        let variant = "warning";
        if (res === "N") {
          msg = "등록되지 않은 사업자 번호 입니다."
        } else if (res === "F") {
          msg = "휴업/폐업된 사업자 번호 입니다.";
        } else if (res === "S") {
          title = "업데이트 성공";
          msg = "사업자 번호가 업데이트 되었습니다.";
          variant = "success";
          this.handleCancel()
        } else {
          msg = "관리자에게 문의하세요.";
          this.handleCancel()
        }
        showToast(title, msg, variant);
        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
      }).catch(err => {
        console.log("updateBizNum err ::: ", JSON.stringify(err));
        showToast("관리자 문의", "관리자에게 문의하세요", "error");
    });
  }

  handleEnterKey(e) {
    if(e.key === 'Enter') {
      this.updateBizNum();
      return;
    }
  }
  handleChange(e) {

    // if(e.key === 'Enter') {
    //   this.updateBizNum();
    //   return;
    // }

    const numInput = e.target.value.replace(/[^0-9]/g, '');
    this.bizNum = this.formatBusinessNumber(numInput);
    e.target.value = this.bizNum;
  }

  formatBusinessNumber(value) {
    // 길이 제한: 최대 10자리 숫자
    const maxLength = 10;
    const digits = value.slice(0, maxLength);

    // 포맷팅: XXX-XX-XXXXX
    const part1 = digits.slice(0, 3);
    const part2 = digits.slice(3, 5);
    const part3 = digits.slice(5);

    let formatted = part1;
    if (part2) formatted += `-${part2}`;
    if (part3) formatted += `-${part3}`;

    return formatted;
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
    this.mobileReturnPage();
  }

  mobileReturnPage() {
    if(formFactor === "Small") {
      recordNavigation(this, this.objectApiName, this.recordId);
    }
  }
}