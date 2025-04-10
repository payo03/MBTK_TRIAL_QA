/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-27
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-27        San.Kang           Created
**************************************************************/
@IsTest
private class ImportSpecTypeController_test {
    static final SpecTypeNo__c specTypeNo = TestObjectBuilder.createSpecTypeNo();
    static final List<Map<String, String>> excelList = new List<Map<String, String>>{
            new Map<String, String>{
                    'SCNTAN__c' => '016-1-11111-1111-1111',
                    'ApprovalDate__c' => '2024-07-10',
                    'Type__c' => 'TGS 41.520 8X4 BB CH KCT',
                    'SCAR__c' => 'TG3 유로6e 덤프트럭',
                    'AsbestosBrake__c' => '',
                    'RPS__c' => '',
                    'BMSCN__c' => '',
                    'SD__c' => '',
                    'OCMN__c' => '',
                    'MN__c' => '',
                    'OMN__c' => '',
                    'COM__c' => '',
                    'VehicleName__c' => '',
                    'SAD__c' => '',
                    'TypeName__c' => '',
                    'FABS__c' => '',
                    'PC__c' => '',
                    'SeatingCapacity__c' => '',
                    'StandingCapacity__c' => '',
                    'EngineType__c' => 'D2676LFAX',
                    'EngineNetPower__c' => '520/1800rpm'
            }
    };

    static{
        insert specTypeNo;
    }
    @IsTest
    static void testBehavior() {
        Test.startTest();
        ImportSpecTypeController.importExcelData(excelList);
        Test.stopTest();
    }

}