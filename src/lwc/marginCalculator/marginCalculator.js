/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2025-03-12      jh.jung           Created
 */
import {LightningElement, wire, track} from 'lwc';
import { showToast } from "c/commonUtil";
import {columns, simulationColumns} from "./marginCalculatorColumns";
import COMMISSION_RATE from "@salesforce/label/c.CommissionRate"
import NDDR_RATE from "@salesforce/label/c.NDDRRate"

import getInit from "@salesforce/apex/MarginCalculatorController.getInit";

export default class MarginCalculator extends LightningElement {

  // git test message

  columns = columns;
  simulationColumns = simulationColumns;

  isModalOpen = false;
  isLoading = false;
  productConfigData = [];

  selectedRowList = [];
  selectedRowIdList = [];

  @track simulationTransposeData = [];
  draftValues = [];

  connectedCallback() {
    console.log('connectedCallback :::')
    let styleEl = document.querySelector(".margin-calculator-simulation-custom-style");
    // 첫 로드 시
    console.log('styleEl :::' + styleEl)
    if (!styleEl) {
      styleEl = document.createElement("style");
      styleEl.className = "margin-calculator-simulation-custom-style";
      // 테이블 버튼 넓이 조정
      styleEl.innerText = `
        .no-edit .slds-cell-edit__button {
          visibility: hidden;
        }
      `;
      // 추후 추가
      // .simulation-table .slds-row-number {
      //   visibility: hidden;
      // }

      console.log('styleEl :::' + styleEl)
      console.log('styleEl.className :::' + styleEl.className)
      console.log('styleEl.innerText :::' + styleEl.innerText)
      document.body.appendChild(styleEl);
    }
  }

  @wire(getInit)
  wiredProductConfigData({ error, data }) {
    if (data) {
      // 데이터 가공하여 테이블 형식으로 변환
      console.log('data ::: ' + JSON.stringify(data))
      this.productConfigData = Object.keys(data).map(key => {
        // const productObj = data[productId];
        const productObj = data[key];
        const product = productObj.product;
        const config = productObj.config;
        let meanBuyingPrice = (product.VehicleStock__r || [])
          .reduce((sum, r, _, arr) => sum + (r.AvisOrderInfo__r?.BuyingPrice__c || 0) / arr.length, 0);
        meanBuyingPrice = Math.round(meanBuyingPrice * 1500);
        // TODO: 추가로 필요한 데이터 있으면 불러오기
        return {
          // id: productId,
          id: key,
          productName: product.Name,
          isOTV: product.IsOTV__c ? 'Y' : 'N',
          isLNS: product.IsLNS__c ? 'Y' : 'N',
          isPremium: (product.TrimLevel__c === '1') ? 'Y' : 'N',
          reportSpec: product.VehicleCategory__r?.Name,
          emissionLevel: product.EmissionLevel__c,
          localTotal: parseInt(config?.LocalCostAvg__c || 0) + parseInt(config?.PdiCostAvg__c || 0) + parseInt(config?.OtherCostAvg__c || 0),
          localCost: Number(config?.LocalCostAvg__c || 0).toLocaleString(),
          pdiCost: Number(config?.PdiCostAvg__c || 0).toLocaleString(),
          otherCost: Number(config?.OtherCostAvg__c || 0).toLocaleString(),
          purchaseInvoicePrice: meanBuyingPrice.toLocaleString(),
          oilCoupon: product.SalesConditionMaster__r?.Discount__c || 0,
          saCommission: COMMISSION_RATE,
          nddr: NDDR_RATE,
          campaign: 0,
          var: 0,
          costComponents: Math.round((Number(COMMISSION_RATE) + Number(NDDR_RATE) + Number(product.SalesConditionMaster__r?.Discount__c || 0))*10)/10,
          listPrice: product.CarAmt__c,
          listPriceVat: Math.round(parseInt(product.CarAmt__c)*10/11),
        };
      });
      console.log('this.productConfigData ::: ' + this.productConfigData);
    } else if (error) {
      console.error(error.message);
    }
  }

  // record를 column으로 변경 class로 edit 컨트롤
  get dynamicColumns() {
    let dynamicColumns = [
      { label: '', fieldName: 'fieldLabel', type: 'text', hideDefaultActions: true }
    ];

    console.log('selectedRowList :: ', JSON.stringify(this.selectedRowList, null, 4));
    this.selectedRowList.forEach((record, index) => {

      dynamicColumns.push({
        label: record.productName,
        fieldName: record.productName,
        type: 'text',
        hideDefaultActions: true,
        editable: true,
        cellAttributes: {
          class: {fieldName: `${record.productName}_class`}
        }
      });
    });
    console.log('dynamicColumns :: ', JSON.stringify(dynamicColumns, null, 4));

    return dynamicColumns;
  }

  // 시뮬레이션 테이블에 들어갈 데이터
  // get transposedData() {
  transposedData() {

    let returnTransposeData = [];

    this.simulationColumns.map(field => {
      let rowData = {
        fieldLabel: field.label,
        fieldName: field.fieldName,
        editable: field.editable,
      };

      // selectedRowList 돌면서 rowData에 쌓기
      this.selectedRowList.forEach((record, index) => {

        // productName을 key로 하는 value
        rowData[record.productName] = record[field.fieldName];

        // 속성 주입
        rowData[`${record.productName}_class`] = field.editable ? '' : 'no-edit';
      });

      returnTransposeData.push(rowData);
    });

    console.log('returnTransposeData ::: ' + JSON.stringify(returnTransposeData));

    this.simulationTransposeData = returnTransposeData;
    // return returnTransposeData;
  }

  handleCellChange(e) {
    const draftValues = e.detail.draftValues; // 변경된 값 목록
    console.log('Cell changed:', JSON.stringify(draftValues));

    // 기존 데이터를 복사해서 수정된 값 반영
    this.simulationTransposeData = this.simulationTransposeData.map(row => {
      const updatedRow = draftValues.find(item => item.fieldLabel === row.fieldLabel);
      return updatedRow ? { ...row, ...updatedRow } : row;
    });

    console.log('this.simulationTransposeData ::: ' + JSON.stringify(this.simulationTransposeData))

    const costRows = {
      localCost: this.simulationTransposeData.find(row => row.fieldName === 'localCost'),
      pdiCost: this.simulationTransposeData.find(row => row.fieldName === 'pdiCost'),
      otherCost: this.simulationTransposeData.find(row => row.fieldName === 'otherCost')
    };

    this.simulationTransposeData.forEach((row) => {
      // 'localTotal'만 업데이트 하도록
      if (row.fieldName === "localTotal") {
        let newTotal = 0;

        // 각 TGL 항목에 대해 합산
        for (const key in row) {
          if (key !== 'fieldLabel' && key !== 'fieldName' && key !== 'editable' && !key.endsWith('_class')) {
            const localCost = parseInt(costRows.localCost[key] || 0);  // 1) Local installation
            const pdiCost = parseInt(costRows.pdiCost[key] || 0);  // 2) PDI cost
            const otherCost = parseInt(costRows.otherCost[key] || 0);  // 3) Others
            newTotal += localCost + pdiCost + otherCost;

            // 계산된 합을 localTotal 값에 업데이트
            row[key] = newTotal.toString();  // 새로운 합을 localTotal 필드에 저장
          }
        }
      }
    });

    console.log('this.simulationTransposeData ::: ' + JSON.stringify(this.simulationTransposeData))
  }

  // 저장시 데이터 보내서 저장?
  handleSave() {
    console.log('handleSave :::')
    // console.log(this.transposedData());
  }
  handleCancel() {
    console.log('handleCancel :::')
    this.transposedData()
  }

  handleHeaderClick(e) {

    const name = e.target.dataset.name;
    if(this.selectedRowIdList.length === 0) {
      showToast('시뮬레이션 실패', 'Product를 선택해주세요', 'warning');
      return;
    }
    this.toggleModal();
  }

  handleSelection(e) {
    console.log('handleSelection ::: ' + e.detail.selectedRows)
    this.selectedRowList = e.detail.selectedRows;
    this.selectedRowIdList = this.selectedRowList.map(row => row.id);
  }

  toggleModal() {
    this.isModalOpen = !this.isModalOpen;
    if(this.isModalOpen) {
      this.transposedData()
    }
  }
}