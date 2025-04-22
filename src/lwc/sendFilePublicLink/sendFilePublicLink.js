/*************************************************************
 * @author : chaebeom.do
 * @date : 2024-12-17
 * @description : 레코드 상세 페이지에서 버튼 클릭시 file의 pdf 링크 생성 후 카톡으로 고객에게 전송
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-12-17      chaebeom.do     Created
 * 1.1          2025-04-08      chaebeom.do     한글 버전을 디폴트로 수정
 **************************************************************/
import { api, LightningElement, track, wire } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { NavigationMixin } from "lightning/navigation";
import { CurrentPageReference } from "lightning/navigation";
import { RefreshEvent } from "lightning/refresh";

//library
import createPublicLink from "@salesforce/apex/SendFilePublicLinkController.createPublicLink";
import getQuote from "@salesforce/apex/SendFilePublicLinkController.getQuote";
import updateQuote from "@salesforce/apex/SendFilePublicLinkController.updateQuote";
import kakaoAlimTalk from "@salesforce/apex/InterfaceKakao.doCallOutKakaoAlimTalk";
import formFactor from "@salesforce/client/formFactor";

// Util
import { showToast, recordNavigation } from "c/commonUtil";

export default class SendFilePublicLink extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @track isLoading = false;

  radioValue = "";
  selectedValue = "KR";
  quoteName;
  accId;
  domain = "";
  publicUrl = "";
  previewUrl = "";

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
    getQuote({ recordId: this.recordId }).then((res) => {
      this.quoteName = res.name;
      this.accId = res.acc;
    });
  }

  handleSend() {
    let title;
    let msg;
    let variant = "error";
    let inputMap = {
      recordId: this.recordId,
      language: this.selectedValue,
      type: "send",
    };
    this.isLoading = true;
    createPublicLink({ inputMap: inputMap })
      .then((res) => {
        if (res === null) {
          title = "오류";
          msg = "관리자에게 문의해주세요.";
        } else {
          this.domain = res.domain.substring(
            res.domain.indexOf("//") + 2,
            res.domain.length
          );
          this.publicUrl = res.publicLink.substring(
            res.publicLink.indexOf("/sfc") + 1,
            res.publicLink.length
          );
          title = "링크가 전송되었습니다.";
          variant = "success";
          this.callKakaoAlimTalk();
          this.updateQuoteStatus();
          this.handleCancel();
          setTimeout(() => {
            location.reload();
          }, 1000);
        }
        showToast(title, msg, variant);
      })
      .catch((err) => {
        console.log("err :: ", err);
        if (err.body.exceptionType == "System.ListException") {
          title = "파일이 없습니다.";
          msg = "pdf 파일을 추가해주세요.";
        }
        if (err.body.exceptionType == "System.VisualforceException") {
          title = "파일이 생성되지않았습니다.";
          msg = "유효한 옵션으로 다시 구성해주세요.";
        }
        showToast(title, msg, variant);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  handleSave() {
    let title;
    let msg;
    let variant = "error";
    let inputMap = {
      recordId: this.recordId,
      language: this.selectedValue,
      type: "save",
    };
    this.isLoading = true;
    createPublicLink({ inputMap: inputMap })
      .then((res) => {
        if (res === null) {
          title = "오류";
          msg = "관리자에게 문의해주세요.";
        } else {
          if (res.isNewV == "yes") {
            title = "견적이 저장되었습니다.";
            variant = "success";
          } else if (res.isNewV == "no") {
            title = "동일한 견적이 존재합니다.";
            variant = "warning";
          }
          this.handleCancel();
        }
        this.onRefresh();
        showToast(title, msg, variant);
      })
      .catch((err) => {
        console.log("err :: ", err);
        if (err.body.exceptionType == "System.ListException") {
          title = "파일이 없습니다.";
          msg = "pdf 파일을 추가해주세요.";
        }
        if (err.body.exceptionType == "System.VisualforceException") {
          title = "파일이 생성되지않았습니다.";
          msg = "유효한 옵션으로 다시 구성해주세요.";
        }
        showToast(title, msg, variant);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  handleOpenPdf() {
    let title;
    let msg;
    let variant = "error";
    let inputMap = {
      recordId: this.recordId,
      language: this.selectedValue,
      type: "view",
    };
    this.isLoading = true;
    createPublicLink({ inputMap: inputMap })
      .then((res) => {
        console.log('pdf 미리보기 테스트 :: ', res);
        const isIOS = () => {
          return (
            /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream
          );
        };
        const isAndroid = () => {
          return /Android/.test(navigator.userAgent);
        };

        if (formFactor === "Large") {
          window.open("/apex/QuotePdf?id=" + this.recordId + "&language=" + this.selectedValue);
        } else {
          if (isAndroid()) {
            recordNavigation(this, "ContentDocument", res.contentDocumentId, null, null, true);
          }
          if (isIOS()) {
            recordNavigation(this, "ContentDocument", res.contentDocumentId);
          }
        }
      })
      .catch((err) => {
        console.log("err :: ", err);
        if (err.body.exceptionType == "System.ListException") {
          title = "파일이 없습니다.";
          msg = "pdf 파일을 추가해주세요.";
        }
        if (err.body.exceptionType == "System.VisualforceException") {
          title = "파일이 생성되지않았습니다.";
          msg = "유효한 옵션으로 다시 구성해주세요.";
        }
        showToast(title, msg, variant);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
    this.mobileReturnPage();
  }

  mobileReturnPage() {
    if (formFactor === "Small") {
      recordNavigation(this, "Contract", this.recordId);
    }
  }

  onRefresh() {
    this.dispatchEvent(new RefreshEvent());
  }

  callKakaoAlimTalk() {
    // 수신자의 데이터 Record
    let infoMapList = [
      {
        objectName: "Account",
        // recordId: '001H200001ZKbj8IAD' // < 테스트용 카톡 수신자 (도채범)
        recordId: this.accId, // < 실제 사용
      },
    ];
    // 템플릿. URL이 존재할 경우. 해당 URL에 해당하는 버튼명 - 변수명 - Value값 지정
    let buttonMap = {
      View: {
        domain: this.domain,
        publicLink: this.publicUrl,
      },
    };

    // 템플릿. 변수명에 해당하는 데이터 RecordId
    let infoMap = {
      templateTitle: "견적서 PDF 전송 2", // [v] 카카오톡 Template명
      object: "Quote", // 카카오톡 Body에 설정될 Object명
      recordId: this.recordId, // [v] 카카오톡 Body에 설정될 recordId
      infoMapList: infoMapList, // [v] 카카오톡 수신데이터 설정
      buttonMap: buttonMap, // 카카오톡 버튼 정보
      externalId: this.recordId, // 외부연결 Id
    };

    kakaoAlimTalk({ paramMap: infoMap })
      .then((response) => {
        let result = response;
        console.log("카톡결과::: " + JSON.stringify(result));
      })
      .catch((error) => {
        console.log("카톡에러::: " + error);
      });
  }

  updateQuoteStatus() {
    updateQuote({ recordId: this.recordId })
      .then(() => {})
      .catch((error) => {
        console.log("견적 업데이트 에러::: " + error);
      });
  }
}
