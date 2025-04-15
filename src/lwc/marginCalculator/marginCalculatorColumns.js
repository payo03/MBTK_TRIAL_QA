/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2025-03-12      jh.jung           Created
 */
const columns = [
  {
    label: "ProductName",
    fieldName: "productName",
    type: "text",
    hideDefaultActions: true,
  },
  {
    label: "Optview",
    fieldName: "isOTV",
    type: "text",
    hideDefaultActions: true,
  },
  {
    label: "Lion-S",
    fieldName: "isLNS",
    type: "text",
    hideDefaultActions: true,
  },
  {
    label: "Premium",
    fieldName: "isPremium",
    type: "text",
    hideDefaultActions: true,
  },
  {
    label: "reportSpec",
    fieldName: "reportSpec",
    type: "text",
    hideDefaultActions: true,
  },
  // {
  //   label: "specShort",
  //   fieldName: "specShort",
  //   type: "text",
  //   hideDefaultActions: true,
  // },
];

const simulationColumns = [
  {
    label: 'Report spec',
    fieldName: 'reportSpec',
    editable: false,
  },
  {
    label: 'Emissions Class',
    fieldName: 'emissionLevel',
    editable: false,
  },
  {
    label: '\u00A0\u00A0\u00A0\u00A0Optview',
    fieldName: 'isOTV',
    editable: false,
  },
  {
    label: '\u00A0\u00A0\u00A0\u00A0Lion-S',
    fieldName: 'isLNS',
    editable: false,
  },
  {
    label: '\u00A0\u00A0\u00A0\u00A0Premium',
    fieldName: 'isPremium',
    editable: false,
  },
  {
    label: 'Purchase Invoice Price, KRW',
    fieldName: 'purchaseInvoicePrice',
    editable: false,
  },
  {
    label: 'GLP, EUR',
    fieldName: '',
    editable: false,
  },
  {
    label: 'Top Option, EUR',
    fieldName: '',
    editable: false,
  },
  {
    label: 'Cost components, KRW',
    fieldName: 'costComponents',
    editable: false,
  },
  {
    label: '\u00A0\u00A0\u00A0\u00A01) Oil coupon',
    fieldName: 'oilCoupon',
    editable: true,
  },
  {
    label: '\u00A0\u00A0\u00A0\u00A02) SA Commission',
    fieldName: 'saCommission',
    editable: false,
  },
  {
    label: '\u00A0\u00A0\u00A0\u00A03) NDDR',
    fieldName: 'nddr',
    editable: false,
  },
  {
    label: '\u00A0\u00A0\u00A0\u00A04)Campaign',
    fieldName: 'campaign',
    editable: true,
  },
  {
    label: '\u00A0\u00A0\u00A0\u00A05)Var',
    fieldName: 'var',
    editable: true,
  },
  {
    label: 'Local costs, KRW',
    fieldName: 'localTotal',
    editable: false,
  },
  {
    label: '\u00A0\u00A0\u00A0\u00A01) Local installation',
    fieldName: 'localCost',
    editable: true,
  },
  {
    label: '\u00A0\u00A0\u00A0\u00A02) PDI cost',
    fieldName: 'pdiCost',
    editable: true,
  },
  {
    label: '\u00A0\u00A0\u00A0\u00A03) Others',
    fieldName: 'otherCost',
    editable: true,
  },
  {
    label: 'List price',
    fieldName: 'listPrice',
    editable: true,
  },
  {
    label: 'List price(w/o VAT)',
    fieldName: 'listPriceVat',
    editable: false,
  },
];


export { columns, simulationColumns };