/*************************************************************
 * @author : th.kim
 * @description : 
 * @target : 
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-26      th.kim          Created
**************************************************************/
@IsTest
private class VehicleStock_tr_test {

    @IsTest
    static void doTest() {
        Test.startTest();

        Contract contract = TestObjectBuilder.createContract();
        insert contract;

        Opportunity opportunity = TestObjectBuilder.createOpportunity();
        opportunity.ContractId = contract.Id;
        update opportunity;

        VehicleStock__c stock = TestObjectBuilder.createVehicleStock();

        stock.Status__c = '재고 미노출(임시)';
        update stock;

        stock.Status__c = '60일 재고';
        update stock;

        stock.Status__c = '30일 재고';
        update stock;

        stock.Status__c = '재고 노출';
        update stock;

        stock.Status__c = '판매완료';
        stock.VehicleStatus__c = '출고됨';
        update stock;

        stock.Status__c = '재고 미노출(임시)';
        stock.VehicleStatus__c = '출고불가';
        update stock;

        stock.Product__c = null;
        update stock;

        Test.stopTest();
    }
}