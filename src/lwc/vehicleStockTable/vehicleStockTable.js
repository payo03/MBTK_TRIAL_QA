/*************************************************************
 * @author : th.kim
 * @date : 2024-11-12
 * @description :
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-12      th.kim          Initial Version
 * 2.0          2025-02-06      San.kang        Updated Version
 **************************************************************/
import { LightningElement, track, wire } from "lwc";

// Library
import { CurrentPageReference } from "lightning/navigation";
import userId from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";
import { loadStyle } from "lightning/platformResourceLoader";

// Controller
import getInitData from "@salesforce/apex/VehicleStockTableController.getInitData";
import getProductWrap from "@salesforce/apex/VehicleStockTableController.getProductWrap";
import getFilteredCategoryList from "@salesforce/apex/VehicleStockTableController.getFilteredCategoryList";
import getFilteredProductWrapList from "@salesforce/apex/VehicleStockTableController.getFilteredProductWrapList";
import updateStockShow from "@salesforce/apex/VehicleStockTableController.updateStockShow";
// import createPreAssignRequest from "@salesforce/apex/VehicleStockTableController.createPreAssignRequest";
// import createOpp from "@salesforce/apex/VehicleStockTableController.createOpp";

// Util
import { showToast, sortData, resourceList } from "c/commonUtil";
import {
	masterColumnsForSA,
	masterColumnsForAdmin,
	detailColumns,
    additionalDetailColumns,
	selectedColumns,
	detailColumnsForAdmin
} from "./vehicleStockColumns";

// 필터 초기화 데이터
const filterDefault = { Segment2__c: "", AxleConfiguration__c: "", HorsePower__c: "", Wheelbase__c: "", Styling__c: "" };

// 모달 데이터
// const createOppModal = { type: "createOpp", title: "기회 생성", isOpp: true };
const preAssignModal = { type: "사전배정", title: "사전배정요청" };
const stockShowModal = { type: "stockShow", title: "재고 노출", content: "아래 재고가 재고노출 상태로 변경됩니다." };
const stockNoShowModal = { type: "stockNoShow", title: "재고 미노출", content: "아래 재고가 재고 미노출 상태로 변경됩니다." };
const waitingModal = { type: "대기리스트", title: "대기리스트 요청", content: "대기리스트 요청 하시겠습니까 ?", isWaiting: true };

// 공통 모달 설정
const modalMap = {
	// createOpp: createOppModal,
	preAssign: preAssignModal,
	waiting: waitingModal,
	stockShow: stockShowModal,
	stockNoShow: stockNoShowModal
};

// 재고 미노출/노출 체크 Map
const isStockNoShow = {
	stockShow: false,
	stockNoShow: true
};

// TODO :: 변수 관리 변경 필요
const initDataMap = {
	masterData: [],
	detailData: [],
    additionalDetailData: [],
	selectedRowDetail: [],
	selectedRowDetailId: [],
	selectedStockIdList: [],
	currentCategoryKey: null,
	selectedRows: [],
	sortBy: null,
	sortDirection: null,
	filterMap: { ...filterDefault },
	optionValue: null,
	selectedData: []
};

export default class VehicleStockTable extends LightningElement {

	// 현재 레코드
	stockId;
	oppId;
	userName;
	isAdminUser;
	isLoading; // 로딩바 Boolean
	activeTab = "sa"; // 현재 활성화된 탭

	// TODO :: 변수 관리 변경 필요
    @track profileDataMap = {
		admin: { ...initDataMap, masterColumns: masterColumnsForAdmin, detailColumns: detailColumnsForAdmin },
		sa: { ...initDataMap, masterColumns: masterColumnsForSA, detailColumns: detailColumns, additionalDetailColumns: additionalDetailColumns }
	};

	// 디테일
	detailColumns = detailColumns; // 디테일 컬럼
	additionalDetailColumns = additionalDetailColumns; // 디테일 컬럼
	detailColumnsForAdmin = detailColumnsForAdmin; // 디테일 컬럼
	@track detailData; // 디테일 데이터 리스트
	@track additionalFlag = false;
	@track selectedRowDetail = [];
	@track selectedRowDetailId = [];
	@track selectedStockIdList = [];

	// 디테일 - Admin
	@track detailDataForAdmin = [];
	@track selectedRowDetailForAdmin = [];
	@track selectedRowDetailIdForAdmin = [];
	@track selectedStockIdListForAdmin = [];

	// 필터
	filterOptions = { segment: [], wheelbase: [] }; // 필터 옵션 맵
	@track filterMap = { ...filterDefault }; // 적용할 필터 맵
	optionValue; // 디테일 옵션 필터 Value

	// 필터 - Admin
	@track filterMapForAdmin = { ...filterDefault }; // 적용할 필터 맵
	optionValueForAdmin;

	// 모달
	isModalOpen; // 모달 창 on/off 변수
	modalMap; // 모달 데이터 Map
	selectedColumns = selectedColumns; // 모달에 보여줄 선택한 데이터 컬럼
	@track selectedData; // 모달에 보여줄 선택한 데이터
	accountFilter = {
		criteria: [
			{
				fieldPath: "OwnerId",
				operator: "eq",
				value: userId
			}
		]
	};
	oppFilter = {
		criteria: [
			{
				fieldPath: "OwnerId",
				operator: "eq",
				value: userId
			}
			// {
			// 	fieldPath: 'Website',
			// 	operator: 'eq',
			// 	value: null,
			// },
			// {
			// 	fieldPath: 'Type',
			// 	operator: 'ne',
			// 	value: 'Partner',
			// },
			// {
			// 	fieldPath: 'Parent.Name',
			// 	operator: 'like',
			// 	value: 'Acme%',
			// },
		]
		// filterLogic: '(1 OR 2) AND NOT(4) AND 3',
	};

	// 모달 - Admin
	selectedDataForAdmin; // 모달에 보여줄 선택한 데이터

	@wire(CurrentPageReference)
	getStateParameters(pageRef) {
		if (pageRef) {
			console.log("pageRef :: ", pageRef.state);
			this.stockId = pageRef.state.c__stockId;
			this.oppId = pageRef.state.c__oppId;
		}
	}

	/**
	 * @description 유저 정보 가져오기
	 */
	@wire(getRecord, { recordId: userId, fields: ["User.Name", "User.Profile.Name"] })
	currentUserInfo({ error, data }) {
		if (data) {
			console.log("data :: ", data);
			this.userName = data.fields.Name.value;
			this.isAdminUser = data.fields.Profile.displayValue === "System Administrator" || data.fields.Profile.displayValue === "시스템 관리자";
		}
	}

	/**
	 * @description 현재 활성화된 탭이 SA인지 체크
	 * @returns {boolean}
	 */
	get isSaTab() {
		return this.activeTab === "sa";
	}

	/**
	 * @description 동적으로 데이터테이블 높이 조절
	 * @returns {string}
	 */
	// get dynamicTableHeight() {
	// 	if(this.profileDataMap.sa.masterData?.length >= 10) {
	// 		return "height: 50vh;";
	// 	} else {
	// 		return "height: auto;";
	// 	}
	// }

	connectedCallback() {
     console.log('ref1');
		this.isLoading = true;
		loadStyle(this, resourceList.CustomTableStyle).catch(err => console.log("err ::", err));
		this.doInit();
		// 전체화면
		// getVehicleStock({recordId: this.recordId}).then(res => {
		// 	console.log("res :: ", res);
		// 	this.replaceChildren(res);
		// 	this.data = res;
		//
		// 	requestAnimationFrame(() => {
		// 		const grid = this.template.querySelector("lightning-tree-grid");
		// 		grid.expandAll();
		// 	});
		// }).catch(err => {
		// 	console.log("err ::", err);
		// });
	}

	doInit() {
		getInitData({ stockId: this.stockId }).then(res => {

			this.profileDataMap.sa.masterData = res.categoryList.filter(el => el.quantity > 0 || el.after30DaysQty > 0 || el.after60DaysQty > 0);
			this.profileDataMap.admin.masterData = res.categoryList;
            console.log('test',res.categoryList.styling);
			this.formatCountField();
			this.filterOptions.segment = [{ label: "선택안함", value: "" }].concat(res.segment);
			this.filterOptions.wheelbase = [{ label: "선택안함", value: "" }].concat(res.wheelbase);
			this.filterOptions.axle = [{ label: "선택안함", value: "" }].concat(res.axle);
			// this.filterOptions.trimLevel = [{ label: "선택안함", value: "" }].concat(res.trimLevel);
			this.filterOptions.styling = [{ label: "선택안함", value: "" }].concat(res.styling);
			this.stockId = res.stockId;
			this.profileDataMap.sa.currentCategoryKey = this.profileDataMap.admin.currentCategoryKey || res.currentCategoryKey;
			console.log("this.filterOptions.styling ",res.currentCategoryKey);
			this.profileDataMap.admin.currentCategoryKey = this.profileDataMap.admin.currentCategoryKey || res.currentCategoryKey;

			// 파라미터 값 존재 시
			if (this.profileDataMap.sa.currentCategoryKey || this.profileDataMap.admin.currentCategoryKey) {
				this.profileDataMap.sa.selectedRowsMaster = [this.profileDataMap.sa.currentCategoryKey];
				this.getDetailData(this.profileDataMap.sa.currentCategoryKey, "sa");
				this.profileDataMap.admin.selectedRowsMaster = [this.profileDataMap.admin.currentCategoryKey];
				this.getDetailData(this.profileDataMap.admin.currentCategoryKey, "admin");

				// requestAnimationFrame(() => {
				// 	const datatableEl = this.template.querySelector("lightning-datatable");
				// 	console.log("datatable :: ", datatableEl);
				// 	console.log("datatable :: ", datatableEl.selectedRows);
				// 	console.log("datatable :: ", JSON.stringify(datatableEl.data));
				// 	datatableEl.data.forEach(el => {
				// 		if (el.id === profileDataMap.sa.currentCategoryKey) {
				// 			el.focus;
				// 		}
				// 	})
				// 	console.log("this.profileDataMap.sa.currentCategoryKey :: ", profileDataMap.sa.currentCategoryKey);
				// 	const rowIndex = this.profileDataMap.sa.masterData.findIndex(row => row.id === profileDataMap.sa.currentCategoryKey);
				// 	console.log("rowIndex :: ", rowIndex);
				//
				// 	if (rowIndex !== -1) {
				// 		setTimeout(() => {
				// 			const rowElement = datatableEl.querySelectorAll(".slds-table tbody tr");
				// 			console.log("rowElement :: ", rowElement);
				// 			if (rowElement) {
				// 				rowElement.scrollIntoView({ behavior: "smooth", block: "center" });
				// 				rowElement.focus();
				// 			}
				// 		});
				// 	}
				// });
			}
             console.log('test',this.profileDataMap[this.activeTab].currentCategoryKey);
             console.log('res::::',res);
             console.log('activeTab',[this.activeTab]);

		}).catch(err => {
			console.log("err :: ", err);
			showToast("", err.body.message, "warning");
			this.isLoading = false;
		}).finally(() => {
			this.isLoading = false;
			this.adjustTableHeight();
		});
	}

	/**
	 * @description 테이블 row action 이벤트 함수
	 * @param e row action 이벤트
	 */
	handleRowAction(e) {
		try {
			const action = e.detail.config.action;

			const currentId = e.detail.config.value;
            console.log('currentId::',currentId);
			// 체크박스 이벤트 처리
			const checkboxChange = (currentSelectedAllRow, currentSelectedRow) => {
                let selectedStockIdList = [...this.profileDataMap[this.activeTab].selectedStockIdList];
                let selectedRowDetailId = [...this.profileDataMap[this.activeTab].selectedRowDetailId];
                let selectedRowDetail = this.profileDataMap[this.activeTab].selectedRowDetail;
                let detailData = this.profileDataMap[this.activeTab].detailData;
				const isParent = currentSelectedRow?.hasChildren;
				// console.log("currentSelectedRows :: ", JSON.stringify(currentSelectedRows));
				// 전체 선택
				if (action === "selectAllRows") {
					const selectedAllIdList = [];
					const selectedAllChildIdList = [];

					// 선택된 모든 부모와 모든 자식 Id 가져오기
					currentSelectedAllRow.forEach(parent => {
						selectedAllIdList.push(parent.id);
						if (parent.hasChildren) {
							parent.children.forEach(child => {
								selectedAllChildIdList.push(child.id);
								selectedAllIdList.push(child.id);
							});
						}
					});
                    this.profileDataMap[this.activeTab].selectedRowDetailId = selectedAllIdList; // 부모 ID 업데이트
                    this.profileDataMap[this.activeTab].selectedStockIdList = selectedAllChildIdList; // 자식 ID 업데이트
                    this.profileDataMap[this.activeTab].selectedRowDetail = currentSelectedAllRow;
//					if (this.isSaTab) {
//						this.profileDataMap.sa.selectedRowDetailId = selectedAllIdList; // 부모 ID 업데이트
//						this.profileDataMap.sa.selectedStockIdList = selectedAllChildIdList; // 자식 ID 업데이트
//						this.profileDataMap.sa.selectedRowDetail = currentSelectedAllRow;
//					} else {
//						this.profileDataMap.admin.selectedRowDetailId = selectedAllIdList;
//						this.profileDataMap.admin.selectedStockIdList = selectedAllChildIdList;
//						this.profileDataMap.admin.selectedRowDetail = currentSelectedAllRow;
//					}
				}
				// 전체 선택 해제
				else if (action === "deselectAllRows") {

                    // 선택 해제 시 모두 초기화
                    this.profileDataMap[this.activeTab].selectedRowDetailId = [];
                    this.profileDataMap[this.activeTab].selectedStockIdList = [];
				}
				// Row 선택/해제
				else {

					// 자식 선택 시 자식의 부모 Id 가져오기
					const getParentIdByChildId = (array, childId) => {
						for (const element of array) {
							if (element.children && element.children.some(child => child.id === childId)) {
								return element.id; // 부모의 Id 반환
							}
						}
						return null; // 해당하는 부모가 없을 경우
					};

					// 선택한 Id 리스트에 추가
					const addSelectedId = (id, isStock) => {
						if (isStock) {
							if (!selectedStockIdList.includes(id)) {
								selectedStockIdList.push(id);
							}
						} else {
							if (!selectedRowDetailId.includes(id)) {
								selectedRowDetailId.push(id);
							}
						}
					};

					// Row 선택
					if (action === "rowSelect") {

						// 부모 선택 시 자식 모두 추가
						if (isParent) {
							currentSelectedRow.children.forEach(child => {
								addSelectedId(child.id, true);
								addSelectedId(child.id, false);
							});
						}
						// 자식만 선택
						else {
							addSelectedId(currentId, true);
							const ParentId = getParentIdByChildId(detailData, currentId);
							if (ParentId) {
								// 부모 데이터 가져오기
								const parentRow = detailData.find(el => el.id === ParentId);
								if (parentRow?.children?.length) {
									// 부모의 자식 데이터 가져오기
									const childRowIdList = parentRow.children.map(child => child.id);

									// 자식 모두 선택되었을 때 부모도 선택
									if (childRowIdList.every(id => selectedStockIdList.includes(id))) {
										addSelectedId(ParentId, false);
										parentRow.hasChildren = true;
										currentSelectedAllRow.push(parentRow);
									}
								}
							}
						}
						// 현재 ID 추가
						addSelectedId(currentId, false);
					}
					// Row 선택 해제
					else if (action === "rowDeselect") {
						const currentEl = selectedRowDetail.find(el => el.id === currentId);
						// 부모 해제
						if (currentEl?.hasChildren) {
							const childIdList = currentEl.children.map(child => child.id);
							// 부모 해제 시 자식 모두 제거
							selectedStockIdList = selectedStockIdList.filter(id => !childIdList.includes(id));
							selectedRowDetailId = selectedRowDetailId.filter(id => !childIdList.includes(id));
						}
						// 자식 해제
						else {
							selectedStockIdList = selectedStockIdList.filter(id => id !== currentId);

							const parentId = getParentIdByChildId(currentSelectedAllRow, currentId);
                            console.log('parenId:4', parenId);
							if (parentId) {
								// 자식의 부모도 해제
								selectedRowDetailId = selectedRowDetailId.filter(id => id !== parentId);
								currentSelectedAllRow.filter(el => el.id !== parentId);
							}
						}
						// 부모 ID 제거
						selectedRowDetailId = selectedRowDetailId.filter(id => id !== currentId);
					}
                    this.profileDataMap[this.activeTab].selectedRowDetailId = selectedRowDetailId;
                    this.profileDataMap[this.activeTab].selectedStockIdList = selectedStockIdList;
                    this.profileDataMap[this.activeTab].selectedRowDetail = currentSelectedAllRow;
				}
			};
			// 마스터 라디오박스
			if (e.target.dataset.id === "master" && action === "rowSelect") {

                this.profileDataMap[this.activeTab].currentCategoryKey = currentId;
                this.profileDataMap[this.activeTab].selectedRowDetailId = [];
                this.profileDataMap[this.activeTab].selectedStockIdList = [];
                this.profileDataMap[this.activeTab].selectedRowDetail = [];
				this.getDetailData(currentId, this.activeTab);
			}
			// 디테일 체크박스
			else {
				let currentSelectedAllRow = e.detail.selectedRows;
				console.log("currentSelectedAllRow :: ", currentSelectedAllRow);
				if (this.isSaTab) {
					this.profileDataMap.sa.selectedRowDetail = currentSelectedAllRow;
					this.profileDataMap.sa.selectedStockIdList = currentSelectedAllRow.map(row => (row.id));
				} else {
					const currentSelectedRow = currentSelectedAllRow.find(el => el.id === currentId);
					checkboxChange(currentSelectedAllRow, currentSelectedRow, this.activeTab);
				}
			}
		} catch (err) {
			console.log("err :: ", err.message);
		}
	}

	/**
	 * @description 필터 선택 시 필터 맵에 필터 데이터 저장
	 */
	handleChange(e) {
		const id = e.target.dataset.id;
		const value = e.target.value;
        console.log('id:',id);
        console.log('value:',value);
		const setFilterValue = (field, value) => {
			const filterMap = this.profileDataMap[this.activeTab].filterMap;
			filterMap[field] = value;
		};

		switch (id) {
			case "segment" :
				setFilterValue("Segment2__c", value);
				break;
            case "styling" :
                setFilterValue("Styling__c", value);
                break;
			case "axle" :
				setFilterValue("AxleConfiguration__c", value);
				break;
			case "power" :
				setFilterValue("HorsePower__c", value);
				break;
			case "wheelbase" :
				setFilterValue("Wheelbase__c", value);
				break;
			case "option" :
                this.profileDataMap[this.activeTab].optionValue = value;
				break;
			case "oppId" :
                this.profileDataMap[this.activeTab].selectedData[e.target.dataset.idx].oppId = e.detail.recordId;
				break;
			case "accountId" :
                this.profileDataMap[this.activeTab].selectedData[e.target.dataset.idx].accountId = e.detail.recordId;
				break;
		}
	}

	/**
	 * @description Master 화면 버튼 클릭 이벤트 함수
	 * @param e
	 */
	handleClickMaster(e) {
		const id = e.currentTarget.dataset.id;
		switch (id) {
			// 필터 리셋
			case "refresh":
                this.profileDataMap[this.activeTab].filterMap = { ...filterDefault };
				break;
			// 선택된 필터로 검색
			case "search":
				this.isLoading = true;
                this.profileDataMap[this.activeTab].masterData = [];
                console.log('Map>:::',  this.profileDataMap[this.activeTab].filterMap);
                console.log('Map>:::',  this.profileDataMap[this.activeTab].filterMap.value);


				getFilteredCategoryList({ filterMap: this.profileDataMap[this.activeTab].filterMap}).then(res => {
					console.log("res :: ", res);
					if (this.isSaTab) {
						this.profileDataMap.sa.masterData = res.filter(el => el.quantity > 0 || el.after30DaysQty > 0 || el.after60DaysQty > 0);
                    }else{
                        this.profileDataMap.admin.masterData = res;
                    }
						// 마스터 검색 시 디테일 데이터 초기화
                    this.profileDataMap[this.activeTab].detailData = null;
                    this.profileDataMap[this.activeTab].optionValue = "";
                    this.profileDataMap[this.activeTab].currentCategoryKey = null;

                    // 필터 검색 후 디테일 체크박스 초기화
                    this.profileDataMap[this.activeTab].selectedRowDetail = [];
                    this.profileDataMap[this.activeTab].selectedStockIdList = [];
                    this.profileDataMap[this.activeTab].selectedRowDetailId = [];
					this.formatCountField();
				}).catch(err => {
					console.log("err :: ", err);
					showToast("", err.body.message, "warning");
				}).finally(() => {
					this.isLoading = false;
					this.adjustTableHeight();
				});
				break;
			// 대기리스트 요청
			case "waiting":
				const currentRow = this.profileDataMap.sa.masterData.find(row => row.id === this.profileDataMap.sa.currentCategoryKey);
				if ((!this.profileDataMap.sa.currentCategoryKey)) {
					showToast("", "카테고리를 선택해주세요.", "warning");
					return;
				} else if (currentRow.quantity > 0) {
					showToast("", "이미 재고가 존재합니다.", "warning");
					return;
				} else if (currentRow.after30DaysQty < 1 && currentRow.after60DaysQty < 1) {
					showToast("", "입항 예정 재고가 존재하지 않습니다.", "warning");
					return;
				} else {
					if (id in modalMap) {
						this.modalMap = modalMap[id];
						currentRow.userName = this.userName;
						this.profileDataMap.sa.selectedData = [currentRow];
						this.handleModalChange();
					}
				}
				break;
		}
	}

	/**
	 * @description 테이블 동적으로 높이 조정
	 */
	adjustTableHeight() {
		const tableWrapEl = this.template.querySelector(`.master-table-wrap[data-tab='${this.activeTab}']`);
		let lightningTableEl = this.template.querySelector(`lightning-datatable[data-tab='${this.activeTab}']`);
		const vh25 = window.outerHeight * 0.25;

		if (lightningTableEl && tableWrapEl) {
			let tableHeight = lightningTableEl.offsetHeight;
			// 테이블 전체 높이 가져오기 위한 높이 초기화
			tableWrapEl.style.height = "auto";
			requestAnimationFrame(() => {
				// 테이블 변경 후 다시 호출
				lightningTableEl = this.template.querySelector(`lightning-datatable[data-tab='${this.activeTab}']`);
				tableHeight = lightningTableEl.offsetHeight;
				tableWrapEl.style.height = tableHeight > vh25 ? `${vh25}px` : `auto`;
				this.isLoading = false;
			});
		}
	}

	/**
	 * @description 마스터 데이터테이블 정렬 이벤트 함수
	 * @param e 정렬 시 이벤트
	 */
	handleSort(e) {
		// 정렬 기준 필드명과 정렬 방향 저장

		const sortBy = e.detail.fieldName;
		const sortDirection = e.detail.sortDirection;
        this.profileDataMap[this.activeTab].sortBy = sortBy;
        this.profileDataMap[this.activeTab].sortDirection = sortDirection;
        // 데이터 정렬
        this.profileDataMap[this.activeTab].masterData = sortData(this.profileDataMap[this.activeTab].masterData, sortBy, sortDirection);
        this.profileDataMap.sa.additionalDetailData = sortData(this.profileDataMap.sa.additionalDetailData, sortBy, sortDirection);
	}

	/**
	 * @description 디테일 화면 버튼 클릭 이벤트 함수
	 */
	handleClickDetail(e) {
		const id = e.currentTarget.dataset.id;
		const isDataExist = this.profileDataMap.sa.selectedStockIdList.length > 0;
		const isDataExistAdmin = this.profileDataMap.admin.selectedStockIdList.length > 0;

		// 데이터 없는 요청일 시 바로 반환
		if ((["preAssign", "waiting", "createOpp"].includes(id) && !isDataExist) || (["stockNoShow", "stockShow"].includes(id) && !isDataExistAdmin)) {
			showToast("", "재고를 선택해주세요.", "warning");
			return;
		}

		// 필터 데이터 검색 후 디테일 데이터 설정
		const searchData = (filterMap) => {
			this.isLoading = true;
			getFilteredProductWrapList({ filterMap: filterMap, tab: this.activeTab }).then(res => {
				console.log("res :: ", res);
				this.replaceChildren(res);
					// 필터 검색 후 체크박스 초기화
                this.profileDataMap[this.activeTab].selectedRowDetail = [];
                this.profileDataMap[this.activeTab].selectedStockIdList = [];
                this.profileDataMap[this.activeTab].selectedRowDetailId = [];
			}).catch(err => {
				console.log("err :: ", err);
				showToast("", err.body.message, "warning");
			}).finally(() => this.isLoading = false);
		};

		switch (id) {
			// 새고고침
			case "refresh" :
					this.profileDataMap[this.activeTab].optionValue = "";
				break;
			// 필터 검색
			case "search" :
                const filterMap = {
                    "Product__r.VehicleCategory__c":  this.profileDataMap[this.activeTab].currentCategoryKey,
                };
                searchData(filterMap);
				break;
			// 모달 관리 (공통 처리)
			default:
				// 각 모달별 모달 데이터 설정
				if (id in modalMap) {
					this.modalMap = modalMap[id];
					this.handleModalChange();
				}
				break;
		}
	}

	/**
	 * @description 모달 창 on/off
	 */
	handleModalChange() {
		const type = this.modalMap.type;
        console.log('type',type);
		const getSelectedData = (selectedRowDetail) => {
			console.log("selectedRowDetail :: ", JSON.stringify(selectedRowDetail));
			const childList = [];
			selectedRowDetail.forEach(el => {
				if (el.hasChildren) {
					el.children.forEach(child => {
						if (!childList.some(existingChild => existingChild.id === child.id)) {
							childList.push(child);
						}
					});
				} else {
					if (!childList.some(existingChild => existingChild.id === el.id)) {
						childList.push(el);
					}
				}
			});
			return childList;
		};

		let childList;

		// 어드민 모달 처리
		if (this.activeTab === "admin") {
			childList = getSelectedData(this.profileDataMap.admin.selectedRowDetail);
			this.profileDataMap.admin.selectedData = childList.map(row => ({
				...row,
				stockNoShow: isStockNoShow[type]
			}));
		}
		// SA 모달 처리
		else {
			if (type !== "대기리스트") {
				childList = getSelectedData(this.profileDataMap.sa.selectedRowDetail);
				this.profileDataMap.sa.selectedData = childList.map(row => ({
					...row,
					userName: this.userName,
					oppId: row.id === this.stockId && this.oppId ? this.oppId : null,
					type: type
				}));
			}
		}
		this.isModalOpen = !this.isModalOpen;
	}

	/**
	 * @description 모달 창에서 저장 버튼 클릭 시
	 */
	handleModalClick() {
		this.isLoading = true;
		const type = this.modalMap.type;
		switch (type) {
			// // 사전배정요청 || 대기안건요청
			// case "대기안건" :
			// case "대기리스트" :
			// 	const isOppIdNotExist = this.profileDataMap.sa.selectedData.some(el => !el.oppId);
			//
			// 	if (isOppIdNotExist) {
			// 		showToast("", "기회를 선택해주세요.", "warning");
			// 		this.isLoading = false;
			// 		return;
			// 	}
			// 	const paramMap = {
			// 		type: type,
			// 		selectedData: JSON.stringify(this.profileDataMap.sa.selectedData)
			// 	};
			// 	createPreAssignRequest({ paramMap: paramMap }).then(() => {
			// 		this.handleModalChange();
			// 		showToast("", "success", "success");
			// 	}).catch(err => {
			// 		console.log("err :: ", err);
			// 		showToast("", err.body.message, "warning");
			// 	}).finally(() => this.isLoading = false);
			// 	// recordFormEl.submit();
			// 	break;
			// 기회 생성
			// case "createOpp" :
			// 	const isAccountIdNotExist = this.profileDataMap.sa.selectedData.some(el => !el.accountId);
			//
			// 	if (isAccountIdNotExist) {
			// 		showToast("", "게정을 선택해주세요.", "warning");
			// 		this.isLoading = false;
			// 		return;
			// 	}
			//
			// 	createOpp({ selectedData: JSON.stringify(this.profileDataMap.sa.selectedData) }).then(() => {
			// 		this.handleModalChange();
			// 		showToast("", "success", "success");
			// 	}).catch(err => {
			// 		console.log("err :: ", err);
			// 		showToast("", err.body.message, "warning");
			// 	}).finally(() => this.isLoading = false);
			// 	break;
			// 재고 노출 || 미노출
			default :
				if (type in isStockNoShow) {
					updateStockShow({
						stockIdList: this.profileDataMap.admin.selectedStockIdList,
						isStockNoShow: isStockNoShow[type]
					}).then(() => {
						this.handleModalChange();
						showToast("", "success", "success");
						// this.profileDataMap.sa.masterData = [];
						// this.profileDataMap.admin.masterData = [];
						// this.detailData = [];
						// this.detailData = [];
						this.doInit();
						// this.getDetailData(this.profileDataMap.admin.currentCategoryKey, "admin");
					}).catch(err => {
						console.log("err :: ", err);
						showToast("", err.body.message, "warning");
					}).finally(() => this.isLoading = false);
				}
				break;
		}
	}

	/**
	 * @description 현재 탭 변경
	 */
	handleTabActive(e) {
		this.isLoading = true;
		this.activeTab = e.target.value;
		requestAnimationFrame(() => {
			this.adjustTableHeight();
		});
	}

	/**
	 * @description 수량 필드 스타일 포맷
	 */
	formatCountField() {
		// 필드 포맷
		const formatFieldMap = [
			{ key: "quantity", formatKey: "format" },
			{ key: "waitingListQty", formatKey: "waitingFormat" },
			{ key: "stockNoShowQty", formatKey: "stockFormat" },
			{ key: "preAssignQty", formatKey: "preFormat" },
			{ key: "after30DaysQty", formatKey: "after30Format" },
			{ key: "after60DaysQty", formatKey: "after60Format" }
		];

		// 동적 클래스 설정
		const getFormatClass = (value) => {
			// 기본 클래스 배열
			const classList = ["table-cell-padding", "slds-text-title_bold"];

			if (value > 0) {
				// 1개 이상 녹색
				classList.push("slds-text-color_success");
			} else {
				// 1개 미만 빨간색
				classList.push("slds-text-color_error");
			}

			return classList.join(" ");
		};

		// const profileDataMap.sa.masterData = this.isSaTab ? this.profileDataMap.sa.masterData : this.profileDataMap.admin.masterData;
		this.profileDataMap.sa.masterData.forEach(el => {
			formatFieldMap.forEach(({ key, formatKey }) => {
				// 수량 필드에 클래스 할당
				el[formatKey] = getFormatClass(el[key]);
			});
		});
		this.profileDataMap.admin.masterData.forEach(el => {
			formatFieldMap.forEach(({ key, formatKey }) => {
				// 수량 필드에 클래스 할당
				el[formatKey] = getFormatClass(el[key]);
			});
		});
	}

	/**
	 * @description 디테일 데이터 가져오기
	 * @param profileDataMap.sa.currentCategoryKey
	 * @param tab
	 */
	getDetailData(currentCategoryKey, tab) {
		this.isLoading = true;
		getProductWrap({ categoryKey: currentCategoryKey, tab: tab }).then(res => {
			console.log("res :: ", res);
			if (res) {
				if (tab === "sa") {
					this.profileDataMap.sa.detailData = res;
                    const additionalDetailData = [];
                    res.forEach(parent => {
                        parent.children.forEach(child => {
                            additionalDetailData.push(child);
                        });
                    });
					this.profileDataMap.sa.additionalDetailData = sortData(additionalDetailData, "totalDC", "desc");
					this.replaceChildren(this.profileDataMap.sa.detailData);
                    this.replaceChildren(this.profileDataMap.sa.additionalDetailData, true);
				} else {
					this.profileDataMap.admin.detailData = res;
					this.replaceChildren(this.profileDataMap.admin.detailData, true);
				}

				// 데이터 로드 완료 후 포커스 잡아주기
				requestAnimationFrame(() => {
					const detailTitleEl = this.template.querySelectorAll("span[title='Detail']");
					detailTitleEl.forEach(el => {
						el.scrollIntoView({
							behavior: "smooth",  // 부드러운 스크롤 효과
							block: "center",     // 요소를 수직 시작점에 위치
							inline: "start"     // 요소를 수평 중앙에 위치
						});
						el.focus();
					});
				});
			}
		}).catch(err => {
			console.log("err :: ", err);
			showToast("", err.body.message, "warning");
		}).finally(() => this.isLoading = false);
	}

	/**
	 * @description 모든 하위 children을 처리하는 재귀 함수
	 * @param item item
	 * @param isAdmin
	 */
	replaceChildren(item, isAdmin) {
		// 퍼센트 계산
		const calcPercent = (value) => (value || 0) / 100;
        console.log('calcPercent' , calcPercent);
		item.forEach(el => {
			if (el.children) {
				// el.DC = calcPercent(el.DC);
				if (!this.isSaTab || isAdmin) {
					el._children = el.children;
					this.replaceChildren(el.children);
				}
			} else {
				el.longTermDiscountRate = calcPercent(el.longTermDiscountRate);
                el.partsDC = calcPercent(el.partsDC);
                el.specialDC = calcPercent(el.specialDC);
			}
		});
	}
    handleCheckChange(event){
       this.additionalFlag = event.target.checked;
    }
}