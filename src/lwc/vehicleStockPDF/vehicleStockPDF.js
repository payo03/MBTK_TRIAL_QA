/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-13
 * @description :
 * @target :
 ==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-13        San.Kang           Created
 **************************************************************/
import {LightningElement, track, api, wire} from "lwc";
import {CloseActionScreenEvent} from "lightning/actions";
import {CurrentPageReference} from "lightning/navigation";

import getVehicleStockInit from "@salesforce/apex/PDFCommonController.getVehicleStockInit";
import downloadSelectedPDFs from "@salesforce/apex/PDFCommonController.downloadSelectedPDFs";
import updatedTempDriver from "@salesforce/apex/PDFCommonController.updatedTempDriver";
import {labelList, showToast} from "c/commonUtil";
import {NavigationMixin} from "lightning/navigation";
import formFactor from "@salesforce/client/formFactor";

export default class vehicleStockPDF extends NavigationMixin(LightningElement) {

    recordId;
    @track allDocuments = [
//        { label: '고객정보활용동의서', value: '/apex/AgreementLocator?id=', selected: false },
        {label: "고객동의서", value: "/apex/SNSAgreement?id=", selected: false, isNeedCheck: false, isOpen: false, downloadStatus: false},
        {label: "안전기준 적합 여부 확인서", value: "/apex/CarSafetyStandards?id=", selected: false, isNeedCheck: false, isOpen: false, downloadStatus: false},
        {label: "연료탱크 용량 확인서", value: "/apex/TankVolumeCert?id=", selected: false, isNeedCheck: false, isOpen: false, downloadStatus: false},
        {label: "양도증명서 및 제작증", value: "/apex/TransCert?id=", selected: false, isNeedCheck: false, isOpen: false, downloadStatus: false},
        {label: "제작증", value: "/apex/VehiceManufactCert?id=", selected: false, isNeedCheck: false, isOpen: false, downloadStatus: false},
        {label: "첨단안전장치 설치 확인서", value: "/apex/AdvancedSafetyDevice?id=", selected: false, isNeedCheck: false, isOpen: false},
        {label: "첨단안전장치 설치 확인서(덤프)", value: "/apex/AdvancedSafetyDevice_Dump?id=", selected: false, isNeedCheck: false, isOpen: false},
        {label: "차량인수인계서", value: "/apex/PdfTakeTruck?isdtp=p1&id=", selected: false, showSignature: true, isNeedCheck: false, isOpen: false, downloadStatus: false},
        {label: "차량 용품 패키지 장착 요청서", value: "/apex/VehiclePackageCover?id=", selected: false, isNeedCheck: false, isOpen: false, downloadStatus: false},
        {label: "주유상품권 수령증", value: "/apex/OilReceipt?isdtp=p1&id=", selected: false, showSignature: true, isNeedCheck: false, isOpen: false, downloadStatus: false},
        {label: "덮개장착요청서", value: "/apex/DumpAutoCover?id=", selected: false, isNeedCheck: false, isOpen: false, downloadStatus: false},
        {label: "최소회전반경적합확인서", value: "/apex/TurningRadius?id=", selected: false, isNeedCheck: false, isOpen: false, downloadStatus: false},
        {label: "자기인증 라벨", value: "/apex/CompliancePDF?id=", selected: false, isNeedCheck: false, isOpen: false, downloadStatus: false},
        {label: "출고증", value: "/apex/ReleaseCert?id=", selected: false, isNeedCheck: false, isOpen: false, downloadStatus: false},
        {label: "교육증", value: "/apex/ProfiDrive?id=", selected: false, isNeedCheck: false, isOpen: false, downloadStatus: false},
        {label: "임시운행허가신청서", value: "/apex/TempDrivePermit?id=", selected: false, isNeedCheck: false, isOpen: false, downloadStatus: false}
    ];
    @track filteredDocuments = [...this.allDocuments];

    @track exceptionMap = {
        '고객동의서': [],
        '안전기준 적합 여부 확인서': [],
        '첨단안전장치 설치 확인서': [],
        '첨단안전장치 설치 확인서(덤프)': [],
        '양도증명서 및 제작증': [],
        '제작증': [],
        '차량인수인계서': [],
        '차량 용품 패키지 장착 요청서': [],
        '덮개장착요청서': [],
        '주유상품권 수령증': [],
        '출고증': [],
        '교육증': [],
        '임시운행허가신청서': [],
        '최소회전반경적합확인서': [],
        '자기인증 라벨': []
    };
    @track pdiTeamAllUserArray ={};
    @track pdiTeamUserArray = {};
    @track opportunity = {};
    @track downloadFlag = false;
    @track isReleaseDateModalOpen = false;
    @track isTempDriveIntroModalOpen = false;
    @track modalMap = {isOilReceipt: false, oilReceiptUrl: "", isHandOver: false, handOverUrl: "", isSignature: false};
    @track downloadAll = false;
    allCheckBtn = false;
    @track rrnErrorMsg = '';  // 오류 메시지
    @track errorClass = '';  // 오류 스타일
    tempReqDate;
    drivePurpose;
    driveDays;
    userName;
    userRRN;
    userAddr;
    userDetailAddr='';
    userRoadAddr;
    docReleaseDate;
    releaseDate = '';
    tempDriveIntroUrl = '';
    isNewUserChecked;
    isAddressSearch = false;
    vfHost = labelList.VFHost;
    // 로딩
    isLoading;

    get modalStyle() {
        return this.modalMap.isSignature ? "text-align: center;" : "height: 100vh;";
    }

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state) {
            if (formFactor === "Large") {
                this.recordId = pageRef.state.recordId;
            } else {
                this.recordId = pageRef.state.c__recordId;
            }
        }
    }

    connectedCallback() {
        window.addEventListener("message", this.getDataFromChild.bind(this));
        this.resizePop();

        getVehicleStockInit({recordId: this.recordId}).then(res => {

            this.tempReqDate = res.vehicleStock?.TempReqDate__c;
            this.drivePurpose = res.vehicleStock?.DrivePurpose__c == null ? "신규등록" : res.vehicleStock.DrivePurpose__c;
            this.opportunity = !res.opportunity || res.opportunity.length === 0 ? {} : { ...res.opportunity[0] };

            this.driveDays = res.vehicleStock?.DriveDays__c;
            let checkMngNo = res?.vehicleStock?.MngNo__c && res.vehicleStock.MngNo__c.length > 5;
            if (checkMngNo && typeof res.vehicleStock.MngNo__c === 'string') {
                checkMngNo = res.vehicleStock.MngNo__c.charAt(4) === '5';
            }
            const tractorList = ['SAFETY PACKAGE PLUS TRACTOR'];
            const cargoList = ['SAFETY PACKAGE CARGO', 'SAFETY PACKAGE TIPPER'];
            const oldDumpList = ['TGS_41.510_8X4_BB', 'TGS_41.470_8X4_BB', 'TGS_41.510_8x4_BB_CH'];
            const newDumpList = ['TGS_41.470_8x4_BB_CH', 'TGS_41.480_8x4_BB_CH', 'TGS_41.520_8x4_BB_CH'];

            const description = res.vehicleStock?.Safety_Package_Description__c?.toUpperCase() || '';
            const checkSafetyTractor = tractorList.includes(description);
            const checkSafetyCargo = cargoList.includes(description);
            const checkSafetyDump = oldDumpList.includes(res?.vehicleStock?.SpecShort__c) && res?.vehicleStock?.Product__r?.CabMark__c === 'M' || newDumpList.includes(res?.vehicleStock?.SpecShort__c) && res?.vehicleStock.Product__r?.CabMark__c === 'NN'
            const cargoCheck = ["LDC", "MDC", "HDC"].includes(res?.vehicleStock?.Product__r?.Segment2__c) || (res?.vehicleStock?.Product__r?.Segment2__c === 'TPP' && res?.vehicleStock?.Shasi__c);
            const tppCheck = ["TPP"].includes(res?.vehicleStock?.Product__r?.Segment2__c);
            const trtCheck = ["TRT"].includes(res?.vehicleStock?.Product__r?.Segment2__c);
            const checkSpecShort = res?.vehicleStock?.SpecShort__c
                ? res.vehicleStock.SpecShort__c.toUpperCase().includes('10X4' || '10X04' || 'TGS')
                : false;
            const mgUserCheck = res.mgmtUser;
            const saUserCheck = res.saUser;
            console.log(mgUserCheck);
            if (Array.isArray(res.user) && res.user.length > 0) {
                this.pdiTeamAllUserArray = res.user.map(user => ({
                    Id: user.Id,
                    name: user.Name,
                    idNumber: user.IDNumber__c,
                    address: user.Street,
                    checked: false // 체크박스 상태 추가

                }));
                this.pdiTeamUserArray = [...this.pdiTeamAllUserArray];
            }


            Object.assign(this.exceptionMap, {
                '고객동의서': {
                    required: res?.opportunity?.[0] == null,
                    type: false
                },
                '안전기준 적합 여부 확인서': {
                    required: res?.opportunity?.[0] == null || !checkMngNo,
                    type: !cargoCheck,
                    errMsg : '카고 차량이 아닐 경우, PDF를 열 수 없습니다.'
                },
                '첨단안전장치 설치 확인서': {
                    required: res?.opportunity?.[0] == null,
                    type: !(checkSafetyTractor || checkSafetyCargo),
                    errMsg : '차량 타입이 조건에 만족하지 않습니다.'
                },
                '첨단안전장치 설치 확인서(덤프)': {
                    required: res?.opportunity?.[0] == null,
                    type: !checkSafetyDump,
                    errMsg : '차량 타입이 조건에 만족하지 않습니다.'
                },
                '양도증명서 및 제작증': {
                    required: res?.opportunity?.[0] == null,
                    type: !tppCheck,
                    errMsg : '덤프 차량이 아닐 경우, PDF를 열 수 없습니다.'
                },
                '제작증': {
                    required: res?.opportunity?.[0] == null,
                    type: !(trtCheck || cargoCheck),
                    errMsg : '트랙터나 카고 차량이 아닐 경우, PDF를 열 수 없습니다.'
                },
                '차량인수인계서': {
                    required: res?.opportunity?.[0] == null,
                    type: false,
                    profile: saUserCheck,
                    profileMsg : '해당 프로필은 PDF를 열 수 있는 권한이 없습니다.'

                },
                '차량 용품 패키지 장착 요청서': {
                    required: res?.opportunity?.[0] == null,
                    type: false,
                    profile: saUserCheck,
                    profileMsg : '해당 프로필은 PDF를 열 수 있는 권한이 없습니다.'
                },
                '덮개장착요청서': {
                    required: res?.opportunity?.[0] == null,
                    type: !tppCheck,
                    errMsg : '덤프 차량이 아닐 경우, PDF를 열 수 없습니다.',
                    profile: saUserCheck,
                    profileMsg : '해당 프로필은 PDF를 열 수 있는 권한이 없습니다.'
                },
                '주유상품권 수령증': {
                    required: res?.opportunity?.[0] == null,
                    type: false,
                    profile: (mgUserCheck || saUserCheck),
                    profileMsg : '해당 프로필은 PDF를 열 수 있는 권한이 없습니다.'
                },
                '출고증': {
                    required: res?.opportunity?.[0] == null || res?.opportunity?.[0]?.HandoverDate__c == null,
                    type: false,
                    profile: mgUserCheck || saUserCheck,
                    profileMsg : '해당 프로필은 PDF를 열 수 있는 권한이 없습니다.'
                },
                '교육증': {
                    required: res?.opportunity?.[0] == null,
                    type: false,
                    profile: mgUserCheck || saUserCheck,
                    profileMsg : '해당 프로필은 PDF를 열 수 있는 권한이 없습니다.'
                },
                '임시운행허가신청서': {
                    required: res?.opportunity?.[0] == null,
                    type: !(cargoCheck || trtCheck),
                    errMsg : '트랙터나 카고 차량이 아닐 경우, PDF를 열 수 없습니다.',
                    profile: mgUserCheck || saUserCheck,
                    profileMsg : '해당 프로필은 PDF를 열 수 있는 권한이 없습니다.'
                },
                '자기인증 라벨': {
                    required: res.vehicleStock?.Product__c == null || res.vehicleStock?.Product__r?.SelfCertWeightLabel__c == null,
                    type: false,
                    profile: mgUserCheck || saUserCheck,
                    profileMsg : '해당 프로필은 PDF를 열 수 있는 권한이 없습니다.'
                },
                '최소회전반경적합확인서': {
                    required: false,
                    type: !(cargoCheck && checkSpecShort),
                    errMsg : '10x4 카고 차량이 아닐 경우, PDF를 열 수 없습니다.'
                }
            });
        })
        .catch(err => {
            showToast(err?.body?.message || err.message || "ERROR", "", "warning");
        })
    }
    resizePop() {
        let modalBody = document.querySelector('.modal-body');
        let closeIcon = document.querySelector('.closeIcon');

        let modalWidth = 600;

        if (modalBody && closeIcon) {
            // modal-body width 설정
            modalBody.style.width = `${modalWidth}px`;
            modalBody.style.margin = '0 auto';

            // 부모 요소 너비 기준으로 closeIcon 위치 조정
            const containerWidth = modalBody.parentElement.offsetWidth;
            const adjustedMarginRight = (containerWidth - modalWidth) / 2;

            closeIcon.style.marginRight = `${adjustedMarginRight}px`;
        }
        // 스타일 요소가 이미 존재하는지 확인
        let styleEl = document.querySelector(".releasedate-custom-style");

        // 첫 로드 시 한 번만 실행
        if (!styleEl) {
            // LWC 내부 요소에서 lightning-input을 찾을 때까지 기다림
            requestAnimationFrame(() => {
                if (this.template.querySelector("lightning-input")) {
                    styleEl = document.createElement("style");
                    styleEl.className = "releasedate-custom-style";
                    styleEl.innerText = ".slds-form-element__help { display: none !important; }";

                    // LWC 내부 shadow DOM이 아니라 document에 추가하여 적용
                    document.head.appendChild(styleEl);
                }
            });
        }
    }

    get docsWithClass() {
        return this.filteredDocuments.map(doc => {
            let baseClass = "cellBorder slds-p-vertical_xx-small slds-m-bottom_xx-small";
            if (doc.selected) {
                baseClass += " selectedRow";
            }
            return {...doc, docClass: baseClass};
        });
    }

    handleCheckboxClick(event) {
        event.stopPropagation();
    }


    handleAddressSearch(){
        this.isAddressSearch = true;
    }

    handleLoad() {
        const iframe = this.template.querySelector("iframe");
        if (iframe) {
            const contentWindow = iframe.contentWindow;
            const data = { target: "address_vehicleStockPDF", formFactor: formFactor };
            contentWindow.postMessage(data, this.vfHost);
        }
    }

    getDataFromChild(e) {
        if (this.vfHost !== e.origin || e.data.target !== "address_vehicleStockPDF") return;
        this.isAddressSearch = false;
        this.userRoadAddr = e.data.roadAddress;
    }

    handleCheckboxChange(event) {
        event.stopPropagation(); // 이벤트 전파 방지
        const docValue =event.target.value;
        this.filteredDocuments = this.filteredDocuments.map(doc => {
            if (doc.value === docValue) {
                if (this.exceptionMap[doc.label]?.profile || this.exceptionMap[doc.label]?.type || this.exceptionMap[doc.label]?.required) {
                    this.exceptionToast(doc);
                    event.target.checked = false;
                } else if (doc.label === "출고증" || doc.label === "교육증") {
                    doc.isNeedCheck = true;
                    doc.selected = true;
                } else if (doc.label === "임시운행허가신청서") {
                    doc.isNeedCheck = true;
                    doc.selected = true;
                } else {
                    return {...doc, selected: !doc.selected, downloadStatus: false};
                }
            }
            return doc;
        });
    }

    handleDateChange(event) {
        this.docReleaseDate = event.target.value;
    }

    handleUserNameChange(event) {
        this.userName = event.target.value;
    }

    handleUserRRNChange(event) {
        const inputField = event.target;
        const userInput = event.target.value;
        const result = this.validateUserRRN(userInput);

        if (result.isValid) {
            this.userRRN = userInput;
            this.rrnErrorMsg = '';
            this.errorClass = '';  // 오류 스타일 초기화
            inputField.setCustomValidity("");  // 오류 메시지 초기화
        } else {
            this.rrnErrorMsg = result.message;
            this.errorClass = 'slds-has-error';  // 오류 스타일 적용
            inputField.setCustomValidity(result.message);  // 오류 메시지 설정
        }

        inputField.reportValidity();  // 유효성 검사 메시지 표시
    }

    validateUserRRN(userRRN) {
        if (!userRRN) {
            return { isValid: false, message: '주민번호를 입력하세요.' };
        }

        // 1. '-' 제거
        let idStr = userRRN.replace(/-/g, '');

        // 2. 길이 및 숫자 여부 확인
        if (idStr.length !== 13 || !/^\d{13}$/.test(idStr)) {
            return { isValid: false, message: '유효한 주민번호가 아닙니다.' };
        }

        // 3. 가중치 리스트
        const weights = [2, 3, 4, 5, 6, 7, 8, 9, 2, 3, 4, 5];

        // 4. 합계 계산
        let sum = 0;
        for (let i = 0; i < 12; i++) {
            sum += parseInt(idStr[i], 10) * weights[i];
        }

        // 5. 검증번호 계산
        let checkNum = 11 - (sum % 11);
        if (checkNum === 10) checkNum = 0;
        if (checkNum === 11) checkNum = 1;

        // 6. 마지막 자리 비교
        let lastDigit = parseInt(idStr[12], 10);
        if (checkNum !== lastDigit) {
            return { isValid: false, message: '유효한 주민번호가 아닙니다.' };
        }

        return { isValid: true, message: '' };
    }

    handleUserAddrChange(event) {
        this.userAddr = event.target.value;
    }

    handleUserDetailAddrChange(event) {
        this.userDetailAddr = event.target.value;
    }

    handleTempDriveIntro() {
        console.log('test');
        if (!this.driveDays || !this.tempReqDate || !this.drivePurpose) {
            alert("운행 관련 필드를 입력 해 주세요.");
            return;
        }
        if (this.isNewUserChecked && (!this.userName || !this.userRRN || !this.userRoadAddr)) {
            alert("신청인 필드를 입력 해 주세요.");
            return;
        }

        if ( !this.pdiTeamUserArray.some(user => user.checked) && !this.isNewUserChecked ){
            alert("신청인을 선택 해 주세요.");
            return;
        }
        try {
            this.isAddressSearch = false;
            let driverAddr = this.userRoadAddr + this.userDetailAddr;
            let driverName = this.userName;
            let driverIDNumber = this.userRRN;
            if (!this.isNewUserChecked) {
                this.pdiTeamUserArray = this.pdiTeamUserArray.map(user => {

                    if (user.checked) {
                        driverName = user.name != null ? user.name : '';
                        driverAddr = user.address != null ? user.address : '';
                        driverIDNumber = user.idNumber != null ? user.idNumber : '';
                    }
                });
                this.pdiTeamUserArray = [...this.pdiTeamAllUserArray];
            }

            this.tempDriveIntroUrl = "&name=" + driverName + "&rrn=" + driverIDNumber + "&addr=" + driverAddr + "&driveDays=" + this.driveDays + "&drivePurpose=" + this.drivePurpose + "&tempReqDate=" + this.tempReqDate;
            this.isTempDriveIntroModalOpen = !this.isTempDriveIntroModalOpen;
            this.filteredDocuments = this.filteredDocuments.map(doc => {
                if ( doc.label === '임시운행허가신청서' ){
                    const tempDriverMap = {
                        driveDays: this.driveDays,
                        drivePurpose: this.drivePurpose,
                        tempReqDate: this.tempReqDate
                    }
                    updatedTempDriver({recordId: this.recordId, tempDriverMap: tempDriverMap}).then(res => {
                        console.log('업데이트 되었습니다.');
                    });
                }

                if (doc.label === '임시운행허가신청서' && this.downloadFlag) {
                    if (doc.isNeedCheck) {
                        return { ...doc, isNeedCheck: false, downloadStatus: true };
                    } else {
                        return {...doc, selected: true};
                    }
                } else if (doc.isOpen) {
                    window.open(doc.value + this.recordId + this.tempDriveIntroUrl, "PDF Viewer", "width=1100,height=600,scrollbars=yes,resizable=yes");
                    return {...doc, selected: false, isOpen: false};
                }

                return doc;
            });
            if(this.downloadFlag) this.handleDownloadSelected();

        } catch (e) {
            console.log('err msg ::', e.message);
        }
    }

    handleDriverChange(event) {
        const selectedValue = event.target.value;
        const selectedChecked = event.target.checked;
        // 기존 유저 선택 시
        if (selectedValue !== "newUser") {
            this.pdiTeamUserArray = this.pdiTeamUserArray.map(user => {
                if(user.Id === selectedValue){
                    return { ...user, checked: selectedValue }
                }else{
                    return { ...user, checked: false };
                }
            });
            this.isNewUserChecked = false;
        } else {
            this.pdiTeamUserArray = this.pdiTeamUserArray.map(user => {
                return { ...user, checked: false };
            });
            this.isNewUserChecked = selectedChecked;
        }
    }

    handleInputChange(event) {
        const fieldName = event.target.dataset.field; // data-field 속성에서 필드명 가져오기
        const fieldValue = event.target.value; // 입력된 값 가져오기

        // 필드 업데이트
        this[fieldName] = fieldValue;
    }


    handleViewRow(event) {
        this.filteredDocuments = this.filteredDocuments.map(doc => ({...doc, isOpen: false}));
        event.stopPropagation();
        try {
            const docValue = event.currentTarget.dataset.id;
            this.filteredDocuments = this.filteredDocuments.map(doc => {
                if (doc.value === docValue) {
                    console.log('test');
                    console.log(this.exceptionMap[doc.label]?.profile);
                    console.log(this.exceptionMap[doc.label]?.type);
                    console.log(this.exceptionMap[doc.label]?.required);
                    if (this.exceptionMap[doc.label]?.profile || this.exceptionMap[doc.label]?.type || this.exceptionMap[doc.label]?.required) {
                        this.exceptionToast(doc);
                    } else if (doc.label === "출고증" || doc.label === "교육증") {
                        this.isReleaseDateModalOpen = true;
                        return {...doc, isOpen: true};

                    } else if (doc.label === "임시운행허가신청서") {
                        console.log('test3');
                        this.isTempDriveIntroModalOpen = true;
                        console.log('test5');
                        return {...doc, isOpen: true};

                    } else {
                        if(doc.label === "제작증"){
                            window.open(doc.value + this.opportunity.Id, "PDF Viewer", "width=1100,height=600,scrollbars=yes,resizable=yes");
                        } else {
                            window.open(doc.value + this.recordId + this.tempDriveIntroUrl, "PDF Viewer", "width=1100,height=600,scrollbars=yes,resizable=yes");
                        }

                    }
                    console.log('test2');
                }
                this.downloadFlag = false;
                return doc;
            });
        } catch (e) {
            console.log(e.message);
        }
    }

    handleConfirm() {
        if (this.docReleaseDate == null) {
            alert("실 출고일을 입력하세요.");
            return;
        }
        try {
            const [year, month, day] = this.docReleaseDate.split("-");
            this.releaseDate = "&year=" + year + "&month=" + month + "&day=" + day;
            this.isReleaseDateModalOpen = !this.isReleaseDateModalOpen;

            // filteredDocuments 상태 업데이트 (모든 분기에서 항상 객체 반환)
            this.filteredDocuments = this.filteredDocuments.map(doc => {
                if ((doc.label === '출고증' || doc.label === '교육증') && doc.selected && !doc.isOpen) {
                    if (doc.isNeedCheck) {
                        return {...doc, selected: true, isNeedCheck: false, downloadStatus: true};
                    } else {
                        return {...doc, selected: true};
                    }
                } else if (doc.isOpen) {
                    // 여기서 각 항목의 URL을 사용 (doc.value)
                    if (doc.label === "출고증") {
                        window.open(doc.value + this.opportunity.Id + this.releaseDate, "PDF Viewer", "width=1100,height=600,scrollbars=yes,resizable=yes");
                        return {...doc, isOpen: false};
                    } else if(doc.label === "교육증") {
                        window.open(doc.value + this.recordId + this.releaseDate, "PDF Viewer", "width=1100,height=600,scrollbars=yes,resizable=yes");
                        return {...doc, isOpen: false};
                    }
                }
                // 조건에 해당하지 않는 경우 원본 doc을 그대로 반환
                return doc;
            });

            // 모든 문서 업데이트 후 한 번만 다운로드 처리
            if(this.downloadFlag) this.handleDownloadSelected();
        } catch (e) {
            console.log(e.message);
        }
    }



    handleRowClick(event) {
        event.stopPropagation();
        const docValue = event.currentTarget.dataset.id;
        this.filteredDocuments = this.filteredDocuments.map(doc => {
            if (doc.value === docValue) {
                if (this.exceptionMap[doc.label]?.profile || this.exceptionMap[doc.label]?.type || this.exceptionMap[doc.label]?.required) {
                    this.exceptionToast(doc);
                    return doc;
                } else if (doc.label === "출고증" || doc.label === "교육증") {
                    doc.isNeedCheck = !doc.selected;
                    doc.selected = !doc.selected;
                } else if (doc.label === "임시운행허가신청서") {
                    doc.isNeedCheck = !doc.selected;
                    doc.selected = !doc.selected;
                } else {
                    return {...doc, selected: !doc.selected, downloadStatus: false};
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
                if (this.exceptionMap[doc.label]?.profile || this.exceptionMap[doc.label]?.type || this.exceptionMap[doc.label]?.required && value) {

                    // this.exceptionToast(doc);
                    return doc;
                } else {
                    if (doc.label === '출고증' || doc.label === '교육증' || doc.label === "임시운행허가신청서") {
                        return {...doc, selected: value, isNeedCheck: value, downloadStatus: false};
                    }
                    return {...doc, selected: value, downloadStatusd: false};
                }
            });
        } catch (err) {
            console.log('err :: ', err.message);
        }

    }
    handleDownloadSelected() {
        const validDocs = (this.filteredDocuments || []).filter(doc => doc);
        this.downloadFlag = true;
        if (this.filteredDocuments.filter(doc => doc.selected).length === 0) {
            showToast('다운로드 할 PDF 항목을 선택 해 주세요.', "", "warning");
            return;
        }

        this.filteredDocuments = validDocs.map(doc => {
            if (doc.selected) {
                doc.downloadUrl = doc.value + this.recordId;
                if (doc.isNeedCheck) {
                    if ((doc.label === "출고증" || doc.label === "교육증")) {
                        this.isReleaseDateModalOpen = true;
                    } else if (doc.label === "임시운행허가신청서") {
                        console.log('test???')
                        this.isTempDriveIntroModalOpen = true;
                    }
                    return doc;
                } else {
                    if (doc.label === "출고증") {
                        doc.downloadUrl = doc.value + this.opportunity.Id + this.releaseDate;
                    } else if (doc.label === "교육증") {
                        doc.downloadUrl = doc.value + this.recordId + this.releaseDate;
                    } else if (doc.label === "임시운행허가신청서") {
                        doc.downloadUrl = doc.value + this.recordId + this.tempDriveIntroUrl;
                    } else if (doc.label === "주유상품권 수령증") {
                        doc.downloadUrl = "/apex/OilReceipt?id=" + this.recordId;
                    } else if (doc.label === "차량인수인계서") {
                        doc.downloadUrl = "/apex/PdfTakeTruck?id=" + this.recordId;
                    } else if (doc.label === "제작증"){
                        doc.downloadUrl = doc.value + this.opportunity.Id;
                    }
                }
                return { ...doc, downloadStatus: true };
            }
            return doc;
        });

        if (this.filteredDocuments.filter(doc => doc.selected).length === this.filteredDocuments.filter(doc => doc.downloadStatus).length) {
            this.filteredDocuments.forEach(doc => {
                if (doc.downloadStatus) {
                    this.handleDownload(doc);  // 변경: doc 전체를 전달
                    this.downloadFlag = false;
                    if(('출고증','교육증','임시운행허가서').includes(doc.label)) console.log('test',doc.label); doc.isNeedCheck = true;
                }
                return { ...doc, downloadStatus: false, isOpen: false };
            });
        }
    }

// doc 객체를 받도록 수정
    handleDownload(doc) {
        downloadSelectedPDFs({ vfUrl: doc.downloadUrl})
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
    }


    base64ToBlob(base64, contentType) {
        contentType = contentType || "";
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

    closeReleaseDateModal() {
        this.isReleaseDateModalOpen = !this.isReleaseDateModalOpen;
    }

    closeIsTempDriveIntroModal() {
        this.isTempDriveIntroModalOpen = !this.isTempDriveIntroModalOpen;
        this.isAddressSearch = false;

    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    exceptionToast(doc) {
        if(this.exceptionMap[doc.label].profile){
            showToast(doc.label, this.exceptionMap[doc.label].profileMsg, "warning");
        } else if (this.exceptionMap[doc.label].type) {
            showToast(doc.label, this.exceptionMap[doc.label].errMsg, "warning");
        } else if (this.exceptionMap[doc.label].required){
            showToast(doc.label, "PDF 생성에 필요한 필수 데이터가 누락되었습니다.", "warning");
        }
    }

    handleResignRow(event) {
        event.stopPropagation();
        const docValue = event.currentTarget.dataset.id;
        this.filteredDocuments = this.filteredDocuments.map(doc => {
            if (doc.value === docValue) {
                if (this.exceptionMap[doc.label]?.profile || this.exceptionMap[doc.label]?.type || this.exceptionMap[doc.label]?.required) {
                    this.exceptionToast(doc);
                } else if(doc.label === '주유상품권 수령증'){
                    this.modalMap.isOilReceipt = true;
                    this.modalMap.oilReceiptUrl = `${doc.value + this.recordId + "#zoom=50"}`;
                }else{
                    this.modalMap.isHandOver = true;
                    this.modalMap.handOverUrl = `${doc.value + this.recordId + "#zoom=50"}`;
                }
            }
            return doc;
        });
    }
    handleClickModal(e)
    {
        const name = e.target.dataset.name;
        switch (name) {
            case "cancel":
                if (this.modalMap.isSignature) {
                    this.modalMap.isSignature = false;
                    break;
                }
                Object.keys(this.modalMap).forEach(key => {
                    if (key === "oilReceiptUrl" || key === "handOverUrl") {
                        this.modalMap[key] = "";
                    } else {
                        this.modalMap[key] = false;
                    }
                });
                return;
            case "signature":
                this.modalMap.isSignature = true;
                break;
            case "save":
                if (this.modalMap.isSignature) {
                    this.isLoading = true;
                    let dataMap;
                    if(this.modalMap.isOilReceipt){
                        dataMap = {
                            value: "차량관리-주유상품권서명",
                            label: "주유상품권 수령증"
                        }
                    } else {
                        dataMap = {
                            value: "차량재고-차량인수서명",
                            label: "차량인수 서명"
                        }
                    }
                    const result = this.template.querySelector("c-signature-pad").doSave(this.recordId, dataMap);
                    setTimeout(() => {
                        if (result) {
                            this.modalMap.isSignature = false;
                        }
                        this.isLoading = false;
                    }, 1000);
                    break;
                }
                break;
        }
    }
}