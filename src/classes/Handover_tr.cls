/*************************************************************
 * @author : th.kim
 * @date : 2025-01-22
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-22      th.kim          Created
**************************************************************/
public without sharing class Handover_tr extends TriggerHandler {

    private final List<Handover__c> newList { get; set; }
    private final List<Handover__c> oldList { get; set; }
    private final Map<Id, Handover__c> newMap { get; set; }
    private final Map<Id, Handover__c> oldMap { get; set; }

    public Handover_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap = (Map<Id, Handover__c>) Trigger.newMap;
        oldMap = (Map<Id, Handover__c>) Trigger.oldMap;
    }

    public override void afterInsert() {
        inactivatePreviousRecord();
    }

    public override void beforeUpdate() {
//        setUpdatedField();
    }

    public override void afterUpdate() {
        updatedField();
//        setUpdatedField();
//        checkUpdatedFields(newMap.keySet());
    }

    /**
     * @author th.kim
     * @description 1. 필드 업데이트 시 '업데이트된 필드'에 저장
     *              2. 업데이트 확인 필드 true일 시 '업데이트된 필드' 초기화
     */
//    private void setUpdatedField() {
//
//        List<Handover__c> updateHandoverList = new List<Handover__c>();
//        for (Handover__c newHandover : newList) {
//            Handover__c oldHandover = oldMap.get(newHandover.Id);
//
//            // 업데이트 확인 시 업데이트 확인 필요 필드 초기화
//            if (oldHandover.IsNeedToCheckUpdate__c && !newHandover.IsNeedToCheckUpdate__c) {
//                updateHandoverList.add(new Handover__c(Id = newHandover.Id, UpdatedFields__c = ''));
//            } else {
//                // 업데이트 확인 필요 필드 추가
//                updatedField();
//            }
//        }
//
//        if (!updateHandoverList.isEmpty()) {
//            TriggerHandler.bypass('Handover_tr');
//            update updateHandoverList;
//            TriggerHandler.clearBypass('Handover_tr');
//        }
//    }

    /**
     * @author th.kim
     * @description 1. 필드 업데이트 시 '업데이트된 필드'에 저장
     *                  UpdatedFieldSet 필드셋의 필드 내역 추적하여 업데이트 여부 체크 및 저장
     *                  핸드오버의 업데이트된 필드 확인하기 위한 로직
     *                  UpdatedFieldSet 필드셋에 필드 추가 필요 (수식 필드일 시 Tracked['FieldName'] 이름의 필드 생성 필요)
     *              2. 업데이트 확인 필드 true일 시 '업데이트된 필드' 초기화
     */
    private void updatedField() {

        String objectName = 'Handover__c';  // 사용하려는 객체 이름

        Schema.FieldSet fieldSet = Schema.getGlobalDescribe().get(objectName).getDescribe().fieldSets.getMap().get('UpdatedFieldSet');
        List<Handover__c> updateHandoverList = new List<Handover__c>();
        for (Handover__c newHandover : newList) {
            Handover__c oldHandover = oldMap.get(newHandover.Id);
            // 업데이트 확인 완료
            if (oldHandover.IsNeedToCheckUpdate__c && !newHandover.IsNeedToCheckUpdate__c) {
                updateHandoverList.add(new Handover__c(Id = newHandover.Id, UpdatedFields__c = ''));
            }
            // 업데이트 확인 필요 필드 추가
            else {
                Handover__c updateHandover = new Handover__c(Id = newHandover.Id);
                Set<String> updatedFieldSet = new Set<String>();
                for (Schema.FieldSetMember field : fieldSet.getFields()) {

                    String fieldName = field.fieldPath;

                    // 객체의 SObjectType 가져오기
                    Schema.SObjectType objectDescribe = Schema.getGlobalDescribe().get(objectName);

                    // 필드 정보 가져오기
                    Schema.DescribeFieldResult fieldDescribe = objectDescribe.getDescribe().fields.getMap().get(fieldName).getDescribe();
                    // 수식 필드
                    if (fieldDescribe.isCalculated()) {
                        String trackedFieldName = 'Tracked' + fieldName.replace('fm_', '');

                        // 추적 필드 존재 여부 확인
                        if (objectDescribe.getDescribe().fields.getMap().containsKey(trackedFieldName)) {
                            // 필드 변경 시 업데이트 필드 추가
                            if (oldHandover.get(fieldName) != newHandover.get(trackedFieldName)) {
                                updatedFieldSet.add(fieldName);
                                updateHandover.put(trackedFieldName, newHandover.get(fieldName));
                            }
                        } else {
                            // Tracked 필드 없을 때
                            System.debug('Tracked 필드 없음 :: ' + trackedFieldName);
                            continue;
                        }
                    }

                    // 일반 필드
                    if (oldHandover.get(fieldName) != newHandover.get(fieldName)) {
                        updatedFieldSet.add(fieldName);
                    }
                }

                // 변경 필드 없을 때
                if (updatedFieldSet.isEmpty()) {
                    continue;
                }

                // 업데이트 확인 아직 안했을 때 기존 필드에서 신규 필드만 추가
                if (newHandover.IsNeedToCheckUpdate__c) {
                    if (String.isNotBlank(newHandover.UpdatedFields__c)) {
                        updatedFieldSet.addAll(newHandover.UpdatedFields__c.split(','));
                    }
                }

                updateHandover.IsNeedToCheckUpdate__c = true;
                updateHandover.UpdatedFields__c = String.join(updatedFieldSet, ',');
                updateHandoverList.add(updateHandover);
            }
        }

        if (!updateHandoverList.isEmpty()) {
            TriggerHandler.bypass('Handover_tr');
            update updateHandoverList;
            TriggerHandler.clearBypass('Handover_tr');
        }
    }

    /**
     * @author th.kim
     * @description 기존 핸드오버 비활성화 처리하기
     */
    private void inactivatePreviousRecord() {

        Set<Id> opportunityIdSet = new Set<Id>();

        for (Handover__c newHandover : newList) {
            opportunityIdSet.add(newHandover.Opportunity__c);
        }

        List<Handover__c> updateHandoverList = new List<Handover__c>();
        Map<Id, Handover__c> opportunityIdHandoverMap = new Map<Id, Handover__c>();

        for (Handover__c handover : [
            SELECT Id, IsActive__c, Opportunity__c
            FROM Handover__c
            WHERE Opportunity__c IN :opportunityIdSet
            ORDER BY CreatedDate DESC
        ]) {
            // 최신 레코드 Map
            if (!opportunityIdHandoverMap.containsKey(handover.Opportunity__c)) {
                opportunityIdHandoverMap.put(handover.Opportunity__c, handover);
                continue; // 최신 레코드는 업데이트 리스트에서 제외
            }

            // 이전 레코드 비활성화
            handover.IsActive__c = false;
            updateHandoverList.add(handover);
        }

        if (!updateHandoverList.isEmpty()) {
            TriggerHandler.bypass('Handover_tr');
            update updateHandoverList;
            TriggerHandler.clearBypass('Handover_tr');
        }
    }

    /**
     * @author th.kim
     * @description 변경된 필드 가져와서 저장하기
     * @param newIdSet new Id
     */
//    @Future
//    private static void checkUpdatedFields(Set<Id> newIdSet) {
//
//        // 히스토리 데이터 쿼리
//        List<Handover__History> historyList = [
//            SELECT Field, OldValue, NewValue, ParentId
//            FROM Handover__History
//            WHERE ParentId IN :newIdSet
//            AND CreatedDate > :Datetime.now().addSeconds(-3)
//        ];
//
//        Map<Id, Set<String>> historyFieldMap = new Map<Id, Set<String>>();
//        for (Handover__History history : historyList) {
//            if (history.Field != 'created') {
//                if (!historyFieldMap.containsKey(history.ParentId)) {
//                    historyFieldMap.put(history.ParentId, new Set<String>());
//                }
//                // 업데이트된 필드 추가
//                historyFieldMap.get(history.ParentId).add(history.Field);
//            }
//        }
//
//        List<Handover__c> handoverList = [SELECT Id, IsNeedToCheckUpdate__c, UpdatedFields__c FROM Handover__c WHERE Id IN :historyFieldMap.keySet()];
//        for (Handover__c handover : handoverList) {
//            // 업데이트 확인 아직 안했을 때 기존 필드에서 신규 필드만 추가
//            if (handover.IsNeedToCheckUpdate__c) {
//                historyFieldMap.get(handover.Id).addAll(handover.UpdatedFields__c.split(','));
//            }
//            handover.IsNeedToCheckUpdate__c = true;
//            handover.UpdatedFields__c = String.join(historyFieldMap.get(handover.Id), ',');
//        }
//
//        TriggerHandler.bypass('Handover_tr');
//        update handoverList;
//        TriggerHandler.clearBypass('Handover_tr');
//    }
}