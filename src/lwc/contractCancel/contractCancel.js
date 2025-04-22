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
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { showToast, recordNavigation } from "c/commonUtil";
import { CloseActionScreenEvent } from "lightning/actions";

import init from "@salesforce/apex/ContractCancelController.init";
import getPicklistValues from "@salesforce/apex/ContractCancelController.getPicklistValues";
import cancelByCase from "@salesforce/apex/ContractCancelController.cancelByCase";
import formFactor from "@salesforce/client/formFactor";

export default class ContractCancel extends NavigationMixin(LightningElement) {
  @api recordId;
  isLoading = false;
  contractNo;

  // 실주 사유 변수
  @track lostReasons = {};
  @track selectedValues = {};
  picklistFields = [
    "CompetitorSelection__c",
    "EconomicReasons__c",
    "PersonalReasons__c",
    "TechnicalReasons__c",
  ];

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference) {
      this.recordId = currentPageReference.state.recordId;
    }
    if (currentPageReference && !this.recordId) {
      this.recordId = currentPageReference.state?.c__recordId;
    }
  }

  connectedCallback() {
    init({ recordId: this.recordId })
      .then((result) => {
        this.contractNo = result.Contract.ContractNumber;
      })
      .catch((error) => {
        showToast("Error", "Error init()", "error", "dismissable");
        console.log("error :: ", error);
      });
    this.getPicklist();
  }

  //실주 사유 픽리스트 값 가져오기
  getPicklist() {
    getPicklistValues({
      objectName: "Opportunity",
      fieldNames: this.picklistFields,
    })
      .then((result) => {
        this.picklistFields.forEach((field) => {
          this.lostReasons[field] = result[field].map((value) => ({
            label: value,
            value: value,
          }));
          this.selectedValues[field] = []; // 초기 선택값은 빈 배열
        });
      })
      .catch((error) => {
        console.error("Error fetching picklist values:", error);
      });
  }

  //실주 사유 선택
  handleChange(e) {
    const fieldName = e.target.name; // dual-listbox의 name 속성으로 필드명 지정
    this.selectedValues[fieldName] = e.detail.value;
    console.log('선택값 :: ' + JSON.stringify(this.selectedValues));
  }

  //선택 취소
  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
    this.mobileReturnPage();
  }

  mobileReturnPage() {
    if (formFactor === "Small") {
      recordNavigation(this, "Contract", this.recordId);
    }
  }

  //계약 취소 실행
  handleCancelContract() {
    this.isLoading = true;
    cancelByCase({ type: "closedLost", opptyId: this.recordId, selectedValues: this.selectedValues })
      .then((result) => {
        console.log("result :: ", result);
        showToast(
          "취소 완료",
          "계약을 취소하고 기회를 실주 처리했습니다.",
          "success"
        );
      })
      .catch((error) => {
        showToast("Error", "Error cancelContract", "error", "dismissable");
        console.log("error :: ", error);
      })
      .finally(() => {
        this.handleCancel();
        this.isLoading = false;
        setTimeout(() => {
          location.reload();
        }, 1000);
      });
  }
}
