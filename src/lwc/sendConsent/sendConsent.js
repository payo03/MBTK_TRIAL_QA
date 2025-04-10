/*************************************************************
 * @author : chaebeom.do
 * @date : 2024-01-02
 * @description : 레코드 상세 페이지에서 버튼 클릭시 카톡으로 고객에게 동의 랜딩페이지 전송
 * @target :
 ==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-01-02      chaebeom.do     Created
 * 1.1          2024-01-03      San.Kang        Updated
 **************************************************************/
import {LightningElement, api, wire, track} from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import {CloseActionScreenEvent} from "lightning/actions";

import getSubCustomerConsent from "@salesforce/apex/LandingPageController.getSubCustomerConsent";
// import getAcc from "@salesforce/apex/LandingPageController.getAcc";
// import createCustomerConsent from "@salesforce/apex/LandingPageController.createCustomerConsent";
// import getConsentType from "@salesforce/apex/LandingPageController.getConsentType";
// import callKakaoAlimTalk from "@salesforce/apex/InterfaceKakao.doCallOutKakaoAlimTalk";

import formFactorPropertyName from '@salesforce/client/formFactor';
import {showToast} from "c/commonUtil";
import {NavigationMixin} from "lightning/navigation";

export default class SendConsent extends NavigationMixin(LightningElement) {
    recordId;
    // accName = '';
    // @track filterOptions = { type: [] };
    // realDriver ='';
    // selectType ='';
    // ccId='';
    // sendRealDriverFlag = false;
    // sendCustomerFlag = false;
    // kakaoRecipient ='타입을 선택해주세요.';

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            if (formFactorPropertyName === 'Large') {
                console.log('컴퓨터');
                this.recordId = currentPageReference.state.recordId;
            } else {
                console.log('모바일');
                this.recordId = currentPageReference.state.c__recordId;
            }
        }
    }

    connectedCallback() {
        // this.getConsentType();
        // console.log('https://app-force-1035--partial.sandbox.my.salesforce-sites.com/extlanding?Id=' + this.recordId);
        // console.log("recordId :: ", this.recordId);
        // getAcc({recordId: this.recordId}).then(res => {
        //       if(res === null) {
        //             showToast("", "오류가 발생했습니다. 관리자에게 문의해주세요", "warning");
        //       } else {
        //             this.accName = res[0].Name;
        //             this.realDriver = res[0].RealDriver__pc;
        //             this.sendCustomerFlag = res[0].SendCustomerFlag__c;
        //             this.sendRealDriverFlag = res[0].SendRealDriverFlag__c;
        //       }
        // }).catch(err => {1
        //     console.log("err :: ", err);
        // });
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleResend() {
        console.log('test', this.recordId);
        getSubCustomerConsent({recordId: this.recordId}).then(res => {
            showToast("", "개인정보 고객 동의 알림톡이 발송 되었습니다.","Success");
            this.handleCancel();
        }).catch(err => {
            showToast("", "개인정보 고객 동의 알림톡이 발송 되지 않았습니다.","Warning");
        });
    }

//   sendKakaoTalkToCustomer(){
//     if (this.selectType == '') {
//               showToast("", "타입을 선택해주세요.", "warning");
//     } else {
//     createCustomerConsent({Id: this.recordId,type: this.selectType}).then(res => {
//         if (res === null) {
//             showToast("", "전송에 실패했습니다. 관리자에게 문의해주세요.", "error");
//         } else if (res === "실차주") {
//             showToast("", "실차주 고객님에게 개인정보 고객동의가 이미 발송되었습니다.", "warning");
//         } else if (res === "고객"){
//              showToast("", "고객님에게 개인정보 고객동의가 이미 발송되었습니다.", "warning");
//         } else if (res === "실차주동의 완료") {
//              showToast("", "실차주 고객님께서 이미 개인정보 고객동의에 동의하셨습니다.", "warning");
//         } else if (res === "고객동의 완료"){
//             showToast("", "고객님께서 이미 개인정보 고객동의에 동의하셨습니다.", "warning");
//         } else {
//             console.log('res',res);
// //            this.ccId = res;
//             this.callKakaoAlimTalk(res);
//             showToast("", "전송이 완료되었습니다.", "success");
//             this.handleCancel();
//             RefreshEvent();
//             //https://app-force-1035--partial.sandbox.my.salesforce-sites.com/ExtLanding?AccId=" + this.recordId
//             //https://app-force-1035--partial.sandbox.my.salesforce-sites.com/ExtLanding/?AccId=" + this.recordId
//         }
//       }).catch(err => {
//         console.log("err :::: ", err);
//       });
//     }
//   }

    handleCancel() {
        if (formFactorPropertyName === 'Large') {
            this.dispatchEvent(new CloseActionScreenEvent());
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Account',
                    actionName: 'view',
                },
            });
        }
    }

    // Consent 오브젝트의 Type PickList를 가져옴
    // getConsentType(){
    //       getConsentType({Id: this.recordId}).then(res => {
    //               this.filterOptions.type = [{ label: "-선택-", value: "" }].concat(res.type);
    //       }).catch(err => {
    //               console.log("err :: ", err);
    //       });
    // }

    // Type이 변경될 때, kakaoRecipient의 이름이 변경 됨
    // selectConsentType(e){
    //   this.selectType = e.target.value;
    //   if (this.selectType == '고객'){
    //       this.kakaoRecipient = this.accName + ' 고객님에게 개인정보 활용 동의 페이지를 전송하시겠습니까?';
    //
    //   }
    //   if (this.selectType == '실차주'){
    //       this.kakaoRecipient = this.realDriver + ' 고객님에게 개인정보 활용 동의 페이지를 전송하시겠습니까?';
    //
    //   }
    //   if (this.selectType == ''){
    //       this.kakaoRecipient = '타입을 선택해주세요.';
    //   }
    // }

    // 카카오톡 알림톡 호출
    // callKakaoAlimTalk(res){
    //  {
    //   let infoMapList = [
    //       {
    //           objectName : 'Account',
    //           recordId: this.recordId,
    //           type: this.selectType
    //       }
    //   ];
    //
    //   let buttonMap = {
    //       LINK: {
    //           Id: res
    //       }
    //   };
    //   console.log('buttonMap::', buttonMap);
    //   let infoMap = {}
    //
    //   if(this.selectType == '고객'){
    //       infoMap = {
    //           templateTitle: '개인정보 고객 동의3',
    //           object: 'Account',
    //           name: this.accName,
    //           recordId: this.recordId,
    //           externalId: this.recordId,
    //           infoMapList: infoMapList,
    //           buttonMap: buttonMap
    //       };
    //   }else{
    //        infoMap = {
    //            templateTitle: '개인정보 실차주 동의2',
    //            object: 'Account',
    //            RealDriver__pc: this.realDriver,
    //            recordId: this.recordId,
    //            externalId: this.recordId,
    //            infoMapList: infoMapList,
    //            buttonMap: buttonMap
    //        };
    //   }
    //   callKakaoAlimTalk({paramMap: infoMap}).then(res => {
    //       let result = res;
    //       console.log(result);
    //   }).catch(error => {
    //       console.log(error);
    //   });
    //   }
    // }
}