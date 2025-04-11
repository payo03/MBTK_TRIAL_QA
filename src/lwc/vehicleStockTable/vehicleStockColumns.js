/*************************************************************
 * @author : th.kim
 * @date : 2024-11-20
 * @description :
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-11-20      th.kim          Initial Version
 * 2.0          2025-02-06      San.kang        Updated Version
 **************************************************************/
const columns = [
	// {
	// 	type: "text",
	// 	fieldName: "segment",
	// 	label: "segment"
	// },
	// {
	// 	type: "text",
	// 	fieldName: "reportSpec",
	// 	label: "Report_Spec"
	// },
	// {
	// 	type: "text",
	// 	fieldName: "quantity",
	// 	label: "수량"
	// },
	// {
	// 	type: "text",
	// 	fieldName: "modelName",
	// 	label: "modelName",
	// 	initialWidth: 200
	// },
	// {
	// 	type: "text",
	// 	fieldName: "modelQuantity",
	// 	label: "수량"
	// },
	// {
	// 	type: "text",
	// 	fieldName: "modelYear",
	// 	label: "modelYear"
	// },
	// {
	// 	type: "url",
	// 	fieldName: "vehicleNo",
	// 	label: "vehicleNo",
	// 	typeAttributes: {
	// 		label: { fieldName: "vehicleNo" },
	// 		target: "_blank"
	// 	}
	// },
	// {
	// 	type: "text",
	// 	fieldName: "productionSite",
	// 	label: "productionSite"
	// },
	// {
	// 	type: "text",
	// 	fieldName: "color",
	// 	label: "color"
	// },
	// {
	// 	type: "boolean",
	// 	fieldName: "preAssigned",
	// 	label: "preAssigned"
	// },
	// {
	// 	type: "text",
	// 	fieldName: "stockStatus",
	// 	label: "stockStatus"
	// },
	// {
	// 	type: "button",
	// 	typeAttributes: {
	// 		label: { fieldName: "actionLabel" }, // `actionLabel` 필드를 동적으로 사용
	// 		name: "requestAction",
	// 		variant: "brand"
	// 	}
	// }
];

const masterColumnsForSA = [
	{
		type: "text",
		fieldName: "name",
		label: "Name",
		sortable: true,
		hideDefaultActions: true,
		wrapText: true,
	},
 	{
        type: "text",
        fieldName: "styling",
        label: "Styling",
 		sortable: true,
 		hideDefaultActions: true,
 		wrapText: true
    },
    {
        type: "number",
        fieldName: "carAmt",
        label: "차량 금액",
 		sortable: true,
 		hideDefaultActions: true,
 		wrapText: true
    },
    {
        type: "number",
        fieldName: "price",
        label: "옵션 금액",
 		sortable: true,
 		hideDefaultActions: true,
 		wrapText: true
    },
	{
		type: "text",
		fieldName: "quantity",
		label: "수량",
		sortable: true,
		hideDefaultActions: true,
		wrapText: true,
		cellAttributes: {
			class: {
				fieldName: "format"
			}
		}
	},
	{
		type: "text",
		fieldName: "eta",
		label: "ETA",
		sortable: true,
		hideDefaultActions: true,
		wrapText: true,
		cellAttributes: {
			class: {
				fieldName: "format"
			}
		}
	}
];

const masterColumnsForAdmin = [
	{
		type: "text",
		fieldName: "segment",
		label: "세그먼트2",
		sortable: true,
		hideDefaultActions: true,
		wrapText: true
	},
	{
		type: "text",
		fieldName: "name",
		label: "Name",
		sortable: true,
		hideDefaultActions: true,
		wrapText: true
	},
 	{
 		type: "text",
 		fieldName: "styling",
 		label: "Styling",
        sortable: true,
        hideDefaultActions: true,
  		// initialWidth: 200,
  		wrapText: true
 	},
	{
		type: "text",
		fieldName: "quantity",
		label: "수량",
		sortable: true,
		hideDefaultActions: true,
		wrapText: true,
		cellAttributes: {
			class: {
				fieldName: "format"
			}
		}
	},
	{
		type: "text",
		fieldName: "waitingListQty",
		label: "대기수요",
		sortable: true,
		hideDefaultActions: true,
		wrapText: true,
		cellAttributes: {
			class: {
				fieldName: "waitingFormat"
			}
		}
	},
	{
		type: "text",
		fieldName: "stockNoShowQty",
		label: "감춘재고",
		sortable: true,
		hideDefaultActions: true,
		wrapText: true,
		cellAttributes: {
			class: {
				fieldName: "stockFormat"
			}
		}
	},
	{
		type: "text",
		fieldName: "after30DaysQty",
		label: "30일이후",
		sortable: true,
		hideDefaultActions: true,
		wrapText: true,
		cellAttributes: {
			class: {
				fieldName: "after30Format"
			}
		}
	},
	{
		type: "text",
		fieldName: "after60DaysQty",
		label: "60일이후",
		sortable: true,
		hideDefaultActions: true,
		wrapText: true,
		cellAttributes: {
			class: {
				fieldName: "after60Format"
			}
		}
	}
];

const detailColumns = [
	{
		type: "text",
		fieldName: "VMY",
		label: "VMY",
		wrapText: true
	},
	{
		type: "text",
		fieldName: "LMY",
		label: "LMY",
		wrapText: true
	},
	{
		type: "text",
		fieldName: "colour",
		label: "색상",
		wrapText: true
	},
	{
		type: "number",
		fieldName: "DC",
		label: "할인",
		wrapText: true
	},
	{
		type: "number",
		fieldName: "totalPrice",
		label: "총 금액",
		wrapText: true
	},
	{
		type: "text",
		fieldName: "modelQuantity",
		label: "수량",
		wrapText: true,
		cellAttributes: {
			class: "slds-text-title_bold"
		}
	},

	// {
	// 	type: "percent",
	// 	fieldName: "longTermDiscountRate",
	// 	label: "장기재고할인율",
	// 	wrapText: true
	// },
	// {
	// 	type: "text",
	// 	fieldName: "modelYear",
	// 	label: "modelYear",
	// 	wrapText: true
	// },
	// {
	// 	type: "url",
	// 	fieldName: "vehicleUrl",
	// 	label: "vehicleNo",
	// 	wrapText: true,
	// 	typeAttributes: {
	// 		label: { fieldName: "vehicleNo" },
	// 		target: "_blank",
	// 		href: ""
	// 	}
	// },
	// {
	// 	type: "text",
	// 	fieldName: "productionSite",
	// 	label: "productionSite",
	// 	wrapText: true
	// },
	// {
	// 	type: "text",
	// 	fieldName: "color",
	// 	label: "color",
	// 	wrapText: true
	// },
	// {
	// 	type: "text",
	// 	fieldName: "stockStatus",
	// 	label: "stockStatus",
	// 	editable: true,
	// 	wrapText: true
	// },
	// {
	// 	type: "boolean",
	// 	fieldName: "preAssigned",
	// 	label: "preAssigned",
	// 	wrapText: true
	// }
];

const additionalDetailColumns = [
	{
		type: "text",
		fieldName: "modelYear",
		label: "VMY",
		sortable: true,
		wrapText: true
	},
	{
		type: "text",
		fieldName: "localYear",
		label: "LMY",
        sortable: true,
		wrapText: true
	},
	{
		type: "text",
		fieldName: "color",
		label: "색상",
        sortable: true,
		wrapText: true
	},
	{
		type: "number",
		fieldName: "totalDC",
		label: "총 할인",
        sortable: true,
		wrapText: true
	},
	{
		type: "percent",
		fieldName: "longTermDiscountRate",
		label: "장기재고할인율",
        sortable: true,
		wrapText: true
	},
	{
		type: "percent",
		fieldName: "partsDC",
		label: "파츠 할인율",
        sortable: true,
		wrapText: true,
	},
	{
		type: "percent",
		fieldName: "specialDC",
		label: "스페셜 할인율",
        sortable: true,
		wrapText: true,
	},
	{
		type: "number",
		fieldName: "discountedPrice",
		label: "할인가",
        sortable: true,
		wrapText: true,
	},
    {
 		type: "text",
 		fieldName: "deviation",
 		label: "결함",
        sortable: true,
 		wrapText: true,
 	},
    {
        type: "text",
        fieldName: "remarks",
        label: "비고",
        sortable: true,
        wrapText: true,
    },
    {
        type: "text",
        fieldName: "amount",
        label: "수량",
        wrapText: true,
        sortable: true,
        cellAttributes: {
            class: "slds-text-title_bold"
        }
    }
];
const detailColumnsForAdmin = [
	{
		type: "text",
		fieldName: "VMY",
		label: "VMY",
		wrapText: true
	},
	{
		type: "text",
		fieldName: "LMY",
		label: "LMY",
		wrapText: true
	},
	{
		type: "text",
		fieldName: "colour",
		label: "색상",
		wrapText: true
	},
	{
		type: "number",
		fieldName: "DC",
		label: "할인",
		wrapText: true
	},
	{
		type: "text",
		fieldName: "deviation",
		label: "결함",
		wrapText: true
	},
	{
		type: "text",
		fieldName: "remarks",
		label: "비고",
		wrapText: true
	},
	{
		type: "text",
		fieldName: "modelQuantity",
		label: "수량",
		wrapText: true,
		cellAttributes: {
			class: "slds-text-title_bold"
		}
	},
	{
		type: "percent",
		fieldName: "longTermDiscountRate",
		label: "장기재고할인율",
		wrapText: true
	},
	{
		type: "url",
		fieldName: "vehicleUrl",
		label: "VEHICLE NO",
		wrapText: true,
		typeAttributes: {
			label: { fieldName: "vehicleNo" },
			target: "_blank",
			href: ""
		}
	},
	{
		type: "text",
		fieldName: "productionSite",
		label: "생산지",
		wrapText: true
	},
	{
		type: "text",
		fieldName: "stockStatus",
		label: "재고상태",
		wrapText: true
	},
	{
		type: "boolean",
		fieldName: "stockNoShow",
		label: "재고미노출",
		wrapText: true
	}
];

const selectedColumns = [
	{
		type: "text",
		fieldName: "vehicleNo",
		label: "VEHICLE NO",
		hideDefaultActions: true,
		wrapText: true
	},
];

export { columns, masterColumnsForSA, masterColumnsForAdmin, detailColumns, additionalDetailColumns, detailColumnsForAdmin, selectedColumns };