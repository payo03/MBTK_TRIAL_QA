/*************************************************************
 * @author : San.Kang
 * @date : 2025-01-10
 * @description : 요청날짜가 업데이트된 레코드를 7일후 플로에서 Apex를 호출 해 알림톡 발송
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-01-10        San.Kang           Created
**************************************************************/
public without sharing class DepositRequestAlimtalk {

    @InvocableMethod(label='DepositRequestAlimtalk' description='DepositRequestAlimtalk')
    public static void PreAssignRequestAlimtalk(List<String> AccountId) {
        System.debug('acctest::'+AccountId);
        try{
            VirtualAccount__c VAObj = [SELECT Id, Account__c, Account__r.Owner.MobilePhone
                                    FROM VirtualAccount__c
                                    WHERE Account__c =:AccountId[0]];

            List<Map<Object, Object>> infoMapList = new List<Map<Object, Object>>{
                    new Map<Object, Object>{
                            'objectName' => 'Account',
                            'recordId' => VAObj.Account__c
                    }
            };

            Map<Object, Object> buttonMap = new Map<Object, Object>{
                    'Webbutton' => ''
            };

            Map<String, Object> InfoMap = new Map<String, Object>{
                    'templateTitle' => 'Deposit 미입금 알림톡',
                    'object' => 'VirtualAccount__c',
                    'whereField' => 'Account__c',
                    'recordId' => VAObj.Account__c,
                    'externalId' => VAObj.Id,
                    'buttonMap' => buttonMap,
                    'infoMapList' => infoMapList
            };

            if(!test.isRunningTest()){
                InterfaceKakao.doCallOutKakaoAlimTalk(InfoMap);
            }

        }catch (Exception e){
            System.debug('err=>'+e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
}