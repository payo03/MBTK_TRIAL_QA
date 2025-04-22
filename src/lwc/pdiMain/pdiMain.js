/**
 * @Author            : payo03@solomontech.net
 * @Description       : PDI Main
 * @Target            :
 * @Modification Log
 Ver      Date            Author                           Modification
 ===================================================================================
 1.0      2025-01-22      payo03@solomontech.net           Create
 1.1      2025-01-22      chaebeom.do@solomontech.net      차량재고 링크 추가
 1.2      2025-04-21      chaebeom.do@solomontech.net      PDI step3 완료시 기회 연결 로직 추가
 1.3      2025-04-22      chaebeom.do@solomontech.net      PDI step1,2,5 이슈 저장용 별도 버튼 변수 추가
 */
import {LightningElement, track} from 'lwc';
import {showToast} from "c/commonUtil";

import screenInit from '@salesforce/apex/PdiController.screenInit';
import fetchStatus from '@salesforce/apex/PdiController.fetchStatus';
import searchVINbyKey from '@salesforce/apex/PdiController.searchVINbyKey';
import updateVehicleStock from '@salesforce/apex/PdiController.updateVehicleStock';
import rollbackVehicleStock from '@salesforce/apex/PdiController.rollbackVehicleStock';
import step3CheckSpoiler from '@salesforce/apex/PdiController.step3CheckSpoiler';
import doCompleteStep3 from '@salesforce/apex/PdiController.doCompleteStep3';
import doRollbackStep3 from '@salesforce/apex/PdiController.doRollbackStep3';
import spoilerDropoffSAP from '@salesforce/apex/PdiController.spoilerDropoffSAP';

export default class pdiMain extends LightningElement {

    @track switchTabName = 'Step0'; // Default tab

    isStep0 = true;
    isStep1 = false;
    isStep2 = false;
    isStep3 = false;
    isStep4 = false;
    isStep5 = false;

    step3SelectMap = {};
    step3SpoilerLog;
    isLoading = false;
    isModalOpen = false;
    // 0326 추가
    // isNext = false;
    // ver 1.1
    url = '/';
    // ver 1.3
    modalMap = {
        nextStep : false,
        prevStep : false,
        saveIssue : false
    }
    isIssueSave = false;

    @track selectedRow = null;  // 개별 SelectedRow

    @track stockList;           // 출고되지 않은 StockList
    @track idMapList = [];      // 개별/Bulk VIN List
    workNo;                     // 개별 VIN 선택시 해당 VIN의 워크넘버
    @track stepList;            // 선택된 Stock의 StepList

    isBulk = false;
    @track variantMap = {
        specific: "brand",
        bulk: "neutral"
    };

    tabs = [
        {name: 'Step0', label: '차량선택'},
        {name: 'Step1', label: '입고점검'},
        {name: 'Step2', label: '기본작업'},
        {name: 'Step3', label: '차량배정'},
        {name: 'Step4', label: '옵션장착'},
        {name: 'Step5', label: '최종점검'},
    ];

    connectedCallback() {
        this.init();
    }

    init() {
        this.isLoading = true;
        screenInit().then(response => {
            this.stockList = response;
        }).catch(error => {
            showToast('Error', 'Error Loading Init', 'error', 'dismissable');
            console.log(error);
        }).finally(this.isLoading = false);
    }

    handleButtonClick(e) {
        let buttonName = e.target.name;

        // 개별 VIN Select화면 OR 대량 VIN Copy & Paste
        if (buttonName === 'bulk') {
            this.switchTabName = 'Step1';
            this.isBulk = true;
            this.selectedRow = null;
            this.idMapList = [];
            this.variantMap = {
                specific: "neutral",
                bulk: "brand"
            }
        } else {
            this.switchTabName = 'Step0';
            this.isBulk = false;
            this.idMapList = [];
            this.variantMap = {
                specific: "brand",
                bulk: "neutral"
            }
        }
        this.handleTab();
    }

    // Handle tab switch(TAB)
    handleTabSwitch(event) {
        event.preventDefault();
        let tabName = event.target.value;
        this.switchTabName = tabName;
        if (this.isBulk) this.idMapList = [];
        if (this.isBulk && ['Step3', 'Step4'].includes(tabName)) {
            this.switchTabName = 'Step1'
            showToast("Error", "Step 3, 4 진행은 개별 VIN을 선택하여야 합니다.", "error");
        }
        if (!this.isBulk && tabName != 'Step0' && this.selectedRow == null) {
            this.switchTabName = 'Step0'
            showToast("Warning", "VIN을 선택해주세요.", "warning");
        }
        this.handleTab();
    }

    // Handle tab switch(LEFT PANEL)
    handleStepChange(event) {
        let variant = event.detail.variant;
        if (this.isBulk) this.idMapList = [];
        if (variant === 'destructive') {
            this.switchTabName = 'Step1'
            showToast("Error", "Step 3, 4 진행은 개별 VIN을 선택하여야 합니다.", "error");
            return;
        }
        if (!this.isBulk && this.selectedRow == null) {
            this.switchTabName = 'Step0'
            showToast("Warning", "VIN을 선택해주세요.", "warning");
            this.handleTab();
            return;
        }
        this.switchTabName = event.detail.value;
        this.handleTab();
    }

    // Handle Step0 S
    handleRecordSelected(event) {
        try {
            let selectedRows = event.detail.selectedRows;
            if (selectedRows && selectedRows.length > 0) {
                this.workNo = selectedRows.map(row => row.VehicleNo__c);
                this.idMapList = [];
                const vinObj = {
                    WorkNo: this.workNo[0],
                    DriveDistance: 0
                };
                this.idMapList.push(vinObj);
                this.selectedRow = selectedRows?.[0];
                this.url = '/' + this.selectedRow.Id;
                step3CheckSpoiler({vinId: this.selectedRow.Id}).then(response => {
                    this.step3SpoilerLog = response;
                }).catch(error => {
                    showToast('Error', 'Error Loading VIN', 'error', 'dismissable');
                    console.log(error);
                });
                this.showStep(false);
            }
        } catch (err) {
            console.log('err :: ', err.message);
        }
    }

    handleBulkPaste(event) {
        this.selectedRow = null;
        this.idMapList = [];
        let bulkData = event.detail.bulkVIN;
        bulkData.forEach(vin => {
            const vinObj = {
                WorkNo: vin.WorkNo,
                DriveDistance: vin.DriveDistance
            };
            this.idMapList.push(vinObj);
        });
    }

    handleSearch(event) {
        this.stepList = null;
        this.searchKey = event.detail.searchKey;
        this.isLoading = true;
        searchVINbyKey({keyword: this.searchKey}).then(response => {
            this.stockList = response;
        }).catch(error => {
            showToast('Error', 'Error Loading VIN', 'error', 'dismissable');
            console.log(error);
        }).finally(this.isLoading = false);
    }

    // Handle Step0 E

    // Handle Step3 S
    handleStep3open(event) {
        const tempMap = event.detail.matchRow;
        this.step3SelectMap['stockId'] = this.selectedRow.Id;
        this.step3SelectMap['opportunityId'] = tempMap[0]?.opp?.Id;
        this.step3SelectMap['previousStockId'] = tempMap[0]?.vehicleStock?.Id;
    }
    // Handle Step3 E

    handleTab() {
        // Object.keys(this.tabs).forEach(el => {
        //     (this.tabs[el].name == this.switchTabName);
        // })
        this.tabs.forEach(tab => {
            this[`is${tab.name}`] = false;
        });
        this[`is${this.switchTabName}`] = true;
        // ver 1.3
        this.isIssueSave = !this.isBulk && (this.switchTabName == 'Step1' || this.switchTabName == 'Step2' || this.switchTabName == 'Step5');
    }

    showStep(isRollback) {
        this.isLoading = true;
        fetchStatus({workNo: this.workNo}).then(response => {
            this.stepList = response;
            for (const el of this.stepList) {
                if (el.IsPass__c) {
                    if (isRollback) {
                        this.switchTabName = el.Stage__c.charAt(0) + el.Stage__c.slice(1).toLowerCase();
                        break;
                    } else {
                        continue;
                    } 
                }
                this.switchTabName = el.Stage__c.charAt(0) + el.Stage__c.slice(1).toLowerCase();
                break;
            }
            // 단계 선택 or 완료시 진행해야 할 단계로 자동이동 기능 미사용
            this.handleTab();
        }).catch(error => {
            showToast('Error', 'Error Fetch Status', 'error', 'dismissable');
            console.log(error);
        }).finally(this.isLoading = false);
    }

    /**
     * @description 모달 on/off
     */
    toggleModal(e) {
        // this.isNext = (e.target.dataset.name === 'nextStep');
        const name = e.target.dataset.name;
        this.isModalOpen = !this.isModalOpen;
        if (this.isModalOpen) {
			Object.keys(this.modalMap).forEach(el => this.modalMap[el] = (el === name));
		}
    }

    handleRollback() {
        this.isLoading = true;
        let message = '';
        let stepName = this.switchTabName;
        let record = this.stepList.find(item => item.Stage__c === stepName.toUpperCase());

        // Validation1. 개별 VIN선택 확인
        if (!this.selectedRow) {
            message = '차량을 선택해주세요.';
            this.isLoading = false;
        }

        // Validation2. Step 선행여부 확인
        if (this.switchTabName == 'Step1' && this.stepList[1].IsPass__c == true) {
            message = '기본작업을 먼저 취소해주세요.';
            this.isLoading = false;
        }
        if (this.switchTabName == 'Step2' && this.stepList[2].IsPass__c == true) {
            message = '차량배정을 먼저 취소해주세요.';
            this.isLoading = false;
        }
        if (this.switchTabName == 'Step3' && this.stepList[3].IsPass__c == true) {
            message = '옵션장착을 먼저 취소해주세요.';
            this.isLoading = false;
        }
        if (this.switchTabName == 'Step4' && this.stepList[4].IsPass__c == true) {
            message = '최종점검을 먼저 취소해주세요.';
            this.isLoading = false;
        }

        // Validation3. Step 현재 완료여부 확인. 선택한 vehicle이 현재 step을 이미 진행하지 않았을 경우에는 경고 토스트
        if (!record.IsPass__c) {
            message = '완료되지 않은 단계입니다.';
            this.isLoading = false;
        }

        // Validation Fail 검증.
        if (!this.isLoading) {
            showToast('Warning', message, 'warning');
            return;
        }

        if (this.switchTabName == 'Step3') {
            doRollbackStep3({rollbackMap: this.step3SelectMap}).then(() => {
                showToast('PDI 단계 취소 완료', '배정 취소 완료', 'Success');
                this.showStep(false);
            }).catch(error => {
                showToast('Error', 'Error Update', 'error', 'dismissable');
                console.log('error: ' + error);
            }).finally(() => {
                this.isLoading = false;
                this.isModalOpen = false;
            });
        } else {
            rollbackVehicleStock({
                stepName: stepName.toUpperCase(),
                vinInfoList: this.idMapList,
            }).then(response => {
                // 단일 업데이트인경우
                showToast('PDI 단계 취소 완료', this.switchTabName.toUpperCase() + ' 취소 완료', 'Success');
                this.showStep(true);
            }).catch(error => {
                showToast('Error', 'Error Update', 'error', 'dismissable');
                console.log('error: ' + error);
            }).finally(() => {
                this.isLoading = false;
                this.isModalOpen = false;
            });
        }

    }

    handleComplete() {
        this.isLoading = true;
        let message = '';
        let stepName = this.switchTabName;
        if (!this.isBulk) {
            // 개별 VIN step 완료 처리
            let record = this.stepList.find(item => item.Stage__c === stepName.toUpperCase());

            // Validation1. 개별 VIN선택 확인
            if (!this.selectedRow) {
                message = '차량을 선택해주세요.';
                this.isLoading = false;
            }

            // Validation2. Step 현재 완료여부 확인. 선택한 vehicle이 현재 step을 이미 진행했을 경우에는 경고 토스트
            if (record.IsPass__c === true) {
                message = '이미 완료된 단계입니다.';
                this.isLoading = false;
            }

            // Validation3. Step 선행여부 확인
            if (this.switchTabName == 'Step2' && this.stepList[0].IsPass__c == false) {
                message = '입고점검을 먼저 완료해주세요.';
                this.isLoading = false;
            }
            if (this.switchTabName == 'Step3' && this.stepList[1].IsPass__c == false) {
                message = '기본작업을 먼저 완료해주세요.';
                this.isLoading = false;
            }
            if (this.switchTabName == 'Step4' && this.stepList[2].IsPass__c == false) {
                message = '차량배정을 먼저 완료해주세요.';
                this.isLoading = false;
            }
            if (this.switchTabName == 'Step5' && this.stepList[3].IsPass__c == false) {
                message = '옵션장착을 먼저 완료해주세요.';
                this.isLoading = false;
            }
        }

        // Validation1-2. Bulk VIN 붙여넣기 확인
        if (this.isBulk && this.idMapList.length === 0) {
            message = '업데이트할 워크넘버 컬럼을 붙여넣기 해주세요.';
            this.isLoading = false;
        }

        // Validation Fail 검증.
        if (!this.isLoading) {
            showToast('Warning', message, 'warning');
            return;
        }
        //ver 1.2
        if (this.switchTabName == 'Step3') {
            // 현재 화면이 3단계이면서 IFAuditLogDetail에 데이터 미존재시 Spoiler I/F
            if(this.step3SpoilerLog.length == 0) this.step3CallSAP();
            doCompleteStep3({completeMap: this.step3SelectMap}).then(() => {
                showToast('Success', this.switchTabName.toUpperCase() + ' 완료', 'Success');
                this.showStep(false);
            }).catch(error => {
                showToast('Error', 'Error Update', 'error', 'dismissable');
                console.log('error: ' + error);
            }).finally(() => {
                this.isLoading = false;
                this.isModalOpen = false;
            });
        } else {
            updateVehicleStock({
                stepName: stepName.toUpperCase(),
                vinInfoList: this.idMapList,
                isBulk: this.isBulk
            }).then(response => {
                if (this.isBulk) {
                    // Bulk 업데이트일경우
                    if (response === null) {
                        showToast('Warning', '해당하는 차량을 검색할 수 없습니다. 유효한 VIN을 입력해주세요.', 'warning');
                    } else {
                        const tableChoosen = this.template.querySelector(`c-pdi-${this.switchTabName.toLowerCase()}-view`);
                        tableChoosen.fetchResultBulkRow(response);
                    }
                } else {
                    // 단일 업데이트인경우
                    if (this.switchTabName == 'Step1' || this.switchTabName == 'Step2' || this.switchTabName == 'Step5') {
                        const tableChoosen = this.template.querySelector(`c-pdi-${this.switchTabName.toLowerCase()}-view`);
                        tableChoosen.handleUpdateIssue();
                        // this.handleUpdateIssue();
                    }
                    showToast('PDI 단계 완료', this.switchTabName.toUpperCase() + ' 완료', 'Success');
                    this.showStep(false);
                }
            }).catch(error => {
                showToast('Error', 'Error Update', 'error', 'dismissable');
                console.log('error: ' + error);
            }).finally(() => {
                this.isLoading = false;
                this.isModalOpen = false;
            });
        }
    }

    // ver 1.3
    handleUpdateIssue() {
        const tableChoosen = this.template.querySelector(`c-pdi-${this.switchTabName.toLowerCase()}-view`);
        tableChoosen.handleUpdateIssue();
        showToast('저장 완료', '주행거리와 이슈가 저장되었습니다.', 'Success');
        this.isModalOpen = false;
    }

    async step3CallSAP() {
        let paramMap = {
            stockId: this.selectedRow.Id,
            spoilerCode: this.selectedRow.SpoilerPart__r.SpoilerCode__c,
            isAttach: true
        };
        let paramMapList = [paramMap];
        await spoilerDropoffSAP({inputMapList: paramMapList}).then(() => {

        }).catch(error => {
            showToast('Error', 'Error SAP Update', 'error', 'dismissable');
            console.log(error);
        });
    }
}