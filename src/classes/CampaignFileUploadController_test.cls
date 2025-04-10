/*************************************************************
 * @author : tw.Choi
 * @date : 2025-01-21
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-21      tw.Choi          Created
**************************************************************/

@isTest
private class CampaignFileUploadController_test {

    static final CampaignJunction__c campaignJunction;
    static final Account accountPerson;
    static final Account accountCompany;
    static final CampaignMaster__c amtCampaign;
    static final VehicleStock__c vehicleStock;

    static {
        TestObjectBuilder.createObjects();
        accountPerson = TestObjectBuilder.accountPerson;
        accountCompany = TestObjectBuilder.accountCompany;
        campaignJunction = TestObjectBuilder.campaignJunction;
        amtCampaign = TestObjectBuilder.amtCampaign;
        vehicleStock = TestObjectBuilder.vehicleStock;
    }


    @isTest
    static void testAccountFileUpload() {

        Test.startTest();

        String csvData = 'AccountId\n' + accountPerson.Id + '\n' + accountCompany.Id;
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf(csvData));

        CampaignFileUploadController.accountFileUpload(base64Data, amtCampaign.Id);

        Test.stopTest();
    }

    @isTest
    static void testStockUploadedFile() {

        Test.startTest();

        String csvData = 'StockId\n' + vehicleStock.Id + '\n' + vehicleStock.Id;
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf(csvData));

        CampaignFileUploadController.stockUploadedFile(base64Data, amtCampaign.Id);

        Test.stopTest();
    }
}