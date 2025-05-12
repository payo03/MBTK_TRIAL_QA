/**
* @Author            : payo03@solomontech.net
* @Description 		 :
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-05-12      payo03@solomontech.net           Created
*/
import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";

export default class commonVfPopup extends LightningElement {
    @api isOpen = false;
    @api vfPageUrl = '';
    @api header = 'Common';
    @api button = '확인';

    @api popupWidth = '1200px';
    @api popupHeight = '80vh';

 	handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleButton() {
        this.dispatchEvent(new CustomEvent('action'));
    }

    get containerStyle() {
        return `width: ${this.popupWidth};`;
    }

    get iframeStyle() {
        return `
            width: 100%;
            height: ${this.popupHeight};
            border: none;
            overflow: auto;
        `;
    }
}
