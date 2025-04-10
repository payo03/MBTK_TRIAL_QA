/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2024-12-17      jh.jung           Created
 */
import {api, track, LightningElement} from 'lwc';
import {showToast} from "c/commonUtil";
import {notifyRecordUpdateAvailable} from "lightning/uiRecordApi";

import getBizNum from "@salesforce/apex/UpdateBusinessNumberField.getBizNum";
import updateBizNum from "@salesforce/apex/UpdateBusinessNumberField.updateBizNum";

// 안씀
export default class UpdateBusinessNumber extends LightningElement {

  isModal;
  @track bizNum;
  @api recordId;

  // @api invoke() {
  //   this.isModal = true;
  //   this.getBusinessNumber();
  // }

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
        console.log("getBizNum error ::: " + err);
      });
  }
  updateBizNum() {
    console.log('this.bizNum ::: ' + this.bizNum)
    // 자리 값 확인
    if(this.bizNum.length !== 12 || this.bizNum === null) {
      showToast("Error", "사업자번호를 다시 입력해 주세요", "warning");
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
          this.closeModal()
        } else {
          msg = "관리자에게 문의하세요.";
          this.closeModal()
        }
        showToast(title, msg, variant);
        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
      }).catch(err => {
        console.log("updateBizNum err ::: ", err);
        showToast("관리자 문의", "관리자에게 문의하세요", "error");
    });
  }

  handleChange(e) {
    const numInput = e.target.value.replace(/[^0-9]/g, '');
    this.bizNum = this.formatBusinessNumber(numInput);

    console.log('handleInput result ::: ' + this.bizNum)
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
  closeModal() {
    this.isModal = false;
  }

}