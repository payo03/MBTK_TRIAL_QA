/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-13      payo03@solomontech.net           Created
*/
@IsTest
public class InterfaceSAP_test {

    @TestSetup
    static void setup() {
        TestObjectBuilder2.createIfBundle();
        TestObjectBuilder2.createOrderBundle();
    }

    @IsTest
    static void testBehavior() {
        InterfaceSAP.doHealthCheck();
        Map<String, Object> healthCheckMap2 = InterfaceSAP.doCallOutSAP(InterfaceSAP.IF_SMS000, new List<Object>());
        Map<String, Object> stockResultMap2 = InterfaceSAP.doCallOutSAP(InterfaceSAP.IF_SMS004, new List<Object>());

        AvisOrderInfo__c info = [SELECT Id FROM AvisOrderInfo__c LIMIT 1];

        IF_DTO.CommonResult result = new IF_DTO.CommonResult();
        Map<String, String> keyMap = new Map<String, String>{
                info.Id => info.Id
        };
        for(String key : stockResultMap2.keySet()) {
            String code = (String) stockResultMap2.get('Code');
            String message = (String) stockResultMap2.get('Message');
            List<String> resultData = (List<String>) stockResultMap2.get('ResultData');

            result.Code = code;
            result.Message = message;
        }

        Map<String, Object> infoMap = new Map<String, Object>();
        infoMap.put('ifId', InterfaceSAP.IF_SMS004);
        infoMap.put('logId', CommonUtilCustomController.parseIFIdSAP(InterfaceSAP.DFLT));
        infoMap.put('logType', 'ERP_MODEL');
        infoMap.put('keyMap', keyMap);
        infoMap.put('items', new List<Object>{keyMap});
        infoMap.put('isLogDetail', true);
        Map<String, Object> logMap = InterfaceSAP.doCallOutSAPLog(infoMap);
    }
}