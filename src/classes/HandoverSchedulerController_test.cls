/*************************************************************
 * @author : th.kim
 * @date : 2025-02-21
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-02-21      th.kim          Created
**************************************************************/
@IsTest
private class HandoverSchedulerController_test {

    //todo : 테스트 실행시 CommissionHistory_tr.setFieldDataForRollUp: line 78 에서 에러 발생(Attempt to de-reference a null object)
    static final Handover__c handover;
    static final Handover__c newHandover;
    static final Product2 product;

    static {
        // TestObjectBuilder.createObjects();
        // TestObjectBuilder2.createContractBundle2();
        Contract contract = TestObjectBuilder2.createContract();
        insert contract;
        Opportunity opportunity = TestObjectBuilder2.createOpportunity();
        Quote quote = TestObjectBuilder2.createQuote();
        List<SObject> SObjectList = new List<SObject>();
        opportunity.ContractId = contract.Id;
        quote.ContractId = contract.Id;
        SObjectList.add(opportunity);
        SObjectList.add(quote);
        update SObjectList;
        insert TestObjectBuilder2.createPDIStep();
        insert TestObjectBuilder2.createHandover();
        handover = TestObjectBuilder2.createHandover();
        product = TestObjectBuilder2.createProduct();
        newHandover = [
            SELECT Id, Opportunity__c, fm_VehicleStock__c, Opportunity__r.Name, Opportunity__r.OwnerId,
                Opportunity__r.ContractId, Opportunity__r.VehicleStock__r.Name
            FROM Handover__c
            WHERE Id = :handover.Id
        ];
    }

    @IsTest
    static void testGetFilteredHandoverList() {
        Test.startTest();
        HandoverSchedulerController.getFilteredHandoverList(null);
        Test.stopTest();
    }

    @IsTest
    static void testUpdateCheckHandoverList() {
        Test.startTest();
        HandoverSchedulerController.updateCheckHandoverList(new List<String>{
            handover.Id
        });
        Test.stopTest();
    }

    @IsTest
    static void testDoCompleteHandover() {
        Test.startTest();
        HandoverSchedulerController.doCompleteHandover(new List<Map<String, String>>{
            new Map<String, String>{
                'opportunityId' => newHandover.Opportunity__c,
                'stockId' => newHandover.fm_VehicleStock__c
            }
        });
        Test.stopTest();
    }

    @IsTest
    static void testUpdateHandoverStock() {
        Test.startTest();

        SchedulerMainController.HandoverWrap handoverWrap = HandoverSchedulerController.getFilteredHandoverList(null).get(0);
        System.debug('handoverWrap :: ' + handoverWrap);
        VehicleStock__c vehicleStock = new VehicleStock__c(
            Name = 'Test',
            Product__c = handoverWrap.vehicleStock.Product__c
        );
        insert vehicleStock;

        Map<String, String> dataMap = new Map<String, String>{
            'stockId' => newHandover.fm_VehicleStock__c,
            'opportunityId' => newHandover.Opportunity__r.Id,
            'oppName' => newHandover.Opportunity__r.Name,
            'ownerId' => newHandover.Opportunity__r.OwnerId,
            'contractId' => newHandover.Opportunity__r.ContractId,
            'previousVIN' => newHandover.Opportunity__r.VehicleStock__r.Name,
            'currentVIN' => null
        };

        HandoverSchedulerController.updateHandoverStock(dataMap);

        Test.stopTest();
    }

    @IsTest
    static void testUpdateHandoverStock2() {
        Test.startTest();

        SchedulerMainController.HandoverWrap handoverWrap = HandoverSchedulerController.getFilteredHandoverList(null).get(0);
        System.debug('handoverWrap :: ' + handoverWrap);
        VehicleStock__c vehicleStock = new VehicleStock__c(
            Name = 'Test',
            Product__c = handoverWrap.vehicleStock.Product__c
        );
        insert vehicleStock;

        Map<String, String> dataMap = new Map<String, String>{
            'stockId' => newHandover.fm_VehicleStock__c,
            'opportunityId' => newHandover.Opportunity__r.Id,
            'oppName' => newHandover.Opportunity__r.Name,
            'ownerId' => newHandover.Opportunity__r.OwnerId,
            'contractId' => newHandover.Opportunity__r.ContractId,
            'previousVIN' => 'Test',
            'currentVIN' => newHandover.Opportunity__r.VehicleStock__r.Name
        };

        HandoverSchedulerController.updateHandoverStock(dataMap);

        Test.stopTest();
    }

    @IsTest
    static void testGetVehicleStockList() {
        Test.startTest();
        HandoverSchedulerController.getVehicleStockList(new Map<String, String>{
            'Product__c' => product.Id
        });
        Test.stopTest();
    }
}