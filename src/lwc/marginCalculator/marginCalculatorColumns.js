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
    label: 'Emissions',
    fieldName: 'emissionLevel',
    editable: false,
  },
  {
    label: 'Class',
    fieldName: '',
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
    label: '',
    fieldName: '',
    editable: false,
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
];


export { columns, simulationColumns };