/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-22      payo03@solomontech.net           Created
*/
import { LightningElement, track, api } from 'lwc';

// Util
import { showToast } from "c/commonUtil";

export default class pdiStepView extends LightningElement {
    @track varStepList = 'specific';
    @track varIsBulk;

    @track steps = [
        {
            name: 'Step1',
            label: '1',
            short: '입고점검',
            long: '항구도착 -> 입고',
            variant: 'neutral',
            completed: false
        },
        {
            name: 'Step2',
            label: '2',
            short: '기본작업',
            long: '판매준비완료',
            variant: 'neutral',
            completed: false
        },
        {
            name: 'Step3',
            label: '3',
            short: '차량배정',
            long: '배정 확인 및 수동 변경',
            variant: 'neutral',
            completed: false
        },
        {
            name: 'Step4',
            label: '4',
            short: '옵션장착',
            long: '스포일러 장착 확인',
            variant: 'neutral',
            completed: false
        },
        {
            name: 'Step5',
            label: '5',
            short: '최종점검',
            long: '출고준비완료',
            variant: 'neutral',
            completed: false
        }
    ]

    handleButtonClick(event) {
        const stepName = event.currentTarget.dataset.name;
        const stepObj = this.steps.find(s => s.name === stepName);

        const customEvent = new CustomEvent('stepchange', {
            detail: {
                value: stepName,
                variant: stepObj.variant
            }
        });
        this.dispatchEvent(customEvent);
    }

    // Step1 ~ 5 Button Action
    @api
    set stepList(value) {
        if(value) {
            console.log('PDI StepView. StepList : ' + JSON.stringify(value));
            this.varStepList = value;
            this.steps = this.steps.map(step => {
                let record = value.find(item => item.Stage__c === step.name.toUpperCase());

                return {
                    ...step,
                    completed: record?.IsPass__c
                };
            });
        }
    }
    get stepList() {
        return this.varStepList;
    }

    // Step1 Button Action
    @api
    set isBulk(value) {
        console.log('PDI StepView. isBulk : ' + value);
        this.varIsBulk = value;

        if(this.varIsBulk) {
            this.steps = this.steps.map(step => {
                if (['Step3', 'Step4'].includes(step.name)) {
                    return { ...step, variant: 'destructive', completed: false };
                } else {
                    return { ...step, variant: 'neutral', completed: false };
                }
            });
        } else {
            this.steps = this.steps.map(step => {
                return { ...step, variant: 'neutral', completed: false };
            });
        }
    }
    get isBulk() {
        return this.varIsBulk;
    }

    get overallProgress() {
        let requiredSteps = this.steps.filter(s => s.variant !== 'destructive');
        let completed = this.steps.filter(s => s.completed && s.variant !== 'destructive').length;
        return Math.round((completed / requiredSteps.length) * 100);
    }

    get progressBarStyle() {
        return `width: ${this.overallProgress}%;`;
    }
}