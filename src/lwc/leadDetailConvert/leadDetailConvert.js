/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2025-02-14      jh.jung           Created
 */
import {LightningElement, track, wire} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";
import {defaultNavigation, recordNavigation, showToast} from "c/commonUtil";
import {CloseActionScreenEvent} from "lightning/actions";
import LightningConfirm from "lightning/confirm";

// import convertByLead from "@salesforce/apex/LeadManagementController.convertByLead";
import createPreQuote from "@salesforce/apex/LeadManagementController.createPreQuote";
import callApprovalProcess from "@salesforce/apex/LeadManagementController.callApprovalProcess";

import PRODUCTID_FIELD from "@salesforce/schema/Lead.ProductId__c"
import PRODUCTNAME_FIELD from "@salesforce/schema/Lead.ProductId__r.Name"
import formFactor from "@salesforce/client/formFactor";

const FIELDS = [
  'Lead.Id',
  'Lead.Name',
  'Lead.MobilePhone',
  'Lead.RoadAddress__c',
  'Lead.CreatedDate',
  'Lead.Latitude__c',
  'Lead.Longitude__c',
  'Lead.Company',
  'Lead.fm_Rating__c',
  'Lead.ProductId__c',
  'Lead.ProductId__r.Name' // Lookup 필드 가져오기
];

export default class LeadDetailConvert extends NavigationMixin(LightningElement) {

  @track recordId;
  objectApiName;

  @track leadData;
  @track selectedProductId;
  selectedCampaignId;
  selectedCampaignList;
  isConvertModal = true;

  @track isLoading = false;
  // @wire(CurrentPageReference) pageRef;
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

  connectedCallback() {
    // this.recordId = this.pageRef.state.recordId;
    // this.isConvertModal = true;
  }

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  wiredLead({ error, data }) {
    if (this.recordId && data) {
      this.leadData = [{
        Id: data.fields.Id.value,
        Name: data.fields.Name.value,
        MobilePhone: data.fields.MobilePhone.value,
        RoadAddress__c: data.fields.RoadAddress__c.value,
        CreatedDate: data.fields.CreatedDate.value,
        Latitude__c: data.fields.Latitude__c.value,
        Longitude__c: data.fields.Longitude__c.value,
        Company: data.fields.Company.value,
        fm_Rating__c: data.fields.fm_Rating__c.value,
        ProductId__c: data.fields.ProductId__c.value,
        ProductId__r: {
          Name: data.fields.ProductId__r.value ? data.fields.ProductId__r.value.fields.Name.value : 'N/A'
        }
      }];
      this.selectedProductId = data.fields.ProductId__c?.value;
      console.log('this.leadData ::: ' + JSON.stringify(this.leadData));
      console.log('this.selectedProductId ::: ' + JSON.stringify(this.selectedProductId));

      requestAnimationFrame(() => {
        const convertModalEl = this.template.querySelector("c-product-campaign-table");
        // 다음주 여기에 알맞는 lead 레코드를 파라미터로 던져서 잘 받자.(리드 관리랑 비슷하게 하면 될 듯)
        convertModalEl.getProductByLead(this.leadData);
      })

    } else if (error) {
      console.error('Error fetching record:', error);
    }
  }

  convertHandler() {
    console.log('convertHandler')

    if(this.selectedProductId === '' || typeof this.selectedProductId === 'undefined') {
      showToast("Error", "선택한 차종이 없습니다.", "warning");
      return;
    }

    // const leadList = this.leadData
    //   .map(({ ProductId__r, ...lead }) => lead);

    // console.log('leadList ::: ' + JSON.stringify(leadList))

    // console.log('this.leadData[0] ::: ' + JSON.stringify(this.leadData[0]))
    this.isLoading = true;
    // convertByLead({
    //   checkedLead : leadList[0],
    //   productId : this.selectedProductId,
    //   campaignListString : JSON.stringify(this.selectedCampaignList)
    // }).then(res => {
    const inputMap = {
      'leadId' : this.recordId
      , 'productId' : this.selectedProductId
      , 'campaignIdList' : JSON.stringify(this.selectedCampaignList.map(item => item.id))
      , 'financeId' : null
      , 'totalLoan' : 0
      , 'interestRate' : 0
      , 'duration' : 0
    }
    console.log('inputMap ::: ' + JSON.stringify(inputMap));
    createPreQuote({'inputMap' : inputMap}).then(res => {
      console.log('res ::: ' + res)
      console.log('res ::: ' + JSON.stringify(res))
      const dupType = res['dupType'];
      const accountId = res['accountId'];

      if (dupType === 'error') {
        showToast("Error.", "관리자에게 문의.", "error");
        return;
      }

      // 다른 SA가 소유한 계정 -> 승인 프로세스
      if (dupType === 'otherAcc') {
        // 변경 확인 문구
        LightningConfirm.open({
          message: "담당 매니저에게 승인 요청을 보내겠습니까?",
          // variant: "headerless",
          label: '이미 존재하는 계정 입니다.' // 모달 제목
        }).then(res => {
          if (res) {
            const inputMap = {
              'accountId': accountId
              , 'leadId': this.recordId
            }
            this.isLoading = true;
            callApprovalProcess({'inputMap': inputMap}).then(res => {
              console.log('res ::: ' + JSON.stringify(res));
              const isSuccess = res['isSuccess'];
              const value = res['value'];
              if (isSuccess) {
                showToast("승인프로세스 요청 성공", value, "success");
              } else {
                showToast("승인프로세스 요청 실패", value, "warning");
              }
            }).catch(err => {
              console.log('err ::: ' + JSON.stringify(err))
            }).finally(() => {
              this.isLoading = false
              this.handleCancel()
            })
          }
        });
      } else {
        showToast("Success", "견적이 생성 되었습니다.", "success");
        defaultNavigation(this, "Quote", '', res['value']);
      }
    }).catch(err => {
      console.log("err :: ", err.message);
    }).finally(() => {
      this.isLoading = false;
    });

    // 화면 전환이 없어진다면
    // this.closeModal({ target: { name: 'ConvertOppty' } });
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