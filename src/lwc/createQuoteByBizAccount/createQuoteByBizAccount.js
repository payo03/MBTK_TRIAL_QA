/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2025-04-07      jh.jung           Created
 */
import {LightningElement, track, wire} from 'lwc';
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";
import {CloseActionScreenEvent} from "lightning/actions";
import formFactor from "@salesforce/client/formFactor";
import {defaultNavigation, recordNavigation, showToast} from "c/commonUtil";

import createQuoteByBizAcc from "@salesforce/apex/CreateQuoteBizAccController.createQuoteByBizAcc";

export default class CreateQuoteByBizAccount extends NavigationMixin(LightningElement) {


  @track recordId;

  @track selectedProductId;
  selectedCampaignId;
  selectedCampaignList;
  @track isLoading = false;

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    this.recordId = currentPageReference.state.recordId;
    if (currentPageReference && !this.recordId) {
      this.recordId = currentPageReference.state?.c__recordId;
    }
  }

  convertHandler() {
    console.log('convertHandler')

    if(this.selectedProductId === '' || typeof this.selectedProductId === 'undefined') {
      showToast("Error", "선택한 차종이 없습니다.", "warning");
      return;
    }

    const inputMap = {
      'accountId' : this.recordId
      , 'productId' : this.selectedProductId
      , 'campaignIdList' : JSON.stringify(this.selectedCampaignList.map(item => item.id))
      , 'financeId' : null
      , 'totalLoan' : 0
      , 'interestRate' : 0
      , 'duration' : 0
    }
    console.log('inputMap ::: ' + JSON.stringify(inputMap));
    this.isLoading = true;
    createQuoteByBizAcc({'inputMap' : inputMap}).then(res => {
      console.log('res ::: ' + res)
      console.log('res ::: ' + JSON.stringify(res))
      const isSuccess = res['isSuccess'];

      if (isSuccess === true) {
        showToast("Success", "견적이 생성 되었습니다.", "success");
        defaultNavigation(this, "Quote", '', res['value']);
      }
    }).catch(err => {
      console.log("err :: ", err.message);
    }).finally(() => {
      this.isLoading = false;
    });
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
    this.mobileReturnPage();
  }

  mobileReturnPage() {
    if(formFactor === "Small") {
      recordNavigation(this, 'Account', this.recordId);
    }
  }

  // productCampaignTable에서 이벤트 받기
  handleRowSelect(e) {
    if (e.detail.type === "product") {
      this.selectedProductId = e.detail.id;
      this.selectedCampaignId = '';
      this.selectedCampaignList = [];
    }
    if (e.detail.type === "campaign") {
      this.selectedCampaignId = e.detail.id;
      this.selectedCampaignList = e.detail.selectedRow;
    }
  }

  getProductIdByChild(e) {
    this.selectedProductId = e.detail.productId;
    this.selectedCampaignId = '';
    this.selectedCampaignList = [];
  }
}