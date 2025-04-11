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
        {label: '최종 견적서', value: '/apex/QuotePdf?id=', selected: false, isOpen: false},
        {label: '출고예정서', value: '/apex/ReleaseSchedule?id=', selected: false, isOpen: false},
        // {label: '보관확인서', value: '/apex/StorageCertification?id=', selected: false, isOpen: false},
        {label: '양도증명서 및 제작증', value: '/apex/TransCert?id=', selected: false, isOpen: false},
        // {label: 'MDS 가입서류', value: '/apex/MDSRegisterImgForm?id=', selected: false, isOpen: false},
        {label: '국세환급금양도요구서', value: '/apex/TaxRefund?id=', selected: false, isOpen: false},
        {label: '판매정산결과 REPORT', value: '/apex/SalesResultReport?id=', selected: false, isOpen: false},
        {label: '제작증', value: '/apex/VehiceManufactCert?id=', selected: false, isOpen: false}

    ];
    @track exceptionMap = {
        '양도증명서 및 제작증': [],
        '제작증': [],
        '판매정산결과 REPORT': [],
        'Sales Summary REPORT EN': []
    };

    @track filteredDocuments = [...this.allDocuments];
    @track downloadAll = false;
    @track selectedDocument = '';
    @track allCheckBtn = false;

    quoteId;

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state) {
            if (formFactorPropertyName === 'Large') {
                console.log('컴퓨터');
                this.recordId = pageRef.state.recordId;
            } else {
                console.log('모바일');
                this.recordId = pageRef.state?.c__recordId;
            }
            console.log('recordId:', this.recordId);
        }
    }

    connectedCallback() {
        this.resizePop();
        getOpportunityInit({recordId: this.recordId}).then(res => {
            console.log(res.opportunity?.[0]?.Contract?.Quote__c);
            this.quoteId = res.opportunity?.[0]?.Contract?.Quote__c;
            const checkAccount = res?.opportunity?.[0]?.AccountId == null;
            const checkVehicleStock = res?.opportunity?.[0]?.VehicleStock__c == null;
            const checkProduct = res?.opportunity?.[0]?.VehicleStock__r?.Product__c == null;
            const checkPaymentTracker = res.paymentTracker === null;
            const checkPaymentType = res.paymentTracker?.[0]?.PaymentTypes__r === null;
            if(res.checkSAPermission) this.filteredDocuments = this.filteredDocuments.filter(doc => doc.label !== '판매정산결과 REPORT');
            console.log('>>>>',res.checkSAPermission);

            Object.assign(this.exceptionMap, {
                ['최종 견적서']: this.quoteId == null,
                ['출고예정서']: checkVehicleStock || res.opportunity[0].TaxInvoiceDate__c == null,
                ['제작증']: checkVehicleStock || this.quoteId == null,
                ['양도증명서 및 제작증']: checkVehicleStock || checkAccount,
                ['판매정산결과 REPORT']: checkVehicleStock || checkAccount || checkProduct || checkPaymentTracker || checkPaymentType || this.quoteId == null,
                // ['Sales Summary REPORT EN']: checkVehicleStock || checkAccount || checkProduct || checkPaymentTracker || checkPaymentType || this.quoteId == null
                // ['Sales Summary REPORT EN']: false,
                // ['판매정산결과 REPORT']: false
            })
        })
        .catch(error => {
            console.error(error);
        });

    }

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

    // handleFromNoChange(event) {
    //     this.firstNo = event.target.value;
    // }
    //
    // handleToNoChange(event) {
    //     this.lastNo = event.target.value;
    // }

    handleRowClick(event) {
        event.stopPropagation();
        const docValue = event.currentTarget.dataset.id;
        this.filteredDocuments = this.filteredDocuments.map(doc => {
            if (doc.value === docValue) {
                if (this.exceptionMap[doc.label]) {
                    this.exceptionToast(doc.label);
                }else{
                    return {...doc, selected: !doc.selected};
                }
            }
            return doc;
        });
    }

    handleSelectAllChange(event) {
        const value = event.target.checked;
        try {
            this.allCheckBtn = value;
            this.filteredDocuments = this.filteredDocuments.map(doc => {
                if (this.exceptionMap[doc.label] && value) {
                    this.exceptionToast(doc.label);
                    return doc;
                }
                return {...doc, selected: value};
            });
        } catch (err) {
            console.log('err :: ', err.message);
        }
    }

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
                console.log(doc.label);
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

    handleViewRow(event) {
        event.stopPropagation();
        const docValue = event.currentTarget.dataset.id;
        this.filteredDocuments = this.filteredDocuments.map(doc => {
            if (doc.value === docValue) {
                if (this.exceptionMap[doc.label]) {
                    this.exceptionToast(doc.label);
                } else if (doc.label === '최종 견적서') {
                    window.open(doc.value + this.quoteId + '&language=KR', 'PDF Viewer', 'width=1100,height=600,scrollbars=yes,resizable=yes');
                } else {
                    window.open(doc.value + this.recordId, 'PDF Viewer', 'width=1100,height=600,scrollbars=yes,resizable=yes');
                }
            }
            return doc;
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

    handleCheckboxChange(event) {
        event.stopPropagation(); // 이벤트 전파 방지
        const value = event.target.value;

        this.filteredDocuments = this.filteredDocuments.map(doc => {
            if (doc.value === value) {
                console.log(doc.value);
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

    // handlePrint() {
    //     // 입력값 검증
    //     if (isNaN(this.firstNo) || isNaN(this.lastNo)) {
    //         alert('숫자만 입력해주세요.');
    //         return;
    //     }
    //     const fromNumber = parseInt(this.firstNo, 10);
    //     const toNumber = parseInt(this.lastNo, 10);
    //     if (fromNumber > toNumber) {
    //         alert('시작 번호가 끝 번호보다 큽니다.');
    //         return;
    //     }
    //     if ((toNumber - fromNumber) > 100) {
    //         alert('한번에 100매 이하로 출력 바랍니다.');
    //         return;
    //     }
    //
    //     this.taxRefundURL = '&from_no=' + fromNumber + '&to_no=' + toNumber;
    //     // 새 창에서 URL 열기
    //     this.isTaxRefundModal = !this.isTaxRefundModal;
    //     console.log(this.downloadAll);
    //     if (this.downloadAll) {
    //         this.downloadAll = !this.downloadAll;
    //         this.handleDownloadSelected();
    //
    //     } else {
    //         this.filteredDocuments = this.filteredDocuments.map(doc => {
    //             if (doc.value === this.clickedDoc.value) {
    //                 return {...doc, selected: true};
    //             }
    //             return doc;
    //         });
    //     }
    //     // else if (doc.label === '최종 견적서') {
    //     //     window.open(this.clickedDoc.value + this.quoteId + '&language=KR' + this.taxRefundURL, 'PDF Viewer', 'width=1100,height=600,scrollbars=yes,resizable=yes');
    //     // } else {
    //     //     window.open(this.clickedDoc.value + this.recordId + this.taxRefundURL, 'PDF Viewer', 'width=1100,height=600,scrollbars=yes,resizable=yes');
    //     // }
    //
    // }

    // closeModal() {
    //     this.isTaxRefundModal = !this.isTaxRefundModal;
    //     this.allCheckBtn = false;
    //     this.filteredDocuments = this.filteredDocuments.map(doc => ({...doc, selected: false}));
    // }

    exceptionToast(label) {
        showToast(label, "PDF 생성에 필요한 필수 데이터가 누락되었습니다.", "warning");
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}