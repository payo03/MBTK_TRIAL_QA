/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-12
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-12        San.Kang           Created
**************************************************************/
public without sharing class ImportSpecTypeController {

    @AuraEnabled
    public static List<SpecTypeNo__c> importExcelData(List<Map<String, String>> excelList) {
        List<SpecTypeNo__c> upsertSpecTypeNos = new List<SpecTypeNo__c>();
        try {
            Set<String> mngNoKeySet = new Set<String>(); // 제원관리번호 key값
            Set<String> typeNoKeySet = new Set<String>(); // 형식승인번호 key값
            for(Map<String,String> excelMap : excelList){
                String sCNTAN = excelMap.get('SCNTAN__c'); // 엑셀에서 들어오는 제원관리번호/형식승인번호 값
                if(sCNTAN.replaceAll('-','').length() == 17){ // 하이픈 제거 17자리면 제원관리번호
                    mngNoKeySet.add(sCNTAN);
                } else if (sCNTAN.replaceAll('-','').length() == 11){// 11자리면 형식승인번호
                    typeNoKeySet.add(sCNTAN);
                }
            }
            Map<String, Id> updateSpectypeMap = new Map<String, Id>();

            for (SpecTypeNo__c specTypeNo : [SELECT Id, MngNo__c, TypeNo__c FROM SpecTypeNo__c WHERE TypeNo__c IN:typeNoKeySet OR MngNo__c IN:mngNoKeySet]) {
                if(specTypeNo != null) {
                    if(specTypeNo.MngNo__c != null){
                        updateSpectypeMap.put(specTypeNo.MngNo__c, specTypeNo.Id);
                    } else if (specTypeNo.TypeNo__c != null){
                        updateSpectypeMap.put(specTypeNo.TypeNo__c, specTypeNo.Id);
                    }
                }
            }
            System.debug('updateSpectypeMap:::'+updateSpectypeMap);
            Set<Id> addedIds = new Set<Id>();

            for (Map<String, String> excelMap : excelList) {
                SpecTypeNo__c specTypeNo = new SpecTypeNo__c();
                String recordId = null;

                for (String label : excelMap.keySet()) {
                    if (label == 'Index' || label == 'id') continue;

                    String value = excelMap.get(label);
                    if(label == 'SCNTAN__c'){
                        System.debug('length:::'+value.replaceAll('-','').length());
                        if(value.replaceAll('-','').length() == 17){
                            specTypeNo.put('MngNo__c', value);
                        } else if(value.replaceAll('-','').length() == 11){
                            specTypeNo.put('TypeNo__c', value);
                        }
                    } else {
                        specTypeNo.put(label, value);
                    }

                    if (label == 'SCNTAN__c' && updateSpectypeMap.containsKey(value)) {
                        recordId = updateSpectypeMap.get(value);
                    }
                }

                if (recordId != null) {
                    if (addedIds.contains(recordId)) continue;
                    specTypeNo.put('Id', recordId);
                    addedIds.add(recordId);
                }

                upsertSpecTypeNos.add(specTypeNo);
            }

            System.debug(upsertSpecTypeNos.size());

            if(!upsertSpecTypeNos.isEmpty()) upsert upsertSpecTypeNos;
        } catch (Exception e) {
            System.debug('err :: ' + e);
        }
        System.debug('specTypeNos'+upsertSpecTypeNos);
        return upsertSpecTypeNos;
    }

}