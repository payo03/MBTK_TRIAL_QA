/*************************************************************
 * @author : th.kim
 * @description : 차량 옵션 마스터 트리거 핸들러
 * @target : 
 * @modified log
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-03-26      th.kim          Created
**************************************************************/
public with sharing class VehicleOptionMaster_tr extends TriggerHandler {

    private final List<VehicleOptionMaster__c> newList { get; set; }
    private final List<VehicleOptionMaster__c> oldList { get; set; }
    private final Map<Id, VehicleOptionMaster__c> oldMap { get; set; }
    private final Map<Id, VehicleOptionMaster__c> newMap { get; set; }

    public VehicleOptionMaster_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        oldMap = (Map<Id, VehicleOptionMaster__c>) Trigger.oldMap;
        newMap = (Map<Id, VehicleOptionMaster__c>) Trigger.newMap;
    }

    public override void beforeInsert() {
        updateRequiredField();
    }

    public override void beforeUpdate() {
        updateRequiredField();
    }

    /**
     * @description 필수옵션일 시 필수 체크 필드 업데이트
     */
    private void updateRequiredField() {

        for (VehicleOptionMaster__c newOption : newList) {
            Boolean isRequired = newOption.Division__c == '필수 옵션' || newOption.Division__c == '기본제공' || newOption.Name.contains('No Carefree');

            // 생성 시 필수체크 필드를 직접 true로 바꾼 경우 제외
            if (Trigger.isInsert && !newOption.IsRequired__c) {
                newOption.IsRequired__c = isRequired;
            } else if (Trigger.isUpdate) {
                VehicleOptionMaster__c oldOption = oldMap.get(newOption.Id);

                // 필수체크 필드를 직접 업데이트 하지 않은 경우만 자동 변경
                if (oldOption.IsRequired__c == newOption.IsRequired__c) {
                    newOption.IsRequired__c = isRequired;
                }
            }
        }
    }
}