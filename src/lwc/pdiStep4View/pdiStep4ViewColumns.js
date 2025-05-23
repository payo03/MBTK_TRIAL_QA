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
		label: "그룹명",
		fieldName: "Name",
		type: "button",
		hideDefaultActions: true,
		typeAttributes: {
			label: { fieldName: "Name"},
      name: "View", 
      title: "View", 
      value: "view",
			variant: "base"
		}
	},
  {
    type: "button", label: "추가", initialWidth: 150, typeAttributes: {
      label: "추가",
      name: "Add",
      title: "Add",
      disabled: false,
      value: "add",
      iconPosition: "left",
      iconName: "utility:add",
      variant: "Brand"
    }
  }
];


const selectedVinColumns= [
  { 
    label: "기회", 
    type: "url",
    fieldName: "oppUrl",
    typeAttributes: {
			label: { fieldName: "oppName" },
			tooltip: { fieldName: "tooltip" }
		}, 
    hideDefaultActions: true 
  },
  { 
    label: "견적", 
    type: "url",
    fieldName: "quoteUrl",
    typeAttributes: {
			label: { fieldName: "quoteName" },
			tooltip: { fieldName: "tooltip" }
		}, 
    hideDefaultActions: true 
  },
  { 
    label: "계약", 
    type: "url",
    fieldName: "contractUrl",
    typeAttributes: {
			label: { fieldName: "contractName" },
			tooltip: { fieldName: "tooltip" }
		}, 
    hideDefaultActions: true 
  }
];

const optionColumns = [
	{
		type: "text",
		fieldName: "type",
		label: "Type",
		hideDefaultActions: true
	},
	{
		type: "text",
		fieldName: "name",
		label: "Name",
		hideDefaultActions: true
	},
	{
		type: "number",
		fieldName: "price",
		label: "가격",
		hideDefaultActions: true
	}
];

const detailColumns= [
  { label: "파츠이름", fieldName: "Name", hideDefaultActions: true },
  { label: "파츠코드", fieldName: "SpoilerCode__c", hideDefaultActions: true },
  { label: "P11", fieldName: "P11", hideDefaultActions: true },
  { label: "P21", fieldName: "P21", hideDefaultActions: true },
  // { label: "그룹명", fieldName: "groupName", hideDefaultActions: true }
];

const installColumns = [
  { label: "파츠이름", fieldName: "Name", hideDefaultActions: true },
  { label: "파츠코드", fieldName: "SpoilerCode__c", hideDefaultActions: true },
  { label: "장착 확인일", fieldName: "installDate", type: 'date', initialWidth: 100, hideDefaultActions: true },
  // { label: "SAP 재고", fieldName: "installDate", type: 'date', initialWidth: 100, hideDefaultActions: true },
  // { label: "그룹명", fieldName: "groupName", hideDefaultActions: true },
  {
    type: "button", 
    label: "", 
    initialWidth: 100, 
    typeAttributes: {
      label: "제거",
      name: "Remove",
      title: "Remove",
      disabled: false,
      value: "remove",
      // iconPosition: "left",
      // iconName: "utility:add",
      variant: "Brand"
    }
  }
];

// 추가
const spoilerColums = [
  { label: '파츠이름 ', fieldName: 'name', hideDefaultActions: 'true'},
  { label: '파츠코드', fieldName: 'spoilerCode', initialWidth: 160, hideDefaultActions: 'true'},
  { label: "P11", fieldName: "p11", initialWidth: 70, hideDefaultActions: true },
  { label: "P21", fieldName: "p21", initialWidth: 70, hideDefaultActions: true },
  {
    type: "button", label: "추가", initialWidth: 120, typeAttributes: {
      label: "추가",
      name: "Add",
      title: "Add",
      disabled: false,
      value: "add",
      iconPosition: "left",
      iconName: "utility:add",
      variant: "Brand"
    }
  }
];


export {columns, optionColumns, selectedVinColumns, detailColumns, installColumns, spoilerColums};