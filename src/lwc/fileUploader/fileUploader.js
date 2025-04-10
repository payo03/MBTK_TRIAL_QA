import { LightningElement,api, track, wire } from 'lwc';
import fileNameUpdate from "@salesforce/apex/OpptyFileUploaderController.fileNameUpdate";
import getVATStatus from "@salesforce/apex/OpptyFileUploaderController.getVATStatus";
import getInit from "@salesforce/apex/OpptyFileUploaderController.getInit";
import { CloseActionScreenEvent } from "lightning/actions";
import { recordNavigation, showToast } from "c/commonUtil";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import formFactorPropertyName from '@salesforce/client/formFactor';

export default class FileUploader extends NavigationMixin(LightningElement) {

    @api recordId;
    file1Details = null;
    file2Details = null;
    @track files = [];
    @track file3Details = [];
    @track isVATApproved = false; // VAT 상태 저장
    username;
    newFiles;
    isLoading = false;
    isJumin;
    isBus;
    isVAT;
    accept = [".jpg",  ".png", ".pdf", ".heic"];

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state) {
            if (formFactorPropertyName === 'Large') {
                console.log('컴퓨터3333');
                this.recordId = pageRef.state.recordId;
            } else {
                this.recordId = pageRef.state?.c__recordId;
            }
            this.accHandleName();
            this.checkVATStatus();
        }
    }
 
    // connectedCallback() {
    //     this.accHandleName();
    //     this.checkVATStatus();
    // }

    checkVATStatus() {
        getVATStatus({ recordId: this.recordId })
            .then((result) => {
                this.isVATApproved = result === '승인됨';
            })
            .catch((error) => {
                console.log('VAT 상태 조회 오류:', error);
                // showToast('실패', '부가세 후취 상태가 승인됨이어야지만 부가세후취 필수 파일 첨부가 가능합니다. ', 'error', 'dismissable');
            });
    }

    accHandleName() {
        getInit({recordId: this.recordId}).then(res => {
            this.username = res.userName;
            this.isJumin = res.checkFile?.['주민등록증'];
            this.isBus = res.checkFile?.['사업자등록증'];
            this.isVAT = res.checkFile?.['부가세후취'];

        }).catch(err => {
            console.log('err :: ',err);
        });
    }

    handleDragOver(event) {
        // event.preventDefault();
        // this.template.querySelector('.slds-file-selector__dropzone').classList.add('slds-has-drag-over');
        event.preventDefault(); // 기본 동작 방지

        // 드래그 중인 특정 영역만 선택
        const dropZone = event.target.closest('.slds-file-selector__dropzone');
        if (dropZone) {
            // 기존 드래그 오버 클래스를 모두 제거
            this.template.querySelectorAll('.slds-file-selector__dropzone').forEach(zone => {
                zone.classList.remove('slds-has-drag-over');
            });

            // 드래그 중인 특정 영역에만 클래스 추가
            dropZone.classList.add('slds-has-drag-over');
        }
    }

    handleDragLeave(event) {
        // 드래그가 떠난 특정 드롭존을 찾기
        const dropZone = event.target.closest('.slds-file-selector__dropzone');
        if (dropZone) {
            // 떠난 드롭존에서 클래스 제거
            dropZone.classList.remove('slds-has-drag-over');
        }
    }

    handleDrop(event) {
        event.preventDefault();

        const dropZone = event.target.closest('.slds-file-selector__dropzone');
        if (dropZone) {
            // 떠난 드롭존에서 클래스 제거
            dropZone.classList.remove('slds-has-drag-over');
        }
        // this.template.querySelector('.slds-file-selector__dropzone').classList.remove('slds-has-drag-over');

        const files = event.dataTransfer.files;
        // 드래그 앤 드롭에서 파일이 어느 필드(file1, file2, file3)에 들어가는지 지정
        const dropTargetName = event.currentTarget.dataset.name;

        this.handleUploadFinished({ target: { files, name: dropTargetName } });
    }

    handleUploadFinished(event) {
        this.newFiles = event.target.name;
        console.log('event ::: ', event.target.name);
        const filesTest = [...event.target.files]; // FileList를 배열로 변환

        let prefix = '';
        let activeFieldName = '';

        if(this.newFiles === 'file1' || this.newFiles === 'file2') {
            if (filesTest.length > 1) {
                showToast('실패', '단일 파일만 업로드 할 수 있습니다.', 'error', 'dismissable');
                return;
            }
        }

        let flag = false;
        filesTest.forEach(file => {
            const fileExtension = `.${file.name.split('.').pop().toLowerCase()}`;

            if(!this.accept.includes(fileExtension)) {
                flag = true;
            } 
        });


        if(flag) {
            showToast('파일 유형에 맞는 것을 업로드해주세요.', 'PDF 파일,이미지 파일(.jpg, .png)만 업로드 가능합니다.', 'warning');
            return;
        }

        switch (this.newFiles) {
            case 'file3':

                if (!this.isVATApproved) {
                    // showToast('부가세후취 파일 업로드 제한', '부가세 후취 상태가 승인됨일때만 부가세 후취 파일첨부가 가능합니다', 'error');
                    showToast('부가세후취 파일 업로드 제한', '부가세 후취 상태가 승인됨이어야지만 부가세후취 필수 파일 첨부가 가능합니다.', 'error', 'sticky');
                    return;
                }

                if(this.isVAT && this.newFiles === 'file3') {
                    showToast('이미 부가세후취 파일이 존재합니다.', '기존 부가세후취 파일을 전체 삭제 후 업로드 가능합니다.', 'warning');
                    break;
                }
                prefix = '부가세후취';
                activeFieldName = 'IsVAT__c';
                
                filesTest.forEach((file) => {

                    const filetype = file.name.split('.').pop();
                    const reader = new FileReader();
                    reader.onload = () => {

                        const base64 = reader.result.split(',')[1];
                        this.file3Details.push({
                            name : file.name,
                            // filename: `${prefix}${index + 1}_${this.username}.${filetype}`,
                            base64 : base64,
                            prefix: prefix,
                            filetype: filetype,
                            recordId: this.recordId,
                            isActiveFields: { [activeFieldName]: true }
                        });
                        
                        this.file3Details = this.file3Details.map((file, index) => {
                            return {
                                ...file,
                                key: prefix + index ,
                                filename: `${prefix}${index + 1}_${this.username}.${file.filetype}` // 번호 재할당
                            };
                        });
                    };
                    
                    reader.readAsDataURL(file);
                });

                break;
    
            case 'file1':
                if(this.isJumin && this.newFiles === 'file1') {
                    showToast('이미 주민등록증 파일이 존재합니다.', '기존 주민등록증 파일 삭제 후 업로드 가능합니다.', 'warning');
                    break;
                }
            case 'file2':
                if(this.isBus && this.newFiles === 'file2') {
                    showToast('이미 사업자등록증 파일이 존재합니다.', '기존 사업자등록증 파일 삭제 후 업로드 가능합니다.', 'warning');
                    break;
                }
                
                const fileName = this.newFiles === 'file1' ? this.file1Details?.name : this.file2Details?.name;
                const file = event.target.files[0];
                const filetype = file.name.split('.')[1];
                const reader = new FileReader();

                if (this.newFiles === 'file1') {
                    prefix = '주민등록증';
                    activeFieldName = 'isJumin__c';
                    this.file1Details = {
                        key: prefix,
                        name: file.name,
                    };

                } else if (this.newFiles === 'file2') {
                    prefix = '사업자등록증';
                    activeFieldName = 'IsBusiness__c';
                    this.file2Details = {
                        key: prefix,
                        name: file.name,
                    };
                }
                const key = prefix;
                
                reader.onload = () => {
                    const base64 = reader.result.split(',')[1];
                    this.files.push({
                        key: key,
                        name : file.name,
                        filename: `${prefix}_${this.username}.${filetype}`,
                        base64 : base64,
                        recordId: this.recordId,
                        prefix : prefix,
                        isActiveFields: { [activeFieldName]: true }
                    });

                    if(fileName) {
                        this.files = this.files?.filter(el => {
                            return el.name != fileName;
                        })
                    }
                };
    
                reader.readAsDataURL(file);
        }
    }

    handleChooseFile(e) {
        this.template.querySelector(`input[name="${e.target.name}"]`).click();
    }

    handleSave() {
        try {
            // if(this.isJumin == true && this.isBus == true) {
            //     showToast('이미 파일이 존재합니다.', '기존 파일들을 삭제 후 업로드하세요.', 'warning');
            //     return;
            // } 
            if(this.files.length < 1 && this.file3Details.length < 1) {
                showToast('실패', '업로드할 파일이 존재하지 않습니다', 'error', 'dismissable');
                return;
            } 
            // else if(this.file3Details.length < 5 ) {
            //     showToast('실패', '부가세후취에 업로드하는 파일의 개수가 6개미만인지 확인하세요', 'error', 'dismissable');
            //     return;
            // }
            else if(this.file3Details.length > 0 && this.file3Details.length < 6) {
                showToast('실패', '부가세후취 파일은 6개 이상부터 파일 저장이 가능합니다.', 'error', 'dismissable');
                return;
            }

            this.files = [...this.files, ...this.file3Details];
            this.isLoading = true;
            // 파일 업로드
            if (this.files.length > 0) {
                fileNameUpdate({ jsonFileList: JSON.stringify(this.files) })
                    .then(res => {
                        showToast('성공', '모든 파일 저장 성공', 'success', 'dismissable');
                        this.isLoading = false;
                        this.dispatchEvent(new CloseActionScreenEvent());   // Panel 닫기
                        this.mobileReturnPage();
                        setTimeout(() => {
                            window.location.reload();   // 새로고침
                        }, 1000);
                    })
                    .catch(err => {
                        console.log('err ::: ', err);
                    });
                    // .finally(() => {
                    //     this.isLoading = false;
                    // });
            } else {
                showToast('오류', '업로드할 파일이 없습니다.', 'error', 'dismissable');
                isLoading = false;
            }

        } catch(error) {
            console.error('Error uploading files:', error);
        }
    }

    handleRemove(e) {
        const name = e.target.dataset.name; // 삭제할 pill의 name
        const key = e.target.dataset.key;
        if(name === 'vat') {
            this.file3Details = this.file3Details.filter(el => el.key !== key);
        } else {
            this.files = this.files.filter(el => el.key !== key);
            if(name === 'regNum') this.file1Details = null;
            else if(name === 'bizNum') this.file2Details = null;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.mobileReturnPage();
    }

    mobileReturnPage() {
        if(formFactorPropertyName === "Small") {
            recordNavigation(this, "Opportunity", this.recordId);
        }
    }

}