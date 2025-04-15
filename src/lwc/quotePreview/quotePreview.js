/*************************************************************
 * @author : th.kim
 * @date : 2025-01-08
 * @description : 현재 기회 레코드의 가장 최신 견적 데이터 가져와서 보여줌
 * @target : 기회 레코드 페이지 -> 견적 프리뷰 탭
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-08      th.kim          Initial Version
 **************************************************************/
import { LightningElement, track, api, wire } from "lwc";

import getInit from "@salesforce/apex/QuotePreviewController.getInit";
import getServiceItem from "@salesforce/apex/QuoteCreatorController.getServiceItem";
import { CurrentPageReference } from "lightning/navigation";

export default class quotePreview extends LightningElement {

	// 현재 테이블 데이터맵 test
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

	@api recordId; // 현재 레코드 Id
	isView; // 데이터 존재 유무

	/**
	 * @description url 변경 시 초기 데이터 세팅
	 */
	@wire(CurrentPageReference)
	getStateParameters(pageRef) {
		if (pageRef) {
			this.renderedCallback();
			getInit({ oppId: this.recordId }).then(res => {
				console.log("res :: ", res);
				const { name, quote, ...quoteDetail } = res.quoteDetail;
				if (quoteDetail && Object.keys(quoteDetail).length > 0) {
					this.isView = true;
					this.tableDataMap.product = quoteDetail.product;
					this.tableDataMap.product.optionList = quoteDetail.option?.filter(el => el.type !== "기본제공");
					const productPrice = this.tableDataMap.product?.price || 0;

					const promotionList = quoteDetail.promotion?.map(el => {
						const discountRate = el.discountRate ? el.discountRate : el.discountPrice ? (el.discountPrice / productPrice) : 0;
						const discountPrice = el.discountPrice ? el.discountPrice : productPrice * (el.discountRate || 0);
						return {
							...el,
							discountRate: discountRate,
							discountPrice: discountPrice
						};
					}) || [];
					this.tableDataMap.promotion = {
						baseDiscount: productPrice * (res.baseDiscount / 100),
						promotionList: promotionList,
						additionalDiscount: quote.AdditionalLossPrice__c,
						additionalStockDiscount: quote.fm_VehicleDiscountPrice__c
					};

					this.tableDataMap.discountDetail = {
						oilCouponCount: quoteDetail.oilCouponCount,
						oilCouponPrice: quoteDetail.oilCouponCount * 100000
					};

					this.tableDataMap.defaultOptions = quoteDetail.option?.filter(el => el.type === "기본제공");

					this.tableDataMap.special = quoteDetail.special;

					this.tableDataMap.financial = quoteDetail.financial;/*{
						financeId: quote.Finance__c,
						financialName: quote.Finance__r?.Name,
						loanAmount: quote.LoanAmount__c,
						interestRate: quote.DefaultInterestRate__c,
						loanTermMonth: quote.MonthDivideInputMonth__c,
						deposit: quote.Deposit__c,
						deliveryPrice: quote.DeliveryPrice__c
					};*/
					this.tableDataMap.financial.isVAT = res.oppData?.VATDefermentStatus__c === "승인됨";
					this.tableDataMap.financial.defermentVATDays = res.oppData?.VATDeferredDays__c;
					this.tableDataMap.financial.paymentDeferredAmount = res.oppData?.PaymentDeferredAmount__c || 0;

					this.tableDataMap.extraExpenses = {
						consignment: quote.ConsignmentPrice__c,
						insurance: quote.InsurancePrice__c,
						stampDuty: quote.StampDuty__c
					};

					const serviceItem = quoteDetail.option?.find(el => el.type === "서비스품목");
					if (serviceItem) {
						getServiceItem({ serviceItemId: serviceItem.id }).then(res => {
							console.log("res :: ", res);
							this.tableDataMap.serviceItem = res;
						}).catch(err => {
							console.log("err :: ", err);
						});
					}
				}
			}).catch(err => {
				console.log("err :: ", err);
			});
		}
	}

	/**
	 * @description 렌더링 시 스타일 설정
	 */
	renderedCallback() {
		const quoteStyleEl = document.querySelector(".custom-style");
		if (quoteStyleEl) quoteStyleEl.remove();

		let styleEl = document.querySelector(".opp-custom-style");
		if (!styleEl) {
			styleEl = document.createElement("style");
			styleEl.className = "opp-custom-style";
			styleEl.innerText = `
				.quote-preview-wrap .calc-wrap > div {
					width: 100% !important;
					padding: 0.5rem 0;
				}
			`;
			document.body.appendChild(styleEl);
		}
	}
}