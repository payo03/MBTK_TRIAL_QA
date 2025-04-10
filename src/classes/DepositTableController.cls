/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-12
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-12        San.Kang           Created
**************************************************************/
public class DepositTableController {
    public Opportunity opportunity { get; set; }
    public Date depositDT { get; set; }
    public Boolean isNewAddress { get; set; }
    public Document bzIngam { get; set; }
    public DepositTableController() {
    }
    public void init() {
//        opportunity = [SELECT Id, Name, isNewAddress__c, BankPrintYn__c, BankPrintNo__c, Account.Name, Account.CustCodeReadOnly__c, TotTransDeposit__c, TotDivideDeposit__c, totalDepositAmount__c FROM Opportunity WHERE Id = :ApexPages.currentPage().getParameters().get('id') LIMIT 1];
//        List<DepositCondition__c> dc = [SELECT Id, depositDate__c FROM DepositCondition__c WHERE Opportunity__c = :opportunity.Id AND Content__c != '연체이자' ORDER BY depositDate__c DESC];
//        if (!dc.isEmpty()) {
//            depositDT = dc[0].depositDate__c;
//            opportunity.BankPrintNo__c++;
//            //opportunity.BankPrintYn__c=false;
//            update opportunity;
//        }
//        isNewAddress = PDFCommonController.isNewAddress(opportunity.VehicleStock__r.Product__r.ReleaseDate__c);
//        bzIngam = [SELECT Id FROM Document WHERE Name = 'man_bizingam' LIMIT 1];
    }
}