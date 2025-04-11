/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2024-12-13      jh.jung           Created
 */
import {api, wire, LightningElement} from 'lwc';
import {labelList, recordNavigation, showToast} from "c/commonUtil";
import {notifyRecordUpdateAvailable} from "lightning/uiRecordApi";

import formFactor from "@salesforce/client/formFactor";
import updateRoadAddress from "@salesforce/apex/UpdateRoadAddressField.updateRoadAddress";
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";


export default class UpdateRoadAddress extends NavigationMixin(LightningElement) {

  vfHost = labelList.VFHost;
  isModal = false;
  isMobile = false;
  isDetailAddressModal;
  roadAddress;
  detailAddress;
  postalCode;
  @api recordId;
  objectApiName;

  connectedCallback() {
    window.addEventListener("message", this.getDataFromChild.bind(this));
  }

  @api invoke() {
    console.log('UpdateRoadAddress invoke :::')
    this.isModal = true;
    this.isDetailAddressModal = false;
    this.roadAddress = '';
    this.detailAddress = '';
    this.postalCode = '';
    this.objectApiName = this.getObjectApiNameFromId(this.recordId);
    // window.addEventListener("message", this.getDataFromChild.bind(this));
  }

  // URL에서 recordId 가져오기
  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    console.log('RealDriver ::: currentPageReference ::: ' + currentPageReference)
    console.log('RealDriver ::: this.recordId ::: ' + this.recordId)
    if (!this.recordId || this.isMobile) {
      this.recordId = currentPageReference.state?.c__recordId;
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

    this.roadAddress = e.data.roadAddress;
    this.postalCode = e.data.zonecode;
    this.isDetailAddressModal = true;

    // 모달 정상적으로 나오도록
    document.body.style.overflow = 'hidden';
    document.body.classList.add('slds-backdrop_open');
    window.scrollTo({ top: 0 });
  }

  handleChange(e) {
    if(e.key === 'Enter') {
      this.updateRoadAddressAndDetailAddress();
      return;
    }

    this.detailAddress = e.target.value;
  }

  updateRoadAddressAndDetailAddress() {
    updateRoadAddress({recordId : this.recordId, roadValue : this.roadAddress, detailValue : this.detailAddress, postalCode : this.postalCode})
      .then(res => {
        if(res === false) {
          showToast("Error", "도로명 주소 업데이트 실패", "warning");
          return;
        }

        showToast("Success", "도로명 주소 업데이트", "success");
        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
        this.closeModal();
      })
      .catch(err => {
        console.log("RoadAddress error ::: " + JSON.stringify(err));
      });
  }

  closeModal() {
    this.isModal = false;
    this.isDetailAddressModal = false;
    document.body.style.overflow = '';
    document.body.classList.remove('slds-backdrop_open');
    this.mobileReturnPage();
  }

  mobileReturnPage() {
    if(formFactor === "Small") {
      recordNavigation(this, this.objectApiName, this.recordId);
    }
  }
}