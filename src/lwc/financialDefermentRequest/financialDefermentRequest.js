/**
 * @Author            : payo03@solomontech.net
 * @Description 		 : VAT 후취 요청
 * @Target            : Opportunity Record Page
 * @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-07      payo03@solomontech.net           Created
  1.1      2025-02-20      payo03@solomontech.net           VAT 후취, 인도금 유예의 유예일수-일자 Validation
  1.2      2025-02-27      th.kim                           유예요청 Step추가. Quote List조회 -> Quote의 데이터 Pick
  1.3      2025-03-31      th.kim                           RealSalesPrice -> fm_RealSellAmt__c 필드 변경
  1.4      2025-04-07      chaebeom.do@solomontech.net      모바일 동작 대응
  1.5      2025-05-08      payo03@solomontech.net           유예금액 Validation
 */
import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { CurrentPageReference } from "lightning/navigation";
import { CloseActionScreenEvent } from "lightning/actions";
import { loadStyle } from "lightning/platformResourceLoader";
import styles from "@salesforce/resourceUrl/removeDataFormat";
import formFactor from "@salesforce/client/formFactor";

import { showToast, recordNavigation } from "c/commonUtil";

import screenInit from "@salesforce/apex/FinancialDefermentRequest.screenInit";
import requestDeferred from "@salesforce/apex/FinancialDefermentRequest.requestDeferred";

const MAX_DAYS_MAP = {
	"LDC": 90,
	"MDC": 90,
	"HDC": 90,
	"TRT": 70,
	"TPP": 70
};

const MIN_DAYS = 45;

export default class financialDefermentRequest extends NavigationMixin(LightningElement) {

	@track recordId;
	@track apiName;
	@track header;
	@track updateField;
	@track isVATDeferred = false;
	@track isCheck = false;
	@track isDaysValid = true;

	@track overflowMessage;
	@track underflowMessage;

	@track realSalesPrice;
	@track deferredAmount;
	@track requestDays;
	@track comment;
	@track requestDueDate;
	@track selectedQuoteRow = {};

	@wire(CurrentPageReference) pageRef;
	// getStateParameters(currentPageReference) { // ver 1.4
	// 	if (currentPageReference && !this.recordId) {
	// 		this.recordId = currentPageReference.state?.c__recordId;
	// 		this.apiName = currentPageReference.state?.c__apiName;
	// 	}
	// }

	// 유예 요청일자와 오늘 사이의 날짜 차이
	diffDay;

	// 견적 선택 화면 추가 (25-02-27)
	isLoading = true;
	isSelectView = true;
	minDays = MIN_DAYS;
	columns = [
		{
			label: "견적 이름",
			fieldName: "Name",
			type: "text",
			hideDefaultActions: true
		},
		{
			label: "상태",
			fieldName: "Status",
			type: "text",
			hideDefaultActions: true
		},
		{
			label: "차종",
			fieldName: "productName",
			type: "text",
			hideDefaultActions: true
		},
		{
			label: "실판매가 + 특장 합계",
			fieldName: "fm_TotalRealAndSpecialPrice__c",
			type: "number",
			hideDefaultActions: true
		}
	];
	quoteList = [];
	selectedQuoteRowIdList = [];

	connectedCallback() {
		this.recordId = this.pageRef.state.recordId;
		this.apiName = this.pageRef.attributes.apiName.replace("Opportunity.", "");
		// this.apiName = this.apiName != undefined ? this.apiName : this.pageRef.attributes.apiName.replace("Opportunity.", "");
		this.init();

		if (this.apiName.includes("VAT")) {
			this.isVATDeferred = true;

			this.header = "VAT 후취요청";
			this.updateField = "TaxDeferredAmount__c";
		} else if (this.apiName.includes("Payment")) {

			this.header = "인도금 유예";
			this.updateField = "PaymentDeferredAmount__c";
		}
		// this.resizePop();
	}

	renderedCallback() {
		Promise.all([
			loadStyle(this, styles)
		]).then(() => {
			console.log("Help Text Remove CSS Files loaded.");
		}).catch(error => {
			console.log("Error " + error.body.message);
		});
	}

	resizePop() {

		requestAnimationFrame(() => {
			const modalContainerEl = document.querySelector(".slds-modal__container");

			if(modalContainerEl) {
				let modalWidth = 700;
				if (!this.isVATDeferred) modalWidth = 600;
				modalContainerEl.style.width = this.isSelectView ? "initial" : `${modalWidth}px`;
			}
			
			// const modalBody = document.querySelector(".modal-body");
			// const closeIcon = document.querySelector(".closeIcon");

			// if (modalBody && closeIcon) {
			// 	// modal-body width 설정
			// 	modalBody.style.width = this.isSelectView ? "initial" : `${modalWidth}px`;
			// 	modalBody.style.margin = this.isSelectView ? "initial" : "0 auto";
			//
			// 	// 부모 요소 너비 기준으로 closeIcon 위치 조정
			// 	const containerWidth = modalBody.parentElement.offsetWidth;
			// 	const adjustedMarginRight = (containerWidth - modalWidth) / 2;
			//
			// 	closeIcon.style.marginRight = this.isSelectView ? "initial" : `${adjustedMarginRight}px`;
			// }
		});

		/*
				if (modalBody && closeIcon) {
					modalBody.classList.add('custom-quick-action-modal-body');
					closeIcon.classList.add('custom-quick-action-close-button');
				}
		*/
	}

	init() {
		this.isLoading = true;
		screenInit({ recordId: this.recordId }).then(response => {
			console.log("### response : ", response);

			this.quoteList = response?.Quotes?.map(quote => {
				quote.productName = quote.Product__r.Name;
				return quote;
			}) || [];
			console.log("quoteList :: ", JSON.stringify(this.quoteList));

			// this.realSalesPrice = response.Quotes?.[0].RealSalesPrice__c || 0;
			//
			// // ver1.1 VAT 후취, 인도금 유예의 유예일수-일자 Validation
			// if (this.isVATDeferred) {
			// 	this.deferredAmount = response.Quotes?.[0].fm_DefermentVAT__c || 0;
			//
			// 	let productObj = response.Quotes?.[0].Product__r;
			// 	const maxDays = MAX_DAYS_MAP[productObj.Segment2__c];
			//
			// 	this.overflowMessage = "[" + productObj.Segment2__c + "] 유예 최대일수는 " + maxDays + "일 이하입니다";
			// 	this.underflowMessage = "[" + productObj.Segment2__c + "] 유예 최소일수는 " + this.minDays + "일 이상입니다";
			// }

			if (this.quoteList.length < 1) {
				showToast("Error", "구성된 견적이 없습니다", "error", "dismissable");
				setTimeout(() => {
					this.dispatchEvent(new CloseActionScreenEvent());
				}, 1000);
			}
		}).catch(error => {
			showToast("Error", error.body?.message || error.message || "ERROR", "error", "dismissable");
			console.log(error.message);
		}).finally(() => this.isLoading = false);
	}

	// get formattedRealSalesPrice() {
	// 	return this.formatNumber(this.realSalesPrice);
	// }
	//
	// get formattedDeferredAmount() {
	// 	return this.formatNumber(this.deferredAmount);
	// }

	handleRowSelection(e) {
		const selectedQuoteRowList = e.detail?.selectedRows || [];
		this.selectedQuoteRowIdList = selectedQuoteRowList.map(row => row.Id);
		try {
			this.selectedQuoteRow = selectedQuoteRowList.length > 0 ? (() => {
				const selectedRow = { ...selectedQuoteRowList[0] };
				const segment = selectedRow.Product__r?.Segment2__c || "N/A";
				selectedRow.maxDays = MAX_DAYS_MAP[segment] || 0;
				selectedRow.overflowMessage = `[${segment}] 유예 최대일수는 ${selectedRow.maxDays}일 이하입니다`;
				selectedRow.underflowMessage = `[${segment}] 유예 최소일수는 ${this.minDays}일 이상입니다`;
				return selectedRow;
			})() : [];
		} catch (err) {
			console.log("err :: ", err.message);
		}
	}

	/**
	 * @description 모달 창 버튼 클릭 이벤트
	 */
	handleClick(e) {
		const name = e.target.dataset.name;
		switch (name) {
			case "cancel":
				this.handleCancel();
				break;
			case "prev":
				this.isSelectView = true;
				this.resizePop();
				break;
			case "next":
				if (this.selectedQuoteRowIdList.length < 1) {
					showToast("견적을 선택해주세요.", "", "warning");
					return;
				}
				this.isSelectView = false;
				this.resizePop();
				break;
			case "submit":
				this.handleSubmit();
				break;
		}
	}

	handleSubmit() {
		let message = "";

		// 5-1. [인도금 유예] 유예일 범위 Validation
		if (!this.isVATDeferred && !this.isDaysValid) {
			if(this.diffDay < this.minDays) 					message = this.selectedQuoteRow.underflowMessage;
			if(this.diffDay > this.selectedQuoteRow.maxDays) 	message = this.selectedQuoteRow.overflowMessage;
		}
		// 5-2. [부가세 후취] 유예일 범위 Validation
		if (this.isVATDeferred && !this.isDaysValid) message = "유예일수 문구를 확인해주세요";

		// 4. [공통] 유예일 설정 Validation
		if (
			(this.isVATDeferred && !this.selectedQuoteRow.RequestDays__c) ||    // 부가세후취
			(!this.isVATDeferred && !this.selectedQuoteRow.RequestDueDate__c)   // 인도금유예
		) {
			message = "유예일을 설정해 주세요";
		}

  	    // 3. 인도금유예 신청 MAX값 Validation
        let maxDefferedAmount = this.selectedQuoteRow.AdvancePayment__c || 0;
        if (this.isVATDeferred) {
            let totPrice = this.selectedQuoteRow.fm_TotalRealAndSpecialPrice__c * 0.1;  // 10%의 값

            maxDefferedAmount = Math.min(maxDefferedAmount, totPrice);
        }
        if(this.selectedQuoteRow.fm_DefermentVAT__c > maxDefferedAmount) message = '유예금액은 ' + maxDefferedAmount + '원을 초과할 수 없습니다';

		// 2. [인도금 유예] 금액 0원 이하 Validation
		if (!this.isVATDeferred && !this.selectedQuoteRow.fm_DefermentVAT__c) message = "유예 금액을 입력해주세요";

		// 1. [공통] 안내문구 Check Validation
		if (!this.isCheck) message = "안내문구를 확인해주세요";

		if (message != "") {
			showToast("Error", message, "error", "dismissable");
			return;
		}

		this.isLoading = true;
		const infoMap = {
			recordId: this.recordId,
			apiName: this.apiName,
			updateField: this.updateField,
			deferredAmount: this.selectedQuoteRow.fm_DefermentVAT__c,
			contractAmount: this.selectedQuoteRow.fm_RealSellAmt__c, 
			comment: this.comment,

			isCheck: this.isCheck,
			requestDays: this.selectedQuoteRow.RequestDays__c,
			requestDueDate: this.selectedQuoteRow.RequestDueDate__c
		};

		requestDeferred({ paramMap: infoMap }).then(response => {
			/*
            let isEqualUser = response.isEqualUser;
            if(!isEqualUser) {
                // Record의 Owner가 아닐경우. Validation
                showToast('Error', 'Record Owner Error', 'error', 'dismissable');
            } else {
                let isSuccess = response.isSuccess;

                if(isSuccess) {
                    showToast('Success', '승인 요청이 완료되었습니다', 'success', 'dismissable');
                } else {
                    showToast('Error', response.message, 'error', 'dismissable');
                }
            }
			*/

			let isSuccess = response.isSuccess;
			if (isSuccess) {
				showToast("Success", "승인 요청이 완료되었습니다", "success", "dismissable");

				setTimeout(() => {
					this.dispatchEvent(new CloseActionScreenEvent());
				}, 1000);
			} else {
				showToast("Error", response.message, "error", "dismissable");
			}
		}).catch(error => {
			showToast("Error", "Submit Request Error", "error", "dismissable");
			console.log(error);
		}).finally(() => this.isLoading = false);
	}

	handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.mobileReturnPage();
    }

    mobileReturnPage() {
        if(formFactor === "Small") {
            recordNavigation(this, "Contract", this.recordId);
        }
    }

	handleChange(event) {
		let fieldLabelName = event.target.name;
		let value = event.target.value;
		let today = new Date();
		this.selectedQuoteRow[fieldLabelName] = value;

		this.diffDay = Math.ceil((new Date(value) - today) / (1000 * 60 * 60 * 24));

		console.log(`${fieldLabelName}:`, this.selectedQuoteRow[fieldLabelName]);
		console.log('fieldLabelName ::: ' + fieldLabelName);

		// ver1.1 VAT 후취, 인도금 유예의 유예일수-일자 Validation
		if (fieldLabelName == "RequestDays__c") {
			this.isDaysValid = true;

			if (value < this.minDays || value > this.selectedQuoteRow.maxDays) this.isDaysValid = false;
			console.log("isDaysValid :: ", this.isDaysValid);
		} else if (fieldLabelName == "RequestDueDate__c") {
            this.isDaysValid = true;

            // if (value < this.minDays || value > this.selectedQuoteRow.maxDays) this.isDaysValid = false;
            if (this.diffDay < this.minDays || this.diffDay > this.selectedQuoteRow.maxDays) {
                this.isDaysValid = false;
            }
            console.log("isDaysValid :: ", this.isDaysValid);
        }
	}

	handleCheckChange(event) {
		this.isCheck = event.target.checked;
	}

	formatNumber(number) {
		return new Intl.NumberFormat("ko-KR").format(number);
	}
}