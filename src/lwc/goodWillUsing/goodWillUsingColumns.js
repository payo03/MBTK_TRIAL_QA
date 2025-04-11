/*************************************************************
 * @author : chaebeom.do
 * @date : 2025-03-17
 * @description :
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-17      chaebeom.do     Initial Version
 **************************************************************/

const columns = [
	{
		label: "신청 차량",
		fieldName: "GoodWillVIN__c",
		type: "text",
		hideDefaultActions: true
	},
	{
		label: "사용 요청금액",
		fieldName: "UsingGoodWill__c",
		type: "number",
		hideDefaultActions: true,
    initialWidth: 100
	},
	{
		label: "승인 상태",
		fieldName: "ApprovalStatus__c",
		type: "text",
		hideDefaultActions: true,
    initialWidth: 100
	}
];

export {columns};