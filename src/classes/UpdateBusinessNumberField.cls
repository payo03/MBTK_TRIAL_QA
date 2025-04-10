/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2024-12-19      jh.jung           Created
*/
public with sharing class UpdateBusinessNumberField {

    private static final String IF_ID = 'API_BIZ_CHK';

    public class InputWrap {
        public List<String> b_no;
        public InputWrap(String bNo) {
            b_no = new List<String>{
                    bNo
            };
        }
    }

    public class OutputWrap {
        public Integer request_cnt;
        public String status_code;
        public List<OutputData> data;
    }

    public class OutputData {
        public String b_no;
        public String b_stt;
        public String b_stt_cd;
        public String tax_type;
        public String end_dt;
        public String utcc_yn;
        public String tax_type_change_dt;
        public String invoice_apply_dt;
    }

    /**
     * @param recordId
     *
     * @return result : bizNum value
     *  fail : Object가 Account, Lead가 아님
     */
    @AuraEnabled
    public static String getBizNum(Id recordId) {
        System.debug('getBizNum ::: ');

        String result;
        String objectType = recordId.getSobjectType().getDescribe().getName();
        if(objectType.equals('Account')) {
            Account accountRecord = [SELECT Id, BusinessNumber__c FROM Account WHERE Id = :recordId LIMIT 1];
            result = accountRecord.BusinessNumber__c;
        } else if(objectType.equals('Lead')) {
            Lead leadRecord = [SELECT Id, BusinessNumber__c FROM Lead WHERE Id = :recordId LIMIT 1];
            result = leadRecord.BusinessNumber__c;
        } else {
            result = 'fail';
        }
        return result;
    }

    /**
     * @param recordId
     * @param bizNum
     *
     * @return result
     *  null : 조회중 에러
     *  N    : 미등록
     *  F    : 휴/폐업
     *  S    : 정상
     *  fail : Object가 Account, Lead가 아님
     */
    @AuraEnabled
    public static String updateBizNum(Id recordId, String bizNum) {
        System.debug('updateBizNum ::: ');

        // objectType ::: Account, Contact, Lead
        String objectType = recordId.getSobjectType().getDescribe().getName();
        Savepoint sp;

        String result = null;
        try {
            result = doCheckBizNum(bizNum);
            sp = Database.setSavepoint();

            // 정상 사업자가 아니면 return
            if(!result.equals('S')) {
                return result;
            }

            String formattedBizNum = formatBusinessNumber(bizNum);

            if(objectType.equals('Account')) {
                Account accountRecord = [SELECT Id, BusinessNumber__c FROM Account WHERE Id = :recordId LIMIT 1];
                accountRecord.BusinessNumber__c = formattedBizNum;
//                update accountRecord;
                CommonUtilController.applyObject(new List<Account> {accountRecord}, 'UPDATE');
            } else if(objectType.equals('Lead')) {
                Lead leadRecord = [SELECT Id, BusinessNumber__c FROM Lead WHERE Id = :recordId LIMIT 1];
                leadRecord.BusinessNumber__c = formattedBizNum;
//                update leadRecord;
                CommonUtilController.applyObject(new List<Lead> {leadRecord}, 'UPDATE');
            } else {
                return 'fail';
            }

        } catch (Exception e) {
            System.debug('e.getMessage() :::' + e.getMessage());
            System.debug('e.getStackTraceString() :::' + e.getStackTraceString());
            Database.rollback(sp);
        }

        return result;
    }

    private static String formatBusinessNumber(String bizNum) {
        String part1 = bizNum.substring(0, 3); // 첫 3자리
        String part2 = bizNum.substring(3, 5); // 다음 2자리
        String part3 = bizNum.substring(5);    // 나머지 5자리

        return part1 + '-' + part2 + '-' + part3;
    }

    private static String doCheckBizNum(String bizNum) {
        System.debug('doCheckBizNum ::: ' +bizNum);

        String result;
        InputWrap inputWrap = new InputWrap(bizNum);

        IF_Util ifUtil = new IF_Util(IF_ID);
        System.debug('JSON.serialize(inputWrap) ::: ' + JSON.serialize(inputWrap));
        HttpResponse res = ifUtil.webCallout(JSON.serialize(inputWrap));

        System.debug('res getBody :: ' + res.getBody());

        OutputWrap outputWrap = (OutputWrap) JSON.deserialize(res.getBody(), OutputWrap.class);
        System.debug('outputWrap :: ' + outputWrap);
        OutputData outputData = outputWrap.data[0];

        // 등록 안됨
        if (String.isBlank(outputData.b_stt_cd)) {
            result = 'N';
        }
        // 휴/폐업
        else if (outputData.b_stt_cd != '01') {
            result = 'F';
        }
        // 정상 사업자
        else {
            result = 'S';

        }
        System.debug('result :: ' + result);

        return result;
    }
}