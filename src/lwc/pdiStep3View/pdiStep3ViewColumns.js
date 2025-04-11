/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-02-10
 * @description :
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-02-10      chaebeom.do     Initial Version
 **************************************************************/

const columns = [
	{
		label: "고객명",
		fieldName: "customer",
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
		typeAttributes: {
			label: { fieldName: "oppName" },
			tooltip: { fieldName: "tooltip" }
		},
		cellAttributes: {
			style: { fieldName: "oppUrlStyle" }
		}
	},
	// {
	// 	label: "옵션 목록",
	// 	fieldName: "helpText",
	// 	type: "helpTextType",
	// 	hideDefaultActions: true,
	// 	typeAttributes: {
	// 		optionQty: { fieldName: "optionQty" },
	// 		defaultOptionQty: { fieldName: "defaultOptionQty" }
	// 	}
	// },
	{
		label: "VIN",
		fieldName: "VIN",
		type: "button",
		hideDefaultActions: true,
		typeAttributes: {
			label: { fieldName: "VIN" },
			variant: "base"
		},
		cellAttributes: {
			style: { fieldName: "VINStyle" }
		}
	},
	{
		label: "워크넘버",
		fieldName: "vehicleNo",
		type: "text",
		hideDefaultActions: true,
		cellAttributes: {
			style: { fieldName: "vehicleNoStyle" }
		}
	},
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
		label: "입금 상태",
		fieldName: "paymentStatus",
		type: "text",
		hideDefaultActions: true,
		cellAttributes: {
			style: { fieldName: "paymentStatusStyle" }
		}
	},
	{
		label: "세금계산서 발행일",
		fieldName: "taxInvoiceDate",
		type: "text",
		hideDefaultActions: true,
		cellAttributes: {
			style: { fieldName: "taxInvoiceDateStyle" }
		}
	},
	{
		label: "출고일",
		fieldName: "handoverDate",
		type: "text",
		hideDefaultActions: true,
		cellAttributes: {
			style: { fieldName: "handoverDateStyle" }
		}
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
		label: "진행할 단계",
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

export {columns, stockColumns};