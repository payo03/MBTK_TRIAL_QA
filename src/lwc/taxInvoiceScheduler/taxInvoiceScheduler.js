/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2025-01-22      jh.jung           Created
 */
import {LightningElement, api, track} from 'lwc';
import LightningConfirm from 'lightning/confirm';

import getInit from "@salesforce/apex/TaxInvoiceSchedulerController.getInit";
import getFilteredHandoverList from "@salesforce/apex/TaxInvoiceSchedulerController.getFilteredHandoverList";
import createPDFBySFDC from "@salesforce/apex/TaxInvoiceSchedulerController.generatePdfBlob"
import callTaxInvoice from "@salesforce/apex/TaxInvoiceSchedulerController.callTaxInvoice"

// import getCalendarInit from "@salesforce/apex/TaxInvoiceSchedulerController.getCalendarInit"
// import getHandoverDateList from "@salesforce/apex/TaxInvoiceSchedulerController.getHandoverDateList"
// import getOpptyListByHandoverDate from "@salesforce/apex/TaxInvoiceSchedulerController.getOpptyListByHandoverDate"
// import updateHandoverDate from "@salesforce/apex/TaxInvoiceSchedulerController.updateHandoverDate"
// import insertHandoverDateAllocationHistory from "@salesforce/apex/TaxInvoiceSchedulerController.insertHandoverDateAllocationHistory"

import { columns, fieldApiMapping, contractStatusStyles, vehicleStatusStyles, paymentStatusStyles } from "./taxInvoiceSchedulerColumns";
import {showToast, getFormattedDate, labelList} from "c/commonUtil";
import formFactor from "@salesforce/client/formFactor";
import {notifyRecordUpdateAvailable} from "lightning/uiRecordApi";

export default class TaxInvoiceScheduler extends LightningElement {

  columns = columns;
  contractStatusStyles = contractStatusStyles;
  vehicleStatusStyles = vehicleStatusStyles;
  paymentStatusStyles = paymentStatusStyles;
  vfHost = labelList.VFHost;

  // @track _parentData;

  handoverList;
  @track optionDelayList;
  paymentStatusOption;
  isSalesManager = false;

  selectedRows = [];
  selectedRowInfo;

  selectedHandoverDateRow;

  initFilterMap;
  @track filterMap;
  @track isLoading = false;

  @track filterOptionMap = {
    paymentStatusOption: [{ label: "선택안함", value: "" }]
  };

  // calendar로 잠시 사용
  isCalendarModal = false;
  // isUpdatingData = false; // 데이터 변경 중인지 확인하는 플래그

  @track handoverDateList = [];
  // @track opptyList = [];

  @track selectedRowsOppty = [];
  selectedRowInfoOppty;
  @track selectedDate = '';

  opptycolumns = [
    {
      label: "기회이름",
      fieldName: "Name",
      type: "text"
    },
    {
      label: "입금상태",
      fieldName: "PaymentStatus__c",
      type: "text"
    },
  ];

  connectedCallback() {
    console.log("connectedCallback");
    // calendar로 잠시 사용
    // window.addEventListener("message", this.getDataFromChild.bind(this));

    // 초기값 : from : 이전달 1일, to : 다음달 말일
    const today = new Date();
    const fromDate = getFormattedDate(new Date(today.getFullYear(), today.getMonth() -1, 1));
    const endDate = getFormattedDate(new Date(today.getFullYear(), today.getMonth() + 2, 0));

    this.filterMap = this.initFilterMap = {
      paymentStatus: "",
      startDate: '=' + fromDate,
      endDate: '=' + endDate,
      searchAccountName: "",
      searchSalesAgentName: ""
    };

    this.isLoading = true;
    getInit().then(res => {
      console.log('getInit:::')

      this.handoverList = res.taxInvoiceHandoverList;
      if(res.userProfileName !== "MTBK Agent") {
        this.isSalesManager = true;
      } else {
        this.isSalesManager = false;
      }

      this.filterOptionMap.paymentStatusOption = [
        ...this.filterOptionMap.paymentStatusOption,
        ...res.paymentStatusOption];

      this.filterRefresh();
      this.setCssField();
    }).catch(err => {
      console.log('err ::: ' + JSON.stringify(err));
    }).finally(() => this.isLoading = false);


  }

  filterRefresh() {
    console.log('filterRefresh')
    this.filterMap = { ...this.initFilterMap };
    console.log('this.filterMap ::: ' + JSON.stringify(this.filterMap))
  }

  setCssField() {
    this.handoverList = this.handoverList.map((item) => ({
      ...item,
      contractStatusCss : this.contractStatusStyles[item.conStatus] || 'color: black; font-weight: normal;',
      vehicleStatusCss : this.vehicleStatusStyles[item.vehicleStatus] || 'color: black; font-weight: normal;',
      paymentStatusCss : this.paymentStatusStyles[item.paymentStatus] || 'color: black; font-weight: normal;',
    }));
  }

  getFilteredList() {

    let filterMap = {};

    Object.keys(this.filterMap).forEach(el => {
      filterMap[fieldApiMapping[el]] = this.filterMap[el];
    });

    this.isLoading = true;
    getFilteredHandoverList({ filterMap: filterMap }).then(res => {
      console.log("res :: ", res);
      this.handoverList = res;
      this.setCssField();
    }).catch(err => {
      console.log("err :: ", err);
    }).finally(() => this.isLoading = false);
  }

  handleHeaderClick(e) {
    const name = e.target.dataset.name;

    // Calendar로 임시 추가 ::: 2/6
    // if(name === "calendar") {
    //
    //   this.isLoading = true;
    //   this.openModal();
    //   return;
    // }

    if(this.selectedRows.length === 0) {
      let title = '';
      if(name === "taxInvoicePublish")  title = '발행 요청 실패';
      if(name === "taxInvoiceCancel")  title = '취소 요청 실패';
      if(name === "depositReceipt")  title = '영수증 호출 실패';
      showToast(title, '대상을 선택하세요', 'warning');
      return;
    }
    if(name === "taxInvoicePublish") {
      LightningConfirm.open({
        message: "[" + this.selectedRowInfo.vehicleStock.Name + "] 수입부대비용 입력여부 확인 바람",
        // variant: "headerless",
        label: '세금 계산서 발행' // 모달 제목
      }).then(res => {
        if (res) {
          this.taxInvoiceProcess(true);
        }
      })
    }
    if(name === "taxInvoiceCancel") {
      this.taxInvoiceProcess(false)
    }
    if(name === "depositReceipt") {
      this.createDepositReceiptPDF();
    }
  }

  taxInvoiceProcess(isCreate) {
    let title = '';
    let message = '';

    if(isCreate === false && (this.selectedRowInfo.opp.TaxInvoiceDate__c === undefined || this.selectedRowInfo.opp.TaxInvoiceDate__c === '')) {
      showToast('취소 요청 실패', '세금 계산서 요청이 되어 있지 않은 기회 입니다.', 'warning');
      return;
    }

    this.isLoading = true;
    callTaxInvoice({opptyId: this.selectedRowInfo.opp.Id, isCreate: isCreate}).then( () => {
      if(isCreate === true) {
        title = '세금 계산서 발행';
        message = '발행요청을 하였습니다.'
      } else {
        title = '세금 계산서 취소';
        message = '취소요청을 하였습니다.'
      }
      showToast(title, message, 'success');
    }).finally(() => { this.isLoading = false;})
  }

  // Calendar로 임시 추가 Start
  // openModal() {
  //   console.log('this.selectedHandoverDateRow ::: ' + this.selectedHandoverDateRow)
  //   getCalendarInit({vehicleStockId : this.selectedHandoverDateRow['vehicleStock']['Id']}).then((res) => {
  //     this.handoverDateList = res.handoverDateList;
  //     this.optionDelayList = res.optionDelayList;
  //     this.isCalendarModal = true;
  //     this.optionDelayList.sort((a, b) => a.Attribute2__c - b.Attribute2__c);
  //
  //     const baseClass = "slds-m-bottom_small";
  //     this.optionDelayList.map(option => {
  //       option.isAssign = (option.Attribute2__c == res.diffDays) ? true : false;
  //
  //       option.className = (option.Attribute2__c == res.diffDays)
  //         ? `${baseClass} slds-text-color_error slds-text-heading_large`
  //         : `${baseClass} slds-text-heading_medium`;
  //     })
  //     console.log('this.optionDelayList ::: ' + JSON.stringify(this.optionDelayList))
  //
  //
  //     // console.log('this.handoverDateList ::: ' + JSON.stringify(this.handoverDateList));
  //   })
  // }
  //
  // closeModal() {
  //   this.isCalendarModal = false;
  //   this.selectedRowsOppty = [];
  //   this.selectedRowInfoOppty = '';
  //   // this.opptyList = [];
  // }
  //
  // get modalClass() {
  //   const defaultClass = "slds-modal__content";
  //   const headlessClass = `${defaultClass} slds-modal__content_headless`;
  //   return this.isModalHeader ? defaultClass : headlessClass;
  // }
  //
  // handleLoad(e) {
  //   // iframe의 윈도우 객체를 저장
  //   this.iframeWindow = e.target.contentWindow;
  //
  //   // VF 페이지로 초기 데이터를 전송
  //   const initialData = {
  //     type: 'INIT_DATA',
  //     target: 'calendar',
  //     event: this.handoverDateList,
  //     selectedDay: this.selectedHandoverDateRow['handoverDate']
  //   };
  //
  //   // VF 페이지로 데이터 전송
  //   this.iframeWindow.postMessage(initialData, '*');
  //
  //   // this.isLoading = false;
  // }
  //
  // async getDataFromChild(e) {
  //   // console.log("origin :: ", e.origin);
  //   // console.log("vfHost :: ", this.vfHost);
  //
  //   if (this.vfHost !== e.origin || e.data.target !== "calendar") return;
  //
  //   // console.log('e ::: ' + JSON.stringify(e));
  //   // console.log('e.data ::: ' + JSON.stringify(e.data));
  //   // console.log('e.data.type ::: ' + e.data.type);
  //
  //
  //   const type = e.data.type;
  //   let value = '';
  //   // if(type === 'dateClick') {
  //   //   this.selectedDate = e.data.dateStr;
  //   //   value = '0/6';
  //   // }
  //   if(type === 'eventClick') {
  //     this.selectedDate = e.data.event.start;
  //     value = e.data.event.title;
  //   }
  //
  //   console.log('this.selectedDate' + this.selectedDate)
  //   console.log('this.selectedHandoverDateRow[\'handoverDate\']' + this.selectedHandoverDateRow['handoverDate'])
  //
  //   if(this.selectedDate === this.selectedHandoverDateRow['handoverDate']) {
  //     showToast('변경 불가', '현재 출고일과 같습니다.', 'warning');
  //     return;
  //   }
  //   if(value == '6/6') {
  //     showToast('변경 불가', '가득 찬 상태입니다.', 'warning');
  //     return;
  //   }
  //   if(value == '휴일') {
  //     showToast('변경 불가', '휴일은 선택할 수 없습니다.', 'warning');
  //     return;
  //   }
  //
  //   const opptyObj = {
  //     id : this.selectedHandoverDateRow['id'],
  //     handoverDate : this.selectedHandoverDateRow['handoverDate']
  //   }
  //
  //   const result = await LightningConfirm.open({
  //     message: '출고일을 ' + this.selectedDate + '로 변경하시겠습니까?',
  //     variant: 'headerless', // 'headerless'도 가능
  //     label: '기존 출고일 : ' + this.selectedHandoverDateRow['handoverDate'], // 모달 제목
  //   });
  //   if (!result) {
  //     console.log('작업 취소');
  //     return;
  //   }
  //
  //   this.isLoading = true;
  //   console.log('this.selectedHandoverDateRow ::: ' + JSON.stringify(this.selectedHandoverDateRow));
  //   console.log('new Date(this.selectedDate) ::: ' + new Date(this.selectedDate))
  //   console.log('this.selectedHandoverDateRow[\'opp\'][\'Id\'] ::: ' + this.selectedHandoverDateRow['opp']['Id'])
  //   console.log('stockId : this.selectedHandoverDateRow[\'stockId\'] ::: ' + this.selectedHandoverDateRow['stockId'])
  //   // updateHandoverDate({handoverInfo : opptyObj, targetDate : this.selectedDate}).then(res => {
  //   insertHandoverDateAllocationHistory({
  //     targetDate : new Date(this.selectedDate),
  //     opptyId : this.selectedHandoverDateRow['opp']['Id'],
  //     stockId : this.selectedHandoverDateRow['stockId'],
  //     isAssign : true
  //   }).then(res => {
  //     console.log('res ::: ' + res)
  //     if(res) {
  //       showToast('성공', '출고일이 ' + this.selectedDate +'로 변경되었습니다.', 'success');
  //       // TODO: 모달 끄고 기존 필터 기반으로 재조회
  //     } else {
  //       showToast('변경 불가2', '가득 찬 상태입니다.', 'warning');
  //       // Todo: 테이블 정보 다시 그려주기 -> 다시 그리기 애매함... 그냥 모달 끄고 재조회?
  //     }
  //   }).catch(err => {
  //     console.log(JSON.stringify(err))
  //   }).finally(() => {
  //     this.getFilteredList();
  //     this.closeModal();
  //     this.isLoading = false;
  //   })
  //
  //   // 선택한 값 초기화
  //   // this.selectedRowsOppty = [];
  //   // this.selectedRowInfoOppty = '';
  //   //
  //   // console.log('this.selectedRowsOppty ::: ' + JSON.stringify(this.selectedRowsOppty))
  //   // console.log('this.selectedRowInfoOppty ::: ' + this.selectedRowInfoOppty)
  //
  //   // this.callOpptyList();
  //   // this.openModal();
  // }
  //
  // // callOpptyList() {
  // //   console.log('this.selectedDate ::: ' + this.selectedDate);
  // //   this.opptyList = [];
  // //   getOpptyListByHandoverDate({handoverDate : this.selectedDate}).then(res => {
  // //     // this.opptyList = this.updateDisplayedData(res);
  // //     this.opptyList = res;
  // //     console.log('this.opptyList ::: ' + JSON.stringify(this.opptyList))
  // //   }).catch(err => {
  // //     console.log('err ::: ' + JSON.stringify(err));
  // //   })
  // // }
  //
  // handleRowAction(e) {
  //   console.log('handleRowAction start' )
  //   this.selectedHandoverDateRow = e.detail.row;
  //   this.openModal();
  // }
  //
  // // updateDisplayedData(res) {
  // //   // 원본 데이터 복사
  // //   let tempData = [...res];
  // //
  // //   // 6행 미만이면 빈 데이터 추가
  // //   while (tempData.length < 6) {
  // //     tempData.push({
  // //       Id: `empty-${tempData.length}`,
  // //       name: '',
  // //       value: null
  // //     });
  // //   }
  // //
  // //   // 업데이트된 데이터 반영
  // //   return tempData;
  // // }
  //
  // handleSelectionOppty(e) {
  //
  //   console.log(e.detail.selectedRows[0]);
  //   console.log(e.detail.selectedRows[0].Id);
  //   console.log(e.detail.selectedRows[0].Id.includes('empty'));
  //
  //   this.selectedRowsOppty = e.detail.selectedRows?.map(el => el.Id);
  //   this.selectedRowInfoOppty = e.detail.selectedRows[0];
  //
  //   console.log('this.selectedRowsOppty ::: ' + this.selectedRowsOppty)
  //   console.log('this.selectedRowInfoOppty ::: ' + this.selectedRowInfoOppty)
  // }

  // Calendar로 임시 추가 End

  createDepositReceiptPDF() {
    this.isLoading = true;
    createPDFBySFDC({recordId : this.selectedRows[0]}).then(res => {
      const blob = this.pdfBase64ToBlob(res.pdfBase64);

      showToast('입금 영수증', 'PDF 생성', 'success');

      // Blob URL 생성
      this.pdfUrl = URL.createObjectURL(blob);
      alert(this.pdfUrl)

      if (formFactor === "Large") {
        window.open(this.pdfUrl, '_blank');
      } else {
        // const downloadLink = document.createElement("a");
        // downloadLink.href = `data:text/csv;charset=utf-8,${encodeURI(csvFile)}`;
        // downloadLink.target = "_blank";
        // downloadLink.download = `${this.exportTitle}.csv`;
        // downloadLink.click();

        // const link = document.createElement('a');
        // link.href = this.pdfUrl;
        // link.target = "_blank";
        // link.download = `${this.selectedRowInfo.customer}_입금영수증.pdf`;
        // document.body.appendChild(link);
        // link.click();
        // document.body.removeChild(link);
        window.location.href = this.pdfUrl;
      }
    }).catch(err => {
      console.log('err :::' + err.message);
    }).finally(() => {
      this.isLoading = false;
    })
  }

  pdfBase64ToBlob(pdfCnvStr) {
    const byteCharacters = atob(pdfCnvStr); // Base64 디코딩
    const byteNumbers = new Array(byteCharacters.length);
    for (let i = 0; i < byteCharacters.length; i++) {
      byteNumbers[i] = byteCharacters.charCodeAt(i);
    }
    const byteArray = new Uint8Array(byteNumbers);
    const blob = new Blob([byteArray], { type: 'application/pdf' });

    return blob;
  }

  handleSelection(e) {
    this.selectedRows = e.detail.selectedRows?.map(el => el.id);
    this.selectedRowInfo = e.detail.selectedRows[0];
    console.log('this.selectedRows ::: ' + this.selectedRows)
    console.log('this.selectedRowInfo ::: ' + JSON.stringify(this.selectedRowInfo))
  }

  handleFilterChange(e) {
    const name = e.target.dataset.name;
    const value = e.target.value;

    if(name === "startDate" && value > this.filterMap['endDate'].substring(1)) {
      showToast('시작일은 종료일보다 이전 날짜여야 합니다.', 'warning', 'warning');
      e.target.value = this.filterMap['startDate'];
      return;
    }
    if(name === "endDate" && value < this.filterMap['startDate'].substring(1)) {
      showToast('종료일은 시작일보다 이후 날짜여야 합니다.', 'warning', 'warning');
      e.target.value = this.filterMap['endDate'];
      return;
    }

    this.filterMap[name] = (name === "startDate" || name === "endDate") ? `=${value}` : value;
    // this.filterMap[name] = value;
  }

  handleEnterKey(e) {
    if (e.key === 'Enter') {
      this.getFilteredList();
    }
  }

  // /**
  //  * @description 부모에서 데이터 받아오는 setter
  //  * @param value 부모 데이터
  //  */
  // @api
  // set parentData(value) {
  //   if (value) {
  //     this._parentData = { ...value };
  //     this.handoverList = this._parentData?.taxInvoiceHandoverList || [];
  //     this.saUserList = this._parentData?.saUserList || [];
  //     this.userProfileName = this._parentData?.userProfileName || '';
  //
  //     console.log(JSON.stringify(this.userProfileName));
  //   }
  // }
  //
  // /**
  //  * @description 부모 데이터 getter
  //  */
  // get parentData() {
  //   return this._parentData;
  // }
}