/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2024-12-05      jh.jung           Created
 */
import {LightningElement, track} from 'lwc';
import getDashboardData from '@salesforce/apex/LeadManagementController.getDashboardData';

export default class LeadDashboard extends LightningElement {
  @track leadData = {
    openLeads: 0,
    convertedLeads: 0,
    highTempRate: 0,
    conversionRate: 0
  };

  connectedCallback() {
    this.loadLeadsData();
  }

  loadLeadsData() {
    getDashboardData()
      .then((result) => {
        const { openLeads, convertedLeads, highTempLeads, totalLeads } = result;
        const conversionRate = totalLeads > 0 ? ((convertedLeads / totalLeads) * 100).toFixed(2) : 0;
        const highTempRate = totalLeads > 0 ? ((highTempLeads / totalLeads) * 100).toFixed(2) : 0;

        this.leadData = {
          openLeads,
          convertedLeads,
          highTempRate,
          conversionRate
        };

        console.log('leadData ::: ' + JSON.stringify(this.leadData))
      })
      .catch((error) => {
        console.error('Error fetching lead data', error);
      });
  }
}