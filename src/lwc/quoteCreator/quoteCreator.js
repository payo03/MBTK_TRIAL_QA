/*************************************************************
 * @author : th.kim
 * @date : 2024-12-09
 * @description : 견적 구성기
 * @target : Quote, Opportunity Record Page Button
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-12-09      th.kim          Initial Version
 **************************************************************/
import { LightningElement, track, wire } from "lwc";

// Library
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import formFactor from "@salesforce/client/formFactor";
import LightningConfirm from "lightning/confirm";
// Test
// Controller
import getInit from "@salesforce/apex/QuoteCreatorController.getInit";
import getProductChangeData from "@salesforce/apex/QuoteCreatorController.getProductChangeData";
import getServiceItem from "@salesforce/apex/QuoteCreatorController.getServiceItem";
import getFilteredOptionList from "@salesforce/apex/QuoteCreatorController.getFilteredOptionList";
import doSaveQuote from "@salesforce/apex/QuoteCreatorController.doSaveQuote";
import getCalendarInit from "@salesforce/apex/TaxInvoiceSchedulerController.getCalendarInit";

// Util
import {
	campaignColumns,
	completedSubOptions,
	incompletedSubOptions,
	modalOptionColumns,
	optionColumns,
	specialOptions,
	stockColumns,
	tipperSubOptions,
	tractorSubOptions
} from "./quoteCreatorColumns";
import { deepClone, labelList, recordNavigation, showToast } from "c/commonUtil";

const specialDependency = {
	"캡섀시 - 미완성": incompletedSubOptions,
	"트랙터": tractorSubOptions,
	"덤프": tipperSubOptions,
	"캡섀시 - 완성": completedSubOptions
};

const initSpecialData = { idx: 0, accountId: null, option: "", subOption: "", price: 0 };
const defaultOptionSearchMap = { type: "", name: "" };
const initFinancialData = [{ idx: 0 }, { idx: 1 }];

export default class quoteCreator extends NavigationMixin(LightningElement) {

	// 현재 데이터
	vfHost = labelList.VFHost;
	oppId;
	oppData;
	quoteData;
	productData;
	productId;
	quoteName;
	handoverDate;
	activeSectionNames = ["option", "campaign", "oilCoupon", "special", "finance", "expenses"];
	filter = {
		criteria: [
			{
				fieldPath: "Quantity__c",
				operator: "gt",
				value: 0
			},
			{
				fieldPath: "After30DaysQty__c",
				operator: "gt",
				value: 0
			},
			{
				fieldPath: "After60DaysQty__c",
				operator: "gt",
				value: 0
			}
		],
		filterLogic: "1 OR 2 OR 3"
	};
	displayInfo = { primaryField: "Name", additionalFields: ["Styling__c"] };
	isViewStock;
	stockColumns = stockColumns;
	selectedStockIdList = [];
	summaryData = {
		realSalesPrice: 0,
		specialPrice: 0,
		totalRealAndSpecialPrice: 0,
		monthlyPayment: 0,
		totalPaymentBeforeReleased: 0
	};

	// 옵션 데이터
	modalOptionColumns = modalOptionColumns;
	optionColumns = optionColumns;
	optionFilter;
	@track optionSearchMap = { ...defaultOptionSearchMap };
	optionData = [];
	allOptionData = [];
	selectedOptionData = [];
	@track selectedOptionIdList = [];
	defaultOptionData = [];

	// 캠페인 데이터
	campaignColumns = campaignColumns;
	campaignData = [];
	selectedCampaignList = [];
	selectedCampaignIdList = [];
	campaignDupList = [];

	// 주유권
	oilCouponCount = 0;
	oilCouponPrice = 0;
	availableOilCouponQty = 0;

	// 특장
	specialOptions = specialOptions;
	@track specialOptionList = [{ ...initSpecialData }];
	specialFilter = {
		criteria: [
			{
				fieldPath: "IsSpecialAccount__c",
				operator: "eq",
				value: true
			}
		]
	};

	// 금융
	financialList = [];
	financeId;
	loanAmount;
	interestRate;
	loanTermMonth;
	isFirst = true;

	// 부대비용
	consignment;
	insurance;

	// 모달 데이터
	isModalOpen;
	isLoading;
	modalMap = { option: false, finance: false, calendar: false };
	@track compareFinancialList = deepClone(initFinancialData);

	// 현재 테이블 데이터맵
	@track tableDataMap = {
		product: {},
		promotion: {},
		discountDetail: {},
		defaultOptions: [],
		special: [],
		financial: {},
		extraExpenses: {},
		serviceItem: {}
	};

	/**
	 * @description 옵션 선택 여부 체크
	 */
	get isSelectedOptionData() {
		return this.selectedOptionData?.length;
	}

	/**
	 * @description 모달 사이즈 정의
	 */
	get modalSizeClass() {
		const defaultClass = "slds-modal slds-fade-in-open";
		const sizeClass = { 2: "slds-modal_small", 3: "slds-modal_medium", 4: "slds-modal_large" };
		const modalSize = this.modalMap.option
			? "slds-modal_large"
			: this.modalMap.calendar
				? "slds-modal_medium"
				: sizeClass[this.compareFinancialList.length] || "";
		return `${defaultClass} ${modalSize}`;

	}

	/**
	 * @description 모달 클래스 정의
	 */
	get modalClass() {
		const defaultClass = "slds-modal__content slds-p-around_small";
		const headlessClass = `${defaultClass} slds-modal__content_headless`;
		return this.modalMap.finance ? defaultClass : headlessClass;
	}

	/**
	 * @description 금융 비교 레이아웃 사이즈
	 */
	get compareSize() {
		return formFactor === "Large"
			? 12 / this.compareFinancialList.length
			: formFactor === "Medium"
				? 6
				: 12;
	}

	/**
	 * @description 페이지 접속 시 마다 호출됨
	 * @param pageRef
	 */
	@wire(CurrentPageReference)
	getStateParameters(pageRef) {
		if (pageRef) {
			this.isLoading = true;
			this.tableDataMap.discountDetail = {};
			this.tableDataMap.financial = {};
			this.tableDataMap.extraExpenses = {};
			this.specialOptionList = [{ ...initSpecialData }];
			this.selectedOptionData = [];
			this.oppId = pageRef.state.c__oppId;
			this.quoteId = pageRef.state.c__quoteId;

			getInit({ oppId: this.oppId, quoteId: this.quoteId }).then(res => {

				// 차종 체크
				if (!res.productData) {
					showToast("차종이 선택되지 않은 데이터입니다.", "", "warning");
					this.navigateToBack();
					return;
				}

				this.isViewStock = false;
				this.quoteName = res.quoteDetail?.name;
				this.optionFilter = [{ label: "선택안함", value: "" }].concat(res.optionFilter);
				this.oppData = res.oppData;
				this.allOptionData = res.optionList;
				this.availableOilCouponQty = res.availableOilCouponQty;
				this.selectedOptionData = this.allOptionData?.filter(el => el.isRequired);
				this.campaignDupList = res.campaignDupList;
				this.financialList = [{ label: "선택안함", value: null }].concat(res.financialList);

				const { name, quote, ...quoteDetail } = res.quoteDetail;
				this.quoteName = name;
				this.quoteData = quote;
				this.handoverDate = quote?.HopeHandoverDate__c;

				// 기존에 저장된 견적 데이터 있으면 가져오기
				if (quoteDetail && Object.keys(quoteDetail)?.length > 0) {

					// 옵션
					if (quoteDetail?.option.length > 0) {
						const optionDataList = quoteDetail?.option || [];

						// 필수 옵션 모두 체크하기 위한 기존 데이터 Id Set
						const optionIdSet = new Set(optionDataList.map(el => el.id));

						// 기존 데이터에 필수 옵션이 포함되어 있지 않았을 때 Merge
						this.selectedOptionData = [...optionDataList, ...this.selectedOptionData?.filter(el => !optionIdSet.has(el.id)) || []];
						this.defaultOptionData = this.selectedOptionData?.filter(el => el.type === "기본제공");
					}
					this.tableDataMap.defaultOptions = this.defaultOptionData;

					// 캠페인
					this.selectedCampaignList = quoteDetail?.promotion || [];

					// 주유상품권
					const oilCouponCount = quoteDetail.oilCouponCount || 0;
					this.tableDataMap.discountDetail.oilCouponCount = oilCouponCount;
					this.tableDataMap.discountDetail.oilCouponPrice = Number(oilCouponCount) * 100000;

					// 특장
					if (quoteDetail.special?.length > 0) {
						this.specialOptionList = quoteDetail.special;
						this.specialOptionList.forEach(special => {
							special.subOptions = [];
							special.subOptions = specialDependency[special?.option];
							special.isViewAccount = special?.option === "캡섀시 - 미완성";
							if (!special.isViewAccount) special.accountId = null;
						});
						this.tableDataMap.special = this.specialOptionList;
					}

					// 금융
					this.tableDataMap.financial = quoteDetail.financial;

					// 부대비용
					this.tableDataMap.extraExpenses = quoteDetail.extraExpenses;
					this.tableDataMap.extraExpenses.isStampDuty = false;
					this.tableDataMap.extraExpenses.isStampDuty = this.tableDataMap.extraExpenses?.stampDuty > 0;
				}

				// 금융 기본값 설정
				const finance = this.financialList?.find(el => el?.value && el?.value === this.tableDataMap.financial?.financeId);
				this.tableDataMap.financial.isVAT = this.oppData?.VATDefermentStatus__c === "승인됨";
				this.tableDataMap.financial.defermentVATDays = this.oppData?.VATDeferredDays__c;
				this.tableDataMap.financial.paymentDeferredAmount = this.oppData?.PaymentDeferredAmount__c || 0;
				this.setFinancialData(this.tableDataMap.financial, finance);

				this.hideRequiredOptionButton();
				this.setProductData(res?.productData, res?.optionList, res?.campaignList, res?.baseDiscount);
				this.getServiceItem();
				this.getSummaryData();
			}).catch(err => {
				console.error("err :: ", err.message);
			}).finally(() => this.isLoading = false);
		}
	}

	connectedCallback() {
		// 캘린더 이벤트
		window.addEventListener("message", this.getDataFromChild.bind(this));
	}

	/**
	 * @description 렌더링 시 화면 스타일 조정
	 */
	renderedCallback() {
		window.addEventListener("beforeunload", this.clearStyle.bind(this));
		if (formFactor === "Large") {
			const bodyHeaderBoxEl = this.template.querySelectorAll(".body-header .body-wrap");
			let boxHeight;
			// 요약 테이블 높이 조절
			bodyHeaderBoxEl?.forEach(el => {
				if (boxHeight) {
					el.style.height = `${boxHeight}px`;
					el.style.alignContent = "center";
				} else {
					boxHeight = el.offsetHeight;
				}
			});
			const oppStyle = document.querySelector(".opp-custom-style");
			if (oppStyle) oppStyle.remove();

			let styleEl = document.querySelector(".custom-style");
			if (!styleEl) {
				requestAnimationFrame(() => {
					const carTableWrapEl = this.template.querySelector(".car-table-wrap");
					carTableWrapEl.style.overflowY = "initial";
				});
				styleEl = document.createElement("style");
				styleEl.className = "custom-style";
				styleEl.innerText = `
					.quote-creator-wrap {
						.slds-icon {
							fill: var(--slds-c-icon-color-foreground, var(--slds-g-color-neutral-base-100)) !important;
						}
						.slds-input:disabled {
							color: #2e2e2e;
						}
						.slds-input[readonly] {
							color: #2e2e2e;
							--slds-c-input-spacing-inlinestart: initial;
						    --slds-c-input-color-border: initial;
						    --slds-c-input-color-background: initial;
						}
						.stock-table-wrap table tbody th,
						.stock-table-wrap table tbody td {
							padding: 0.3rem;
						}
						lightning-datatable[data-name="option"] table tbody th,
						lightning-datatable[data-name="option"] table tbody td {
							padding: 0 0.3rem;
						}
						lightning-datepicker .slds-form-element__help {
							display: none;
						}
					}
					.slds-popover__body {
				        white-space: pre-wrap;
				    }
				    
				    lightning-overlay-container {
				        lightning-confirm {
						    text-align: center;
						    font-size: 1rem;
						    font-weight: bold;
						}
						.slds-modal__footer {
							text-align: center !important;
						}
				    }
				`;
				document.body.appendChild(styleEl);
			}
		}
	}

	/**
	 * @description 테이블 행 삭제 이벤트
	 */
	handleRowAction(e) {
		const type = e.detail.row.type;
		const currentRowId = e.detail.row.id;

		if (type === "기본제공") {
			this.defaultOptionData = this.defaultOptionData.filter(el => el.id !== currentRowId);
		} else if (type === "서비스품목") {
			this.tableDataMap.serviceItem = { name: null, fieldList: [] };
		}

		this.selectedOptionIdList = this.selectedOptionIdList.filter(el => el !== currentRowId);
		this.selectedOptionData = this.selectedOptionData.filter(el => el.id !== currentRowId);
		this.tableDataMap.product.optionList = this.selectedOptionData.filter(el => el.type !== "기본제공");
		this.tableDataMap.defaultOptions = this.defaultOptionData;
		this.getServiceItem();
		this.getSummaryData();
	}

	/**
	 * @description 테이블 체크박스 클릭 이벤트
	 */
	handleRowSelection(e) {
		const name = e.target.dataset.name;
		const selectedRows = e.detail.selectedRows;
		const action = e.detail.config.action;
		const value = e.detail.config.value;

		// 캠페인 테이블
		if (name === "campaign") {
			let isDuplicated = false;
			if (action === "rowSelect") {
				isDuplicated = this.campaignDupList.some(el => {
					// 기존에 선택된 캠페인 먼저 중복 리스트에 포함되는지 체크
					if (this.selectedCampaignIdList.includes(el.CampaignMaster__c) || this.selectedCampaignIdList.includes(el.CampaignMaster2__c)) {
						// 현재 선택한 캠페인이 중복에 포함되는지 체크
						if (el.CampaignMaster__c === value || el.CampaignMaster2__c === value) {
							showToast(`[${el.CampaignMaster__r.Name}] 캠페인과 [${el.CampaignMaster2__r.Name}] 캠페인은 중복이 불가합니다.`, "", "warning", "sticky");
							return true;
						}
					}
					return false;
				});
			} else if (action === "selectAllRows") {
				if (this.campaignDupList?.length > 0) {
					isDuplicated = true;
					showToast("중복 불가한 캠페인이 있습니다.", "", "warning");
				}
			}

			// 중복 시 함수 종료
			if (isDuplicated) {
				this.selectedCampaignIdList = [...this.selectedCampaignIdList];
				return;
			}

			this.selectedCampaignIdList = selectedRows?.map(row => row.id) || [];
			this.tableDataMap.promotion.promotionList = selectedRows;
			this.getSummaryData();
		}
		// 할인 차량 테이블
		else if (name === "stock") {
			this.selectedStockIdList = selectedRows?.length ? [selectedRows[0].Id] : [];
			this.tableDataMap.promotion.additionalStockDiscount = selectedRows?.[0]?.totalDiscountPrice || 0;
		}
		// 옵션 모달 테이블
		else if (name === "modalOption") {
			if (action) {
				switch (action) {
					// 전체 체크 해제
					case "deselectAllRows":
						const optionData = this.optionData?.filter(el => !el.isRequired) || [];
						const optionDataIdList = optionData?.map(el => el.id) || [];
						this.selectedOptionIdList = this.selectedOptionIdList?.filter(el => !optionDataIdList.includes(el));
						break;
					// 행 체크 해제
					case "rowDeselect":
						const currentRow = this.optionData?.find(row => row.id === value);
						this.selectedOptionIdList = this.selectedOptionIdList?.filter(el => el !== value || currentRow.isRequired);
						break;
					// 전체 체크
					case "selectAllRows":
						selectedRows?.forEach(el => {
							if (!this.selectedOptionIdList.includes(el.id)) {
								this.selectedOptionIdList.push(el.id);
							}
						});
						break;
					// 행 체크
					case "rowSelect":
						if (!this.selectedOptionIdList.includes(value)) {
							this.selectedOptionIdList.push(value);
						}
						break;
				}
			}
		}
	}

	/**
	 * @description 차종, 옵션 섹션 데이터 변경 시 계산기 컴포넌트로 데이터 전송
	 */
	handleChange(e) {
		const name = e.target.dataset.name;
		const recordId = e.detail.recordId;
		const value = e.target.value;
		const numValue = Number(value);
		const checked = e.target.checked;
		const idx = e.target.dataset.idx;

		// 특장 데이터 전송
		const setSpecialOption = (idx) => {
			if (idx) this.specialOptionList[idx].idx = idx;
			this.tableDataMap.special = this.specialOptionList;
		};
		switch (name) {
			// 차종 변경 시
			case "product" :
				this.productId = recordId;
				if (this.productId) {
					this.isLoading = true;
					// 차종 관련 데이터 가져오기
					getProductChangeData({ oppId: this.oppId, productId: this.productId }).then(res => {
						this.allOptionData = res.optionList;
						this.selectedOptionData = this.allOptionData?.filter(el => el.isRequired);
						this.hideRequiredOptionButton();
						this.campaignDupList = res.campaignDupList;
						this.setProductData(res.productData, res.optionList, res.campaignList, res.baseDiscount);
						this.getSummaryData();
						this.financialList = res.financialList;
					}).catch(err => {
						console.error("err :: ", err);
					}).finally(() => this.isLoading = false);
				}
				// 차종 제거 시 데이터 초기화
				else {
					this.financeId = null;
					this.tableDataMap.financial = {};
					this.tableDataMap.financial.advancePayment = 1000000;
					this.tableDataMap.discountDetail = {};
					this.tableDataMap.extraExpenses = {};
					this.specialOptionList = [{ ...initSpecialData }];
					this.selectedOptionData = [];
					this.selectedOptionIdList = [];
					this.financialList = [];
					this.setProductData(null, null, null, 0);
				}
				this.getServiceItem();
				break;
			case "handover":
				this.handoverDate = value;
				break;
			case "additionalDC":
				this.isViewStock = checked;
				break;
			// 주유상품권
			case "oilCoupon" :
				this.tableDataMap.discountDetail.oilCouponCount = numValue || 0;
				this.tableDataMap.discountDetail.oilCouponPrice = this.tableDataMap.discountDetail.oilCouponCount * 100000;
				break;
			// BB Case 특장 대분류
			case "specialOption" :
				this.specialOptionList[idx].option = value;
				this.specialOptionList[idx].subOptions = specialDependency[value];
				this.specialOptionList[idx].isViewAccount = value === "캡섀시 - 미완성";
				if (!this.specialOptionList[idx].isViewAccount) this.specialOptionList[idx].accountId = null;
				setSpecialOption(idx);
				break;
			// BB Case 특장 회사
			case "specialAccountId" :
				this.specialOptionList[idx].accountId = e.detail.recordId;
				setSpecialOption(idx);
				break;
			// BB Case 특장 분류
			case "specialSubOption" :
				this.specialOptionList[idx].subOption = value;
				setSpecialOption(idx);
				break;
			// BB Case 특장 가격
			case "specialPrice" :
				this.specialOptionList[idx].price = numValue;
				setSpecialOption(idx);
				break;
			// 최종 특장 제작사 / 최종 차랑명
			case "specialFinal" :
				this.specialOptionList[idx].specialFinal = value;
				setSpecialOption(idx);
				break;
			// 금융 회사
			case "financeId" :

				// Picklist
				const finance = this.financialList?.find(el => el.value === value);
				this.setFinancialData(this.tableDataMap.financial, finance);
				break;
			// 인도금
			case "advancePayment" :
				this.tableDataMap.financial.advancePayment = numValue;
				break;
			// 대출금액
			case "loanAmount" :
				this.tableDataMap.financial.loanAmount = numValue;
				break;
			// 캐피탈 유예
			case "capitalDeferment" :
				this.tableDataMap.financial.capitalDeferment = numValue;
				break;
			// 이자율
			case "interestRate" :
				this.tableDataMap.financial.interestRate = numValue;
				break;
			// 대출 개월 수
			case "loanTermMonth" :
				this.tableDataMap.financial.loanTermMonth = numValue;
				break;
			// 탁송료
			case "consignment":
				this.tableDataMap.extraExpenses.consignment = numValue;
				break;
			// 출고보험료
			case "insurance":
				this.tableDataMap.extraExpenses.insurance = numValue;
				break;
			// 인지대
			case "stampDuty":
				const loanAmount = this.tableDataMap.financial?.loanAmount || 0;
				this.tableDataMap.extraExpenses.isStampDuty = checked;
				this.tableDataMap.extraExpenses.stampDuty = checked ? loanAmount < 100000000 ? 35000 : 75000 : 0;
				break;
		}
		this.getSummaryData();
	}

	/**
	 * @description 캠페인 선택 초기화
	 */
	handleRefresh(e) {
		const name = e.target.dataset.name;
		if (name === "campaign") {
			this.selectedCampaignIdList = [];
			const currentStock = this.tableDataMap.product.stockList.length > 0 ? this.tableDataMap.product.stockList[0] : [];

			Object.assign(this.tableDataMap.promotion, {
				promotionList: [],
				baseDiscount: this.baseDiscount,
				additionalDiscount: this.quoteData.AdditionalLossPrice__c,
				additionalStockDiscount: currentStock?.totalDiscountPrice || 0
			});
		} else if (name === "stock") {
			this.selectedStockIdList = [];
			this.tableDataMap.promotion.additionalStockDiscount = 0;
		}
	}

	// 모달 창 on/off
	toggleModal(type) {
		this.isModalOpen = !this.isModalOpen;

		// 이벤트인지 함수 호출 파라미터인지 체크
		if (!type || typeof type !== "string") type = "option";

		// 모바일 모달 오픈 시 맨 위로 스크롤
		if (this.isModalOpen && formFactor !== "Large") this.scrollToTop();

		Object.keys(this.modalMap).forEach(el => this.modalMap[el] = el === type);
	}

	/**
	 * @description 옵션 모달 창 필터 변경 이벤트
	 */
	handleModalChange(e) {
		const name = e.target.dataset.name;
		const value = e.target.value;
		if (name === "searchType") {
			this.optionSearchMap.type = value;
		} else if (name === "searchName") {
			this.optionSearchMap.name = value;
		}
	}

	/**
	 * @description 비교 창 열기
	 */
	handleCompareOpen() {
		this.toggleModal("finance");
		this.compareFinancialList = deepClone(initFinancialData);

		this.compareFinancialList = this.compareFinancialList.map((el, idx) => {
			const financial = this.getCurrentFinancial();
			return {
				...financial,
				idx: idx
			}
		});
	}

	/**
	 * @description 현재 금융 데이터 가져오기
	 */
	getCurrentFinancial() {
		const currentFinancial = deepClone(this.tableDataMap.financial);
		currentFinancial.idx = 0;
		currentFinancial.checked = null;

		const childEl = this.template.querySelector("c-quote-calculator-table");
		currentFinancial.monthlyPayment = childEl?.calcMonthPayment(currentFinancial.loanAmount, currentFinancial.interestRate, currentFinancial.loanTermMonth) || 0;

		return currentFinancial;
	}

	/**
	 * @description 비교 창에서 (+) (-) 버튼 클릭
	 */
	handleCompareClick(e) {
		const name = e.target.dataset.name;
		if (name === "addBtn") {
			if (this.compareFinancialList?.length === 4) {
				showToast("비교는 최대 4개까지 가능합니다", "", "warning");
				return;
			}
			this.compareFinancialList.push({ ...this.getCurrentFinancial(), idx: this.compareFinancialList.length });
		} else {
			if (this.compareFinancialList?.length > 2) {
				this.compareFinancialList.pop();
			} else {
				this.compareFinancialList = deepClone(initFinancialData);
			}
		}
	}

	/**
	 * @description 비교 창에서 데이터 변경 시 onchange 함수
	 */
	handleCompareChange(e) {
		const name = e.target.dataset.name;
		const value = e.target.value;
		const numValue = Number(value);
		const idx = e.target.dataset.idx;
		const finance = this.financialList?.find(el => el.value === value);

		// 현재 객체
		const currentFinancial = this.compareFinancialList[idx];

		// 기본값 처리
		const defaultFinance = {
			value: "",
			label: "",
			minInterestRate: 0,
			maxInterestRate: 0,
			minimumDuration: 6,
			maximumDuration: 84
		};
		const selectedFinance = finance || defaultFinance;

		switch (name) {

			// 금융 선택
			case "select":
				this.compareFinancialList.forEach(el => el.checked = "");
				currentFinancial.checked = "checked";
				break;
			// 금융 회사
			case "financeId":
				this.setFinancialData(currentFinancial, selectedFinance);
				break;

			// 선수금
			case "advancePayment":
				currentFinancial.advancePayment = numValue;
				currentFinancial.loanAmount = this.summaryData.realSalesPrice - numValue;
				break;

			// 이자율
			case "interestRate":
				currentFinancial.interestRate = numValue;
				break;

			// 대출 개월 수
			case "loanTermMonth":
				currentFinancial.loanTermMonth = numValue;
				break;
		}

		// 월별 상환액 계산
		const childEl = this.template.querySelector("c-quote-calculator-table");
		currentFinancial.monthlyPayment = childEl?.calcMonthPayment(currentFinancial.loanAmount, currentFinancial.interestRate, currentFinancial.loanTermMonth) || 0;
	}

	/**
	 * @description 모달 창에서 버튼 클릭 이벤트
	 */
	handleModalClick(e) {
		const name = e.currentTarget.dataset.name;

		// 옵션 데이터 가져오기
		const getOptionData = () => {
			this.isLoading = true;
			this.optionSearchMap = { ...this.optionSearchMap, product: this.productId };
			getFilteredOptionList({ filterMap: this.optionSearchMap }).then(res => {
				this.optionData = res;
				this.selectedOptionIdList = [...this.selectedOptionIdList];
			}).catch(err => {
				console.error("err :: ", err);
			}).finally(() => this.isLoading = false);
		};

		switch (name) {
			// 옵션 검색 초기화 버튼
			case "refresh":
				this.optionSearchMap = { ...defaultOptionSearchMap };
				break;
			// 옵션 검색 버튼
			case "search":
				if (this.productId) getOptionData();
				break;
			case "save":
				// 옵션 모달 저장
				if (this.modalMap.option) {
					const selectedRows = this.allOptionData?.filter(el => this.selectedOptionIdList.includes(el.id));
					// 서비스 품목 개수 체크
					if (selectedRows?.filter(el => el.type === "서비스품목" && !el.isRequired)?.length > 1) {
						showToast("No Carefree 제외 1개의 서비스품목만 선택해주세요.", "", "warning");
						return;
					}

					this.optionSearchMap = { ...defaultOptionSearchMap };
					getOptionData();

					this.selectedOptionData = selectedRows;
					this.hideRequiredOptionButton();
					this.tableDataMap.product.optionList = this.selectedOptionData?.filter(el => el.type !== "기본제공");
					this.defaultOptionData = this.selectedOptionData?.filter(el => el.type === "기본제공");
					this.tableDataMap.defaultOptions = this.defaultOptionData;

					this.getServiceItem();
					this.getSummaryData();
				}
				// 금융 모달 저장
				else if (this.modalMap.finance) {

					const selectedFinance = this.compareFinancialList.find(el => el.checked === "checked");

					// 금융 비교 션택 여부 체크
					if (!selectedFinance) {
						showToast("원하는 금융 옵션을 선택해주세요.", "", "warning");
						return;
					}

					// 이자율 범위 체크
					if (selectedFinance?.interestRate < selectedFinance?.minInterestRate || selectedFinance?.interestRate > selectedFinance?.maxInterestRate) {
						showToast("이자율 범위를 확인해주세요.", "", "warning");
						return;
					}

					// 대출 기간 범위 체크
					if (selectedFinance?.loanTermMonth < selectedFinance?.minimumDuration || selectedFinance?.loanTermMonth > selectedFinance?.maximumDuration) {
						showToast("대출 기간(개월) 범위를 확인해주세요.", "", "warning");
						return;
					}

					this.tableDataMap.financial = selectedFinance;
					this.getSummaryData();
				}
				this.toggleModal();
				break;
			default:
				this.toggleModal();
				break;
		}
	}

	/**
	 * @description 버튼 클릭 이벤트
	 */
	handleClick(e) {
		const name = e.target.dataset.name;
		switch (name) {
			// 견적 저장
			case "save":

				// 차종 확인
				if (!this.productId) {
					showToast("차종을 선택해주세요.", "", "warning");
					return;
				}

				// 주유상품권 확인
				const discountDetail = this.tableDataMap.discountDetail;
				if (discountDetail.oilCouponCount < 0 || discountDetail.oilCouponCount > discountDetail.maxCount) {
					showToast("주유상품권 수량을 확인해주세요.", "", "warning");
					return;
				}

				// 특장 확인
				const isSpecialValidation = this.tableDataMap.special.some(el =>
					el?.option === "캡섀시 - 미완성" && !el?.specialFinal
				);
				if (isSpecialValidation) {
					showToast("최종 특장 제작사 / 최종 차랑명을 입력해주세요.", "", "warning");
					return;
				}

				// 금융 확인
				const financial = this.tableDataMap.financial;
				const interestRate = financial?.interestRate;
				const loanTermMonth = financial?.loanTermMonth;
				const capitalDeferment = financial?.capitalDeferment;
				const advancePayment = financial?.advancePayment;

				// Validation
				if (interestRate < financial?.minInterestRate || interestRate > financial?.maxInterestRate) {
					showToast("이자율 범위를 확인해주세요.", "", "warning");
					return;
				}
				if (loanTermMonth < financial?.minimumDuration || loanTermMonth > financial?.maximumDuration) {
					showToast("대출 기간(개월) 범위를 확인해주세요.", "", "warning");
					return;
				}
				if (advancePayment > this.summaryData.realSalesPrice || advancePayment < financial.minAdvancePayment) {
					showToast("인도금 범위를 확인해주세요.", "", "warning");
					return;
				}
				if (capitalDeferment > financial?.loanAmount || capitalDeferment < 0) {
					showToast("캐피탈 유예금 범위를 확인해주세요.", "", "warning");
					return;
				}

				this.isLoading = true;
				const paramMap = {
					oppId: this.oppId,
					quoteId: this.quoteId,
					handoverDate: this.handoverDate,
					stockId: this.selectedStockIdList?.length > 0 ? this.selectedStockIdList[0] : null,
					oilCouponCount: this.tableDataMap.discountDetail.oilCouponCount,
					dataMap: JSON.stringify(this.tableDataMap),
					summaryData: JSON.stringify(this.summaryData)
				};

				doSaveQuote({ paramMap: paramMap }).then(res => {
					showToast("견적을 저장하였습니다.", "", "success");
					notifyRecordUpdateAvailable([{ recordId: res }]).then(() => {
						setTimeout(() => {
							this.clearStyle();
							recordNavigation(this, "Quote", res);
						}, 1000);
					});
				}).catch(err => {
					console.error("err :: ", err);
					showToast(err.body.message, "", "warning");
					this.isLoading = false;
				});
				break;
			// 견적 취소
			case "cancel":
				this.clearStyle();
				this.navigateToBack();
				break;
			// 특장 추가
			case "addBtn":
				const specialData = { ...initSpecialData };
				specialData.idx = this.specialOptionList?.length;
				this.specialOptionList.push(specialData);
				break;
			// 특장 제거
			case "removeBtn":
				if (this.specialOptionList?.length > 1) {
					this.specialOptionList.pop();
				} else {
					this.specialOptionList = [{ ...initSpecialData }];
				}
				this.tableDataMap.special = this.specialOptionList;
				break;
			// 캘린더
			case "handover":
				this.isLoading = true;
				const stockId = this.selectedStockIdList.length > 0 ? this.selectedStockIdList[0] : null;
				getCalendarInit({ vehicleStockId: stockId }).then(res => {
					this.handoverDateList = res.handoverDateList;
					this.optionDelayList = res.optionDelayList
					.sort((a, b) => a.Attribute2__c - b.Attribute2__c)
					.map(option => ({
						...option,
						isAssign: option.Attribute2__c == res.diffDays
					}));
					this.toggleModal("calendar");
				}).catch(err => {
					console.error("err :: ", err);
				});
				break;
		}
	}

	/**
	 * @description iframe 로드 (캘린더 선택) 시 캘린더 데이터 전송
	 */
	handleLoad(e) {
		// iframe의 윈도우 객체를 저장
		const iframeWindow = e.target.contentWindow;

		// VF 페이지로 초기 데이터를 전송
		const initialData = {
			type: "INIT_DATA",
			target: "calendar_quoteCreator",
			event: this.handoverDateList,
			selectedDay: this.handoverDate
		};

		// VF 페이지로 데이터 전송
		iframeWindow.postMessage(initialData, this.vfHost);

		this.isLoading = false;
	}

	/**
	 * @description visualforce 캘린더에서 받아온 이벤트
	 */
	getDataFromChild(e) {

		if (this.vfHost !== e.origin || e.data.target !== "calendar_quoteCreator") return;

		const type = e.data.type;
		let value;
		let selectedDate;

		if (type === "eventClick") {
			selectedDate = e.data.event.start;
			value = selectedDate === this.handoverDate ? "same" : e.data.event.title;

			// 에러 메시지 맵
			const messageMap = {
				"same": "현재 출고일과 같습니다."
				// "6/6": "이미 마감된 출고일입니다.",
				// "휴일": "휴일은 선택할 수 없습니다."
			};

			if (messageMap[value]) {
				showToast("변경 불가", messageMap[value], "warning");
				return;
			}

			// 변경 확인 문구
			LightningConfirm.open({
				message: `출고 희망일을 [${selectedDate}]로 변경하시겠습니까?`,
				variant: "headerless"
			}).then(res => {
				this.isLoading = true;
				if (res) {
					this.handoverDate = selectedDate;
					this.toggleModal();
					this.getSummaryData();
				}
			}).finally(() => this.isLoading = false);
		}

	}

	/**
	 * @description Product 변경 시 Product 관련 데이터 세팅
	 * @param productData 차종 데이터
	 * @param optionList 옵션 데이터
	 * @param campaignList 캠페인 데이터
	 * @param baseDiscount 기준할인가 데이터
	 */
	setProductData(productData, optionList, campaignList, baseDiscount) {

		this.productId = productData?.id;
		const productPrice = productData?.price || 0;

		// 추가할인차량 데이터 리스트
		const stockList = productData?.stockList?.map(stock => {
			const baseDiscountPrice = baseDiscount / 100;
			const longTermDiscountRate = (stock.LongtermDiscountRate__c || 0);
			const specialDiscountRate = (stock.SpecialDiscountRate__c || 0);
			const optionDiscountRate = (stock.OptionDiscountRate__c || 0);
			const longTermDiscountPrice = productPrice * longTermDiscountRate;
			const specialDiscountPrice = productPrice * specialDiscountRate;
			const optionDiscountPrice = productPrice * optionDiscountRate;
			const totalDiscountPrice = (productPrice * baseDiscountPrice) + longTermDiscountPrice + specialDiscountPrice + optionDiscountPrice;
			const totalDiscountRate = (baseDiscount + (longTermDiscountRate * 100) + (specialDiscountRate * 100) + (optionDiscountRate * 100)).toFixed(2);

			return {
				...stock,
				LMY: productData?.LMY,
				VMY: productData?.VMY,
				totalDiscount: `${Math.floor(totalDiscountPrice / 10000)}만원 할인 (총할인율 ${totalDiscountRate}%)`,
				totalDiscountPrice: longTermDiscountPrice + specialDiscountPrice + optionDiscountPrice,
				baseDiscount: baseDiscountPrice,
				discountedPrice: productPrice - totalDiscountPrice
			};
		}) || [];

		// 차종 데이터 세팅
		this.productData = productData ? {
			...productData,
			optionList: this.selectedOptionData?.filter(el => el.type !== "기본제공"),
			stockList: stockList || []
		} : { segment: null, LMY: null, stockList: [] };
		this.tableDataMap.product = this.productData;

		// 옵션 데이터 세팅
		this.optionData = optionList;
		this.selectedOptionIdList = this.selectedOptionData?.map(el => el.id);

		// 캠페인 데이터 세팅
		this.baseDiscount = (productData?.price || 0) * (baseDiscount / 100);
		this.campaignData = campaignList?.map(el => {
			const discountRate = el.discountRate ? el.discountRate : el.discountPrice ? (el.discountPrice / this.productData.price) : 0;
			const discountPrice = el.discountPrice ? el.discountPrice : this.productData.price * (el.discountRate || 0);
			return {
				...el,
				discountRate: discountRate,
				discountPrice: discountPrice,
				content: el.memo
			};
		}) || [];
		this.selectedCampaignIdList = this.selectedCampaignList?.map(row => row.id);
		const selectedCampaignList = this.campaignData?.filter(row => this.selectedCampaignIdList.includes(row.id));

		// 선택된 추가할인차량 데이터 세팅
		const currentStock = stockList?.find(el => el.Id === this.quoteData?.VehicleStock__c);
		this.selectedStockIdList = [currentStock?.Id] || [];

		// 프로모션 데이터 세팅
		Object.assign(this.tableDataMap.promotion, {
			promotionList: selectedCampaignList,
			baseDiscount: this.baseDiscount,
			additionalDiscount: this.quoteData.AdditionalLossPrice__c,
			additionalStockDiscount: currentStock?.totalDiscountPrice || 0
		});
	}

	/**
	 * @description 필수 옵션 삭제 버튼 제거
	 */
	hideRequiredOptionButton() {
		this.selectedOptionData?.forEach(el => {
			if (el?.isRequired) el.formatClass = "slds-hidden";
		});
	}

	/**
	 * @description CareFree 옵션 선택 시 서비스 품목 데이터 가져오기
	 */
	getServiceItem() {
		const serviceItemList = this.selectedOptionData?.filter(el => el.type === "서비스품목");
		if (serviceItemList && serviceItemList.length > 0) {
			// Carefree 존재 시 No Carefree 제외
			const serviceItem = serviceItemList.length === 1
				? serviceItemList[0]
				: serviceItemList.find(el => !el.isRequired) || serviceItemList.find(el => el.isRequired);
			getServiceItem({ serviceItemId: serviceItem.id }).then(res => {
				if (res) this.tableDataMap.serviceItem = res;
			}).catch(err => {
				console.error("err :: ", err);
				this.tableDataMap.serviceItem = {};
			});
		} else {
			this.tableDataMap.serviceItem = {};
		}

	}

	/**
	 * @description 계산기 요약 데이터 가져오기
	 */
	getSummaryData() {
		requestAnimationFrame(() => {
			const childEl = this.template.querySelector("c-quote-calculator-table");
			this.summaryData = childEl.calcSummary();
			this.tableDataMap.extraExpenses = childEl.getExtraExpensesData();
			const discountDetailData = childEl.getDiscountDetailData();

			const maxCount = discountDetailData.maxCount;
			this.tableDataMap.discountDetail.maxCount = maxCount;
			this.tableDataMap.discountDetail.underflowMessage = "1 이상의 숫자를 입력해주세요.";
			this.tableDataMap.discountDetail.overflowMessage = `최대 입력 가능 수량은 ${maxCount}(장) 입니다.`;

			const financial = childEl.getFinancialData();
			const defermentVAT = financial?.defermentVAT || 0;
			const minAdvancePayment = 1000000 + defermentVAT + financial.paymentDeferredAmount;

			// 처음 로드 시 최솟값 자동 반영
			if (this.isFirst) this.tableDataMap.financial.advancePayment = financial?.advancePayment || minAdvancePayment;
			this.isFirst = false;

			Object.assign(this.tableDataMap.financial, {
				minAdvancePayment: minAdvancePayment,
				defermentVAT: defermentVAT,
				loanAmount: financial?.loanAmount || 0,
				deposit: financial?.deposit || 0,
				deliveryPrice: financial?.deliveryPrice || 0,
				interestDefermentVAT: financial?.interestDefermentVAT || 0,
				maxCapitalPrice: financial?.loanAmount || 0
			});
		});
	}

	/**
	 * @description 금융 데이터 세팅
	 * @param financial 세팅할 금융 데이터 맵
	 * @param finance 적용할 금융 데이터
	 */
	setFinancialData(financial, finance) {
		const financeId = finance?.value;
		const minInterestRate = finance?.minInterestRate || 0;
		const maxInterestRate = finance?.maxInterestRate || 10;
		const minimumDuration = finance?.minimumDuration || 0;
		const maximumDuration = finance?.maximumDuration || 84;
		const advancePayment = financial?.advancePayment || this.tableDataMap.financial.minAdvancePayment;
		const helpText = financeId
			? [
				`최소 기간: ${minimumDuration}`,
				`최대 기간: ${maximumDuration}`,
				`VAT free: ${finance?.VATFree || ""}`,
				`보조금: ${finance?.subvention || 0}`,
				`기타: ${finance?.extra || ""}`
			].join("\n")
			: "금융을 선택해주세요.";

		Object.assign(financial, {
			financeId: financeId,
			financialName: finance?.label || "",
			minInterestRate: minInterestRate,
			maxInterestRate: maxInterestRate,
			minimumDuration: minimumDuration,
			maximumDuration: maximumDuration,
			interestRateRange: `${minInterestRate} ~ ${maxInterestRate}`,
			advancePayment: advancePayment,
			helpText: helpText
		});
	}

	/**
	 * @description 취소 버튼 클릭 시 이전 레코드 페이지로 돌아가기
	 */
	navigateToBack() {
		let targetName, targetId;

		// 이전 페이지 - Quote
		if (this.quoteId) {
			targetName = "Quote";
			targetId = this.quoteId;
		}
		// 이전 페이지 - Opportunity
		else if (this.oppId) {
			targetName = "Opportunity";
			targetId = this.oppId;
		}

		if (targetName) {
			// 전역 스타일 제거 후 페이지 이동
			this.clearStyle();
			recordNavigation(this, targetName, targetId);
		}
	}

	/**
	 * @description 전역 스타일 제거하기
	 */
	clearStyle() {
		const styleEl = document.querySelector(".custom-style");
		if (styleEl) styleEl.remove();
	}

	/**
	 * @description 스크롤 맨 위로
	 */
	scrollToTop() {
		window.scrollTo({ top: 0, behavior: "smooth" });
	}

}