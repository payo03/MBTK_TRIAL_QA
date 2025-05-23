/*************************************************************
 * @author : chaebeom.do
 * @date : 2024-11-29
 * @description : lead acquisition, lead management 공통사용 차종/캠페인 정보 데이터테이블
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-29      chaebeom.do     Created
 **************************************************************/
import { LightningElement, track, api } from 'lwc';

import formFactor from "@salesforce/client/formFactor";
import getInitData from "@salesforce/apex/LeadAcquisitionController.getInitData";
import getFilteredProduct from "@salesforce/apex/LeadAcquisitionController.getFilteredProduct";
import getCampaign from "@salesforce/apex/LeadAcquisitionController.getCampaign";
import getCampaignPreventDuplicate from "@salesforce/apex/LeadAcquisitionController.getCampaignPreventDuplicate";
// import { getRecordCreateDefaults } from 'lightning/uiRecordApi';
import { showToast, labelList } from "c/commonUtil";

const productColumns = [
	{ 
		type: 'text',
		fieldName: 'segment', 
		label: '세그먼트2',
		initialWidth: 80,
		sortable: true,
		hideDefaultActions: true
	},
	{ 
		type: 'text',
		fieldName: 'name', 
		label: '모델명',
		wrapText: true,
		sortable: true,
		hideDefaultActions: true
	},
	{ 
		type: 'number',
		fieldName: 'listPrice', 
		label: '기준가격',
		cellAttributes: { alignment: 'left' },
		initialWidth: 110,
		sortable: true,
		hideDefaultActions: true
	},
	{ 
		type: 'number',
		fieldName: 'quantity', 
		label: '수량',
		cellAttributes: { alignment: 'left' },
		initialWidth: 80,
		sortable: true,
		hideDefaultActions: true
	},
  { 
		type: 'number',
		fieldName: 'etaQuantity', 
		label: 'ETA 수량',
		cellAttributes: { alignment: 'left' },
		initialWidth: 80,
		sortable: true,
		hideDefaultActions: true
	},
];
const productColumnsMobile = [
	{ 
		type: 'text',
		fieldName: 'name', 
		label: '모델명',
		wrapText: true,
		sortable: true,
		hideDefaultActions: true
	},
	{ 
		type: 'number',
		fieldName: 'quantity', 
		label: '수량',
		cellAttributes: { alignment: 'left' },
		initialWidth: 60,
		sortable: true,
		hideDefaultActions: true
	},
	{ 
		type: 'number',
		fieldName: 'etaQuantity', 
		label: 'ETA',
		cellAttributes: { alignment: 'left' },
		initialWidth: 60,
		sortable: true,
		hideDefaultActions: true
	},
];
const campaignColumns = [
	// { 
	// 	type: 'text',
	// 	fieldName: 'name', 
	// 	label: '캠페인 이름',
	// 	wrapText: true,
	// 	hideDefaultActions: true
	// },
	{
		type: "nameHelpTextType",
		fieldName: "name",
		label: "캠페인 이름",
		hideDefaultActions: true,
		typeAttributes: {
			content: { fieldName: "content" },
		},
		initialWidth: 250,
	},
	{ 
		type: 'date',
		fieldName: 'expireDate', 
		label: '캠페인 종료일',
		cellAttributes: { alignment: 'left' },
		hideDefaultActions: true,
	},
	{ 
		type: 'number',
		fieldName: 'discountPrice', 
		label: '할인가격',
		cellAttributes: { alignment: 'left' },
		hideDefaultActions: true,
	},
	{ 
		type: 'number',
		fieldName: 'discountRate', 
		label: '할인율(%)',
		cellAttributes: { alignment: 'left' },
		hideDefaultActions: true,
		initialWidth: 80,
	},
];

//필터 디폴트값
const filterDefault = { Segment2__c: "", Name: ""};

export default class ProductCampaignTable extends LightningElement {
  //차종, 캠페인 컴포넌트 변수
	productData = [];
	isNoProductData = false;
	isNoCampaignData = false;
	@track myLabel = labelList;
  dynamicColumns;	
	@track campaignData = [];
	@track campaignPreventDupData = [];
	firstCamp = true;
  campaignColumns = campaignColumns;
	defaultSortDirection = 'asc';
	sortDirection = 'asc';
	sortedBy;
	filterOptions = { segment: [] }; // 필터 옵션 맵
	@track filterMap = { ...filterDefault }; // 적용할 필터 맵
	@track selectedProductRowIds = [];
	@track selectedCampaignRowIds = [];

	isCheckByManagement = false;
	isProductChange = true;
	productNameByManagement = '';
	selectedProductIdByManagement;

  connectedCallback() {
		this.getInit();
		if (formFactor === "Small")	this.isMobile = true;
		this.dynamicColumns = this.isMobile != true ? productColumns : productColumnsMobile;
	}

	getInit() {
		// 데이터 테이블 생성
		getInitData().then(res => {
			this.productData = res.productList;
			requestAnimationFrame(() => {
				this.selectedProductRowIds = [this.selectedProductIdByManagement];
				if(typeof this.selectedProductIdByManagement !== 'undefined') {
					this.getCampaignList(this.selectedProductIdByManagement);
					this.getProductId();
				}
			})
			this.filterOptions.segment = [{ label: "선택안함", value: "" }].concat(res.segment);
		}).catch(err => {
			console.log("err :: ", err);
		});
	}

	/**
	 * @description 부모 컴포넌트로 이벤트 전송
	 * @param e 클릭한 데이터 이벤트
	 */
  handleRowSelect(e) {
    const id = e.detail.config.value;
    const type = e.target.dataset.type;
    const customEvent = new CustomEvent('rowselect', {
      detail: { 
        id: e.detail.config.value, 
        selectedRow: e.detail.selectedRows,
        type: e.target.dataset.type 
      }      
    });

    if(type === 'product') {
			this.firstCamp = true;
			this.campaignData = [];
			this.selectedCampaignRowIds = [];
			this.campaignPreventDupData = []; 
			this.getCampaignList(id);
			this.getCampaignPreventDupList('');
    }
		// 캠페인을 선택했을 때
		// 1-1. 첫 번째 선택이면 체크는 그대로 진행, 선택한 캠페인 id가 포함된 중복방지 레코드를 찾아서 저장해둠
		// 1-2. 첫 번째 선택 이후면 저장해둔 중복방지 레코드 안에 선택한 캠페인 id가 포함되어있으면 경고 및 체크 해제
		// 2. 체크해제 액션이면 저장해둔 중복방지 레코드에서 선택 해제하는 캠페인 id가 포함된 레코드를 삭제
		// 3. 전체 선택 액션이면 선택된 캠페인끼리의 조합 중 중복방지에 걸리는 조합이 있으면 경고 및 전체 체크 해제
		// 		없으면 전체 선택
		// 4. 전체 해제 액션이면 전체 해제
    if(type === 'campaign') {
			switch (e.detail.config.action) {
				case 'rowSelect':
					if(this.firstCamp) {
						this.campaignPreventDupData = [];
						this.firstCamp = false;
					}
					if(this.campaignPreventDupData.length != 0) {
						for(let el of this.campaignPreventDupData) {
							if(el.campaign1 == id || el.campaign2 == id) {
								const camName = (el.campaign2 == id) ? el.campaign1Name : el.campaign2Name;
								showToast("중복 적용 불가", "이 캠페인은 " + camName + "과 중복 적용이 불가능합니다.", "error");
								this.selectedCampaignRowIds = this.selectedCampaignRowIds.filter(el => el !== id);
								return;
							}
						}
					}
					this.getCampaignPreventDupList(id);
					this.selectedCampaignRowIds.push(id);
					break;
				case 'rowDeselect':
					this.deleteCampaignPreventDupList(id);
					this.selectedCampaignRowIds = this.selectedCampaignRowIds.filter(el => el !== id);
					if(this.selectedCampaignRowIds.length == 0) {
						this.firstCamp = true;
						this.campaignPreventDupData = [];
						this.getCampaignPreventDupList('');
					}
					break;
				case 'selectAllRows':
					this.getCampaignPreventDupList('');
					for(let el of e.detail.selectedRows) {
						this.selectedCampaignRowIds.push(el.id);
					}
					for(let id of this.campaignPreventDupData) {
						if(this.selectedCampaignRowIds.includes(id.campaign1)||this.selectedCampaignRowIds.includes(id.campaign2)) {
							showToast("중복 적용 불가", "중복 적용이 불가능한 캠페인이 포함되어있습니다.", "error");
							this.selectedCampaignRowIds = [];
							return;
						}
					}
					break;
				case 'deselectAllRows':
					this.campaignPreventDupData = [];
					this.getCampaignPreventDupList('');
					this.selectedCampaignRowIds = [];
					this.firstCamp = true;
					break;
				default:
					break;
			}
    }
    this.dispatchEvent(customEvent);
  }

	getProductId() {
		const customEvent = new CustomEvent('getproductid', {
			detail: {
				productId : this.selectedProductIdByManagement
			}
		});
		this.dispatchEvent(customEvent);
	}

	getCampaignList(id){
		this.selectedProductRowIds = [id]; 
      getCampaign({ productId: id }).then(res => {
        console.log("res :: ", res);
				this.campaignData = res?.map(el => {
					return {
						...el,
						content: el.memo
					};
				}) || [];
				this.isNoCampaignData = this.campaignData.length === 0 ? true : false;
				console.log('체크 :: ' + this.myLabel.EmptyCampaignResult);
      }).catch(err => {
        console.log("err :: ", err);
      });
	}

	getCampaignPreventDupList(id){
      getCampaignPreventDuplicate({campaignId: id}).then(res => {
				this.campaignPreventDupData = [...this.campaignPreventDupData, ...res];
				this.campaignPreventDupData = this.campaignPreventDupData.reduce((prev, now) => {
					if(!prev.some(obj => obj.id === now.id)) {
						prev.push(now);
					}
					return prev
				}, []);
      }).catch(err => {
        console.log("err :: ", err);
      });;
	}

	deleteCampaignPreventDupList(id){
		this.campaignPreventDupData = this.campaignPreventDupData.filter(param => param.campaign1 != id && param.campaign2 != id);
	}

	// Management에서 호출시 해당 Lead에 Product 있다면 받기
	@api getProductByLead(data) {
		this.isCheckByManagement = true;
		this.selectedProductIdByManagement = data[0].ProductId__c;
		this.productNameByManagement = (typeof data[0].ProductId__c !== 'undefined') ? data[0].ProductId__r.Name : '';
		this.isProductChange = false;
		this.getInit();
	}

	get isMatching() {
		return this.selectedProductRowIds[0] === this.selectedProductIdByManagement;
	}

	handleCheckboxChange(e) {
		this.isProductChange = e.target.checked;
		if(!this.isProductChange) {
			this.selectedProductRowIds = this.selectedProductIdByManagement;

			// 초기값 던지기
			this.getProductId();

			// 캠페인 값 초기화을 부모로 던져야함
			this.selectedCampaignRowIds = [];
			this.campaignData = null;

			// 캠페인 목록 refresh
			this.getCampaignList(this.selectedProductIdByManagement);

		}
	}

	//lead acquisition에서 생성한 리드 중에서 
	@api
	highlightProduct(productId) {
		this.selectedProductRowIds = [productId];
		this.campaignData = null;
		this.getCampaignList(productId);
	}

	//lead acquisition 선택 초기화 버튼 클릭시 차종, 캠페인 라디오 버튼 해제
  @api
  refreshTable() {
    this.selectedProductRowIds = []; 
    this.selectedCampaignRowIds = []; 
    this.campaignData = null; 
		this.campaignPreventDupData = []; 
		// this.productData = null;
  }

	sortBy(field, reverse, primer) {
		const key = primer
				? function (x) {
							return primer(x[field]);
					}
				: function (x) {
							return x[field];
					};

		return function (a, b) {
				a = key(a);
				b = key(b);
				return reverse * ((a > b) - (b > a));
		};
	}

	onHandleSort(event) {
			const { fieldName: sortedBy, sortDirection } = event.detail;
			const cloneData = [...this.productData];
			cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
			this.productData = cloneData;
			this.sortDirection = sortDirection;
			this.sortedBy = sortedBy;
	}

	/**
	 * @description 필터 선택 시 필터 맵에 필터 데이터 저장
	 */
	handleFilter(e) {
		const id = e.target.dataset.id;
		const value = e.target.value;
		switch (id) {
			case "segment" :
				this.filterMap.Segment2__c = value;
				this.handleProductSearch(e);
				break;
			case "name" :
				this.filterMap.Name = value;
				break;
		}
	}

	/**
	 * @description 차종 검색 버튼 클릭 이벤트 함수
	 * @param e
	 */
	handleProductSearch(e) {
		const id = e.currentTarget.dataset.id;
		// 필터 리셋
		if (id === "refresh") {
			this.filterMap = { ...filterDefault };
		}
		// 선택된 필터로 검색
		// else if(id === "search" || e.key === "Enter") {
		getFilteredProduct({ filterMap: this.filterMap }).then(res => {
			this.productData = res;
			this.selectedProductRowIds = [...this.selectedProductRowIds];
			this.campaignPreventDupData = []; 
			this.campaignData = [];
			this.isNoProductData = this.productData.length === 0 ? true : false;
			this.refreshTable();
		}).catch(err => {
			console.log("err :: ", err);
		});
		// }
	}

}