/*************************************************************
 * @author : San.Kang
 * @date : 25. 2. 20.
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       25. 2. 20.        San.Kang           Created
**************************************************************/
import { LightningElement,track, wire, api } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { CurrentPageReference } from 'lightning/navigation';
import formFactorPropertyName from '@salesforce/client/formFactor';
import { recordNavigation, showToast } from "c/commonUtil";
import { NavigationMixin } from "lightning/navigation";


export default class signPDF extends NavigationMixin(LightningElement) {
    @api recordId;
    canvas;
    context;
    isMouseDown = false;
    isMouseMove = false;
    isMouseUp = false;
    disableSave = true;
    isSignModal = false;
    empty = true;
    calculate = false;
    pixels = [];
    xyLast = {};
    xyAddLast = {};
    clickedDoc;

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state) {
            if(formFactorPropertyName === 'Large'){
				this.recordId = 'a0IH2000004uWdu';
            } else {
                this.recordId = pageRef.state.c__recordId;
            }
        }
    }

    renderedCallback() {
        if (!this.canvas) {
            this.canvas = this.template.querySelector('.newSignature');
            if (this.canvas) {
                this.initializeCanvas();
            }
        }
    }
    initializeCanvas() {
        // 캔버스 크기는 모달 영역에 맞게 지정(모바일 친화적)
        this.canvas.width = 1050;
        this.canvas.height = 540;
        this.context = this.canvas.getContext('2d');
        this.context.fillStyle = "#ffffff";
        this.context.strokeStyle = "#444";
        this.context.lineWidth = 4.0;
        this.context.lineCap = "round";
        this.context.fillRect(0, 0, this.canvas.width, this.canvas.height);
        this.context.translate(20, 0);

        this.canvas.addEventListener('mousedown', this.onMouseDown.bind(this));
        this.canvas.addEventListener('touchstart', this.onMouseDown.bind(this));
    }

    removeEventListeners() {
        this.canvas.removeEventListener('mousemove', this.onMouseMoveBound);
        this.canvas.removeEventListener('mouseup', this.onMouseUpBound);
        this.canvas.removeEventListener('touchmove', this.onMouseMoveBound);
        this.canvas.removeEventListener('touchend', this.onMouseUpBound);
        document.body.removeEventListener('mouseup', this.onMouseUpBound);
        document.body.removeEventListener('touchend', this.onMouseUpBound);
    }

    getCoords(e) {
        let x, y;
        if (e.changedTouches && e.changedTouches[0]) {
            const rect = this.canvas.getBoundingClientRect();
            x = e.changedTouches[0].clientX - rect.left;
            y = e.changedTouches[0].clientY - rect.top;
        } else {
            x = e.offsetX;
            y = e.offsetY;
        }
        return { x, y };
    }

    onMouseDown(e) {
        e.preventDefault();
        e.stopPropagation();
        this.onMouseMoveBound = this.onMouseMove.bind(this);
        this.onMouseUpBound = this.onMouseUp.bind(this);

        this.canvas.addEventListener('mousemove', this.onMouseMoveBound);
        this.canvas.addEventListener('mouseup', this.onMouseUpBound);
        this.canvas.addEventListener('touchmove', this.onMouseMoveBound);
        this.canvas.addEventListener('touchend', this.onMouseUpBound);
        document.body.addEventListener('mouseup', this.onMouseUpBound);
        document.body.addEventListener('touchend', this.onMouseUpBound);

        this.empty = false;
        const xy = this.getCoords(e);
        this.context.beginPath();
        this.pixels.push('moveStart');
        this.context.moveTo(xy.x, xy.y);
        this.pixels.push(xy.x, xy.y);
        this.xyLast = xy;
        this.isMouseDown = true;
    }

    onMouseMove(e) {
        e.preventDefault();
        e.stopPropagation();

        const xy = this.getCoords(e);
        const xyAdd = {
            x: (this.xyLast.x + xy.x) / 2,
            y: (this.xyLast.y + xy.y) / 2
        };

        if (this.calculate) {
            const xLast = (this.xyAddLast.x + this.xyLast.x + xyAdd.x) / 3;
            const yLast = (this.xyAddLast.y + this.xyLast.y + xyAdd.y) / 3;
            this.pixels.push(xLast, yLast);
        } else {
            this.calculate = true;
        }

        this.context.quadraticCurveTo(this.xyLast.x, this.xyLast.y, xyAdd.x, xyAdd.y);
        this.pixels.push(xyAdd.x, xyAdd.y);
        this.context.stroke();
        this.context.beginPath();
        this.context.moveTo(xyAdd.x, xyAdd.y);
        this.xyAddLast = xyAdd;
        this.xyLast = xy;
        this.isMouseMove = true;
    }

    onMouseUp(e) {
        this.removeEventListeners();
        this.disableSave = false;
        this.context.stroke();
        this.pixels.push('e');
        this.calculate = false;
        this.isMouseUp = true;
    }

    signatureSave() {
        console.log(this.recordId);
        const signatureEl = this.template.querySelector("c-signature-pad");
        const result = signatureEl.doSave(this.recordId, this.clickedDoc);
        if (result) {
            if (formFactorPropertyName === "Large") {
                this.dispatchEvent(new CloseActionScreenEvent());
            } else {
                recordNavigation(this, "VehicleStock__c", this.recordId);
            }
        }
    }

    closeModal(){
        this.isSignModal = !this.isSignModal;
    }

    signatureClear() {
        const signatureEl = this.template.querySelector("c-signature-pad");
        signatureEl.doErase();
    }

    handleCancel() {
            if (formFactorPropertyName === "Large") {
                this.dispatchEvent(new CloseActionScreenEvent());
            } else {
                recordNavigation(this, "VehicleStock__c", this.recordId);
            }
            return;
    }
}