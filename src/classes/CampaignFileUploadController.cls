public with sharing class CampaignFileUploadController {
    
    @AuraEnabled
    public static List<Account> accountFileUpload(String base64Data, Id campaignId) {
        System.debug('Start processing CSV data');
        List<Account> accList = new List<Account>();

        try {
            // CSV 데이터를 Base64 디코딩
            String csvData = EncodingUtil.base64Decode(base64Data).toString();
            System.debug('Decoded CSV data: ' + csvData);

            // CSV 파싱
            List<List<String>> csvRows = parseCsv(csvData);
            System.debug('Parsed CSV rows: ' + csvRows);

            if (csvRows.size() < 2) {
                throw new AuraHandledException('CSV 파일에 데이터가 없습니다.');
            }

            // 첫 번째 라인 (헤더) 건너뛰기
            List<List<String>> dataRows = new List<List<String>>();
            for (Integer i = 1; i < csvRows.size(); i++) {
                dataRows.add(csvRows[i]);
            }

            Set<Id> accountIds = new Set<Id>();

            // Account ID 수집
            // for (List<String> row : dataRows) {
            //     if (!row.isEmpty() && row[0] != null && row[0].startsWith('001')) {
            //         accountIds.add((Id) row[0].trim()); // CSV의 첫 번째 필드가 Account ID로 가정
            //     }
            // }

            for (List<String> row : dataRows) {
                if (!row.isEmpty() && row[0] != null) {
                    Id recordId = (Id) row[0].trim();
                    if (recordId.getSObjectType() == Account.SObjectType) {
                        accountIds.add(recordId);
                    }
                }
            }

            // Account 데이터 조회
            Map<Id, Account> accountMap = new Map<Id, Account>(
                [SELECT Id FROM Account WHERE Id IN :accountIds]
            );

            // CampaignJunction__c 생성
            List<CampaignJunction__c> campaignJunctionList = new List<CampaignJunction__c>();

            for (List<String> row : dataRows) {
                if (row.isEmpty() || row[0] == null || !accountMap.containsKey((Id) row[0])) {
                    System.debug('Invalid or missing Account ID: ' + row[0]);
                    continue; // 유효하지 않은 Account ID는 스킵
                }

                Id accountId = (Id) row[0];
                Account accountRecord = accountMap.get(accountId);

                CampaignJunction__c junction = new CampaignJunction__c();
                junction.Account__c = accountRecord.Id;
                junction.CampaignMaster__c = campaignId;

                campaignJunctionList.add(junction);

                // 리턴할 Account 리스트에 추가
                accList.add(accountRecord);
            }

            // CampaignJunction__c 삽입
            if (!campaignJunctionList.isEmpty()) {
                insert campaignJunctionList;
                System.debug('CampaignJunction__c records created successfully');
            } else {
                System.debug('No valid data to insert.');
            }
        } catch (Exception e) {
            System.debug('Error processing CSV: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            throw new AuraHandledException('File processing failed: ' + e.getMessage());
        }

        return accList;
    }


    @AuraEnabled
    public static List<VehicleStock__c> stockUploadedFile(String base64Data, Id campaignId) {
        System.debug('Start processing CSV data');
        List<VehicleStock__c> stockList = new List<VehicleStock__c>();

        try {
            // CSV 데이터를 Base64 디코딩
            String csvData = EncodingUtil.base64Decode(base64Data).toString();
            System.debug('Decoded CSV data: ' + csvData);

            // CSV 파싱
            List<List<String>> csvRows = parseCsv(csvData);
            System.debug('Parsed CSV rows: ' + csvRows);

            if (csvRows.size() < 2) {
                throw new AuraHandledException('CSV 파일에 데이터가 없습니다.');
            }

            // 첫 번째 라인 (헤더) 건너뛰기
            List<List<String>> dataRows = new List<List<String>>();
            for (Integer i = 1; i < csvRows.size(); i++) {
                dataRows.add(csvRows[i]);
            }

            Set<Id> stockIds = new Set<Id>();

            for (List<String> row : dataRows) {
                if (!row.isEmpty() && row[0] != null) {
                    Id recordId = (Id) row[0].trim();
                    if (recordId.getSObjectType() == VehicleStock__c.SObjectType) {
                        stockIds.add(recordId);
                    }
                }
            }

            Map<Id, VehicleStock__c> stockMap = new Map<Id, VehicleStock__c>(
                [SELECT Id FROM VehicleStock__c WHERE Id IN :stockIds]
            );

            // CampaignJunction__c 생성
            List<CampaignJunction__c> campaignJunctionList = new List<CampaignJunction__c>();

            for (List<String> row : dataRows) {
                if (row.isEmpty() || row[0] == null || !stockMap.containsKey((Id) row[0])) {
                    System.debug('Invalid or missing VehicleStock ID: ' + row[0]);
                    continue;
                }

                Id stockId = (Id) row[0];
                VehicleStock__c stockRecord = stockMap.get(stockId);

                CampaignJunction__c junction = new CampaignJunction__c();
                junction.VehicleStock__c = stockRecord.Id;
                junction.CampaignMaster__c = campaignId;

                campaignJunctionList.add(junction);

                stockList.add(stockRecord);
            }

            // CampaignJunction__c 삽입
            if (!campaignJunctionList.isEmpty()) {
                insert campaignJunctionList;
                System.debug('CampaignJunction__c records created successfully');
            } else {
                System.debug('No valid data to insert.');
            }
        } catch (Exception e) {
            System.debug('Error processing CSV: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            throw new AuraHandledException('File processing failed: ' + e.getMessage());
        }

        return stockList;
    }

    // CSV 데이터를 파싱하는 유틸리티 메서드
    private static List<List<String>> parseCsv(String csvData) {
        List<List<String>> rows = new List<List<String>>();
        Boolean inQuotes = false;
        String currentCell = '';
        List<String> currentRow = new List<String>();
    
        for (Integer i = 0; i < csvData.length(); i++) {
            String c = csvData.substring(i, i + 1);
    
            if (c == '"' && (i + 1 < csvData.length() && csvData.substring(i + 1, i + 2) == '"')) {
                currentCell += '"'; // 이스케이프된 큰따옴표
                i++;
            } else if (c == '"') {
                inQuotes = !inQuotes; // 큰따옴표 열기/닫기
            } else if (c == ',' && !inQuotes) {
                currentRow.add(currentCell.trim());
                currentCell = '';
            } else if ((c == '\n' || c == '\r') && !inQuotes) {
                if (currentCell.length() > 0 || currentRow.size() > 0) {
                    currentRow.add(currentCell.trim());
                    currentCell = '';
                }
                if (currentRow.size() > 0) {
                    rows.add(currentRow);
                    currentRow = new List<String>();
                }
            } else {
                currentCell += c;
            }
        }
    
        if (currentCell.length() > 0 || currentRow.size() > 0) {
            currentRow.add(currentCell.trim());
            rows.add(currentRow);
        }
    
        return rows;
    }

}