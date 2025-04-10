/**
* @Author            : payo03@solomontech.net
* @Description 		 : 
* @Target            : InterfaceKakao, IF_Util
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-01-15      payo03@solomontech.net           Created
*/
@IsTest
private class InterfaceKakao_test {
    @TestSetup
    static void setup() {
        TestObjectBuilder2.createIfBundle();

        TestObjectBuilder2.createContractBundle();
    }

    @IsTest
    static void testBehavior() {
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
        APIDocument__c document = [SELECT Id FROM APIDocument__c LIMIT 1];

        Map<Object, Object> infoMapEntry = new Map<Object, Object>();
        infoMapEntry.put('recordId', account.Id);
        Map<Object, Object> infoMapEntry2 = new Map<Object, Object>();
        infoMapEntry2.put('recordId', UserInfo.getUserId());
        List<Map<Object, Object>> infoMapList = new List<Map<Object, Object>>();
        infoMapList.add(infoMapEntry2);
        infoMapList.add(infoMapEntry);
        Map<String, Object> webButton = new Map<String, Object>();
        webButton.put('opportunityId', '00QH2000009q6UpMAI');
        Map<Object, Object> buttonMap = new Map<Object, Object>();
        buttonMap.put('WebButton', webButton);

        Map<String, Object> infoMap = new Map<String, Object>();
        infoMap.put('templateTitle', '카카오톡 샘플_URL');
        infoMap.put('recordId', contract.Id);
        infoMap.put('infoMapList', infoMapList);
        infoMap.put('buttonMap', buttonMap);
        infoMap.put('externalId', document.Id);

        InterfaceKakao.doCallOutKakaoAlimTalk(infoMap);
    }
}