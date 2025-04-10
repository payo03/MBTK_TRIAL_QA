/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2025-01-13      jh.jung           Created
 */
import {api, track, wire, LightningElement} from 'lwc';
import {labelList, showToast, recordNavigation} from "c/commonUtil";
import {notifyRecordUpdateAvailable} from "lightning/uiRecordApi";
import {CurrentPageReference, NavigationMixin} from 'lightning/navigation';

import formFactor from "@salesforce/client/formFactor";
import updateRealDriverRoadAddress from "@salesforce/apex/UpdateRoadAddressField.updateRealDriverRoadAddress";
import getRealDriverInfo from "@salesforce/apex/UpdateRoadAddressField.getRealDriverInfo";

export default class UpdateRealDriverRoadAddress extends NavigationMixin(LightningElement) {

  vfHost = labelList.VFHost;
  isModal = false;
  isMobile = false;
  isAnotherInfoModal;
  @track realDriverRoadAddress;
  @track realDriverName;
  @track realDriverMobile;
  @track realDriverIDNumber;
  @api recordId;

  connectedCallback() {
    window.addEventListener("message", this.getDataFromChild.bind(this));
  }

  @api invoke() {
    console.log('UpdateRealDriverRoadAddress invoke :::')
    this.isModal = true;
    this.isAnotherInfoModal = false;
    this.realDriverRoadAddress = '';
    this.postalCode = '';
    this.realDriverMobile = '';
    this.realDriverIDNumber = '';
    // window.addEventListener("message", this.getDataFromChild.bind(this));
    this.getRealDriverInfo();
  }

  // URL에서 recordId 가져오기
  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    console.log('RealDriver ::: currentPageReference ::: ' + currentPageReference)
    console.log('RealDriver ::: this.recordId ::: ' + this.recordId)
    if (!this.recordId || this.isMobile) {
      this.recordId = currentPageReference.state?.c__accId;
      this.isMobile = true;

      if(this.recordId) {
        this.invoke();
      }
    }
  }

  get iframeClass() {
    if(formFactor !== "Small")  return "iframe-address";
    else                        return "iframe-active";
  }

  get modalSize() {
    const defaultClass = "slds-modal slds-fade-in-open ";
    return `${defaultClass} ${formFactor !== "Small" ? "custom-small-modal" : "custom-large-modal"}`;
  }

  getRealDriverInfo() {
    getRealDriverInfo({recordId : this.recordId})
      .then(res => {
        if(res === 'fail') {
          showToast("Error", "실차주 조회 실패", "warning");
          return;
        }
        this.realDriverName = res.RealDriver;
        this.realDriverRoadAddress = res.RealDriverAddress;
        this.realDriverMobile = res.RealDriverMobile;
        this.realDriverIDNumber = res.RealDriverIDNumber;
      }).catch(err => {
        console.log("getRealDriverInfo error ::: " + JSON.stringify(err));
      });
  }

  handleLoad() {
    const iframe = this.template.querySelector("iframe");
    if (iframe) {
      const contentWindow = iframe.contentWindow;
      const data = { target: "address", formFactor: formFactor };
      contentWindow.postMessage(data, this.vfHost);
    }
  }


  getDataFromChild(e) {
    console.log("origin :: ", e.origin);
    console.log("vfHost :: ", this.vfHost);
    console.log("data :: ", JSON.stringify(e.data));

    if (e.data === "FORCE_CLOSE") {
      console.log('close :::')
      this.closeModal();
      return;
    }

    if (this.vfHost != e.origin || e.data.target != "address") return;

    this.realDriverRoadAddress = e.data.roadAddress;
    this.isAnotherInfoModal = true;

    // 모달 정상적으로 나오도록
    document.body.style.overflow = 'hidden';
    document.body.classList.add('slds-backdrop_open');
    window.scrollTo({ top: 0 });
  }

  handleChange(e) {
    const fieldName = e.target.name;
    const value = e.target.value;
    if(e.key === 'Enter') {
      this.updateRealDriverInfo();
      return;
    }
    if(fieldName === 'realDriverName') {
      this.realDriverName = value;
    }
    if(fieldName === 'realDriverMobile') {
      const numInput = e.target.value.replace(/[^0-9]/g, '');
      this.realDriverMobile = this.formatPhoneNumber(numInput);
      e.target.value = this.realDriverMobile;
    }
    if(fieldName === 'realDriverIDNumber') {
      const numInput = e.target.value.replace(/[^0-9]/g, '');
      this.realDriverIDNumber = this.formatIDNumber(numInput);
      e.target.value = this.realDriverIDNumber;
    }
  }

  updateRealDriverInfo() {

    // 유효성 체크
    if(!this.realDriverName) {
      showToast("Error", "실차주 이름이 없습니다", "warning");
      const inputField = this.template.querySelector('[data-id="realDriverNameField"]');
      if (inputField)   inputField.focus();
      return;
    }
    if(!this.realDriverMobile) {
      showToast("Error", "실차주 번호가 없습니다", "warning");
      const inputField = this.template.querySelector('[data-id="realDriverMobileField"]');
      if (inputField)   inputField.focus();
      return;
    }
    if(!(this.realDriverMobile.length === 13)) {
      showToast("Error", "번호는 11자리여야 합니다.", "warning");
      const inputField = this.template.querySelector('[data-id="realDriverMobileField"]');
      if (inputField)   inputField.focus();
      return;
    }
    if(!this.realDriverMobile.startsWith('010')) {
      showToast("Error", "번호는 010으로 시작해야 합니다.", "warning");
      const inputField = this.template.querySelector('[data-id="realDriverMobileField"]');
      if (inputField)   inputField.focus();
      return;
    }
    if(this.realDriverIDNumber && this.realDriverIDNumber.length !== 14) {
      showToast("Error", "주민번호는 등록하지 않거나 13자리를 입력해야 합니다.", "warning");
      const inputField = this.template.querySelector('[data-id="realDriverIDNumberField"]');
      if (inputField)   inputField.focus();
      return;
    }

    updateRealDriverRoadAddress({
      recordId : this.recordId,
      realDriverRoadAddress : this.realDriverRoadAddress,
      realDriverName : this.realDriverName,
      realDriverMobile : this.realDriverMobile,
      realDriverIDNumber : this.realDriverIDNumber,
    })
      .then(res => {
        if(res === false) {
          showToast("Error", "실차주 정보 업데이트 실패", "warning");
          return;
        }

        showToast("Success", "실차주 정보 업데이트", "success");
        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
        this.closeModal();
      })
      .catch(err => {
        console.log("realDriverRoadAddress error ::: " + JSON.stringify(err));
      });
  }

  formatPhoneNumber(value) {
    // 길이 제한: 최대 10자리 숫자
    const maxLength = 11;
    const digits = value.slice(0, maxLength);

    // 포맷팅: XXX-XXX-XXXX
    const part1 = digits.slice(0, 3);
    const part2 = digits.slice(3, 7);
    const part3 = digits.slice(7);

    let formatted = part1;
    if (part2) formatted += `-${part2}`;
    if (part3) formatted += `-${part3}`;

    return formatted;
  }

  formatIDNumber(value) {
    // 길이 제한: 최대 10자리 숫자
    const maxLength = 13;
    const digits = value.slice(0, maxLength);

    // 포맷팅: XXX-XXX-XXXX
    const part1 = digits.slice(0, 6);
    const part2 = digits.slice(6);

    let formatted = part1;
    if (part2) formatted += `-${part2}`;

    return formatted;
  }

  closeModal() {
    this.isModal = false;
    this.isAnotherInfoModal = false;
    document.body.style.overflow = '';
    document.body.classList.remove('slds-backdrop_open');
    this.mobileReturnPage();
  }

  mobileReturnPage() {
    if(formFactor === "Small") {
      recordNavigation(this, "Account", this.recordId);
    }
  }
}