/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2025-03-13      jh.jung           Created
 */
import {LightningElement, api, track, wire} from 'lwc';
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";
import {recordNavigation, showToast} from "c/commonUtil";
import {CloseActionScreenEvent} from "lightning/actions";
import {notifyRecordUpdateAvailable} from "lightning/uiRecordApi";

import getAccInfoByOppty from '@salesforce/apex/ModuSignPDFController.getAccInfoByOppty';

import openURL from '@salesforce/apex/InterfaceModuSign.doCallOutDraft';
import signRequestByTemplate from '@salesforce/apex/InterfaceModuSign.doCallOutSignRequestByTemplate';
import formFactor from "@salesforce/client/formFactor";

const options = [
  { label: '세금계산서 주민번호 발행 확인서', value: 'resident-tax-invoice-confirmation' },
  { label: '차량 출고 위임장', value: 'handover-authorization-confirmation' },
];

export default class ModuSignByOppty extends NavigationMixin(LightningElement) {

  templateMap = {
    'resident-tax-invoice-confirmation' : '세금계산서 주민번호 발행 확인서',
    'handover-authorization-confirmation' : '차량 출고 위임장',
  };
  selectedOption;
  accountInfo;
  targetMobilePhone;
  targetName;
  publishQuoteId;

  isLoading = false;

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    this.recordId = currentPageReference.state.recordId;
    console.log('moduSign ::: currentPageReference ::: ' + currentPageReference)
    console.log('moduSign ::: this.recordId ::: ' + this.recordId)
    if (currentPageReference && !this.recordId) {
      this.recordId = currentPageReference.state?.c__opptyId;
    }
    if(this.recordId) {
      this.options = options;
      console.log('this.recordId ::: ' + this.recordId)
      console.log('this.options ::: ' + JSON.stringify(this.options));
      getAccInfoByOppty({recordId : this.recordId}).then(res => {
        this.accountInfo = res['account'];
        this.publishQuoteId = res['publishQuoteId'];
        console.log('this.accountInfo ::: ' + JSON.stringify(this.accountInfo))
        // {"Name":"강호동",
        // "RecordTypeId":"012H2000000FuciIAC",
        // "PersonMobilePhone":"010-9585-3559",
        // "Id":"001H200001a26jeIAA",
        // "RecordType":{"Name":"개인 계정","Id":"012H2000000FuciIAC"}}
        this.targetMobilePhone = this.accountInfo['PersonMobilePhone']
          ? this.accountInfo['PersonMobilePhone']
          : this.accountInfo['Phone']
            ? this.accountInfo['Phone']
            : '';
        this.targetName = this.accountInfo['Name'];
      })
    }
  }

  handleSubmit() {

    // 문서 선택 체크
    if (!this.selectedOption) {
      showToast("Warning", "보낼 문서를 선택해주세요.", "warning");
      return;
    }

    // {"Name":"강호동",
    // "RecordTypeId":"012H2000000FuciIAC",
    // "PersonMobilePhone":"010-9585-3559",
    // "Id":"001H200001a26jeIAA",
    // "RecordType":{"Name":"개인 계정","Id":"012H2000000FuciIAC"}}
    // TODO: 선택한 값의 번호가 010으로 시작 안하면 카톡 못보내니까 물리기
    // const mobilePhone = this.accountInfo['PersonMobilePhone']
    //   ? this.accountInfo['PersonMobilePhone']
    //   : this.accountInfo['Phone']
    //     ? this.accountInfo['Phone']
    //     : '';

    // 카톡 보낼 번호 체크
    console.log('mobilePhone ::: ' + this.targetMobilePhone)
    if (this.targetMobilePhone === undefined || !this.targetMobilePhone.startsWith('010')) {
      showToast("서명을 카톡으로 보낼 번호가 유효하지 없습니다.", "전화번호 : " + this.targetMobilePhone, "warning");
      return;
    }

    // 모두 싸인 템플릿에 서명 요청
    this.callModuSignDraft();
  }

  callModuSignDraft() {
    // Record ID와 Object API Name을 기반으로 Popup 호출
    let infoMap = {
      templateTitle: this.templateMap[this.selectedOption],    // [v] 모두싸인 Template Title명
      recordId: this.publishQuoteId                              // [v] this.recordId // 여기선 Quote로 던짐
    }

    this.isLoading = true;
    openURL({ paramMap : infoMap }).then(async response => {
      let result = response;
      console.log('openURL ::: ' + JSON.stringify(result))

      if(result.code === false) {
        showToast("Warning", "관리자에게 문의 바랍니다.", "warning");
        return;
      }
      const isSuccess = await this.callModuSignRequest();
      console.log("isSuccess :: ", isSuccess);
      if(isSuccess === true) {
        // 추후 카톡 필요하면 수정해서 사용
        // this.callKakaoAlimTalk().then(res => {
        //   if(res) {
        //     // 카톡 전송 success
        //     showToast("Success", "서명을 요청하였습니다.", "success");
        //   } else {
        //     // 카톡 전송 fail
        //     showToast("Success", "서명은 요청하였으나 카톡이 전송되지 않았습니다. 관리자에게 문의 바랍니다.", "success");
        //   }
        // })
        showToast("Success", "서명을 요청하였습니다.", "success");
        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
        this.handleCancel();
      } else {
        // 모두사인 전송 fail
        showToast("Warning", "서명 요청에 실패하였습니다. 관리자에게 문의 바랍니다", "warning");
        return;
      }
    }).catch(err => {
      console.log('err ::: ' + err.message);
      showToast("Error", "서명 요청에 실패하였습니다. 관리자에게 문의 바랍니다", "error");
    }).finally(() => {
      this.isLoading = false;
    })
  }

  // 모두싸인 서명요청
  async callModuSignRequest() {
    console.log('callModuSignRequest ::: ')

    // 서명요청받을 사용자 List, 고객은 Account. 내부 사용자는 User 등등.... 동적으로 데이터 요청
    let infoMapList = [
      {
        recordId: this.accountInfo['Id'],
        sendType: 'KAKAO',
        role: '고객',
      },
    ];

    // 문서정보 Setting
    let infoMap = {
      templateTitle: this.templateMap[this.selectedOption],           // [v] 모두싸인 Template Title명
      recordId: this.publishQuoteId,             // [v] this.recordId  // 여기선 Quote로 던짐
      documentTitle: this.templateMap[this.selectedOption],           // 문서 Title명
      infoMapList: infoMapList,            // [v] 사용자 정보 Input
      externalId: this.recordId           // 외부연결 Id  // externalId는 oppty로
    };

    let isSuccess = false;
    await signRequestByTemplate({ paramMap: infoMap }).then(res => {
      console.log("signRequestByTemplate res ::: " + JSON.stringify(res));
      if (res.statusCode === 201) {
        isSuccess = true;

      }
    }).catch(err => {
      console.log("err :::" + err.message);
      isSuccess = false;
    })
    return isSuccess;
  }

  handleChange(e) {
    this.selectedOption = e.detail.value;
    console.log('selected template ::: ' + this.templateMap[this.selectedOption]);
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
    this.mobileReturnPage();
  }

  mobileReturnPage() {
    if(formFactor === "Small") {
      recordNavigation(this, "Opportunity", this.recordId);
    }
  }

}