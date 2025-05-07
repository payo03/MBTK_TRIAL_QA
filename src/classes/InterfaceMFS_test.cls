/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-04-29      payo03@solomontech.net           Created
*/
@IsTest
public class InterfaceMFS_test {

    @TestSetup
    static void setup() {
        TestObjectBuilder2.createIfBundle();
        TestObjectBuilder2.createOrderBundle();
    }

    @IsTest
    static void testBehavior() {
        InterfaceMFS.doHealthCheck();

        AvisOrderInfo__c info = [SELECT Id FROM AvisOrderInfo__c LIMIT 1];
        Map<String, String> keyMap = new Map<String, String>{
                info.Id => info.Id
        };

        Map<String, Object> infoMap = new Map<String, Object>();
        infoMap.put('ifId', InterfaceMFS.IF_MFS001);
        infoMap.put('logId', CommonUtilCustomController.parseIFId(InterfaceSAP.DFLT));
        infoMap.put('logType', 'TEST');
        infoMap.put('keyMap', keyMap);
        infoMap.put('items', new List<Object>{});
        infoMap.put('isLogDetail', true);
        Map<String, Object> logMap = InterfaceMFS.doCallOutMFSLog(infoMap);
    }
}