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
        System.debug('excelList '+excelList);
        try {
            Set<String> sctanSet = new Set<String>(); // 제원관리번호 형식승인번호 key값
            for(Map<String,String> excelMap : excelList){
                if(excelMap.containsKey('SCNTAN__c')) sctanSet.add(excelMap.get('SCNTAN__c'));
            }
            Map<String, Id> updateSpectypeMap = new Map<String, Id>();
            for (SpecTypeNo__c specTypeNo : [SELECT Id,SCNTAN__c FROM SpecTypeNo__c WHERE SCNTAN__c IN: sctanSet]) {
                if(specTypeNo != null)updateSpectypeMap.put(specTypeNo.SCNTAN__c, specTypeNo.Id);
            }

            Set<Id> addedIds = new Set<Id>();

            for (Map<String, String> excelMap : excelList) {
                SpecTypeNo__c specTypeNo = new SpecTypeNo__c();
                String recordId = null;

                for (String label : excelMap.keySet()) {
                    if (label == 'Index' || label == 'id') continue;

                    String value = excelMap.get(label);
                    specTypeNo.put(label, value);

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
//            Set<String> mngTypeNoSet = new Set<String>();
//
//            Map<String, Id> existingRecords = new Map<String, Id>();
//
//            if (!mngTypeNoSet.isEmpty() || !mngTypeNoSet.isEmpty()) {
//                for (SpecTypeNo__c record : [
//                        SELECT Id, TypeNo__c, MngNo__c FROM SpecTypeNo__c
//                        WHERE TypeNo__c IN :mngTypeNoSet OR MngNo__c IN :mngTypeNoSet
//                ]) {
//                    if (record.TypeNo__c != null) {
//                        existingRecords.put(record.TypeNo__c, record.Id);
//                    } else if (record.MngNo__c != null) {
//                        existingRecords.put(record.MngNo__c, record.Id);
//                    }
//                }
//            }
//            System.debug('existingRecords' + existingRecords);
//
//            for (Map<String, Object> obj : excelList) {
//                SpecTypeNo__c specTypeNo = new SpecTypeNo__c();
//                System.debug('obj'+obj);
//                // 필드 매핑 적용
//                for (String label : obj.keySet()) {
//                    if (fieldMap.containsKey(label)) {
//                        Object fieldValue = obj.get(label);
//                        String fieldName = label == '제원관리번호_형식승인번호' ? checkMngNo((String)fieldValue) : fieldMap.get(label);
//                        Schema.DescribeFieldResult fieldDesc = SpecTypeNo__c.SObjectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
//                        Schema.DisplayType fieldType = fieldDesc.getType();
//
//                        Boolean isNumeric = checkIsNumeric(fieldValue);
//
//                        if (obj.containsKey('MngNo__c') && obj.get('MngNo__c') != null) {
//                            mngTypeNoSet.add((String) obj.get('MngNo__c'));
//                        }
//                        if (obj.containsKey('TypeNo__c') && obj.get('TypeNo__c') != null) {
//                            mngTypeNoSet.add((String) obj.get('TypeNo__c'));
//                        }
//                        if (fieldValue != null) {
//                            if (fieldType == Schema.DisplayType.DATE) {
//                                Date convertedDate = parseDate((String) fieldValue);
//                                if (convertedDate != null) {
//                                    specTypeNo.put(fieldName, convertedDate);
//                                }
//                            } else if (fieldType == Schema.DisplayType.DATETIME) {
//                                DateTime convertedDateTime = parseDateTime((String) fieldValue);
//                                if (convertedDateTime != null) {
//                                    specTypeNo.put(fieldName, convertedDateTime);
//                                }
//                            } else if (fieldType == Schema.DisplayType.DOUBLE && isNumeric) {
//                                specTypeNo.put(fieldName, Decimal.valueOf(String.valueOf(fieldValue).replaceAll('[^0-9]', '')));
//                            } else if (fieldType == Schema.DisplayType.INTEGER && isNumeric) {
//                                specTypeNo.put(fieldName, Integer.valueOf(String.valueOf(fieldValue).replaceAll('[^0-9]', '')));
//                            } else if (fieldType == Schema.DisplayType.BOOLEAN) {
//                                specTypeNo.put(fieldName, Boolean.valueOf(fieldValue));
//                            } else {
//                                specTypeNo.put(fieldName, String.valueOf(fieldValue));
//                            }
//                        }
//                    }
//                }
//
//                String upsertKey;
//                if (specTypeNo.TypeNo__c != null) {
//                    upsertKey = specTypeNo.TypeNo__c;
//                } else if (specTypeNo.MngNo__c != null) {
//                    upsertKey = specTypeNo.MngNo__c;
//                } else {
//                    upsertKey = null;
//                }
//                System.debug(upsertKey);
//                if (upsertKey != null && existingRecords.containsKey(upsertKey)) {
//                    specTypeNo.Id = existingRecords.get(upsertKey);
//                }
//                specTypeNos.add(specTypeNo);
//            }
//            System.debug('specTypeNos::: '+ specTypeNos);
//            // Salesforce 데이터 삽입 (DML 실행)
//            if (!specTypeNos.isEmpty()) {
//                upsert specTypeNos;
//            }
        } catch (Exception e) {
            System.debug('err :: ' + e);
        }
        System.debug('specTypeNos'+upsertSpecTypeNos);
        return upsertSpecTypeNos;
    }

//    public static Date parseDate(String dateStr) {
//        if (dateStr == null || dateStr == '') return null;
//
//        List<String> parts = dateStr.split('/');
//        if (parts.size() == 3) {
//            Integer month = Integer.valueOf(parts[0]);
//            Integer day = Integer.valueOf(parts[1]);
//            Integer year = Integer.valueOf(parts[2]);
//            return Date.newInstance(year, month, day);
//        }
//        return null;
//    }
//
//
//    public static String checkMngNo(String value) {
//        String fieldName;
//        Pattern regex = Pattern.compile('^(\\d)-\\d+-\\d+-\\d+-\\d+$');
//        Matcher matcher = regex.matcher((String)value);
//        fieldName = matcher.find() ? 'TypeNo__c' : 'MngNo__c';
//        return fieldName;
//    }

}