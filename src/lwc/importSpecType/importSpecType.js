/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-11
 * @description :
 * @target :
 ==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-11        San.Kang           Created
 **************************************************************/
import { LightningElement, track } from 'lwc';

import importExcelData from "@salesforce/apex/ImportSpecTypeController.importExcelData";
import {labelList, showToast} from "c/commonUtil";

const tableColumns = [];
const gridData = [];
const importDataMap = [];
export default class DynamicExcelDatatable extends LightningElement {

    @track excelMap = { tableColumns: tableColumns, gridData: gridData, importDataMap: importDataMap };
    @track successMap = { tableColumns: tableColumns, gridData: gridData };
    @track hasData = false;
    suceessFlag = false;

    handlePaste(event) {
        event.preventDefault();

        const pastedText = (event.clipboardData || window.clipboardData).getData('text');
        if (!pastedText) return;

        // CSV 파싱 (Tab 구분자 + 큰따옴표 처리 포함)
        const rows = this.parseCSV(pastedText, '\t');
        if (!rows || rows.length < 2) return;

        const headers = rows[0];
        const dataRows = rows.slice(1);

        // 컬럼 생성
        this.excelMap.tableColumns = [
            { label: "Index", fieldName: "Index", type: "number", initialWidth: 60 },
            ...headers.map(h => ({
                label: h,
                fieldName: h,
                type: "text",
                hideDefaultActions: true,
                initialWidth: 150
            }))
        ];

        // 데이터 바인딩
        this.excelMap.gridData = dataRows.map((row, idx) => {
            const rowData = { id: `row-${idx}`, Index: idx + 1 };
            headers.forEach((h, i) => {
                rowData[h] = row[i] ?? '';
            });
            return rowData;
        });

        this.hasData = true;
    }


    parseCSV(text, delimiter = '\t') {
        const pattern = new RegExp(
            (
                // Delimiters.
                "(\\" + delimiter + "|\\r?\\n|\\r|^)" +
                // Quoted fields.
                "(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" +
                // Standard fields.
                "([^\"\\" + delimiter + "\\r\\n]*))"
            ),
            "gi"
        );

        const data = [[]];
        let matches = null;

        while ((matches = pattern.exec(text))) {
            const matchedDelimiter = matches[1];
            if (
                matchedDelimiter.length &&
                matchedDelimiter !== delimiter
            ) {
                data.push([]);
            }

            let value;
            if (matches[2] !== undefined) {
                value = matches[2].replace(/""/g, "\"");
            } else {
                value = matches[3];
            }
            data[data.length - 1].push(value);
        }

        return data;
    }

    handleInput(event) {
        event.preventDefault();
    }

    handleReset() {
        this.excelMap.tableColumns = [];
        this.excelMap.gridData = [];
        this.hasData = false;
        this.suceessFlag = false;
    }

    importExcel(){
        if (!this.excelMap?.gridData || this.excelMap.gridData.length === 0) {
            return showToast('', "데이터를 복사 & 붙여넣기 해주세요.", "warning");
        }

// 변경된 데이터를 Apex API로 전달
        importExcelData({ excelList: this.excelMap.gridData }).then(res => {

            let keyOrder = {Id: -1};

            res.forEach(obj => {
                if (!obj) return;

                Object.keys(obj).forEach(key => {
                    if (!(key in keyOrder)) {
                        keyOrder[key] = Object.keys(keyOrder).length;
                    }
                });
            });

            const allKeys = Object.keys(keyOrder).sort((a, b) => keyOrder[a] - keyOrder[b]);

            this.successMap.tableColumns = [
                ...allKeys.map((key) => ({
                    label: key,
                    fieldName: key,
                    type: "text",
                    hideDefaultActions: true,
                    initialWidth: 150
                }))
            ];

            this.successMap.gridData = res.map((item, rowIndex) => {
                let rowData = {
                    id: `row-${rowIndex}`,
                    label: "Success",
                    fieldName: "successIcon",
                    type: "customIcon",
                    initialWidth: 100
                };

                allKeys.forEach((key) => {
                    rowData[key] = item?.[key] ?? ""; // null 또는 undefined면 빈 문자열 처리
                });

                return rowData;
            });

            this.successMap.gridData = [...this.successMap.gridData];

            this.suceessFlag = true;
    }).catch(err => {
            showToast(err?.body?.message || err.message || "ERROR", "", "warning");
        }).finally(() => {
            showToast('데이터가 성공적으로 업데이트 되었습니다.', "", "success");
        });
    }
}