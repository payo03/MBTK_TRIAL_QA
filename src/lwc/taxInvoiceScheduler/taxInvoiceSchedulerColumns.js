/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2025-01-22      jh.jung           Created
 */
const columns = [
  {
    label: "영업사원",
    fieldName: "agent",
    type: "text",
    hideDefaultActions: true
  },
  {
    label: "영업기회",
    fieldName: "oppUrl",
    type: "url",
    typeAttributes: {
      label: { fieldName: "oppName" }
    },
    hideDefaultActions: true
  },
  {
    label: "계약상태",
    fieldName: "conStatus",
    type: "text",
    cellAttributes: {
      style: { fieldName: "contractStatusCss" }
    },
    hideDefaultActions: true
  },
  {
    label: "차량상태",
    fieldName: "vehicleStatus",
    type: "text",
    cellAttributes: {
      style: { fieldName: "vehicleStatusCss" }
    },
    hideDefaultActions: true
  },
  {
    label: "입금 상태",
    fieldName: "paymentStatus",
    type: "text",
    cellAttributes: {
      style: { fieldName: "paymentStatusCss" }
    },
    hideDefaultActions: true
  },
  {
    label: "VAT 후취",
    fieldName: "isVat",
    type: "boolean",
    hideDefaultActions: true
  },
  {
    label: "인도금 유예",
    fieldName: "isDeposit",
    type: "boolean",
    hideDefaultActions: true
  },
  // {
  //   label: "출고일",
  //   fieldName: "handoverDate",
  //   type: 'button', typeAttributes: {
  //     label: { fieldName: 'handoverDate' },
  //     name: 'handoverDate',
  //     variant: 'base'
  //   }
  // },
  {
    label: "출고일",
    fieldName: "handoverDate",
    type: "text",
    hideDefaultActions: true
  },
  {
    label: "세금계산서 발행일",
    fieldName: "taxInvoiceDate",
    type: "text",
    hideDefaultActions: true
  }
];

const fieldApiMapping = {
  paymentStatus: "fm_PaymentStatus__c",
  startDate: "Opportunity__r.HandoverDate__c >",
  endDate: "Opportunity__r.HandoverDate__c <",
  searchAccountName: "searchAccountName",
  searchSalesAgentName: "searchSalesAgentName",
};

function getStyle(color = 'black', fontWeight = 'normal', backgroundColor = 'white') {
  return `color: ${color}; font-weight: ${fontWeight}; background-color: ${backgroundColor};`;
}

const contractStatusStyles = {
  '승인 단계': getStyle('black', 'normal'),
  '모두싸인 발송': getStyle('#771138', 'bold'),
  '계약금 및 서명 완료': getStyle('blue', 'bold'),
}
const vehicleStatusStyles = {
  '항구도착전': getStyle('orange', 'normal'),
  '항구도착': getStyle('orange', 'normal'),
  '입고': getStyle('green', 'normal'),
  '판매준비완료': getStyle('#771138', 'bold'),
  '출고예정': getStyle('grey', 'bold'),
  '출고준비완료': getStyle('blue', 'bold'),
  '출고됨': getStyle('black', 'bold'),
  '출고불가': getStyle('red', 'bold'),
};

const paymentStatusStyles = {
  '계약금 대기': getStyle('black', 'bold'),
  '계약금 입금완료': getStyle('green', 'bold'),
  '계산서 발행가능': getStyle('grey', 'bold'),
  '출고가능': getStyle('#771138', 'bold'),
  '모든입금완료': getStyle('blue', 'bold'),
  '초과입금': getStyle('red', 'bold'),
  '계약취소': getStyle('red', 'bold'),
};

export { columns, fieldApiMapping, contractStatusStyles, vehicleStatusStyles, paymentStatusStyles };