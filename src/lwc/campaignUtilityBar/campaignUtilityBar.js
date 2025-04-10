/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author                           Modification
 ===================================================================================
 1.0      2024-11-21      jh.jung           Created
 */
import {LightningElement} from 'lwc';

import getCampaignList from "@salesforce/apex/CampaignUtilityBarController.getCampaignList";
export default class CampaignUtilityBar extends LightningElement {

  campaignData = [];

  connectedCallback() {
    getCampaignList().then(res => {
      this.campaignData = res;
      res.forEach((cam) => {
        cam.url = '/lightning/r/CampaignMaster__c/' + cam.Id + '/view';
      })
    }).catch(err => {
      console.log("err ::: ", err);
    });
  }
}