/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-14
 * @description :
 * @target :
 ==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-14        San.Kang           Created
 **************************************************************/
import {LightningElement, track, wire} from 'lwc';
import {CloseActionScreenEvent} from "lightning/actions";
import {CurrentPageReference, NavigationMixin} from 'lightning/navigation';
import {recordNavigation, showToast} from "c/commonUtil";

import downloadSelectedPDFs from '@salesforce/apex/PDFCommonController.downloadSelectedPDFs';
import getOpportunityInit from '@salesforce/apex/PDFCommonController.getOpportunityInit';
import formFactorPropertyName from '@salesforce/client/formFactor';


export default class OpportunityPDF extends NavigationMixin(LightningElement) {

    @track allDocuments = [
        // 모든 PDF 리스트                                        선택           보기
        {label: '최종 견적서', value: '/apex/QuotePdf?id=', selected: false, isOpen: false},
        {label: '출고예정서', value: '/apex/ReleaseSchedule?id=', selected: false, isOpen: false},
        {label: '양도증명서 및 제작증', value: '/apex/TransCert?id=', selected: false, isOpen: false},
        {label: '국세환급금양도요구서', value: '/apex/TaxRefund?id=', selected: false, isOpen: false},
        {label: '판매정산결과 REPORT', value: '/apex/SalesResultReport?id=', selected: false, isOpen: false},
        {label: '제작증', value: '/apex/VehiceManufactCert?id=', selected: false, isOpen: false}

    ];
    // PDF Validation
    @track exceptionMap = {
        '양도증명서 및 제작증': [],
        '제작증': [],
        '판매정산결과 REPORT': [],
        'Sales Summary REPORT EN': []
    };

    @track filteredDocuments = [...this.allDocuments];
    @track selectedDocument = '';
    @track allCheckBtn = false; // 전체 체크

    quoteId;

    //모바일, PC 분기
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state) {
            if (formFactorPropertyName === 'Large') {
                this.recordId = pageRef.state.recordId;
            } else {
                this.recordId = pageRef.state?.c__recordId;
            }
        }
    }


    connectedCallback() {
        this.resizePop(); // 모달창 크기
        getOpportunityInit({recordId: this.recordId}).then(res => {
            this.quoteId = res.opportunity?.[0]?.Contract?.Quote__c;
            const checkAccount = res?.opportunity?.[0]?.AccountId == null;
            const checkVehicleStock = res?.opportunity?.[0]?.VehicleStock__c == null;
            const checkProduct = res?.opportunity?.[0]?.VehicleStock__r?.Product__c == null;
            const checkPaymentTracker = res.paymentTracker === null;
            const checkPaymentType = res.paymentTracker?.[0]?.PaymentTypes__r === null;
            if(res.checkSAPermission) this.filteredDocuments = this.filteredDocuments.filter(doc => doc.label !== '판매정산결과 REPORT');

            // PDF Validation
            Object.assign(this.exceptionMap, {
                ['최종 견적서']: this.quoteId == null,
                ['출고예정서']: checkVehicleStock || res.opportunity[0].TaxInvoiceDate__c == null,
                ['제작증']: checkVehicleStock || this.quoteId == null,
                ['양도증명서 및 제작증']: checkVehicleStock || checkAccount,
                ['판매정산결과 REPORT']: checkVehicleStock || checkAccount || checkProduct || checkPaymentTracker || checkPaymentType || this.quoteId == null
            })
        })
        .catch(error => {
            console.error(error);
        });

    }

    // 모달 사이즈
    resizePop() {
        let modalBody = document.querySelector('.modal-body');
        let closeIcon = document.querySelector('.closeIcon');

        let modalWidth = 500;

        if (modalBody && closeIcon) {
            // modal-body width 설정
            modalBody.style.width = `${modalWidth}px`;
            modalBody.style.margin = '0 auto';

            // 부모 요소 너비 기준으로 closeIcon 위치 조정
            const containerWidth = modalBody.parentElement.offsetWidth;
            const adjustedMarginRight = (containerWidth - modalWidth) / 2;

            closeIcon.style.marginRight = `${adjustedMarginRight}px`;
        }
    }

    // PDF 리스트 선택 시 색 변경
    get docsWithClass() {
        return this.filteredDocuments.map(doc => {
            let baseClass = 'cellBorder slds-p-vertical_xx-small slds-m-bottom_xx-small';
            if (doc.selected) {
                baseClass += ' selectedRow';
            }
            return {...doc, docClass: baseClass};
        });

    }

    // 체크박스 클릭 시 이벤트 전파 차단 (전체 row 클릭 이벤트와 분리)
    handleCheckboxClick(event) {
        event.stopPropagation();
    }

    // 리스트 영역 선택
    handleRowClick(event) {
        event.stopPropagation();
        const docValue = event.currentTarget.dataset.id;
        this.filteredDocuments = this.filteredDocuments.map(doc => {
            if (doc.value === docValue) {
                if (this.exceptionMap[doc.label]) {
                    this.exceptionToast(doc.label); // PDF Validation
                }else{
                    return {...doc, selected: !doc.selected};
                }
            }
            return doc;
        });
    }

    // 전체 선택
    handleSelectAllChange(event) {
        const value = event.target.checked;
        try {
            this.allCheckBtn = value;
            this.filteredDocuments = this.filteredDocuments.map(doc => {
                if (this.exceptionMap[doc.label] && value) {
                    this.exceptionToast(doc.label); // Validation 처리
                    return doc;
                }
                return {...doc, selected: value};
            });
        } catch (err) {
            console.log('err :: ', err.message);
        }
    }

    // 보기 버튼
    handleViewRow(event) {
        event.stopPropagation();
        const docValue = event.currentTarget.dataset.id;
        this.filteredDocuments = this.filteredDocuments.map(doc => {
            if (doc.value === docValue) {
                if (this.exceptionMap[doc.label]) {
                    this.exceptionToast(doc.label); // Validation
                } else if (doc.label === '최종 견적서') {
                    window.open(doc.value + this.quoteId + '&language=KR', 'PDF Viewer', 'width=1100,height=600,scrollbars=yes,resizable=yes');
                } else {
                    window.open(doc.value + this.recordId, 'PDF Viewer', 'width=1100,height=600,scrollbars=yes,resizable=yes');
                }
            }
            return doc;
        });
    }

    // 다운로드 버튼 클릭
    handleDownloadSelected() {
        this.allCheckBtn = false;
        // 먼저, undefined나 null인 요소를 제거
        const validDocs = (this.filteredDocuments || []).filter(doc => doc);
        if (this.filteredDocuments.filter(doc => doc.selected).length === 0) {
            showToast('다운로드 할 PDF 항목을 선택 해 주세요.', "", "warning");
            return;
        }
        this.filteredDocuments = validDocs.map(doc => {
            if (doc.selected) {
                let vfUrl = doc.value + this.recordId;
                if (doc.label === '최종 견적서') {
                    vfUrl = doc.value + this.quoteId + '&language=KR';
                }

                downloadSelectedPDFs({ vfUrl })
                    .then(result => {
                        const pdfBlob = this.base64ToBlob(result, "application/pdf");
                        const blobUrl = window.URL.createObjectURL(pdfBlob);
                        const a = document.createElement("a");
                        a.href = blobUrl;
                        a.download = doc.label + ".pdf";
                        a.click();
                        window.URL.revokeObjectURL(blobUrl);
                    })
                    .catch(error => {
                        console.error("다운로드 실패 (" + doc.label + "):", error);
                    });
                return { ...doc, selected: false };
            } else {
                return doc;
            }
        });
    }

    // base64 문자열을 Blob으로 변환하는 헬퍼 함수
    base64ToBlob(base64, contentType) {
        contentType = contentType || '';
        const sliceSize = 1024;
        const byteCharacters = atob(base64);
        const bytesLength = byteCharacters.length;
        const slicesCount = Math.ceil(bytesLength / sliceSize);
        const byteArrays = new Array(slicesCount);

        for (let sliceIndex = 0; sliceIndex < slicesCount; ++sliceIndex) {
            const begin = sliceIndex * sliceSize;
            const end = Math.min(begin + sliceSize, bytesLength);
            const bytes = new Array(end - begin);
            for (let offset = begin, i = 0; offset < end; ++offset, ++i) {
                bytes[i] = byteCharacters[offset].charCodeAt(0);
            }
            byteArrays[sliceIndex] = new Uint8Array(bytes);
        }
        return new Blob(byteArrays, {type: contentType});
    }

    // 체크 박스 클릭 이벤트
    handleCheckboxChange(event) {
        event.stopPropagation(); // 이벤트 전파 방지
        const value = event.target.value;

        this.filteredDocuments = this.filteredDocuments.map(doc => {
            if (doc.value === value) {
                if (this.exceptionMap[doc.label]) {
                    event.target.checked = false;
                    this.exceptionToast(doc.label);
                    return doc;
                }else{
                    return {...doc, selected: !doc.selected};
                }
            }
            return doc;
        });

    }

    // Validation 메세지
    exceptionToast(label) {
        showToast(label, "PDF 생성에 필요한 필수 데이터가 누락되었습니다.", "warning");
    }

    // 취소 버튼
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}