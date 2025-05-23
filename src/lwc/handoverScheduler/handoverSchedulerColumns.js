/*************************************************************
 * @author : th.kim
 * @date : 2025-01-22
 * @description :
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-22      th.kim          Initial Version
 * 1.1          2025-04-24      chaebeom.do     워크넘버 클릭시 PDI 메인으로 이동하게 url 추가
 **************************************************************/
const columns = [
	{
		label: "영업인",
		fieldName: "agent",
		type: "text",
		hideDefaultActions: true,
		cellAttributes: {
			style: { fieldName: "customerStyle" }
		}
	},
	{
		label: "영업기회",
		fieldName: "oppUrl",
		type: "url",
		hideDefaultActions: true,
		initialWidth: 150,
		typeAttributes: {
			label: { fieldName: "oppName" }
		},
		cellAttributes: {
			style: { fieldName: "oppUrlStyle" }
		}
	},
	{
		label: "계약",
		fieldName: "contractUrl",
		type: "url",
		hideDefaultActions: true,
		initialWidth: 150,
		typeAttributes: {
			label: { fieldName: "contractNumber" }
		},
		cellAttributes: {
			style: { fieldName: "contractUrlStyle" }
		}
	},
	{
		label: "차종",
		fieldName: "productName",
		type: "text",
		hideDefaultActions: true,
		initialWidth: 150,
		cellAttributes: {
			style: { fieldName: "productNameStyle" }
		}
	},
	{
		label: "옵션 목록",
		fieldName: "helpText",
		type: "helpTextType",
		hideDefaultActions: true,
		typeAttributes: {
			optionQty: { fieldName: "optionQty" },
			defaultOptionQty: { fieldName: "defaultOptionQty" },
			specialQty: { fieldName: "specialQty" }
		}
	},
	{
		label: "VIN",
		fieldName: "VIN",
		type: "button",
		hideDefaultActions: true,
		typeAttributes: {
			label: { fieldName: "VIN" },
			variant: "base",
			actionName: "viewVIN"
		},
		cellAttributes: {
			style: { fieldName: "VINStyle" }
		}
	},
	// {
	// 	label: "워크넘버",
	// 	// fieldName: "vehicleNo",
	// 	fieldName: "vehicleNoUrl",
	// 	// type: "text",
	// 	type: "url",
	// 	hideDefaultActions: true,
	// 	typeAttributes: {
	// 		label: { fieldName: "vehicleNo" }
	// 	},
	// 	cellAttributes: {
	// 		style: { fieldName: "vehicleNoStyle" }
	// 	}
	// },
	{
		label: "차량상태",
		fieldName: "vehicleStatus",
		type: "text",
		hideDefaultActions: true,
		cellAttributes: {
			style: { fieldName: "vehicleStatusStyle" }
		}
	},
	{
		label: "출고일",
		fieldName: "handoverDate",
		type: "button",
		hideDefaultActions: true,
		typeAttributes: {
			label: { fieldName: "handoverDate" },
			variant: "base",
			actionName: "handoverDate"
		},
		cellAttributes: {
			style: { fieldName: "handoverDateStyle" }
		}
	},
	{
		label: "세금계산서 발행일",
		fieldName: "taxInvoiceDate",
		type: "text",
		hideDefaultActions: true,
		initialWidth: 150,
		cellAttributes: {
			style: { fieldName: "taxInvoiceDateStyle" }
		}
	},
	{
		label: "입금상태",
		fieldName: "paymentStatus",
		type: "text",
		hideDefaultActions: true,
		cellAttributes: {
			style: { fieldName: "paymentStatusStyle" }
		}
	},
	{
		label: "매출번호",
		fieldName: "saleNumber",
		type: "text",
		hideDefaultActions: true,
		cellAttributes: {
			style: { fieldName: "saleNumberStyle" }
		}
	}
];

const vehicleNoObj = {
	label: "워크넘버",
	// fieldName: "vehicleNo",
	fieldName: "vehicleNoUrl",
	// type: "text",
	type: "url",
	hideDefaultActions: true,
	typeAttributes: {
		label: { fieldName: "vehicleNo" },
		target: '_blank' 
	},
	cellAttributes: {
		style: { fieldName: "vehicleNoStyle" }
	}
};

const oilObj = {
	label: "주유 상품권",
	fieldName: "oilCouponFormat",
	type: "text",
	hideDefaultActions: true,
};



const handoverProfileColumns = columns.map(col =>
	col.fieldName === "VIN"
		? {
			...col,
			fieldName: "stockUrl",
			type: "url",
			typeAttributes: {
				label: { fieldName: "VIN" }
			}
		}
		: col
);

const saColumns = columns.map(col => {
	if (col.fieldName === "handoverDate") {
		return {
			...col,
			fieldName: "handoverDate",
			type: "text",
			typeAttributes: {
				label: {fieldName: "handoverDate"}
			}
		}
	} else if (col.fieldName === "VIN") {
		return {
			...col,
			fieldName: "stockUrl",
			type: "url",
			typeAttributes: {
				label: { fieldName: "VIN" }
			}
		}
	}
	else {
		return col;
	}
});

const pdiColumns = [
	...columns.slice(0, 4)
	, vehicleNoObj
	, ...columns.slice(4, 5)
	, oilObj
	, ...columns.slice(5)
];
// const saColumns = [...handoverProfileColumns];
const handoverColumns = [...handoverProfileColumns];
const defaultColumns = pdiColumns;

const exportColumns = [
	{
		label: "번호",
		fieldName: "idx",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "구분",
		fieldName: "",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "영업지점",
		fieldName: "agency",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "판매자",
		fieldName: "agent",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "차종",
		fieldName: "productName",
		type: "text",
		hideDefaultActions: true
	},
	// {
	// 	label: "차종 Id",
	// 	fieldName: "productId",
	// 	type: "text",
	// 	hideDefaultActions: true
	// },
	// {
	// 	label: "기회 Id",
	// 	fieldName: "opportunityId",
	// 	type: "text",
	// 	hideDefaultActions: true
	// },
	{
		label: "요청 사항",
		fieldName: "handoverRequest",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "works-no",
		fieldName: "vehicleNo",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "차대번호",
		fieldName: "VIN",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "Safety pack",
		fieldName: "safetyPackageDescription",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "입고일",
		fieldName: "eopDate",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "연식",
		fieldName: "modelYear",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "테스트 드라이브",
		fieldName: "",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "램프타입",
		fieldName: "",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "주유 상품권",
		fieldName: "oilCoupon",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "고객명",
		fieldName: "customer",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "출고예정일",
		fieldName: "taxInvoiceDate",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "실출고일",
		fieldName: "handoverDate",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "윙바디 적제함 오픈 경고",
		fieldName: "",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "사이즈",
		fieldName: "shirtSize",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "SCS",
		fieldName: "SCS",
		type: "boolean",
		hideDefaultActions: true
	},
	{
		label: "PTO",
		fieldName: "PTO",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "스포일러2",
		fieldName: "spoiler",
		type: "boolean",
		hideDefaultActions: true
	},
	{
		label: "이지 컨트롤 버튼",
		fieldName: "easyControl",
		type: "boolean",
		hideDefaultActions: true
	},
	{
		label: "냉장고",
		fieldName: "refrigerator",
		type: "boolean",
		hideDefaultActions: true
	},
	{
		label: "알루미늄휠",
		fieldName: "wheel",
		type: "boolean",
		hideDefaultActions: true
	},
	{
		label: "바닥매트",
		fieldName: "mat",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "비고",
		fieldName: "oppName",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "Seg.",
		fieldName: "segment2",
		type: "text",
		hideDefaultActions: true
	}
];

const stockColumns = [
	{
		label: "VIN",
		fieldName: "Name",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "입항일",
		fieldName: "realArrivalDate",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "차종",
		fieldName: "product",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "VEHICLE NO",
		fieldName: "VehicleNo__c",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "Intarder",
		fieldName: "IsIntarder__c",
		type: "boolean",
		hideDefaultActions: true
	},
	{
		label: "IsPTO",
		fieldName: "IsPTO__c",
		type: "boolean",
		hideDefaultActions: true
	},
	{
		label: "IsHypoid",
		fieldName: "IsHypoid__c",
		type: "boolean",
		hideDefaultActions: true
	},
	{
		label: "CAB",
		fieldName: "Cab_Color__c",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "차량 상태",
		fieldName: "VehicleStatus__c",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "STEP",
		fieldName: "fm_PdiNextStep__c",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "PDI 입고일자",
		fieldName: "PDIEntryDate__c",
		type: "text",
		hideDefaultActions: true
	}
];

const fieldApiMapping = {
	paymentStatus: "fm_PaymentStatus__c",
	vehicleStatus: "Opportunity__r.VehicleStock__r.VehicleStatus__c",
	startDate: "Opportunity__r.HandoverDate__c >",
	endDate: "Opportunity__r.HandoverDate__c <"
};

// 엑셀 컬럼 맵핑
const exportMapping = {
	"[MY] BODY DOOR OPEN WARNING": { key: "wingBody", value: true },
	// "출고기념품세트 - 100": { key: "size", value: "100" },
	// "출고기념품세트 - 105": { key: "size", value: "105" },
	// "출고기념품세트 - 110": { key: "size", value: "110" },
	"[MY] 사각지대 카메라 SCS": { key: "SCS", value: true },
	"[MY] 유틸리티 패키지 - SCS, 냉장고, 스포일러": { key: "SCS", value: true },
	"[MY] 유틸리티 패키지 - 휠, SCS, 냉장고, 스포일러": { key: "SCS", value: true },
	"[MY] FLYWHEEL SIDE PTO (메인냉동기용)": { key: "PTO", value: "" },
	"[MY] PTO_NH/1B+Wiring kit": { key: "PTO", value: "1B" },
	"[MY] PTO_NH/4B+Wiring kit": { key: "PTO", value: "4B" },
	"[MY] PTO_NH/4C+Wiring kit": { key: "PTO", value: "4C" },
	"[MY] 루프 스포일러": { key: "spoiler", value: '○' },
	"[MY] 스포일러+사이드플랩": { key: "spoiler", value: '○' },
	"[MY] 이지 컨트롤 버튼": { key: "easyControl", value: '○' },
	"[MY] 냉장고(Cool Box)": { key: "refrigerator", value: '○' },
	"[MY] 알루미늄휠 TGM 4x2": { key: "wheel", value: '○' },
	"[MY] 바닥매트": { key: "mat", value: "잔디매트" },
	"[MY] 차량용품 패키지(블랙박스,썬팅,바닥매트,적재함카메라)": { key: "mat", value: "잔디매트" }
};

const editStyle = "border: 1px solid #A86403; color: #8C4B02; background-color: #f9e3b6; font-weight: bold;";

export { columns, handoverProfileColumns, exportColumns, stockColumns, fieldApiMapping, exportMapping, editStyle, defaultColumns, saColumns, pdiColumns, handoverColumns };