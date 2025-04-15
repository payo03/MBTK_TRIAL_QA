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
    //PDF 전체 리스트
    @track allDocuments = [
        //                                                          선택          모달창 작성 체크        보기          다운로드 준비 상태
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

    //PDF Validation 리스트
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
    @track pdiTeamAllUserArray = [];
    @track pdiTeamUserArray = [];
    @track opportunity = {};
    @track downloadFlag = false;
    @track isReleaseDateModalOpen = false;
    @track isTempDriveIntroModalOpen = false;
    @track modalMap = {isOilReceipt: false, oilReceiptUrl: "", isHandOver: false, handOverUrl: "", isSignature: false};
    allCheckBtn = false; // 전체 선택
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
            let checkMngNo = res?.vehicleStock?.SpecTypeNo__r?.MngNo__c && res.vehicleStock?.SpecTypeNo__r?.MngNo__c.length > 5;
            if (checkMngNo && typeof res.vehicleStock?.SpecTypeNo__r?.MngNo__c === 'string') {
                checkMngNo = res.vehicleStock?.SpecTypeNo__r?.MngNo__c.charAt(4) === '5';
            }
            const tractorList = ['SAFETY PACKAGE PLUS TRACTOR'];
            const cargoList = ['SAFETY PACKAGE CARGO', 'SAFETY PACKAGE TIPPER'];
            const DumpList = ['TGS_41.510_8X4_BB', 'TGS_41.470_8X4_BB', 'TGS_41.510_8x4_BB_CH','TGS_41.470_8x4_BB_CH', 'TGS_41.480_8x4_BB_CH', 'TGS_41.520_8x4_BB_CH',
                                'TGS 41.510 8X4 BB', 'TGS 41.470 8X4 BB', 'TGS 41.510 8x4 BB CH','TGS 41.470 8x4 BB CH', 'TGS 41.480 8x4 BB CH', 'TGS 41.520 8x4 BB CH'];

            const description = res.vehicleStock?.Safety_Package_Description__c?.toUpperCase() || '';
            const checkSafetyTractor = tractorList.includes(description);
            const checkSafetyCargo = cargoList.includes(description);
            const checkSafetyDump = DumpList.includes(res?.vehicleStock?.SpecShort__c);
            const cargoCheck = ["LDC", "MDC", "HDC"].includes(res?.vehicleStock?.Product__r?.Segment2__c) || (res?.vehicleStock?.Product__r?.Segment2__c === 'TPP' && res?.vehicleStock?.Shasi__c);
            const tppCheck = ["TPP"].includes(res?.vehicleStock?.Product__r?.Segment2__c);
            const trtCheck = ["TRT"].includes(res?.vehicleStock?.Product__r?.Segment2__c);
            const checkSpecShort = res?.vehicleStock?.SpecShort__c
                ? res.vehicleStock.SpecShort__c.toUpperCase().includes('10X4' || '10X04' || 'TGS')
                : false;
            const mgUserCheck = res.mgmtUser;
            const saUserCheck = res.saUser;
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

            // PDF 조건 Validtaion
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

    // 팝업창 크기 조절
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

    // 선택 리스트 색 벽환
    get docsWithClass() {
        return this.filteredDocuments.map(doc => {
            let baseClass = "cellBorder slds-p-vertical_xx-small slds-m-bottom_xx-small";
            if (doc.selected) {
                baseClass += " selectedRow";
            }
            return {...doc, docClass: baseClass};
        });
    }

    // 이벤트 부모로 전파되는 것 방지
    handleCheckboxClick(event) {
        event.stopPropagation();
    }

    // 주소창 팝업
    handleAddressSearch(){
        this.isAddressSearch = true;
    }

    // 주소 검색 API 연결
    handleLoad() {
        const iframe = this.template.querySelector("iframe");
        if (iframe) {
            const contentWindow = iframe.contentWindow;
            const data = { target: "address_vehicleStockPDF", formFactor: formFactor };
            contentWindow.postMessage(data, this.vfHost);
        }
    }

    // 주소 저장
    getDataFromChild(e) {
        if (this.vfHost !== e.origin || e.data.target !== "address_vehicleStockPDF") return;
        this.isAddressSearch = false;
        this.userRoadAddr = e.data.roadAddress;
    }

    // 체크박스 클릭 이벤트
    handleCheckboxChange(event) {
        event.stopPropagation(); // 이벤트 전파 방지
        const docValue =event.target.value;
        this.filteredDocuments = this.filteredDocuments.map(doc => {
            if (doc.value === docValue) {
                // Validation 조건에 맞지않으면 토스트 메시지
                if (this.exceptionMap[doc.label]?.profile || this.exceptionMap[doc.label]?.type || this.exceptionMap[doc.label]?.required) {
                    this.exceptionToast(doc);
                    event.target.checked = false;
                } else if (doc.label === "출고증" || doc.label === "교육증") {
                    doc.isNeedCheck = true; // 모달창에서 값 입력 후 false
                    doc.selected = true; // 선택 됨 체크박스
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

    // 임시운행 PDF 실출고일 입력
    handleDateChange(event) {
        this.docReleaseDate = event.target.value;
    }

    // 임시운행 PDF UserName 입력
    handleUserNameChange(event) {
        this.userName = event.target.value;
    }

    // 임시운행 PDF 주민번호 입력
    handleUserRRNChange(event) {
        const inputField = event.target;
        const userInput = event.target.value;
        const result = this.validateUserRRN(userInput); // 주민번호 유효성 검사 호출

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

    // 주민번호 유효성 검사
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

    // 주소 입력
    handleUserAddrChange(event) {
        this.userAddr = event.target.value;
    }

    // 상세 주소 입력
    handleUserDetailAddrChange(event) {
        this.userDetailAddr = event.target.value;
    }

    // 임시운행 유저 선택 이벤트
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

    // 임시운행 PDF 모달 저장
    handleTempDriveIntro() {
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
            this.isAddressSearch = false; // 다시 팝업창 열었을 때 주소창 열리는거 방지
            let driverAddr = this.userRoadAddr + this.userDetailAddr;
            let driverName = this.userName;
            let driverIDNumber = this.userRRN;
            if (!this.isNewUserChecked && this.pdiTeamUserArray && this.pdiTeamUserArray.length > 0) {
                this.pdiTeamUserArray = this.pdiTeamUserArray.map(user => {
                    // PDI Role을 가진 유저가 체크되면 유저 정보 저장
                    if (user.checked) {
                        driverName = user.name != null ? user.name : '';
                        driverAddr = user.address != null ? user.address : '';
                        driverIDNumber = user.idNumber != null ? user.idNumber : '';
                    }
                });
                this.pdiTeamUserArray = [...this.pdiTeamAllUserArray];
            }
            // 임시운행 PDF에 User 정보 파라미터 저장
            this.tempDriveIntroUrl = "&name=" + driverName + "&rrn=" + driverIDNumber + "&addr=" + driverAddr + "&driveDays=" + this.driveDays + "&drivePurpose=" + this.drivePurpose + "&tempReqDate=" + this.tempReqDate;
            this.isTempDriveIntroModalOpen = !this.isTempDriveIntroModalOpen;
            this.filteredDocuments = this.filteredDocuments.map(doc => {
                if ( doc.label === '임시운행허가신청서' ){
                    const tempDriverMap = {
                        driveDays: this.driveDays,
                        drivePurpose: this.drivePurpose,
                        tempReqDate: this.tempReqDate
                    }

                    // 필드 업데이트
                    updatedTempDriver({recordId: this.recordId, tempDriverMap: tempDriverMap}).then(res => {
                        console.log('업데이트 되었습니다.');
                    });
                }

                if (doc.label === '임시운행허가신청서' && this.downloadFlag) {
                    if (doc.isNeedCheck) {
                        return { ...doc, isNeedCheck: false, downloadStatus: true }; // 다운로드 로직
                    } else {
                        return {...doc, selected: true}; // 리스트 선택했을 시
                    }
                } else if (doc.isOpen) {
                    window.open(doc.value + this.recordId + this.tempDriveIntroUrl, "PDF Viewer", "width=1100,height=600,scrollbars=yes,resizable=yes");
                    return {...doc, selected: false, isOpen: false};
                }

                return doc;
            });

            // 다운로드 함수 호출
            if(this.downloadFlag) this.handleDownloadSelected();

        } catch (e) {
            console.log('err msg ::', e.message);
        }
    }

    // input 필드 입력
    handleInputChange(event) {
        const fieldName = event.target.dataset.field; // data-field 속성에서 필드명 가져오기
        const fieldValue = event.target.value; // 입력된 값 가져오기

        // 필드 업데이트
        this[fieldName] = fieldValue;
    }

    // 보기 버튼 클릭 로직
    handleViewRow(event) {
        this.filteredDocuments = this.filteredDocuments.map(doc => ({...doc, isOpen: false}));
        event.stopPropagation(); // 이벤트 전파 방지
        try {
            const docValue = event.currentTarget.dataset.id;
            this.filteredDocuments = this.filteredDocuments.map(doc => {
                if (doc.value === docValue) {
                    if (this.exceptionMap[doc.label]?.profile || this.exceptionMap[doc.label]?.type || this.exceptionMap[doc.label]?.required) { // Validation
                        this.exceptionToast(doc);
                    } else if (doc.label === "출고증" || doc.label === "교육증") {
                        this.isReleaseDateModalOpen = true;
                        return {...doc, isOpen: true};

                    } else if (doc.label === "임시운행허가신청서") {
                        this.isTempDriveIntroModalOpen = true;
                        return {...doc, isOpen: true};

                    } else {
                        if(doc.label === "제작증"){
                            window.open(doc.value + this.opportunity.Id, "PDF Viewer", "width=1100,height=600,scrollbars=yes,resizable=yes");
                        } else {
                            window.open(doc.value + this.recordId + this.tempDriveIntroUrl, "PDF Viewer", "width=1100,height=600,scrollbars=yes,resizable=yes");
                        }

                    }
                }
                this.downloadFlag = false;
                return doc;
            });
        } catch (e) {
            console.log(e.message);
        }
    }
    // 출고증, 교육증 PDF 로직
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
                        return {...doc, selected: true, isNeedCheck: false, downloadStatus: true}; // 다운로드 시 로직
                    } else {
                        return {...doc, selected: true}; // 리스트 선택 시 로직
                    }
                } else if (doc.isOpen) { // 보기 버튼 시 로직
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


    // 리스트 선택
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

    // 리스트 전체 선택
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

    //다운로드 로직
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
                if (doc.isNeedCheck) { // 출고증, 교육증, 임시운행허가신청서 작성하지 않았을 때, 모달창 열기
                    if ((doc.label === "출고증" || doc.label === "교육증")) {
                        this.isReleaseDateModalOpen = true;
                    } else if (doc.label === "임시운행허가신청서") {
                        this.isTempDriveIntroModalOpen = true;
                    }
                    return doc;
                } else { // 그 외 작성했을 때 download 상태
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

        // DownloadStatus와 선택된 값이 같다면 다운로드 진행
        if (this.filteredDocuments.filter(doc => doc.selected).length === this.filteredDocuments.filter(doc => doc.downloadStatus).length) {
            this.filteredDocuments.forEach(doc => {
                if (doc.downloadStatus) {
                    this.handleDownload(doc);  // 변경: doc 전체를 전달
                    this.downloadFlag = false;
                    if(('출고증','교육증','임시운행허가서').includes(doc.label)) doc.isNeedCheck = true;
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

    // 모달 닫기
    closeReleaseDateModal() {
        this.isReleaseDateModalOpen = !this.isReleaseDateModalOpen;
    }
    // 모달 닫기
    closeIsTempDriveIntroModal() {
        this.isTempDriveIntroModalOpen = !this.isTempDriveIntroModalOpen;
        this.isAddressSearch = false;

    }
    // 액션 닫기
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // Validation 별 토스트 메시지
    exceptionToast(doc) {
        if(this.exceptionMap[doc.label].profile){
            showToast(doc.label, this.exceptionMap[doc.label].profileMsg, "warning");
        } else if (this.exceptionMap[doc.label].type) {
            showToast(doc.label, this.exceptionMap[doc.label].errMsg, "warning");
        } else if (this.exceptionMap[doc.label].required){
            showToast(doc.label, "PDF 생성에 필요한 필수 데이터가 누락되었습니다.", "warning");
        }
    }

    // 서명 버튼 로직
    handleResignRow(event) {
        event.stopPropagation();
        const docValue = event.currentTarget.dataset.id;
        this.filteredDocuments = this.filteredDocuments.map(doc => {
            if (doc.value === docValue) {
                if (this.exceptionMap[doc.label]?.profile || this.exceptionMap[doc.label]?.type || this.exceptionMap[doc.label]?.required) {
                    this.exceptionToast(doc);
                } else if(doc.label === '주유상품권 수령증'){
                    this.modalMap.isOilReceipt = true;
                    this.modalMap.oilReceiptUrl = `${doc.value + this.recordId + "#zoom=50"}`; // 미리보기 시 PDF 한눈에 보이도록 줌 기능추가
                }else{
                    this.modalMap.isHandOver = true;
                    this.modalMap.handOverUrl = `${doc.value + this.recordId + "#zoom=50"}`; // 미리보기 시 PDF 한눈에 보이도록 줌 기능추가
                }
            }
            return doc;
        });
    }

    // 서명, 취소, 저장 로직
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