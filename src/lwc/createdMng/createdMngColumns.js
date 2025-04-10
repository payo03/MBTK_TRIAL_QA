/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-10
 * @description :
 * @target :
 ==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-10        San.Kang           Created
 **************************************************************/
const mngNoColumns = [
    {
        type: "text",
        fieldName: "form",
        label: "형식",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true,
        initialWidth: 180
    },
    {
        type: "text",
        fieldName: "mngNo",
        label: "제원관리번호(자동차,트랙터)",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true,
        initialWidth: 180
    },
    {
        type: "date",
        fieldName: "typeDateTractor",
        label: "형식승인일자(자동차,트랙터)",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "text",
        fieldName: "capSize",
        label: "캡사이즈",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "text",
        fieldName: "modelYear",
        label: "연식",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true

    },
    {
        type: "text",
        fieldName: "totalWeight",
        label: "총중량",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true,
        initialWidth: 150
    },
    {
        type: "text",
        fieldName: "maxLoad",
        label: "최대적재량",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "text",
        fieldName: "color",
        label: "색상",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "text",
        fieldName: "engineType",
        label: "원동기형식",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true,
        initialWidth: 100
    },
    {
        type: "text",
        fieldName: "remark",
        label: "특이사항1",
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "text",
        fieldName: "remark2",
        label: "특이사항2",
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "text",
        fieldName: "remark3",
        label: "특이사항3",
        hideDefaultActions: true,
        wrapText: true
    }
];

const typeNoColumns = [
    {
        type: "text",
        fieldName: "form",
        label: "형식",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true,
        initialWidth: 180
    },
    {
        type: "text",
        fieldName: "vehicleName",
        label: "건설기계명",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true,
        initialWidth: 180
    },
    {
        type: "text",
        fieldName: "stdLoad",
        label: "규격(건설기계)",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "text",
        fieldName: "typeNo",
        label: "형식승인번호(덤프,건설기계)",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "date",
        fieldName: "typeDate",
        label: "형식승인일자(덤프,건설기계)",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true,
        initialWidth: 100
    },
    {
        type: "text",
        fieldName: "capSize",
        label: "캡사이즈",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "text",
        fieldName: "modelYear",
        label: "연식",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "text",
        fieldName: "totalWeight",
        label: "총중량",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true,
        initialWidth: 150

    },
    {
        type: "text",
        fieldName: "maxLoad",
        label: "최대적재량",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "text",
        fieldName: "color",
        label: "색상",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "text",
        fieldName: "engineType",
        label: "원동기형식",
        sortable: true,
        hideDefaultActions: true,
        wrapText: true,
        initialWidth: 120
    },
    {
        type: "text",
        fieldName: "remark",
        label: "특이사항1",
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "text",
        fieldName: "remark2",
        label: "특이사항2",
        hideDefaultActions: true,
        wrapText: true
    },
    {
        type: "text",
        fieldName: "remark3",
        label: "특이사항3",
        hideDefaultActions: true,
        wrapText: true
    }
];

export { mngNoColumns,typeNoColumns };