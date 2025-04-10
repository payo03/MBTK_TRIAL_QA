/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-28      payo03@solomontech.net           Created
*/
import { LightningElement } from 'lwc';

export default class customPickList extends LightningElement {

    connectedCallback() {
        console.log('CustomPicklist Initialized');
    }

    /*
    customHandleCellChange(event) {
        console.log('@@@@@@@@@@@ Here @@@@@@@@@@@');
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