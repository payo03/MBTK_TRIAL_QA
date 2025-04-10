import LightningDatatable from 'lightning/datatable';
import customPickList from './customPickList.html';

export default class DatatablePicklist extends LightningDatatable {

    connectedCallback() {
        console.log('CustomPicklist Initialized');
    }

    static customTypes = {
        customPicklist: {
            template: customPickList,
            standardCellLayout: true,
            typeAttributes: [
                'placeholder',
                'options',
                'value',
                'context'
            ]
        }
    }

    /*
    customHandleCellChange(event) {
        console.log('########### Here ###########');
        // 선택된 값을 감지
        let selectedValue = event.detail.value;

        // 변경된 값을 부모 컴포넌트로 전달
        this.dispatchEvent(
            new CustomEvent('cellchange', {
                detail: {
                    value: selectedValue, // 변경된 값 전달
                    context: this.typeAttributes.context
                },
                bubbles: true, // 이벤트를 Datatable로 전달
                composed: true
            })
        );
    }
    */
}