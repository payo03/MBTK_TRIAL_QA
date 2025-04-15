/*************************************************************
 * @author : th.kim
 * @date : 2025-01-21
 * @description :
 * @target :
 ==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-21      th.kim          Initial Version
 **************************************************************/
import { api, LightningElement, track, wire } from "lwc";

// Library
import LightningConfirm from "lightning/confirm";
import { getRecord } from "lightning/uiRecordApi";
import userId from "@salesforce/user/Id";

// Controller
import getFilteredHandoverList from "@salesforce/apex/HandoverSchedulerController.getFilteredHandoverList";
import updateCheckHandoverList from "@salesforce/apex/HandoverSchedulerController.updateCheckHandoverList";
import getVehicleStockList from "@salesforce/apex/HandoverSchedulerController.getVehicleStockList";
import doCompleteHandover from "@salesforce/apex/HandoverSchedulerController.doCompleteHandover";
import updateHandoverStockList from "@salesforce/apex/HandoverSchedulerController.updateHandoverStockList";
import getCalendarInit from "@salesforce/apex/TaxInvoiceSchedulerController.getCalendarInit";
import insertHandoverDateAllocationHistory
	from "@salesforce/apex/TaxInvoiceSchedulerController.insertHandoverDateAllocationHistory";

// Util
import { getMonthStartAndEnd, labelList, showToast } from "c/commonUtil";
import {
	columns,
	exportColumns,
	stockColumns,
	fieldApiMapping,
	exportMapping,
	editStyle,
	handoverProfileColumns
} from "./handoverSchedulerColumns";

// 초기화 Map
const initFilterMap = { paymentStatus: "", vehicleStatus: "", startDate: "", endDate: "" };
const stockInitFilterMap = { Name: "", VehicleNo__c: "" };

// 날짜 상수
const today = new Date();
const currentYear = today.getFullYear();
const currentMonth = today.getMonth() + 1;
const lastYear = currentMonth === 1 ? currentYear - 1 : currentYear;
const lastMonth = currentMonth === 1 ? 12 : currentMonth - 1;

export default class handoverScheduler extends LightningElement {

	vfHost = labelList.VFHost; // visualforce url
	@track _parentData; // 마스터 데이터
	columns = columns; // 핸드오버 테이블 컬럼
	handoverList = []; // 핸드오버 데이터 리스트
	// 우측 버튼 그룹 필터 variant 맵
	@track variantMap = {
		THIS_MONTH: "brand",
		LAST_MONTH: "neutral",
		undecided: "neutral"
	};
	// 좌측 상태 필터 옵션 맵
	@track filterOptionMap = {
		paymentStatusOption: [{ label: "선택안함", value: "" }],
		vehicleStatusOption: [{ label: "선택안함", value: "" }]
	};
	@track filterMap = { ...initFilterMap }; // 좌측 필터 맵
	currentFilterMap; // 현재 적용 중인 필터 맵
	lastStartDate; // 이전 달 시작일
	lastEndDate; // 이전 달 마지막일
	isLoading; // 로딩 여부
	intervalId; // setInterval Id
	profileName;

	// 재고 모달
	stockList = []; // 재고 리스트
	stockColumns = stockColumns; // 재고 테이블 컬럼
	@track stockFilterMap = { ...stockInitFilterMap }; // 재고 필터 맵

	// 모달
	isModalOpen; // 모달 창 on/off 여부
	// 모달 보여줄 화면 맵
	modalMap = {
		calendar: false,
		export: false,
		completeHandover: false,
		cancelStock: false,
		checkUpdate: false,
		viewVIN: false
	};
	exportColumns = exportColumns; // 엑셀 리스트 컬럼
	selectedRowList = []; // 선택한 데이터 리스트
	selectedRowIdList = []; // 선택한 데이터 Id 리스트
	selectedStockRowList = []; // 선택한 재고 리스트
	currentHandover = {}; // 선택한 현재 핸드오버
	exportList = []; // 다운로드할 엑셀 리스트
	exportTitle = `${currentYear}년 ${currentMonth}월 판매예정 리스트`; // 엑셀 다운로드 제목 및 파일명

	// 캘린더
	handoverDateList = []; // 캘린더 슬롯 데이터 리스트
	selectedHandoverDateRow = {}; // 선택한 핸드오버 데이터
	optionDelayList = []; // 소요일 조건 데이터 리스트

	/**
	 * @description 부모 데이터 getter
	 */
	get parentData() {
		return this._parentData;
	}

	/**
	 * @description 모달 헤더 우뮤 체크
	 */
	get isModalHeader() {
		return !this.modalMap.calendar;
	}

	/**
	 * @description 모달 창 사이즈 조절
	 */
	get modalSize() {
		const defaultClass = "slds-modal slds-fade-in-open ";
		return `${defaultClass} ${this.modalMap.calendar ? "slds-modal_medium" : "slds-modal_large"}`;
	}

	/**
	 * @description 모달 클래스 정의
	 */
	get modalClass() {
		const defaultClass = "slds-modal__content slds-p-around_small";
		const headlessClass = `${defaultClass} slds-modal__content_headless`;
		return this.isModalHeader ? defaultClass : headlessClass;
	}

	/**
	 * @description SA 프로필 여부
	 */
	get isSA() {
		return this.profileName === "MTBK Agent";
	}

	/**
	 * @description 프로필 정보 가져오기
	 */
	@wire(getRecord, { recordId: userId, fields: ["User.Profile.Name"] })
	currentUserInfo({ error, data }) {
		this.profileName = data?.fields?.Profile?.displayValue;
		if (this.profileName === "MTBK Agent" || this.profileName === "MTBK Handover") {
			this.columns = handoverProfileColumns;
		}
	}

	/**
	 * @description 부모에서 데이터 받아오는 setter
	 * @param value 부모 데이터
	 */
	@api
	set parentData(value) {
		if (value) {
			// 부모 데이터 복사
			this._parentData = { ...value };
			this.handoverList = this._parentData?.handoverList || [];

			// 필터 옵션
			this.filterOptionMap.paymentStatusOption = [...this.filterOptionMap.paymentStatusOption, ...this._parentData?.paymentStatusOption];
			this.filterOptionMap.vehicleStatusOption = [...this.filterOptionMap.vehicleStatusOption, ...this._parentData?.vehicleStatusOption];

			// 초기 데이터 세팅 가져오기
			this.getInit();

			// 일정 시간 지나면 리프레쉬 해주기
			// this.intervalId = setInterval(() => {
			// 	this.getFilteredList(this.currentFilterMap);
			// }, 1000);
		}
	}

	/**
	 * @description 초기 값 세팅
	 */
	connectedCallback() {

		// 캘린더 이벤트
		window.addEventListener("message", this.getDataFromChild.bind(this));

		// 이번달
		const currentMonthRange = getMonthStartAndEnd(currentYear, currentMonth);
		initFilterMap.startDate = this.filterMap.startDate = `=${currentMonthRange.startDate}`;
		initFilterMap.endDate = this.filterMap.endDate = `=${currentMonthRange.endDate}`;

		// 지난달
		const lastMonthRange = getMonthStartAndEnd(lastYear, lastMonth);
		this.lastStartDate = `=${lastMonthRange.startDate}`;
		this.lastEndDate = `=${lastMonthRange.endDate}`;
	}

	// interval 삭제
	// disconnectedCallback() {
	// 	if (this.intervalId) {
	// 		clearInterval(this.intervalId);
	// 	}
	// }

	/**
	 * @description 헤더 버튼 클릭 이벤트
	 */
	handleHeaderClick(e) {
		const name = e.target.dataset.name;

		// 데이터 선택 여부 체크
		if ((name === "completeHandover" || name === "cancelStock" || name === "checkUpdate") && this.selectedRowList.length < 1) {
			showToast("데이터를 선택해주세요.", "", "warning");
			return;
		}
		// 출고가능 데이터 체크
		else if (name === "completeHandover") {
			this.selectedRowList = this.selectedRowList.filter(row => (
				row.vehicleStatus === "출고준비완료" && (row.paymentStatus === "출고가능" || row.paymentStatus === "모든입금완료" || row.paymentStatus === "초과입금")
			));
			this.selectedRowIdList = this.selectedRowList.map(row => row.id);
			if (this.selectedRowList.length < 1) {
				showToast("출고 가능한 차량을 선택해주세요.", "", "warning");
				return;
			}
		}
		// 배정취소 가능 데이터 체크
		else if (name === "cancelStock") {
			this.selectedRowList = this.selectedRowList.filter(row => row.stockId && row.vehicleStatus !== "출고됨");
			this.selectedRowIdList = this.selectedRowList.map(row => row.id);
			if (this.selectedRowList.length < 1) {
				showToast("배정취소 가능한 차량을 선택해주세요.", "", "warning");
				return;
			}
		}
		// 업데이트된 필드 체크
		else if (name === "checkUpdate") {
			this.selectedRowList = this.selectedRowList.filter(row => {
				let isUpdateField = false;
				Object.keys(row).forEach(key => {
					isUpdateField = key.toLowerCase().includes("style");
				});
				return isUpdateField;
			});
			this.selectedRowIdList = this.selectedRowList.map(el => el.id);
			if (this.selectedRowList.length < 1) {
				showToast("업데이트된 데이터를 선택해주세요.", "", "warning");
				return;
			}
		}
		this.toggleModal(name);
		this.isLoading = (name === "calendar");
	}

	/**
	 * @description 캘린더 로드 시 이벤트
	 */
	handleLoad(e) {
		// iframe의 윈도우 객체를 저장
		const iframeWindow = e.target.contentWindow;

		// VF 페이지로 초기 데이터를 전송
		const initialData = {
			type: "INIT_DATA",
			target: "calendar_handoverScheduler",
			event: this.handoverDateList,
			selectedDay: this.selectedHandoverDateRow["handoverDate"]
		};

		// VF 페이지로 데이터 전송
		iframeWindow.postMessage(initialData, this.vfHost);

		this.isLoading = false;
	}

	/**
	 * @description 모달 저장 버튼 클릭 함수
	 */
	handleModalClick() {
		this.isLoading = true;

		// 로직 성공 후 초기화 함수
		const successProcess = (processName) => {
			showToast(`${processName} 완료`, "", "success");
			this.selectedRowList = [];
			this.selectedRowIdList = [];
			this.toggleModal();
			this.getFilteredList(this.currentFilterMap);
		};

		// 엑셀다운
		if (this.modalMap.export) {
			const columns = exportColumns.map(column => column.label);
			const rows = this.exportList.map(row =>
				exportColumns.map(col => row[col.fieldName] || "").join(",")
			);

			// 한글 적용 위한 UTF-8 BOM 추가
			const BOM = "\uFEFF";
			// csv 파일 형식으로 변환
			const csvFile = BOM + columns.join(",") + "\n" + rows.join("\n");

			// 파일 다운로드
			const downloadLink = document.createElement("a");
			downloadLink.href = `data:text/csv;charset=utf-8,${encodeURI(csvFile)}`;
			downloadLink.target = "_blank";
			downloadLink.download = `${this.exportTitle}.csv`;
			downloadLink.click();

			this.isLoading = false;
		}
		// 출고처리
		else if (this.modalMap.completeHandover) {
			const completeList = this.selectedRowList.map(row => ({
				stockId: row.stockId,
				opportunityId: row.opp.Id
			}));
			doCompleteHandover({ completeList: completeList }).then(() => {
				successProcess("출고처리");
			}).catch(err => {
				console.error("err :: ", err);
				this.failedProcess(err);
			}).finally(() => this.isLoading = false);
		}
		// 업데이트 확인
		else if (this.modalMap.checkUpdate) {
			updateCheckHandoverList({ handoverIdList: this.selectedRowIdList }).then(() => {
				successProcess("업데이트 확인");
			}).catch(err => {
				console.error("err :: ", err);
				this.failedProcess(err);
			}).finally(() => this.isLoading = false);
		}
		// 차량 변경 / 배정 취소
		else if (this.modalMap.viewVIN || this.modalMap.cancelStock) {

			// 컨트롤러에서 사용할 파라미터 데이터 세팅
			const setDataList = (stockId, opportunity, previousVIN, currentVIN) => {
				return {
					stockId: stockId,
					opportunityId: opportunity.Id,
					oppName: opportunity.Name,
					ownerId: opportunity.OwnerId,
					contractId: opportunity.ContractId,
					previousVIN: previousVIN,
					currentVIN: currentVIN
				};
			};

			let dataList;
			// 차량 변경
			if (this.modalMap.viewVIN) {
				const stockId = this.selectedStockRowList.length > 0 ? this.selectedStockRowList[0] : null;
				if (!stockId) {
					showToast("차량을 선택해주세요.", "", "warning");
					this.isLoading = false;
					return;
				}
				const currentStock = this.stockList.find(el => el.Id === stockId);
				if (this.currentHandover.VIN === currentStock.Name) {
					showToast("차량을 변경해주세요.", "", "warning");
					this.isLoading = false;
					return;
				}
				dataList = [setDataList(currentStock.Id, this.currentHandover.opp, this.currentHandover.VIN, currentStock.Name)];
			}
			// 배정 취소
			else if (this.modalMap.cancelStock) {
				dataList = this.selectedRowList.map(row => setDataList(null, row.opp, row.VIN, null));
			}

			updateHandoverStockList({ dataList: dataList }).then(() =>
				successProcess(this.modalMap.viewVIN ? "차량 변경" : "배정 취소")
			).catch(err => {
				console.error("err :: ", err);
				this.failedProcess(err);
			}).finally(() => this.isLoading = false);
		}
	}

	/**
	 * @description 모달 on/off
	 */
	toggleModal(type) {
		this.isModalOpen = !this.isModalOpen;
		if (this.isModalOpen) {
			Object.keys(this.modalMap).forEach(el => this.modalMap[el] = (el === type));
		}
	}

	/**
	 * @description 필터 onchange 이벤트
	 */
	handleFilterChange(e) {
		const name = e.target.dataset.name;
		const value = e.target.value;
		this.filterMap[name] = (name === "startDate" || name === "endDate")
			? (value ? `=${value}` : null)
			: value;
	}

	/**
	 * @description 필터 버튼 클릭 이벤트
	 */
	handleFilterClick(e) {
		const name = e.currentTarget.dataset.name;
		// 새로고침
		if (name === "refresh") {
			this.filterMap = { ...initFilterMap };
		} else {
			let filterMap = {};
			// 검색
			if (name === "search") {
				this.selectedRowList = [];
				this.selectedRowIdList = [];
				// 각 필터 필드 맵핑
				Object.keys(this.filterMap).forEach(el => filterMap[fieldApiMapping[el]] = this.filterMap[el]);

				// 필터, 버튼 동기화
				const keyName = (this.filterMap.startDate === initFilterMap.startDate && this.filterMap.endDate === initFilterMap.endDate)
					? "THIS_MONTH"
					: (this.filterMap.startDate === this.lastStartDate && this.filterMap.endDate === this.lastEndDate)
						? "LAST_MONTH"
						: null;

				Object.keys(this.variantMap).forEach(key => this.variantMap[key] = (key === keyName) ? "brand" : "neutral");
			}
			// 이번달 / 저번달 / 계약완료 & 출고일 미정
			else {
				Object.keys(this.variantMap).forEach(key => this.variantMap[key] = (key === name) ? "brand" : "neutral");

				if (name === "undecided") {
					filterMap = { fm_ContractStatus__c: "계약금 및 서명 완료", "Opportunity__r.HandoverDate__c": "= NULL" };
					this.filterMap.startDate = null;
					this.filterMap.endDate = null;
				} else {
					filterMap = { "Opportunity__r.HandoverDate__c": `=${name}` };
					if (name === "THIS_MONTH") {
						this.filterMap.startDate = initFilterMap.startDate;
						this.filterMap.endDate = initFilterMap.endDate;
					} else {
						this.filterMap.startDate = this.lastStartDate;
						this.filterMap.endDate = this.lastEndDate;
					}
				}
			}
			this.getFilteredList(filterMap);
		}
	}

	/**
	 * @description 모달 필터 변경 함수
	 */
	handleModalFilterChange(e) {
		this.stockFilterMap[e.target.dataset.name] = e.target.value;
	}

	/**
	 * @description 모달 필터 버튼 클릭 함수
	 */
	handleModalFilterClick(e) {
		const name = e.currentTarget.dataset.name;
		if (name === "refresh") {
			this.stockFilterMap = { ...this.stockFilterMap, ...stockInitFilterMap };
		} else if (name === "search") {
			this.isLoading = true;
			getVehicleStockList({ filterMap: this.stockFilterMap }).then(res => {
				this.selectedStockRowList = [];
				this.stockList = res?.map(el => ({
					...el,
					product: el.Product__r.Name
				}));
			}).catch(err => {
				console.error("err :: ", err);
				this.failedProcess(err);
			}).finally(() => this.isLoading = false);
		}
	}

	/**
	 * @description 테이블 데이터 클릭 시 이벤트
	 *              1. VIN 클릭 시 해당 차종의 차량 보여주기
	 *              2. 출고일 클릭 시 출고일 달력 보여주기
	 */
	handleRowAction(e) {
		this.isLoading = true;
		const actionName = e.detail.action.actionName;
		const currentRow = e.detail.row;

		// VIN 클릭
		if (actionName === "viewVIN") {
			this.toggleModal("viewVIN");
			const productId = currentRow.vehicleStock?.Product__c || currentRow.opp.Contract.Quote__r.Product__c;
			getVehicleStockList({ filterMap: { Product__c: productId } }).then(res => {
				this.stockList = res?.map(el => ({
					...el,
					product: el.Product__r.Name
				}));
				this.selectedStockRowList = [currentRow.stockId];
				this.stockFilterMap.Product__c = productId;
				this.currentHandover = currentRow;
			}).catch(err => {
				console.error("err :: ", err);
				this.failedProcess(err);
			}).finally(() => this.isLoading = false);
		}
		// 출고일 클릭
		else if (actionName === "handoverDate") {
			this.selectedHandoverDateRow = currentRow;
			getCalendarInit({ vehicleStockId: currentRow.stockId }).then(res => {
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
				this.failedProcess(err);
			});
		}
	}

	/**
	 * @description 핸드오버 선택 함수
	 */
	handleSelection(e) {
		this.selectedRowList = e.detail.selectedRows;
		this.selectedRowIdList = this.selectedRowList.map(row => row.id);
	}

	/**
	 * @description 모달에서 차량 선택 함수
	 */
	handleModalRowSelection(e) {
		this.selectedStockRowList = e.detail.selectedRows?.map(el => el.Id);
	}

	/**
	 * @description 초기 데이터 세팅 및 디자인 세팅
	 */
	getInit() {
		this.getExportList();

		// 테이블 스타일 변경
		requestAnimationFrame(() => {
			let styleEl = document.querySelector(".handover-custom-style");
			// 첫 로드 시
			if (!styleEl) {
				if (this.template.querySelector("c-custom-data-table")) {
					styleEl = document.createElement("style");
					styleEl.className = "handover-custom-style";
					// 테이블 버튼 넓이 조정
					styleEl.innerText = `
						.handover-scheduler-wrap {
							c-custom-data-table table tbody .slds-button { 
					            line-height: 100%; 
						    }
						    .filter-wrap lightning-datepicker .slds-form-element__help { 
						        display: none; 
						    }
						    c-custom-data-table .slds-form-element__icon { 
						        padding: 0; 
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
			this.setFieldStyle();
		});
	}

	/**
	 * @description 필드 스타일 세팅해주기
	 */
	setFieldStyle() {
		// 업데이트된 필드 하이라이트 추가
		this.handoverList = this.handoverList?.map(el => {
			const updatedEl = { ...el };

			const optionList = [], defaultOptionList = [], specialList = [];
			let optionQty = 0, defaultOptionQty = 0, specialQty = 0;

			// 옵션 데이터 세팅
			updatedEl.quoteDetailList?.forEach(({ Type__c, fm_DetailType__c, Name }) => {
				if (Type__c === "옵션") {
					(fm_DetailType__c === "기본제공" ? defaultOptionList : optionList).push(Name);
					fm_DetailType__c === "기본제공" ? defaultOptionQty++ : optionQty++;
				} else if (Type__c === "특장") {
					specialList.push(Name);
					specialQty++;
				}
			});

			// 옵션 보여주기
			updatedEl.helpText = [
				optionList.length > 0 ? `옵션\n${optionList.join("\n")}` : "",
				defaultOptionList.length > 0 ? `기본제공\n${defaultOptionList.join("\n")}` : "",
				specialList.length > 0 ? `특장\n${specialList.join("\n")}` : ""
			].filter(Boolean).join("\n\n");

			Object.assign(updatedEl, { optionQty, defaultOptionQty, specialQty });

			if (el?.isNeedToCheckUpdate) {
				const fieldMap = {
					"Opportunity__c": "oppUrl",
					"fm_VehicleStock__c": ["VIN", "vehicleNo"],
					"fm_VehicleStatus__c": "vehicleStatus",
					"fm_PaymentStatus__c": "paymentStatus",
					"fm_HandoverDate__c": "handoverDate",
					"fm_TaxInvoiceDate__c": "taxInvoiceDate"
				};

				const fieldList = el.updatedFieldList?.flatMap(field =>
					Array.isArray(fieldMap[field]) ? fieldMap[field] : [fieldMap[field]]
				) || [];

				Object.keys(updatedEl)?.forEach(field => {
					// 업데이트된 필드일 시
					if (fieldList?.includes(field)) {
						// 필드 스타일링 추가
						updatedEl[`${field}Style`] = editStyle;
					}
				});
			}
			return updatedEl;
		});
	}

	/**
	 * @description 필터링된 데이터 리스트 가져오기
	 * @param filterMap 필터링 조건 맵
	 */
	getFilteredList(filterMap) {
		this.isLoading = true;
		this.currentFilterMap = filterMap;
		getFilteredHandoverList({ filterMap: filterMap }).then(res => {
			this.handoverList = res;
			this.setFieldStyle();
			this.getExportList();
		}).catch(err => {
			console.error("err :: ", err);
			this.failedProcess(err);
		}).finally(() => this.isLoading = false);
	}

	/**
	 * @description 엑셀 다운로드할 데이터 가져오기
	 */
	getExportList() {
		const { startDate, endDate } = this.filterMap;

		// 엑셀 타이틀 설정
		this.exportTitle =
			(startDate === initFilterMap.startDate && endDate === initFilterMap.endDate)
				? `${currentYear}년 ${currentMonth}월 판매예정 리스트`
				: (startDate === this.lastStartDate && endDate === this.lastEndDate)
					? `${lastYear}년 ${lastMonth}월 판매예정 리스트`
					: `${startDate?.replace("=", "") || ""} ~ ${endDate?.replace("=", "") || ""} 판매예정 리스트`;


		// 판매예정 리스트 옵션 맵핑
		this.exportList = this.handoverList?.map(handover => {
			const updateHandover = { ...handover };
			updateHandover.product = handover.vehicleStock?.Product__r?.Name;
			updateHandover.productId = handover.vehicleStock?.Product__c;
			updateHandover.opportunityId = handover.opp?.Id;
			if (handover.quoteDetailList && handover.quoteDetailList.length > 0) {
				// 옵션 데이터 추가
				handover.quoteDetailList?.forEach(detail => {
					if (exportMapping[detail.Name]) {
						updateHandover[exportMapping[detail.Name].key] = exportMapping[detail.Name].value;
					}
				});
			}
			// 매트 타입 분기 처리
			if (updateHandover.mat) updateHandover.mat = handover.vehicleStock?.Product__r?.Segment2__c === "TPP" ? "고무매트" : "잔디매트";

			return { ...updateHandover };
		}) || [];
	}

	/**
	 * @description Visualforce에서 받아온 캘린더 클릭 이벤트
	 */
	getDataFromChild(e) {

		if (this.vfHost !== e.origin || e.data.target !== "calendar_handoverScheduler") return;

		const type = e.data.type;
		let value;
		let selectedDate;

		if (type === "eventClick") {
			selectedDate = e.data.event.start;
			value = selectedDate === this.selectedHandoverDateRow["handoverDate"] ? "same" : e.data.event.title;
		}

		// 에러 메시지 맵
		const messageMap = {
			"same": "현재 출고일과 같습니다.",
			"6/6": "이미 마감된 출고일입니다.",
			"휴일": "휴일은 선택할 수 없습니다."
		};

		if (messageMap[value]) {
			showToast("변경 불가", messageMap[value], "warning");
			return;
		}

		// 핸드오버 데이터 변경
		const changeHandoverDate = () => {
			insertHandoverDateAllocationHistory({
				targetDate: new Date(selectedDate),
				opptyId: this.selectedHandoverDateRow["opp"]["Id"],
				stockId: this.selectedHandoverDateRow["stockId"]
			}).then(res => {
				if (res) {
					showToast("성공", "출고일이 " + selectedDate + "로 변경되었습니다.", "success");
				} else {
					showToast("변경 불가", "이미 마감된 출고일입니다.", "warning");
				}
			}).catch(err => {
				this.failedProcess(err);
			}).finally(() => {
				this.getFilteredList(this.currentFilterMap);
				this.toggleModal();
				this.isLoading = false;
			});
		};

		// 변경 확인 문구
		LightningConfirm.open({
			message: `출고일을 [${selectedDate}]로 변경하시겠습니까?`,
			variant: "headerless"
		}).then(res => {
			if (res) {
				this.isLoading = true;
				changeHandoverDate();
			}
		});
	}

	/**
	 * @description 로직 실패 시 토스트 띄우기
 	 */
	failedProcess(err) {
		const errTitle = err?.body?.message || err.message || "ERROR";
		const errBody = errTitle === "ERROR" ? "관리자에게 문의 부탁드립니다" : "";
		showToast(errTitle || err.message, errBody, "warning");
	}
}