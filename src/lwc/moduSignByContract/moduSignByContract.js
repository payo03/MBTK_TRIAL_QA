/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2024-12-31      jh.jung           Created
 */
import {LightningElement, api, track, wire} from 'lwc';
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";
import {recordNavigation, showToast} from "c/commonUtil";
import {CloseActionScreenEvent} from "lightning/actions";
import {notifyRecordUpdateAvailable} from "lightning/uiRecordApi";
// import INTERNAL_USER from '@salesforce/label/c.MTBK_Internal_Modusign'

import userId from '@salesforce/user/Id';

// import createPDFBySFDC from '@salesforce/apex/ModuSignPDFController.generatePdfBlob';
import asyncGeneratePdfBlob from '@salesforce/apex/ModuSignPDFController.asyncGeneratePdfBlob';
import getAccountInfo from '@salesforce/apex/ModuSignPDFController.getAccountInfo';
// import createPreAssignRequest from "@salesforce/apex/CreatePreAssignRequestController.createPreAssignRequest";

import kakaoAlimTalk from '@salesforce/apex/InterfaceKakao.doCallOutKakaoAlimTalk';
import openURL from '@salesforce/apex/InterfaceModuSign.doCallOutDraft';
import signRequestByTemplate from '@salesforce/apex/InterfaceModuSign.doCallOutSignRequestByTemplate';
import formFactor from "@salesforce/client/formFactor";
// import doCallOutSignRequestByPDF from '@salesforce/apex/InterfaceModuSign.doCallOutSignRequestByPDF';
// import savePDF from '@salesforce/apex/InterfaceModuSign.doCallOutURLtoPDF';

// import getQuoteId from '@salesforce/apex/InterfaceModuSign.getQuoteId';


// const RIO_PAGE = 3;
// const CHECKBOX_SIZE = [0.02, 0.02];
// const SIGNATURE_SIZE = [0.142, 0.06];
// const TEXT_SIZE_LARGE = [0.330, 0.022];
// const TEXT_SIZE_SMALL = [0.145, 0.022];

const options = [
  { label: '계약서 + RIO & MDS', value: 'all' },
  { label: '계약서', value: 'contract' },
  { label: 'RIO & MDS', value: 'riomds' },
  { label: '차량 보관', value: 'storage' },
];

const optionsNoMds = [
  { label: '계약서', value: 'contract' },
  { label: 'RIO & MDS', value: 'riomds' },
  { label: '차량 보관', value: 'storage' },
];

const columns = [
  { label: '이름', fieldName: 'Name', type: 'text', hideDefaultActions: true, wrapText: true },
  { label: '도로명 주소', fieldName: 'RoadAddress', type: 'text', hideDefaultActions: true, wrapText: true },
  { label: '번호', fieldName: 'MobilePhone', type: 'text', hideDefaultActions: true, wrapText: true },
  { label: '정보', fieldName: 'Info', type: 'text', hideDefaultActions: true, wrapText: true }
];

export default class ModuSignByContract extends NavigationMixin(LightningElement) {

  recordId;
  internalUserId;

  accountName;
  @track options;
  columns;

  isPersonAccount;
  isRioMds;

  rows = [];
  rowsNoRealDriver = [];

  @track isLoading = false;
  @track tableData = [];
  @track selectedOption = '';

  @track selectedRows;
  selectedRowInfo;
  selectedLanguage = 'KR';

  // @wire(CurrentPageReference) pageRef;
  //
  // connectedCallback() {
  //   this.recordId = this.pageRef.state.recordId;
  //   // this.onlyContractFlag = false;
  //   this.options = options;
  //   this.columns = columns;
  //   this.isRioMds = false;
  //   this.selectedRows = []
  //   this.getAccountInfo();
  // }

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    this.recordId = currentPageReference.state.recordId;
    console.log('moduSign ::: currentPageReference ::: ' + currentPageReference)
    console.log('moduSign ::: this.recordId ::: ' + this.recordId)
    if (currentPageReference && !this.recordId) {
      this.recordId = currentPageReference.state?.c__contractId;
    }
    if(this.recordId) {
        // this.options = options;
        this.columns = columns;
        this.isRioMds = false;
        this.selectedRows = []
        this.getAccountInfo();
    }
  }

  // 한영 PDF - choi 추가
  // get radioOptions() {
  //   return [
  //       { label: '한글', value: 'KR' },
  //       { label: '영어', value: 'EN' },
  //   ];
  // }

  getAccountInfo() {
    const rows = [];
    const rowsNoRealDriver = [];
    getAccountInfo({recordId : this.recordId}).then(res => {
      console.log('res.opptyInfo.NoMDSStatus__c ::: ' + res.opptyInfo.NoMDSStatus__c)
      if(res.opptyInfo.NoMDSStatus__c === '승인됨') {
        this.options = optionsNoMds;
      } else {
        this.options = options;
      }
      console.log('this.options ::: ' + JSON.stringify(this.options));

      const accountObj = res.account;
      this.internalUserId = res.internalUser.Id;
      this.accountName = accountObj.Name;
      this.isPersonAccount = (accountObj.RecordType.DeveloperName !== 'ACCOUNT_CORPORATE');

      let i = 0;
      // setList 안에 idx : i++ 을 하니 이상하게 들어감
      const setList = (rows, idx, id, name, roadAddress, phone, info, postalCode, detailAddress) => {
        rows.push({
          idx : idx,
          Id : id,
          Name : name,
          RoadAddress : roadAddress,
          MobilePhone : phone,
          Info : info,
          PostalCode : postalCode,
          DetailAddress : detailAddress
        });
      }

      // 개인 번호 없으면 -> 회사 레코드
      if(!this.isPersonAccount) {
        setList(rows, i++, accountObj.Id, accountObj.Name, accountObj.RoadAddress__c, accountObj.Phone, '회사', accountObj.PostalCode__c, accountObj.DetailAddress__c);
        setList(rowsNoRealDriver, i++, accountObj.Id, accountObj.Name, accountObj.RoadAddress__c, accountObj.Phone, '회사', accountObj.PostalCode__c, accountObj.DetailAddress__c);
      }

      accountObj.Contacts.forEach(con => {
        setList(rows, i++, con.Id, con.Name, con.RoadAddress__c, con.MobilePhone, '고객', con.PostalCode__c, accountObj.DetailAddress__c);
        setList(rowsNoRealDriver, i++, con.Id, con.Name, con.RoadAddress__c, con.MobilePhone, '고객', con.PostalCode__c, accountObj.DetailAddress__c);

        if(con.RealDriverMobile__c !== undefined) {
          setList(rows, i++, con.Id, con.RealDriver__c, con.RealDriverAddress__c, con.RealDriverMobile__c, '실차주', '', accountObj.DetailAddress__c);
        }
      })

      this.rows = rows;
      this.rowsNoRealDriver = rowsNoRealDriver;
    })
  }

  handleRowSelection(e) {
    this.selectedRows = e.detail.selectedRows?.map(el => el.idx);
    this.selectedRowInfo = e.detail.selectedRows[0];

    console.log('this.selectedRows :::', JSON.stringify(this.selectedRows));
    console.log('this.selectedRowInfo :::', JSON.stringify(this.selectedRowInfo));
  }

  handleChange(e) {
    this.selectedOption = e.detail.value;
    if(this.selectedOption === 'all') {
      this.isRioMds = true;
      this.tableData = this.rowsNoRealDriver;
    } else if(this.selectedOption === 'riomds') {
      this.isRioMds = true;
      this.tableData = this.rows;
    } else {
      this.isRioMds = false;
      this.tableData = this.rows;
    }
    this.selectedRows = [];
    this.selectedRowInfo = null;
  }

  // 한영 PDF - choi 추가 
  // handleLanguageChange(event) {
  //   this.selectedLanguage = event.detail.value;
  // }

  handleSubmit() {
    // console.log('Language :: ' + this.selectedLanguage);
    
    // Pdf 한영 버전 체크 - 최
    // if(!this.selectedLanguage) {
    //   showToast("Warning", "계약서의 언어를 선택해주세요.", "warning");
    //   return;
    // }
    
    // 문서 선택 체크
    if (!this.selectedOption) {
      showToast("Warning", "보낼 문서를 선택해주세요.", "warning");
      return;
    }

    // 서명 대상 체크
    if (this.selectedRows.length === 0) {
      showToast("Warning", "서명을 요청할 대상을 선택해주세요.", "warning");
      return;
    }

    // TODO: 선택한 값의 번호가 010으로 시작 안하면 카톡 못보내니까 물리기
    // 카톡 보낼 번호 체크
    console.log('MobilePhone ::: ' + this.selectedRowInfo.MobilePhone)
    if (this.selectedRowInfo.MobilePhone === undefined || !this.selectedRowInfo.MobilePhone.startsWith('010')) {
      showToast("Warning", "서명을 카톡으로 보낼 번호가 유효하지 없습니다.", "warning");
      return;
    }

    if(this.selectedOption === "storage") {
      // 모두 싸인 템플릿에 서명 요청
      this.callModuSignDraft();
    } else {
      // 그 이외에는 PDF 생성
      // this.createPDFAndCallModusign()

      // 03/28 비동기
      this.isLoading = true;
      asyncGeneratePdfBlob({recordId : this.recordId, selectedOption : this.selectedOption, signInfo : this.selectedRowInfo, language: this.selectedLanguage}).then(() => {
        console.log('asyncGeneratePdfBlob :::')

        showToast("Success", "서명을 요청하였습니다. 알림 발송내역을 확인해주세요.", "success");

        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
        this.handleCancel();
      }).finally(() => { this.isLoading = false; })
    }
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

  // 비동기로 대체함
  // 1. 계약서 + RIO + MDS
  // 2. only 계약서
  // 3. RIO + MDS
  // createPDFAndCallModusign() {
  //   this.isLoading = true;
  //   createPDFBySFDC({recordId : this.recordId, selectedOption : this.selectedOption, signInfo : this.selectedRowInfo, language: this.selectedLanguage}).then(res => {
  //
  //     // PDF 바로 보이기용 테스트 - 실제론 필요없음
  //     // if(res.pdfBase64 !== undefined) {
  //
  //     //   const byteCharacters = atob(res.pdfBase64); // Base64 디코딩
  //     //   const byteNumbers = new Array(byteCharacters.length);
  //     //   for (let i = 0; i < byteCharacters.length; i++) {
  //     //     byteNumbers[i] = byteCharacters.charCodeAt(i);
  //     //   }
  //     //   const byteArray = new Uint8Array(byteNumbers);
  //     //   const blob = new Blob([byteArray], { type: 'application/pdf' });
  //
  //     //   // Pdf 한영버전을 위한 코드 추가 - 최
  //     //   const languageSuffix = this.selectedLanguage === 'KR' ? 'ko' : 'en';
  //     //   // this.selectedLanguage = 'ko';
  //
  //     //   // Blob URL 생성
  //     //   // this.pdfUrl = URL.createObjectURL(blob);
  //     //   this.pdfUrl = URL.createObjectURL(blob) + `#lang=${languageSuffix}`;
  //
  //     //   window.open(this.pdfUrl, '_blank');
  //
  //     //   console.log('this.recordId ::: ' + this.recordId)
  //     //   console.log('this.selectedRowInfo["Id"] :::' + this.selectedRowInfo["Id"])
  //     //   console.log('this.selectedOption ::: ' + this.selectedOption)
  //     //   // 카톡 임시 추가
  //     //   this.callKakaoAlimTalk(this.recordId, this.selectedRowInfo["Id"], this.selectedOption).then(res => {
  //     //     if(res) {
  //     //       // 카톡 전송 success
  //     //       showToast("Success", "서명을 요청하였습니다.", "success");
  //     //     } else {
  //     //       // 카톡 전송 fail
  //     //       showToast("Success", "서명은 요청하였으나 카톡이 전송되지 않았습니다. 관리자에게 문의 바랍니다.", "success");
  //     //     }
  //     //   })
  //     //   return;
  //     // }
  //     // PDF 바로 보이기용 테스트 끝 - 실제론 필요없음
  //
  //     if(res.statusCode === 201) {
  //       // 모두사인 전송 success
  //       console.log('모두사인 요청 success')
  //       this.callKakaoAlimTalk(this.recordId, this.selectedRowInfo["Id"], this.selectedOption).then(res => {
  //         if(res) {
  //           // 카톡 전송 success
  //           console.log('카톡 요청 success')
  //           showToast("Success", "서명을 요청하였습니다.", "success");
  //         } else {
  //           // 카톡 전송 fail
  //           console.log('카톡 요청 fail')
  //           showToast("Success", "서명은 요청하였으나 카톡이 전송되지 않았습니다. 관리자에게 문의 바랍니다.", "success");
  //         }
  //
  //         notifyRecordUpdateAvailable([{recordId: this.recordId}]);
  //         this.handleCancel();
  //       })
  //     } else {
  //       // 모두사인 전송 fail
  //       showToast("서명 요청에 실패하였습니다.",res.errorMessage, "warning");
  //     }
  //   }).catch(err => {
  //     // TODO: toast 처리 필요
  //     console.log('err :::' + err.message);
  //     showToast("Error", "서명 요청에 실패하였습니다. 관리자에게 문의 바랍니다", "error");
  //   }).finally(() => {
  //     this.isLoading = false;
  //   })
  // }

  // 계약서 보내면서 계약금 요청도 같이 진행
  // anycs callDepositRequest() {
  //   let inputMap = {
  //     recordId: this.opptyId
  //     , deposit: 1000000
  //     , stockId: this.stockId
  //     , contractId: this.recordId
  //     , type: 'deposit'
  //   };
  //   this.isLoading = true;
  //   createPreAssignRequest({inputMap: inputMap}).then(res => {
  //
  //   })
  // }

  // TODO: 카톡 발송 - 4가지 케이스 다 다르게 해야 함
  async callKakaoAlimTalk(contractId, sendId, selectedOption) {
    // 수신자의 데이터 Record

    const TEMPLATEMAP = {
      all : '계약서 및 MDS/RIO 동의서 서명 요청',
      contract : '계약서 서명 요청',
      riomds : 'MDS/RIO 동의서 서명 요청',
      storage : '차량보관확인서 서명요청',
    };

    let infoMapList = [
      {
        recordId: sendId,  // contactId임
        customerType: (this.selectedRowInfo.Info === '실차주') ? 'realdriver' : 'owner'
      }
    ];

    // 템플릿. 변수명에 해당하는 데이터 RecordId
    let infoMap = {
      templateTitle: TEMPLATEMAP[selectedOption],   // [v] 카카오톡 Template명
      recordId: contractId,                         // [v] 카카오톡 Body에 설정될 recordId
      infoMapList: infoMapList,                     // [v] 카카오톡 수신데이터 설정
      externalId: contractId                        // 외부연결 Id
    };

    let result = false;
    await kakaoAlimTalk({paramMap : infoMap}).then(response => {
      result = true;
      console.log('카톡결과::: ' + JSON.stringify(response));
    }).catch(err => {
      result = false;
      console.log('카톡에러::: ' + err.message);
    });
    return result;
  }

  // Vehicle Storage는 템플릿으로 호출
  callModuSignDraft() {
    // Record ID와 Object API Name을 기반으로 Popup 호출
    let infoMap = {
      // templateTitle: '차량보관증',                              // [v] 모두싸인 Template Title명
      templateTitle: '차량보관증_확정',                              // [v] 모두싸인 Template Title명
      object: 'Contract',                                        // this.objectApiName
      recordId: this.recordId                                  // [v] this.recordId
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
        this.callKakaoAlimTalk(this.recordId, this.selectedRowInfo["Id"], this.selectedOption).then(res => {
          if(res) {
            // 카톡 전송 success
            showToast("Success", "서명을 요청하였습니다.", "success");
          } else {
            // 카톡 전송 fail
            showToast("Success", "서명은 요청하였으나 카톡이 전송되지 않았습니다. 관리자에게 문의 바랍니다.", "success");
          }
        })
        // showToast("Success", "서명을 요청하였습니다.", "success");
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
        recordId: this.selectedRowInfo.Id,
        // validDuration: 14,
        sendType: 'KAKAO',
        // role: this.selectedRowInfo.Info,
        role: '고객',
        customerType: (this.selectedRowInfo.Info === '실차주') ? 'realdriver' : 'owner'
      },
      {
        // recordId: INTERNAL_USER,
        recordId: this.internalUserId,
        // validDuration: 14,
        sendType: 'KAKAO',
        role: 'Internal',
      }
    ];

    // 문서정보 Setting
    let infoMap = {
      // templateTitle: '차량보관증',           // [v] 모두싸인 Template Title명
      templateTitle: '차량보관증_확정',           // [v] 모두싸인 Template Title명
      object: 'Contract',                  // this.objectApiName
      recordId: this.recordId,             // [v] this.recordId
      // recordId: '800H2000000EmrvIAC',   // [v] this.recordId
      documentTitle: '차량 보관',           // 문서 Title명
      infoMapList: infoMapList,            // [v] 사용자 정보 Input
      externalId: this.recordId           // 외부연결 Id
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
}