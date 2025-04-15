/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-06
 * @description : Account 오브젝트 주민번호 필드 유효성 검사
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-06        San.Kang           Created
**************************************************************/
public without sharing class Account_tr extends TriggerHandler {

    // 깃테스트

    /** TriggerHandler */
    private final List<Account> newList { get; set; }
    private final List<Account> oldList { get; set; }
    private final Map<Id, Account> oldMap { get; set; }
    private final Map<Id, Account> newMap { get; set; }

    public Account_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        oldMap = (Map<Id, Account>) Trigger.oldMap;
        newMap = (Map<Id, Account>) Trigger.newMap;
    }

    public override void beforeInsert() {

    }

    public override void beforeUpdate() {
        identificationValidate();
    }

    public override void afterInsert() {

    }

    public override void afterUpdate() {
    }

    private void identificationValidate(){
        try{
            for(Id accountId : newMap.keySet()){
                if (oldMap.get(accountId).IDNumber__pc != newMap.get(accountId).IDNumber__pc && newMap.get(accountId).IDNumber__pc != null) {
                    // 1. 주민번호에서 '-' 제거
                    String idStr = newMap.get(accountId).IDNumber__pc.replace('-', '');

                    // 2. 길이가 13자리가 아니면 오류 처리
                    if (idStr.length() != 13 || !Pattern.matches('\\d{13}', idStr)) {
                        newMap.get(accountId).addError('유효한 주민번호가 아닙니다.');
                        return;
                    }

                    // 3. 가중치 리스트 (2,3,4,5,6,7,8,9,2,3,4,5)
                    List<Integer> weights = new List<Integer>{2, 3, 4, 5, 6, 7, 8, 9, 2, 3, 4, 5};

                    // 4. 합계 계산 (각 자리 숫자 * 가중치)
                    Integer sum = 0;
                    for (Integer i = 0; i < 12; i++) {
                        sum += Integer.valueOf(idStr.substring(i, i + 1)) * weights[i];
                    }

                    // 5. 검증번호 계산
                    Integer checkNum = 11 - Math.mod(sum, 11);
                    if (checkNum == 10) checkNum = 0;
                    if (checkNum == 11) checkNum = 1;

                    // 6. 입력된 주민번호의 마지막 자리(검증번호)와 비교
                    Integer lastDigit = Integer.valueOf(idStr.substring(12, 13));
                    if (checkNum != lastDigit) {
                        newMap.get(accountId).addError('유효한 주민번호가 아닙니다.');
                    }
                }

            }
        } catch (Exception e){
            System.debug('msg >> '+e.getMessage() + ' getStackTraceString >>' + e.getStackTraceString());
        }
    }
}