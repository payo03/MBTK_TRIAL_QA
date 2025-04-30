/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-01-06
 * @description : 계약 레코드 상세 페이지에서 버튼 클릭시 deposit 사전배정요청 생성
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-12-31      chaebeom.do     Created
 * 1.1          2025-04-07      chaebeom.do     요청시 고객코드/사업자명/사업자번호 체크
 * 1.2          2025-04-18      chaebeom.do     사업자번호 체크 주민등록번호와 OR 조건으로 수정
 * 1.3          2025-04-29      chaebeom.do     AssignRequest__c 오브젝트 삭제로 로직 수정
 **************************************************************/
import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";

//library
import getAcc from "@salesforce/apex/DepositInvoiceController.getAcc";
import assignVirtualAccount from "@salesforce/apex/DepositInvoiceController.assignVirtualAccount";
import updateContract from "@salesforce/apex/DepositInvoiceController.updateContract";
import kakaoAlimTalk from "@salesforce/apex/InterfaceKakao.doCallOutKakaoAlimTalk";
import formFactor from "@salesforce/client/formFactor";

// Util
import { showToast, recordNavigation } from "c/commonUtil";


export default class DepositInvoice extends LightningElement {
  @api recordId;
  @track isLoading = false;
  selectedAcc = {};
  deposit = 1000000;

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
      this.isLoading = true;
      getAcc({recordId: this.recordId}).then(res => {
        Object.assign(this.selectedAcc, {
          ...res,
        });
      }).finally(() => this.isLoading = false);
    }

    // ver 1.1 요청시 account의 고객코드/사업자명/사업자 번호 필드가 없으면 에러 토스트 발생 및 어떤 필드 값이 비었는지 표시
  sendDeposit() {
    if (!this.selectedAcc.bpCode || !this.selectedAcc.businessName || (!this.selectedAcc.businessNumber && !this.selectedAcc.idNumber)) { //ver 1.2
      let required = ["", "", ""];
      if(!this.selectedAcc.bpCode) required[0] = "고객코드";
      if(!this.selectedAcc.businessName) required[1] = "사업자명";
      if(!this.selectedAcc.businessNumber && !this.selectedAcc.idNumber) required[2] = "사업자번호 또는 주민등록번호";
      const filteredRequired = required.filter(str => str && str.trim());
      let msg = "계정의 다음 필드를 입력해주세요. : " + filteredRequired.join(", ");
      showToast("필수 항목이 빈 값입니다.", msg, "error");
      return;
    }
    if (this.deposit == null) {
      showToast("필수 입력", "계약금을 입력해주세요.", "error");
    } else {
      // let inputMap = { opptyId: this.selectedAcc.opportunity, deposit: this.deposit, stockId: this.selectedAcc.vehicleId, contractId: this.recordId, type: 'deposit' };
      let inputMap = { opptyId: this.selectedAcc.opportunity, deposit: this.deposit, stockId: this.selectedAcc.vehicleId, contractId: this.recordId};
      this.isLoading = true;
      assignVirtualAccount({inputMap: inputMap}).then(res => {
        this.callKakaoAlimTalk(res);
      }).catch(err => {
        showToast("계약금 요청 실패", "관리자에게 문의 바랍니다.", "error");
        console.log("err depositInvoice :: ", err)
        this.isLoading = false;
        this.handleCancel();
      })
    }
  }

  callKakaoAlimTalk(inputMap) {
    console.log('인풋맵 :: ' + JSON.stringify(inputMap));
    console.log('가상계좌 Id :: ' + inputMap.recordId);
    // 수신자의 데이터 Record
    let infoMapList = [
      {
        objectName: "Account",
        // recordId: '001H200001ZKbj8IAD' // < 테스트용 카톡 수신자 (도채범)
        recordId: inputMap.accId, // < 실제 사용
      },
    ];

    // 템플릿. 변수명에 해당하는 데이터 RecordId
    let infoMap = {
      templateTitle: "가상계좌정보 전송2", // [v] 카카오톡 Template명
      object: "VirtualAccount__c", // 카카오톡 Body에 설정될 Object명
      recordId: inputMap.recordId, // [v] 카카오톡 Body에 설정될 recordId
      infoMapList: infoMapList, // [v] 카카오톡 수신데이터 설정
      // buttonMap: buttonMap, // 카카오톡 버튼 정보
      externalId: inputMap.accId, // 외부연결 Id
    };

    kakaoAlimTalk({ paramMap: infoMap })
      .then((response) => {
        let result = response;
        console.log("카톡 전송 결과::: " + JSON.stringify(result));
        if(result.code === true) {
          showToast("전송 완료", "계약금 요청을 고객에게 전송하였습니다.", "success");
          this.updateContract();
        } else {
          showToast("카톡 전송 실패", "관리자에게 문의 바랍니다.", "error");
        }
      })
      .catch((error) => {
        showToast("카톡 전송 실패", "관리자에게 문의 바랍니다.", "error");
        console.log("카톡 전송 실패::: " + error);
        this.isLoading = false;
        this.handleCancel();
      });
  }

  updateContract() {
    updateContract({recordId: this.recordId}).finally(() => {
      this.isLoading = false;
      notifyRecordUpdateAvailable([{recordId: this.recordId}]);
      this.handleCancel();
    });
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
    this.mobileReturnPage();
  }

  mobileReturnPage() {
    if(formFactor === "Small") {
      recordNavigation(this, "Contract", this.recordId);
    }
  }
}