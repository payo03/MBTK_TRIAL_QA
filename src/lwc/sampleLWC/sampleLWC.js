/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-18      payo03@solomontech.net           Created
*/
import {LightningElement, api, track, wire} from 'lwc';
import {CurrentPageReference} from "lightning/navigation";

import openURL from '@salesforce/apex/InterfaceModuSign.doCallOutDraft';
import signRequestByTemplate from '@salesforce/apex/InterfaceModuSign.doCallOutSignRequestByTemplate';
//import savePDF from '@salesforce/apex/InterfaceModuSign.doCallOutURLtoPDF';
//import getQuoteId from '@salesforce/apex/InterfaceModuSign.getQuoteId';
import kakaoAlimTalk from '@salesforce/apex/InterfaceKakao.doCallOutKakaoAlimTalk';

export default class SampleLwc extends LightningElement {
    // @api recordId;
    // @api objectApiName;
    @wire(CurrentPageReference) pageRef;
    recordId;
    quoteId;

    connectedCallback() {
        this.recordId = this.pageRef.state.recordId;
        this.getQuote();
        // this.callModuSignDraft();
        // this.callModuSignRequest();
        this.callKakaoAlimTalk();
    }

    getQuote() {
        console.log('this.recordId ::: ' + this.recordId);
        /*
        getQuoteId({contractId : this.recordId}).then(res => {
            this.quoteId = res;
            console.log('this.quoteId ::: ' + this.quoteId)
            this.callModuSignDraft();
            this.callModuSignRequest();
        }).catch(err => {
            console.log('getQuote err ::: '+ err);
        })
        */
    }

    // 모두싸인 Draft Popup 생성
    callModuSignDraft() {
        // Record ID와 Object API Name을 기반으로 Popup 호출
        // let infoMap = {
        //     templateTitle: '[샘플] 개인정보 수집 이용 동의서',   // [v] 모두싸인 Template Title명
        //     object: 'Account',                              // this.objectApiName
        //     recordId: '001H200001Z02c0IAB'                  // [v] this.recordId
        // }
        // let infoMap = {
        //     templateTitle: '계약서',                                 // [v] 모두싸인 Template Title명
        //     object: 'Contract',                                     // this.objectApiName
        //     recordId: '800H2000000EmrvIAC'                          // [v] this.recordId
        // }
        let infoMap = {
            templateTitle: '계약서',                                 // [v] 모두싸인 Template Title명
            object: 'Quote',                                        // this.objectApiName
            recordId: this.quoteId                                  // [v] this.recordId
        }

        openURL({ paramMap : infoMap }).then(response => {
            let result = response;

            let code = result.code;
            let url = result.url;

            if(code && url) {
                window.open(url, '_blank');
            }
        }).catch(error => {
            console.log(error);
        });
    }

    // 모두싸인 서명요청
    callModuSignRequest() {

        // 서명요청받을 사용자 List, 고객은 Account. 내부 사용자는 User 등등.... 동적으로 데이터 요청
        let infoMapList = [
            // {
            //     objectName : 'Account',             // 조회할 Object
            //     recordId: '001H200001Z0BDQIA3',     // [v] Object의 RecordId
            //     validDuration: 4,                   // 문서 서명유효기간(기준 : 일). Default 14일
            //     sendType: 'kakao',                  // 문서 서명요청 Type(email, kakao). Default kakao
            //     role: '근로자',                      // [v] 문서 사용자 역할
            //     locale: 'en',                       // 서명자의 문서 Locale 설정(ko, en, zh-CN, ja, vi)
            // },
            // {
            //     objectName : 'User',
            //     recordId: '005IU00000BhGQdYAN',
            //     validDuration: 4,
            //     sendType: 'kakao',
            //     role: '을',
            // },
            {
                objectName : 'User',
                recordId: '005H2000006e4v7IAA',
                validDuration: 4,
                sendType: 'kakao',
                role: '고객',
            }
        ];

        // 문서정보 Setting
        // let infoMap = {
        //     templateTitle: '[샘플] 개인정보 수집 이용 동의서',       // [v] 모두싸인 Template Title명
        //     object: 'Account',                                   // this.objectApiName
        //     recordId: '001H200001Z02c0IAB',                      // [v] this.recordId
        //     documentTitle: '[Test] 개인정보 수집 이용동의서',       // 문서 Title명
        //     documentPW: '123456',                                // 문서 서명완료시 조회할 PW. 6자리 이상 설정필요
        //     infoMapList: infoMapList                             // [v] 사용자 정보 Input
        // };
        // let infoMap = {
        //     templateTitle: '계약서',       // [v] 모두싸인 Template Title명
        //     object: 'Contract',                                   // this.objectApiName
        //     // recordId: this.recordId,                            // [v] this.recordId
        //     recordId: '800H2000000EmrvIAC',                            // [v] this.recordId
        //     documentTitle: '[Test] 계약서',       // 문서 Title명
        //     documentPW: '123456',                                // 문서 서명완료시 조회할 PW. 6자리 이상 설정필요
        //     infoMapList: infoMapList                             // [v] 사용자 정보 Input
        // };
        let infoMap = {
            templateTitle: '계약서',       // [v] 모두싸인 Template Title명
            object: 'Quote',                                   // this.objectApiName
            recordId: this.quoteId,                            // [v] this.recordId
            // recordId: '800H2000000EmrvIAC',                            // [v] this.recordId
            documentTitle: '[Test] 계약서',       // 문서 Title명
            documentPW: '123456',                                // 문서 서명완료시 조회할 PW. 6자리 이상 설정필요
            infoMapList: infoMapList,                            // [v] 사용자 정보 Input
            externalId: this.recordId           // 외부연결 Id
        };
        console.log(infoMap);

        signRequestByTemplate({ paramMap : infoMap }).then(response => {
            let result = response;

            let code = result.code;
            let url = result.url;

//            this.callModuSignPDF(result.documentId);
        }).catch(error => {
            console.log(error);
        });
    }

/*
    // 문서 All Signed(status : completed)의 Id를 통해 URL to PDF 생성
    callModuSignPDF(documentId) {
        console.log(documentId);

        savePDF({ docId : documentId }).then(response => {
            let result = response;
        }).catch(error => {
            console.log(error);
        });
    }
*/

    // 카카오톡 알림톡 호출 API
    callKakaoAlimTalk() {
        // 수신자의 데이터 Record
        let infoMapList = [
            {
                objectName : 'Account',
                recordId: '001H200001Z03AAIAZ'
            }
        ];
        // 템플릿. URL이 존재할 경우. 해당 URL에 해당하는 버튼명 - 변수명 - Value값 지정
        let buttonMap = {
            WebButton: {
                opportunityId: '00QH2000009q6UpMAI'
            },
            ButtonName2: {
                varKey: 'agreement'
            }
        };
        // https://app-force-1035--partial.sandbox.my.site.com/Agreement/s/#{opportunityId}
        // https://app-force-1035--partial.sandbox.my.site.com/Agreement/s/#{varKey}

        // 템플릿. 변수명에 해당하는 데이터 RecordId
        let infoMap = {
            templateTitle: '카카오톡 샘플_URL',   // [v] 카카오톡 Template명
            object: 'Quote',                    // 카카오톡 Body에 설정될 Object명
            recordId: '005IU00000BhGQdYAN',     // [v] 카카오톡 Body에 설정될 recordId
            infoMapList: infoMapList,           // [v] 카카오톡 수신데이터 설정
            buttonMap: buttonMap,               // 카카오톡 버튼 정보
            externalId: this.recordId           // 외부연결 Id
        };

        kakaoAlimTalk({paramMap : infoMap}).then(response => {
            let result = response;

            console.log(result);
        }).catch(error => {
           console.log(error);
        });
    }
}