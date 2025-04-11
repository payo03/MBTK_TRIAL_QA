/*************************************************************
 * @author : th.kim
 * @date : 2024-11-07
 * @description :
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-07      th.kim          Created
 * 1.3          2024-11-13      chaebeom.do     Added funtion for pre-quote calculation
 * 1.4          2024-11-27      chaebeom.do     Separate Product/Campaign table funtion
 * 2.0          2024-12-20      chaebeom.do     캠페인 중복 적용으로 인한 견적 수정
 * 2.1          2025-03-25      th.kim          리드 생성, 견적 생성 프로세스 변경 및 버튼 통합, UI/UX 조정
 **************************************************************/
import { LightningElement, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import LightningConfirm from "lightning/confirm";

// Library
import formFactor from "@salesforce/client/formFactor";
import getLead from "@salesforce/apex/LeadAcquisitionController.getLead";
// import getProductPrice from "@salesforce/apex/LeadAcquisitionController.getProductPrice";
import getProduct from "@salesforce/apex/LeadAcquisitionController.getProduct";
import getFinancialList from "@salesforce/apex/LeadAcquisitionController.getFinancialList";
import doCheckBizNum from "@salesforce/apex/LeadAcquisitionController.doCheckBizNum";
import doCheckDuplicate from "@salesforce/apex/LeadAcquisitionController.doCheckDuplicate";
// import createPreQuote from "@salesforce/apex/LeadAcquisitionController.createPreQuote";
import createPreQuote from "@salesforce/apex/LeadManagementController.createPreQuote";
import callApprovalProcess from "@salesforce/apex/LeadManagementController.callApprovalProcess";


// Util
import { labelList, showToast, defaultNavigation, recordNavigation } from "c/commonUtil";

// data table
const leadColumns = [
	{
		type: "url",
		fieldName: "recordDetail",
		label: "이름",
		wrapText: true,
		hideDefaultActions: true,
		typeAttributes: { label: { fieldName: "lastName" }, target: "_blank" }
	},
	{
		type: "text",
		fieldName: "mobilePhone",
		label: "전화번호",
		cellAttributes: { alignment: "left" },
		hideDefaultActions: true
	}
];

export default class leadAcquisition extends NavigationMixin(LightningElement) {

	vfHost = labelList.VFHost;

	//리드 입력 컴포넌트 변수
	lastName = "김고객";
	phone = "010-1234-1234";
	phoneLength;
	bizNum = "505-86-03049";
	roadAddress;
	detailAddress;
	postalCode;
	description;
	dupValidated = false; //중복 확인 실행 여부
	dupComplete; //중복 확인 통과시 리드 생성 버튼 submit 활성화
	bizNumValidate = false;
	leadCreated = false;
	isNewLead = true;
	isEditable;
	iframeClass = "iframe-inactive";
	recordId;
	@track leadData = [];
	leadColumns = leadColumns;
	@track selectedLeadRowIds = [];
	inputMap = {};

	//차종 캠페인 id 저장 변수
	selectedProductId;
	selectedCampaignId;
	selectedCampaignList = [];

	//금융정보
	financialList = [];
	financeId;
	@track interestRateRange;
	@track minInterestRate;
	@track maxInterestRate;
	@track minimumDuration;
	@track maximumDuration;
	totalLoan; //대출금액 = 할부원금
	interestRate; //할부금리
	duration = 12; //할부기간

	//월 납입금 계산기, 예상 견적 컴포넌트 변수
	isMobile = false;
	isPC = true;
	listPrice; //기준 가격
	discountPrice; //캠페인 할인가격
	discountRate; //총 할인율
	realSellPrice; //실 판매 가격
	scRate; //세일즈컨디션 할인율
	salesconditionDiscountAmt; //세일즈컨디션 할인가격
	downpayment; //인도금
	// interestTotal; //총 대출이자
	// totalRepayment; //총 상환금액
	monthlyPayment; //월 상환금액

	isCreateQuote;
	isLoading = false;

	get isIframeInactive() {
		return formFactor === "Large" || this.iframeClass != "iframe-active";
	}

	connectedCallback() {
		// vf에서 받아올 이벤트 생성
		window.addEventListener("message", this.getDataFromChild.bind(this));

		if (formFactor === "Small") this.isMobile = true;
		if (formFactor === "Small") this.isPC = false;
	}

	/**
	 * @description input-field 입력 시 onchange 이벤트
	 */
	handleChange(e) {
		const value = e.target.value;
		const id = e.target.dataset.id;
		if (id === "LastName") {
			this.lastName = value;
		} else if (id === "MobilePhone") {
			this.phone = this.formattedNum(value, id);
		} else if (id === "detailAddress") {
			this.detailAddress = value;
		} else if (id === "Description") {
			this.description = value;
		} else if (id === "bizNum") {
			this.bizNum = this.formattedNum(value, id);
		}
	}

	/**
	 * @description 주소 검색 버튼 클릭 시 주소 창 오픈 요청
	 */
	handleSearchClick(event) {
		event.preventDefault();
		const iframe = this.template.querySelector("iframe");
		if (iframe) {
			const contentWindow = iframe.contentWindow;
			const data = { target: "address", formFactor: formFactor };
			contentWindow.postMessage(data, this.vfHost);

			// 모바일에서 iframe 화면 활성화
			if (formFactor === "Small") this.iframeClass = "iframe-active";
		}
	}

	/**
	 * @description 리드 생성폼 리셋 onclick
	 */
	createNewLead() {
		this.recordId = null;
		this.isNewLead = true;
		this.lastName = null;
		this.phone = null;
		this.roadAddress = null;
		this.detailAddress = null;
		this.postalCode = null;
		this.description = null;
		this.bizNum = null;
		this.isEditable = false;
		this.dupValidated = false;
		this.dupComplete = "";
		this.bizNumValidate = false;
		this.selectedLeadRowIds = [];
		this.clearSelection();
	}

	/**
	 * @description 저장 버튼 클릭 시 데이터 저장
	 */
	handleSave() {
		this.isCreateQuote = false;
		this.submitLead();
	}

	async submitLead() {
		if (this.selectedProductId == null) {
			showToast("", "차종 테이블에서 고객의 관심 차종을 선택해주세요.", "warning");
			return false;
		}

		this.isLoading = true;
		const isDupCheck = await this.handleDupCheck();
		let isBizCheck;
		if (this.bizNum) {
			isBizCheck = await this.handleBizCheck();
		}
		if (isDupCheck && (!this.bizNum || isBizCheck)) {
			if (this.bizNumValidate === false) this.bizNum = null;

			const recordEditForm = this.template.querySelector("lightning-record-edit-form");

			// 기존 필드 값 자동 수집
			const inputFields = this.template.querySelectorAll("lightning-input-field");
			let fieldDataMap = {};
			inputFields.forEach(field => {
				fieldDataMap[field.fieldName] = field.value;
			});

			// 추가적인 필드 수동 입력 (lightning-input-field가 아닌 값)
			Object.assign(fieldDataMap, {
				Finance__c: this.financeId,
				TotalLoanAmount__c: this.totalLoan,
				DefaultInterestRate__c: this.interestRate,
				MonthDivideInputMonth__c: this.duration,
				MonthlyPayment__c: this.monthlyPayment
			});
			await recordEditForm.submit(fieldDataMap);
			return true;
		}
		this.isLoading = false;
		return false;
	}

	/**
	 * @description 리드 저장 성공 시
	 */
	async handleSuccess(e) {
		// this.isEditable = true;
		// this.isNewLead = false;
		this.recordId = e.detail.id;
		// showToast("", "리드가 저장되었습니다.", "success");
		if (this.isCreateQuote) {
			if (this.recordId == null) {
				showToast("리드가 생성되지 않았습니다.", "관리자에게 문의해주세요.", "warning");
				return;
			}
			if (!this.downpayment) this.downpayment = 0;
			if (!this.interestRate) this.interestRate = 0;

			const inputMap = {
				"leadId": this.recordId
				, "productId": this.selectedProductId
				, "campaignIdList": JSON.stringify(this.selectedCampaignList.map(item => item.id))
				, "financeId": this.financeId
				, "totalLoan": this.totalLoan || 0 // 리드 수집에서만
				, "interestRate": this.interestRate || 0// 리드 수집에서만
				, "duration": this.duration || 0 // 리드 수집에서만
			};
			console.log("inputMap ::: " + JSON.stringify(inputMap));
			await createPreQuote({ "inputMap": inputMap }).then(res => {
				console.log("createPreQuote :: ", res);
				const dupType = res["dupType"];
				const accountId = res["accountId"];

				if (dupType === "error") {
					showToast("Error.", "관리자에게 문의.", "error");
					return;
				}

				// 다른 SA가 소유한 계정 -> 승인 프로세스
				if (dupType === "otherAcc") {
					// 변경 확인 문구
					LightningConfirm.open({
						message: "담당 매니저에게 승인 요청을 보내겠습니까?",
						// variant: "headerless",
						label: "이미 존재하는 계정 입니다." // 모달 제목
					}).then(res => {
						if (res) {
							const inputMap = {
								"accountId": accountId,
								"leadId": this.recordId
							};
							// this.isLoading = true;
							callApprovalProcess({ "inputMap": inputMap }).then(res => {
								console.log("res ::: " + res);
								const isSuccess = res["isSuccess"];
								const value = res["value"];
								if (isSuccess) {
									showToast("승인프로세스 요청 성공", value, "success");
								} else {
									showToast("승인프로세스 요청 실패", value, "warning");
								}
							}).catch(err => {
								console.log("err ::: " + JSON.stringify(err));
							});
						}
					});
				} else {
					showToast("Success", "견적이 생성 되었습니다.", "success");
					defaultNavigation(this, "Quote", "", res["value"]);
				}
			}).catch(err => {
				console.log("err :: ", err);
			}).finally(() => {
				this.isLoading = false;
			});
		} else {
			recordNavigation(this, "Lead", e.detail.id);
		}
		this.isLoading = false;
		// this.leadCreated = true;
		// const res = {
		// 	id: this.recordId,
		// 	recordDetail: "/" + this.recordId,
		// 	lastName: this.lastName,
		// 	mobilePhone: this.phone
		// };
		// let index = this.leadData.findIndex((item) => item.id === this.recordId);
		// if (index === -1) {
		// 	this.leadData = [...this.leadData, res];
		// } else {
		// 	this.leadData[index] = res;
		// 	this.leadData = [...this.leadData];
		// }
		// ;
		// this.selectedLeadRowIds = [this.recordId];
	}

	/**
	 * @description 리드 저장 실패 시
	 */
	handleError(e) {
		console.log(e.detail.detail);
		this.isLoading = false;
		showToast("", e.detail.detail, "warning");
	}

	/**
	 * @description 생성된 리드 테이블에서 로우 선택시 해당 리드 정보를 입력폼으로 가져오는 이벤트
	 */
	handleLeadRowSelection(e) {
		const selectedRows = e.detail.selectedRows;
		const JSONrow = JSON.parse(JSON.stringify(selectedRows));

		if (selectedRows.length > 0) {
			this.dupValidated = true;
			this.selectedLeadRowIds = [JSONrow[0].id];
			this.recordId = JSONrow[0].id;
			getLead({ leadId: JSONrow[0].id }).then(res => {
				this.lastName = res[0].lastName;
				this.phone = res[0].mobilePhone;
				this.bizNum = res[0].bizNum != null ? res[0].bizNum : null;
				this.bizNumValidate = res[0].bizNum != null ? true : false;
				this.roadAddress = res[0].roadAddress;
				this.detailAddress = res[0].detailAddress;
				this.postalCode = res[0].postalCode;
				this.description = res[0].description;
				this.selectedProductId = res[0].productId;
				const leadChoosen = this.template.querySelector("c-product-campaign-table");
				leadChoosen.highlightProduct(res[0].productId);
				getProduct({ whereConditions: "Id = '" + res[0].productId + "'" }).then(res => {
					this.listPrice = res[0].listPrice;
					this.scRate = res[0].salesconditionRate;
					this.salesconditionDiscountAmt = this.scRate != null ? Math.round(this.listPrice * this.scRate / 100) : 0;
					this.discountRate = this.scRate != null ? this.scRate : 0;
					// this.realSellPrice = this.listPrice - this.salesconditionDiscountAmt;
					this.handleCalc(e);
				}).catch(err => {
					console.log("err :: ", err);
				});
			}).catch(err => {
				console.log("err :: ", err);
			});
			this.isNewLead = false;
		} else {
			this.selectedLeadRowIds = [];
		}
	}

	/**
	 * @description 중복 체크
	 */
	async handleDupCheck() {
		const nameEl = this.template.querySelector("lightning-input-field[data-id=\"LastName\"]");
		let returnValue = true;
		if (nameEl.value && this.phone) {
			let inputMap = { phone: this.phone, name: nameEl.value };
			await doCheckDuplicate({ inputMap: inputMap }).then(res => {
				this.dupValidated = true;
				switch (res.type) {
					case "noDuplicate":
						showToast("등록 가능한 리드입니다.", "", "success");
						break;
					case "myAcc":
						showToast("기존 소유 중인 계정입니다.", "견적 생성 시 기존 계정으로 연결됩니다.", "warning", "sticky");
						break;
					case "oldAcc":
						showToast("다른 SA가 소유 중인 계정입니다.", "리드는 생성되지만 견적 생성이 제한됩니다.", "warning", "sticky");
						break;
					case "ongoingAcc":
						showToast("다른 SA가 진행 중인 계정입니다.", "리드는 생성되지만 견적 생성이 제한됩니다.", "warning", "sticky");
						break;
				}
			}).catch(err => {
				console.log("err :: ", err);
				showToast("", e.detail.message, "warning");
				returnValue = false;
			});
		} else {
			showToast("", "고객 이름과 전화번호를 모두 입력해주세요.", "warning");
			returnValue = false;
		}
		return returnValue;
	}

	/**
	 * @description 사업자 번호 유효 체크
	 */
	async handleBizCheck() {
		const inputEl = this.template.querySelector("lightning-input-field[data-id=\"bizNum\"]");
		const bizNum = inputEl.value.replace(/\D/g, "");
		let returnValue = false;
		await doCheckBizNum({ bizNum: bizNum }).then(res => {

			// TODO :: Custom Label로 변경 필요
			const labal1 = "등록 안되어 있음";
			const labal2 = "휴업/폐업";
			const labal3 = "정상 사업자";

			let title;
			let msg = "유효하지 않은 사업자번호는 빈 칸으로 저장됩니다.";
			let variant = "warning";
			if (res === "N") title = labal1;
			if (res === "F") title = labal2;
			if (res === "S") {
				// title = labal3;
				// msg = "";
				// variant = "success";
				this.bizNumValidate = true;
				returnValue = true;
			} else {
				showToast(title, msg, variant);
			}
		}).catch(err => {
			console.log("err :: ", err);
		});

		return returnValue;
	}

	/**
	 * @description vf에서 주소 선택 시 보내는 이벤트
	 */
	getDataFromChild(e) {
		if (this.vfHost != e.origin || e.data.target != "address") return;

		this.roadAddress = e.data.roadAddress;
		this.detailAddress = "";
		this.postalCode = e.data.zonecode;
		this.isEditable = true;
		this.iframeClass = "iframe-inactive";
	}

	/**
	 * @description 전화번호 형식으로 변경하기
	 * @param value 현재 value
	 * @param id data-id
	 * @returns {*} 전화번호 형식으로 변경된 value
	 */
	formattedNum(value, id) {
		const input = value.replace(/\D/g, ""); // 숫자 외 제거
		let formatted;

		if (id === "MobilePhone") {
			// 서울 지역번호 (02) 형식
			if (input.startsWith("02")) {
				this.phoneLength = "12";
				if (input.length < 3) {
					formatted = input;
				} else if (input.length < 6) {
					formatted = `${input.slice(0, 2)}-${input.slice(2)}`;
				} else if (input.length < 10) {
					formatted = `${input.slice(0, 2)}-${input.slice(2, 5)}-${input.slice(5)}`;
				} else {
					formatted = `${input.slice(0, 2)}-${input.slice(2, 6)}-${input.slice(6, 10)}`;
				}
			}
			// 일반 번호 형식 (000-0000-0000 or 000-000-0000)
			else {
				this.phoneLength = "13";
				if (input.startsWith("010")) { // 010으로 시작하는 번호는 반드시 010-0000-0000
					if (input.length < 4) {
						formatted = input;
					} else if (input.length < 8) {
						formatted = `${input.slice(0, 3)}-${input.slice(3)}`;
					} else {
						formatted = `${input.slice(0, 3)}-${input.slice(3, 7)}-${input.slice(7, 11)}`;
					}
				} else {
					if (input.length < 4) {
						formatted = input;
					} else if (input.length < 7) {
						formatted = `${input.slice(0, 3)}-${input.slice(3)}`;
					} else if (input.length < 11) {
						formatted = `${input.slice(0, 3)}-${input.slice(3, 6)}-${input.slice(6)}`;
					} else {
						formatted = `${input.slice(0, 3)}-${input.slice(3, 7)}-${input.slice(7, 11)}`;
					}
				}
			}
			console.log(formatted);
		} else if (id === "bizNum") {
			if (input.length < 4) {
				formatted = input;
			} else if (input.length < 6) {
				formatted = `${input.slice(0, 3)}-${input.slice(3)}`;
			} else {
				formatted = `${input.slice(0, 3)}-${input.slice(3, 5)}-${input.slice(5, 9)}`;
			}
		}

		return formatted;
	}

	/**
	 * @description 리드 변환 및 기회 견적 생성 onclick
	 */
	handleConvert() {
		this.isCreateQuote = true;
		this.submitLead();
	}

	handleFinanceChange(e) {
		const value = e.target.value;
		const finance = this.financialList?.find(el => el.value === value);
		this.financeId = finance.value;
		this.minInterestRate = finance.minInterestRate || 0;
		this.maxInterestRate = finance.maxInterestRate || 0;
		this.minimumDuration = finance.minimumDuration || 0;
		this.maximumDuration = finance.maximumDuration || 0;
		this.interestRateRange = `${finance.minInterestRate || 0} ~ ${finance.maxInterestRate || 0}`;
		this.interestRate = null;
		this.duration = 0;
		this.handleCalc(e);
	}

	/**
	 * @description 월납입금 계산기 input-field 입력 시 onchange 이벤트
	 */
	handleCalc(e) {
		const dataId = e.target.dataset.id;
		// 변경 필드 확인
		switch (dataId) {
			case "interestRate":
				this.interestRate = e.target.value;
				break;
			case "duration":
				this.duration = e.target.value;
				break;
			case "totalLoan":
				this.totalLoan = e.target.value;
				break;
		}
		this.realSellPrice = this.listPrice - this.salesconditionDiscountAmt - this.discountPrice;
		this.downpayment = this.realSellPrice - this.totalLoan - 1000000;
		this.monthlyPayment = this.calcMonthPayment(this.totalLoan, this.interestRate, this.duration);
		// this.totalRepayment = this.monthlyPayment * this.duration;
		// this.interestTotal = this.totalRepayment > this.totalLoan ? this.totalRepayment - this.totalLoan : 0;
	}

	/**
	 * @description 월 할부금 계산
	 * @param loanAmount 할부원금
	 * @param interestRate 적용금리
	 * @param loanTermMonth 할부개월수
	 */
	calcMonthPayment(loanAmount, interestRate, loanTermMonth) {

		// 월별 금리 계산
		const monthInterestRate = (interestRate / 100) / 12;

		// 원리금 균등 상환 방식 계산
		const PMT = (rate, nper, pv) => {
			return rate === 0
				? -pv / nper
				: (-pv * rate) / (1 - Math.pow(1 + rate, -nper));
		};

		// 월 할부금 계산
		const payment = PMT(monthInterestRate, loanTermMonth, loanAmount);

		// 결과 반올림 (10원 단위)
		return Math.round(Math.abs(payment) / 10) * 10;
	}

	/**
	 * @description 차종/캠페인 테이블 선택시 예상 견적 테이블에 수치 입력
	 */
	handleRowSelect(e) {
		if (e.detail.type === "product") {
			this.clearSelection();
			console.log("selectedRow :: ", e.detail.selectedRow);
			this.scRate = e.detail.selectedRow[0].salesconditionRate;
			this.selectedProductId = e.detail.id;
			this.listPrice = e.detail.selectedRow[0].listPrice;
			this.salesconditionDiscountAmt = this.scRate != null ? Math.round(this.listPrice * this.scRate / 100) : 0;
			this.discountRate = this.scRate != null ? this.scRate : 0;
			// this.realSellPrice = this.listPrice - this.salesconditionDiscountAmt;
			this.handleCalc(e);
			getFinancialList({ productId: this.selectedProductId }).then(res => {
				console.log("financialList :: ", res);
				this.financialList = res;
			}).catch(err => {
				console.log("err :: ", err);
			});
		} else if (e.detail.type === "campaign") {
			console.log("campaign => " + JSON.stringify(e.detail.selectedRow));
			const campaignData = e.detail.selectedRow;

			this.selectedCampaignId = e.detail.id;
			this.selectedCampaignList = e.detail.selectedRow;
			let sumDiscountPrice = 0;
			let sumDiscountRate = 0;
			if (campaignData != null) {
				for (const element of campaignData) {
					if (element.discountPrice != null) {
						sumDiscountPrice += element.discountPrice;
					} else {
						sumDiscountPrice += Math.round(this.listPrice * element.discountRate / 100);
					}
					sumDiscountRate = (this.salesconditionDiscountAmt + sumDiscountPrice) / this.listPrice * 100;
				}
			}
			this.discountPrice = sumDiscountPrice != 0 ? sumDiscountPrice : 0;
			this.discountRate = sumDiscountRate != 0 ? sumDiscountRate : this.scRate;
			// this.realSellPrice = this.listPrice - this.salesconditionDiscountAmt - this.discountPrice;
			this.handleCalc(e);

			// if (formFactor === "Small" && campaignData) {
			//   const containerChoosen = this.template.querySelector('.move-scroll');
			//   containerChoosen.scrollIntoView({behavior: 'smooth'});
			// };
			//캠페인 중복 선택으로 인해 스크롤 이동 주석 처리
		}
	}

	/**
	 * @description datatable 선택 해제
	 */
	clearSelection() {
		const tableChoosen = this.template.querySelector("c-product-campaign-table");
		tableChoosen.refreshTable();
		this.selectedProductId = null;
		this.selectedCampaignId = null;
		this.listPrice = null;
		this.discountPrice = null;
		this.discountRate = null;
		this.realSellPrice = null;
		this.scRate = null;
		this.salesconditionDiscountAmt = null;
		this.totalLoan = null;
		// this.interestTotal = null;
		// this.totalRepayment = null;
		this.monthlyPayment = null;
	}

	/**
	 * @description 모바일에서 보이는 차종 재선택 버튼을 누르면 차종 테이블로 스크롤 이동
	 */
	handleScroll(e) {
		const id = e.target.dataset.id;
		if (id === "product") {
			const containerChoosen = this.template.querySelector("c-product-campaign-table");
			containerChoosen.scrollIntoView({ behavior: "smooth" });
		} else if (id === "top") {
			const containerChoosen = this.template.querySelector(".leftSec");
			containerChoosen.scrollIntoView({ behavior: "smooth" });
		}
	}
}