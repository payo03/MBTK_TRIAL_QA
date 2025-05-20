/*************************************************************
 * @author : th.kim
 * @date : 2024-12-10
 * @description :
 * @target :
 ==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2024-12-10      th.kim          Initial Version
 **************************************************************/
const productColumns = [
	{
		type: "text",
		fieldName: "segment",
		label: "Segment"
		// wrapText: true
	},
	{
		type: "text",
		fieldName: "name",
		label: "차종"
		// wrapText: true
	},
	{
		type: "text",
		fieldName: "LMY",
		label: "연식"
		// wrapText: true
	},
	{
		type: "text",
		fieldName: "service",
		label: "보증"
		// wrapText: true
	},
	{
		type: "text",
		fieldName: "handoverDate",
		label: "Handover Data"
		// wrapText: true
	}
];

const agentColumns = [
	{
		type: "text",
		fieldName: "agency",
		label: "대리점"
	},
	{
		type: "text",
		fieldName: "MobilePhone",
		label: "핸드폰"
	},
	{
		type: "text",
		fieldName: "Email",
		label: "이메일"
	},
	{
		type: "text",
		fieldName: "Fax",
		label: "팩스"
	}
];

const modalOptionColumns = [
	{
		type: "text",
		fieldName: "type",
		label: "Type",
		hideDefaultActions: true
		// wrapText: true
	},
	{
		type: "text",
		fieldName: "name",
		label: "Name",
		hideDefaultActions: true
		// wrapText: true
	},
	{
		type: "number",
		fieldName: "price",
		label: "가격",
		hideDefaultActions: true
		// wrapText: true
	}
];

const optionColumns = [...modalOptionColumns, {
	type: "button-icon",
	initialWidth: 32,
	hideDefaultActions: true,
	// wrapText: true,
	typeAttributes: {
		iconName: "utility:delete",
		name: "delete"
	},
	cellAttributes: {
		class: { fieldName: "formatClass" }
	}
}];

const campaignColumns = [
	{
		type: "nameHelpTextType",
		fieldName: "name",
		label: "이름",
		hideDefaultActions: true,
		// wrapText: true,
		typeAttributes: {
			content: { fieldName: "content" }
		}
	},
	{
		type: "number",
		fieldName: "discountPrice",
		label: "할인가격",
		hideDefaultActions: true
		// wrapText: true
	},
	{
		type: "percent",
		fieldName: "discountRate",
		label: "할인율",
		hideDefaultActions: true,
		// wrapText: true,
		typeAttributes: {
			maximumFractionDigits: "2"
		}
	}, {
		type: "date",
		fieldName: "expireDate",
		label: "종료일",
		hideDefaultActions: true
		// wrapText: true
	}
];

const specialOptions = [
	{ label: "캡섀시 - 미완성", value: "캡섀시 - 미완성" },
	{ label: "트랙터", value: "트랙터" },
	{ label: "덤프", value: "덤프" },
	{ label: "캡섀시 - 완성", value: "캡섀시 - 완성" }
];

const incompletedSubOptions = [
	{ label: "윙바디", value: "윙바디" },
	{ label: "냉동", value: "냉동" },
	{ label: "카고데크", value: "카고데크" },
	{ label: "탱크로리", value: "탱크로리" },
	{ label: "암롤", value: "암롤" },
	{ label: "셀프로더", value: "셀프로더" },
	{ label: "카트랜스포터", value: "카트랜스포터" },
	{ label: "워킹플로어", value: "워킹플로어" },
	{ label: "BCC", value: "BCC" },
	{ label: "CPT", value: "CPT" },
	{ label: "가축", value: "가축" },
	{ label: "견인", value: "견인" },
	{ label: "곡물", value: "곡물" },
	{ label: "공항", value: "공항" },
	{ label: "덤프", value: "덤프" },
	{ label: "드릴", value: "드릴" },
	{ label: "믹서", value: "믹서" },
	{ label: "소방", value: "소방" },
	{ label: "제설", value: "제설" },
	{ label: "준설", value: "준설" },
	{ label: "철강", value: "철강" },
	{ label: "청소", value: "청소" },
	{ label: "컨테이너", value: "컨테이너" },
	{ label: "크레인", value: "크레인" },
	{ label: "평판", value: "평판" },
	{ label: "풀카고(연결차)", value: "풀카고(연결차)" },
	{ label: "기타", value: "기타" }
];

const tractorSubOptions = [
	{ label: "BCT", value: "BCT" },
	{ label: "곡물", value: "곡물" },
	{ label: "컨테이너", value: "컨테이너" },
	{ label: "탱크로리", value: "탱크로리" },
	{ label: "평판", value: "평판" },
	{ label: "철강", value: "철강" },
	{ label: "로우베드", value: "로우베드" },
	{ label: "냉동", value: "냉동" },
	{ label: "윙바디", value: "윙바디" },
	{ label: "덤프", value: "덤프" },
	{ label: "카트랜스포터", value: "카트랜스포터" },
	{ label: "기타", value: "기타" }
];

const tipperSubOptions = [
	{ label: "골재", value: "골재" },
	{ label: "성토", value: "성토" },
	{ label: "토사", value: "토사" },
	{ label: "폐기물", value: "폐기물" },
	{ label: "광물", value: "광물" },
	{ label: "슬러그", value: "슬러그" },
	{ label: "기타", value: "기타" }
];

const completedSubOptions = [
	{ label: "카고데크", value: "카고데크" },
	{ label: "기타", value: "기타" }
];

const stockColumns = [
	{
		type: "text",
		fieldName: "LMY",
		label: "LMY",
		hideDefaultActions: true
		// wrapText: true
	},
	{
		type: "text",
		fieldName: "VMY",
		label: "VMY",
		hideDefaultActions: true
		// wrapText: true
	},
	{
		type: "text",
		fieldName: "CarColor__c",
		label: "색상",
		hideDefaultActions: true
		// wrapText: true
	},
	{
		type: "text",
		fieldName: "totalDiscount",
		label: "총 할인율",
		hideDefaultActions: true
		// wrapText: true
	},
	{
		type: "percent",
		fieldName: "baseDiscount",
		label: "기준 할인율",
		hideDefaultActions: true
		// wrapText: true
	},
	{
		type: "percent",
		fieldName: "LongtermDiscountRate__c",
		label: "장기재고 할인율",
		hideDefaultActions: true,
		// wrapText: true,
		typeAttributes: {
			maximumFractionDigits: "2"
		}
	},
	{
		type: "number",
		fieldName: "SpecialDiscountAmt__c",
		label: "스페셜 할인 금액",
		hideDefaultActions: true,
		// wrapText: true,
		typeAttributes: {
			maximumFractionDigits: "2"
		}
	},
	{
		type: "percent",
		fieldName: "OptionDiscountRate__c",
		label: "옵션 할인율",
		hideDefaultActions: true,
		// wrapText: true,
		typeAttributes: {
			maximumFractionDigits: "2"
		}
	},
	{
		type: "currency",
		fieldName: "discountedPrice",
		label: "할인된 가격",
		hideDefaultActions: true
		// wrapText: true
	},
	{
		type: "text",
		fieldName: "Deviation__c",
		label: "결함",
		hideDefaultActions: true
		// wrapText: true
	},
	{
		type: "text",
		fieldName: "Remarks__c",
		label: "비고",
		hideDefaultActions: true
		// wrapText: true
	}

];

export {
	productColumns,
	agentColumns,
	modalOptionColumns,
	optionColumns,
	campaignColumns,
	specialOptions,
	incompletedSubOptions,
	tractorSubOptions,
	tipperSubOptions,
	completedSubOptions,
	stockColumns
};