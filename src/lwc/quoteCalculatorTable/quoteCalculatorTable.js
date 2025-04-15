/*************************************************************
 * @author : th.kim
 * @date : 2024-12-13
 * @description : 견적 구성 계산 화면
 * @target : quoteCreator, quotePreview
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-12-13      th.kim          Initial Version
 **************************************************************/
import { api, LightningElement } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";

export default class quoteCalculatorTable extends LightningElement {

	@api tableDataMap;
	realSalesPrice = 0;

	/**
	 * @description 로드 시 스타일 적용
	 */
	connectedCallback() {
		let styleEl = document.querySelector(".custom-calc-style");
		if (!styleEl) {
			styleEl = document.createElement("style");
			styleEl.className = "custom-calc-style";
			styleEl.innerText = `
				.calc-wrap {
					table th, 
					table td:not(.slds-border_bottom) {
				        padding: 0.3rem;
					}
					table .slds-border_bottom td {
				        padding: 0.3rem 0.3rem 0.3rem 0.3rem;
			        }
				}
			`;

			document.body.appendChild(styleEl);
		}
	}

	/**
	 * @description 차종 데이터
	 */
	get productData() {
		const product = this.tableDataMap?.product;

		const price = product?.price || 0;
		const optionList = product?.optionList || [];
		let totalPrice = price;
		optionList.forEach(el => {
			if (el.price) totalPrice += el.price;
		});

		return {
			name: product?.name || "",
			price: price,
			totalPrice: totalPrice,
			optionList: product?.optionList || []
		};
	}

	/**
	 * @description 프로모션 데이터
	 */
	get promotionData() {
		const promotion = this.tableDataMap?.promotion || {};
		const promotionList = promotion?.promotionList || [];
		const baseDiscount = promotion?.baseDiscount || 0;
		const additionalDiscount = promotion?.additionalDiscount || 0;
		const additionalStockDiscount = promotion?.additionalStockDiscount || 0;

		const totalPrice = promotionList?.reduce(
			(acc, el) => acc + (el.discountPrice || 0),
			(baseDiscount + additionalDiscount + additionalStockDiscount)
		);

		return {
			promotionList,
			baseDiscount,
			additionalDiscount,
			additionalStockDiscount,
			totalPrice
		};

	}

	/**
	 * @description 총 가격할인 데이터
	 */
	get discountDetailData() {
		const { oilCouponPrice = 0 } = this.tableDataMap?.discountDetail || {};
		const totalPrice = this.promotionData.totalPrice;
		const interestDefermentVAT = this.financialData.interestDefermentVAT;
		let optionAdditionalPrice = 0;
		this.defaultOptionsData.forEach(el => {
			if (el.isOilCouponExclude) optionAdditionalPrice += el.price;
		});
		const maxCount = Math.floor((totalPrice - (interestDefermentVAT + optionAdditionalPrice)) / 100000) || 0;

		return {
			oilCouponPrice,
			discountPrice: totalPrice - oilCouponPrice,
			maxCount: maxCount,
			optionAdditionalPrice: optionAdditionalPrice
		};
	}

	/**
	 * @description 기본제공 품목
	 */
	get defaultOptionsData() {
		return this.tableDataMap?.defaultOptions || [];
	}

	/**
	 * @description 실판매금액
	 */
	get realSalesPriceData() {
		const discountPrice = this.discountDetailData.discountPrice;
		// 재귀 방지 변수
		this.realSalesPrice = this.productData.totalPrice - discountPrice;
		return this.realSalesPrice;
	}


	/**
	 * @description 특장
	 */
	get specialData() {
		const special = this.tableDataMap?.special || [];
		const totalPrice = special?.reduce((prevValue, currentEl) =>
			prevValue + (Number(currentEl?.price || 0)), 0
		);

		return {
			special,
			totalPrice: totalPrice
		};
	}

	/**
	 * @description 실 판매금액 + 특장비용
	 */
	get totalRealAndSpecialPrice() {
		return this.realSalesPriceData + this.specialData?.totalPrice;
	}

	/**
	 * @description 할부
	 */
	get financialData() {
		const financial = this.tableDataMap?.financial;

		const isVAT = financial?.isVAT || false;
		const advancePayment = financial?.advancePayment || 0;
		const deposit = 1000000;
		const paymentDeferredAmount = financial?.paymentDeferredAmount || 0;
		const interestRate = financial?.interestRate || 0;
		const loanTermMonth = financial?.loanTermMonth || 0;

		const defermentVAT = isVAT ? Math.round((this.realSalesPrice / 1.1) * 0.1) : 0;
		const defermentVATDays = financial?.defermentVATDays || 0;
		const interestDefermentVAT = Math.round((((defermentVAT * 0.12) / 365) * defermentVATDays) / 100000) * 100000;

		const deliveryPrice = advancePayment - (deposit + defermentVAT + paymentDeferredAmount);
		const loanAmount = this.realSalesPrice - advancePayment;
		const capitalDeferment = financial?.capitalDeferment || 0;
		const excludeCapitalLoanAmount = loanAmount - capitalDeferment;
		const monthlyPayment = this.calcMonthPayment(loanAmount, interestRate, loanTermMonth);

		return {
			financialName: financial?.financialName || "",
			isVAT: isVAT,
			advancePayment: advancePayment,
			deposit: deposit,
			deliveryPrice: deliveryPrice,
			defermentVAT: defermentVAT,
			paymentDeferredAmount: paymentDeferredAmount,
			loanAmount: loanAmount,
			excludeCapitalLoanAmount: excludeCapitalLoanAmount,
			capitalDeferment: capitalDeferment,
			interestRate: interestRate,
			loanTermMonth: loanTermMonth,
			monthlyPayment: monthlyPayment || 0,
			defermentVATDays: defermentVATDays,
			interestDefermentVAT: interestDefermentVAT || 0
		};
	}


	/**
	 * @description 부대비용
	 */
	get extraExpensesData() {
		const extraExpenses = this.tableDataMap?.extraExpenses;
		const consignment = extraExpenses?.consignment || 0;
		const insurance = extraExpenses?.insurance || 0;
		const isStampDuty = extraExpenses?.isStampDuty || false;
		const stampDuty = isStampDuty ? extraExpenses?.stampDuty || 0 : 0;
		const notarizedFee = this.financialData.isVAT ? Math.round(((this.financialData.defermentVAT * 1.3 * 0.0015) + 21500) / 10) * 10 : 0;
		const totalExpenses = consignment + insurance + stampDuty + notarizedFee;
		const taxRate = this.tableDataMap?.product?.segment === "TPP" ? 0.03 : 0.04;
		const registrationTax = Math.round((this.totalRealAndSpecialPrice / 1.1) * taxRate);
		return {
			consignment: consignment,
			insurance: insurance,
			isStampDuty: isStampDuty,
			stampDuty: stampDuty,
			notarizedFee: notarizedFee,
			totalExpenses: totalExpenses,
			registrationTax: registrationTax
		};
	}

	/**
	 * @description 출고 전 납입금
	 */
	get totalPaymentBeforeReleased() {
		return this.extraExpensesData.registrationTax + this.financialData.deposit + this.financialData.deliveryPrice;
	}

	/**
	 * @description 서비스 품목
	 */
	get serviceItemData() {
		const serviceItem = this.tableDataMap?.serviceItem;
		return {
			name: serviceItem?.name,
			fieldList: serviceItem?.fieldList || []
		};
	}

	/**
	 * @description 월 할부금 계산
	 * @param loanAmount 할부원금
	 * @param interestRate 적용금리
	 * @param loanTermMonth 할부개월수
	 */
	@api
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
	 * @description 부모 컴포넌트에 상세 할인 데이터 반환
	 */
	@api
	getDiscountDetailData() {
		return this.discountDetailData;
	}

	/**
	 * @description 부모 컴포넌트에 부대비용 데이터 반환
	 */
	@api
	getExtraExpensesData() {
		return this.extraExpensesData;
	}

	/**
	 * @description 부모 컴포넌트에 금융 데이터 반환
	 */
	@api
	getFinancialData() {
		return this.financialData;
	}

	/**
	 * @description 부모 컴포넌트에 합계 요약 데이터 반환
	 */
	@api
	calcSummary() {
		return {
			totalPrice: this.productData.totalPrice,
			realSalesPrice: this.realSalesPriceData,
			specialPrice: this.specialData.totalPrice,
			totalRealAndSpecialPrice: this.totalRealAndSpecialPrice,
			monthlyPayment: this.financialData.monthlyPayment,
			totalPaymentBeforeReleased: this.totalPaymentBeforeReleased
		};
	}
}