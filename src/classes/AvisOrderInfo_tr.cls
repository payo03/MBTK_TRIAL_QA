/**
* @Author            : payo03@solomontech.net
* @Description 		 : AvisOrderInfo_tr
* @Target            : AvisConfig_tr 연관있음
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-11-25      payo03@solomontech.net           Created
  1.1      2024-12-06      payo03@solomontech.net           도착대상에 대한 CSV 첨부
  1.2      2024-12-10      payo03@solomontech.net           EmissionLevel, LocalYear는 Config를 통해 Update
  1.3      2024-12-12      payo03@solomontech.net           메일을 두번 보내야함으로 Formula. Status값을 기준으로 메일전송 정보 선택
  1.4      2025-04-10      payo03@solomontech.net           CabColor값에 따라 CarColor데이터 Update
*/
public without sharing class AvisOrderInfo_tr extends TriggerHandler {

    private final static String EMAIL_CODE = 'MAN2000';
    private final static String ARRIVAL_CODE = 'MAN2001';
    private final static String ARRIVAL_KEY = '선박 Arrival List 공유대상';

    // EURO6D - HQMY20 - HDC의 LMY22, LMY24에 대한 로직이 변경될 경우, 추가해주면 됨
    private final static Set<String> LOCAL_CODE_SET = CommonUtilController.getPickListValue('AvisOrderInfo__c', 'ref_HDCCodeList__c');
    private final static Set<String> LOCAL_SPEC_SET = CommonUtilController.getPickListValue('AvisOrderInfo__c', 'ref_SpecList__c');
    private final static Map<String, String> CAR_COLOR_MAP = CommonUtilController.getPickListMap('VehicleStock__c', 'CarColor__c');

    /** TriggerHandler **/
    private List<AvisOrderInfo__c>    newList { get; set; }
    private List<AvisOrderInfo__c>    oldList { get; set; }
    private Map<Id, AvisOrderInfo__c> newMap  { get; set; }
    private Map<Id, AvisOrderInfo__c> oldMap  { get; set; }
    
    public AvisOrderInfo_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap  = (Map<Id, AvisOrderInfo__c>) Trigger.newMap;
        oldMap  = (Map<Id, AvisOrderInfo__c>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        System.debug('AvisOrderInfo_tr.beforeInsert - start');
        doSetDefaultValues();
    }

    public override void beforeUpdate() {
        System.debug('AvisOrderInfo_tr.beforeUpdate - start');
        doSetDefaultValues();
    }

    public override void afterUpdate() {
        System.debug('AvisOrderInfo_tr.afterUpdate - start');
        arriveBF2();
    }

    // ver1.2 EmissionLevel, LocalYear는 Config를 통해 Update
    private void doSetDefaultValues() {
        Map<String, AvisOrderInfo__c> keyMap = new Map<String, AvisOrderInfo__c>();
        for(AvisOrderInfo__c newInfo : newList) {
            keyMap.put(newInfo.OrderIntakeNo__c, newInfo);

            // ver1.4 CabColor값에 따라 CarColor데이터 Update
            String cabColor = newInfo.Cab_Color__c.toUpperCase();
            Integer idx = cabColor.indexOf('RAL');
            String cabColorKey = idx != -1 ? cabColor.substring(0, idx).trim() : cabColor;
            for(String key : CAR_COLOR_MAP.keySet()) {

                if(key.toUpperCase().contains(cabColorKey)) newInfo.CarColor__c = key;
                if(newInfo.CarColor__c != null) break;
            }
        }

        // AvisOrderInfo Update Case. LocalYear는 Config의 정보를 확인한다
        Map<String, Map<String, Object>> configMap = new Map<String, Map<String, Object>>();
        for(AvisConfig__c config : [
                SELECT Id, OrderIntakeNo__c, CodeNo__c,
                        fm_Intarder__c, fm_Pretarder__c, fm_Hypoid__c, fm_PTO__c, fm_Spoiler__c, fm_HQMY__c, fm_EmissionLevel__c
                FROM AvisConfig__c
                WHERE OrderIntakeNo__c IN: keyMap.keySet()
                AND IsActive__c = TRUE
                AND (
                        fm_Intarder__c = 1 OR
                        fm_Pretarder__c = 1 OR
                        fm_Hypoid__c = 1 OR
                        fm_PTO__c = 1 OR
                        fm_Spoiler__c = 1 OR
                        fm_HQMY__c != NULL OR
                        fm_EmissionLevel__c != NULL
                )
        ]) {
            String key = config.OrderIntakeNo__c;
            AvisOrderInfo__c newInfo = keyMap.get(key);
            Map<String, Object> infoMap = configMap.containsKey(key) ? configMap.get(key) : new Map<String, Object>();

            // Code Set담기
            Set<String> codeSet = infoMap.containsKey('codeSet') ? (Set<String>) infoMap.get('codeSet') : new Set<String>();
            codeSet.add(config.CodeNo__c);
            infoMap.put('codeSet', codeSet);

            if(config.fm_Intarder__c == 1) newInfo.IntarderOption__c = 'Intarder';
            if(config.fm_Pretarder__c == 1) newInfo.IntarderOption__c = 'Pretarder';
            if(config.fm_Hypoid__c == 1) newInfo.IsHypoid__c = 1;
            if(config.fm_PTO__c == 1) newInfo.IsPTO__c = 1;
            if(config.fm_Spoiler__c == 1) newInfo.IsSpoiler__c = 1;

            if(config.fm_HQMY__c != null) infoMap.put('my', config.fm_HQMY__c);
            if(config.fm_EmissionLevel__c != null) {
                infoMap.put('emissionLevel', config.fm_EmissionLevel__c);
                newInfo.EmissionLevelEu__c = config.fm_EmissionLevel__c;
            }

            configMap.put(key, infoMap);
            keyMap.put(key, newInfo);
        }

        for(String key : configMap.keySet()) {
            AvisOrderInfo__c newInfo = keyMap.get(key);
            Map<String, String> specMap = CommonUtilCustomController.getSpecMap(newInfo.fm_SpecShort__c);

            Map<String, Object> infoMap = configMap.get(key);
            String segmentType = newInfo.fm_Segment2__c;
            Set<String> codeSet = (Set<String>) infoMap.get('codeSet');
            String emissionLevel = (String) infoMap.get('emissionLevel');
            String my = (String) infoMap.get('my');

            // MTBK Local Year 코드체계 확인하세요... 1년마다 변경된다고 함
            // https://manonlineservices.sharepoint.com/:x:/r/sites/MTBK_Salesforce_Implementation/_layouts/15/Doc2.aspx?action=edit&sourcedoc=%7Be8e0bd2a-8a9b-4099-933f-1952cbec830c%7D&wdOrigin=TEAMS-WEB.teamsSdk_ns.rwc&wdExp=TEAMS-TREATMENT&wdhostclicktime=1733467009267&web=1
            System.debug(segmentType);
            String localYear = null;
            switch on emissionLevel {
                when 'EURO6E' {
                    switch on my {
                        when 'MY24' {
                            if(segmentType == 'TPP') localYear = 'LMY26';
                            if(segmentType == 'HDC') localYear = 'LMY26';

                            if(segmentType == 'MDC') localYear = 'LMY25';
                            if(segmentType == 'LDC') localYear = 'LMY25';
                            if(segmentType == 'TRT') {
                                if(specMap.get('horsePower') == '540') localYear = 'LMY25';
                            }
                        }
                        when 'MY20' {
                            if(segmentType == 'HDC') localYear = 'LMY25';
                            if(segmentType == 'TPP') {
                                if(specMap.get('horsePower') == '520') localYear = 'LMY25';
                            }
                        }
                    }
                }
                when 'EURO6D' {
                    switch on my {
                        when 'MY20' {
                            if(segmentType == 'TPP') localYear = 'LMY24';
                            if(segmentType == 'TRT') localYear = 'LMY24';
                            if(segmentType == 'MDC') localYear = 'LMY24';
                            if(segmentType == 'LDC') localYear = 'LMY24';
                            if(segmentType == 'HDC') {
                                for(String localSpec : LOCAL_SPEC_SET) {
                                    if(newInfo.fm_SpecShort__c.contains(localSpec)) localYear = 'LMY24';

                                    Set<String> tempSet = new Set<String>(codeSet);
                                    tempSet.retainAll(LOCAL_CODE_SET);  // ex, {A, B, C}.retainAll({ A }) => {A}, {A, B, C}.retainAll({ D }) => { }
                                    if(localYear == 'LMY24' && tempSet.isEmpty()) localYear = 'LMY22';
                                }
                            }
                        }
                    }
                }
            }

            if(localYear != null && localYear != newInfo.LocalYear__c) newInfo.LocalYear__c = localYear;
        }
    }

    // 메일 전송버튼 클릭시
    private void arriveBF2() {
        Set<String> idList = new Set<String>();
        Map<String, List<String>> arrivedListMap = new Map<String, List<String>>();
        for(AvisOrderInfo__c newInfo : newList) {

            // 도착완료 선택한 항목들 Mailing
            if(Trigger.isUpdate && newInfo.IsMail__c) {

                // ver1.3 메일을 두번 보내야함으로 Formula. Status값을 기준으로 메일전송 정보 선택
                // TODO : Key값 설정필요
                List<String> arrivedIdList = arrivedListMap.containsKey(ARRIVAL_KEY)
                        ? arrivedListMap.get(ARRIVAL_KEY)
                        : new List<String>();

                arrivedIdList.add(newInfo.Id);
                idList.addAll(arrivedIdList);
                arrivedListMap.put(ARRIVAL_KEY, arrivedIdList);
            }
        }

        // 도착대상이 존재하여 Mail 전송이 필요한 경우
        if(!arrivedListMap.isEmpty()) {
            // ver1.1 도착대상에 대한 CSV 첨부
            Map<String, ConfigDetail__c> configMap = CommonUtilCustomController.getCodeMap(EMAIL_CODE).get(ARRIVAL_CODE);

            List<Map<String, Object>> mailInfoList = new List<Map<String, Object>>();

            // ver1.3 메일을 두번 보내야함으로 Formula. Status값을 기준으로 메일전송 정보 선택
            // TODO : Key값 설정필요
            for(String key : arrivedListMap.keySet()) {
                List<String> arrivedIdList = arrivedListMap.get(key);
                ConfigDetail__c detail = configMap.get(key);

                String sender = detail.Attribute1__c;
                String subject = detail.Attribute2__c;
                String emailBody = detail.Attribute3__c;
                String emailEnd = detail.Attribute4__c;

                String fileName = detail.Attribute5__c;
                String csvHeader = detail.Attribute6__c;
                String csvBody = detail.Attribute7__c;

                List<String> toAddresses = detail.Attribute20__c.trim().split(',');
                List<String> ccAddresses = new List<String>();  // 참조자
                List<String> bccAddresses = new List<String>(); // 숨은 참조자

                Map<String, Object> mailInfo = new Map<String, Object>();
                mailInfo.put('subject', subject);
                mailInfo.put('body', emailBody + emailEnd);
                mailInfo.put('sender', sender);
                mailInfo.put('to', toAddresses);
                mailInfo.put('cc', ccAddresses);
                mailInfo.put('bcc', bccAddresses);

                // ver1.1 도착대상에 대한 CSV 첨부
                List<Messaging.EmailFileAttachment> fileList = new List<Messaging.EmailFileAttachment>();

                // File1. raw 데이터
                fileList.add(EmailConfigController.returnCSV('AvisOrderInfo__c', arrivedIdList, fileName, csvHeader, csvBody));
                // File2. summary 데이터
                fileList.add(returnXLSSummary());
                mailInfo.put('fileList', fileList);

                mailInfoList.add(mailInfo);
            }
            EmailConfigController.sendEmail(mailInfoList);
            doUpdateInfo(idList);
        }
    }

    // Mail Flag 초기화작업
    private static void doUpdateInfo(Set<String> idList) {
        List<AvisOrderInfo__c> updateList = new List<AvisOrderInfo__c>();
        for(AvisOrderInfo__c info : [
                SELECT Id, IsMail__c
                FROM AvisOrderInfo__c
                WHERE Id IN: idList
        ]) {
            info.IsMail__c = false;
            updateList.add(info);
        }
        update updateList;
    }

    // Custom Summary 생성
    private Messaging.EmailFileAttachment returnXLSSummary() {
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();

        attachment.setFileName('Summary.xls');
        attachment.setBody(Blob.valueOf(returnHTMLBody()));
        attachment.setContentType('application/vnd.ms-excel');

        return attachment;
    }

    // Custom Summary Excel파일 Body 생성
    private String returnHTMLBody() {
        Set<String> detailHeaderSet = new Set<String>();
        Map<String, Map<String, Integer>> keyMap = new Map<String, Map<String, Integer>>();

        for (AvisOrderInfo__c newInfo : newList) {
            String pivotRowKey = newInfo.fm_Segment2__c + ',' + newInfo.fm_SpecShort__c + ',';
            String pivotColKey = newInfo.Ship__c + '/' + String.valueOf(newInfo.ETA__c);

            Map<String, Integer> countMap = new Map<String, Integer>();
            if (keyMap.containsKey(pivotRowKey)) countMap = keyMap.get(pivotRowKey);

            Integer count = 0;
            if (countMap.containsKey(pivotColKey)) count = countMap.get(pivotColKey);

            detailHeaderSet.add(pivotColKey);
            countMap.put(pivotColKey, ++count);
            keyMap.put(pivotRowKey, countMap);
        }

        String htmlContent = '<html><body>';
        htmlContent += '<table border="1" style="border-collapse: collapse; width: 100%;">';

        // First header row
        htmlContent += '<tr style="text-align: center;">';
        htmlContent += '<th colspan="2" style="width: 370px; background-color: #d9e2f3;">Count of ORDER INTAKE NO</th>';
        for (String detailHeader : detailHeaderSet) {
            List<String> splitHeader = detailHeader.split('/');
            htmlContent += '<th style="width: 150px; background-color: #d9e2f3;">' + splitHeader[0] + '</th>';
        }
        htmlContent += '<th rowspan="2" style="width: 100px; background-color: #d9e2f3;">Count</th></tr>';

        // Second header row
        htmlContent += '<tr style="text-align: center;">';
        htmlContent += '<th style="width: 70px; background-color: #d9e2f3;">SEGMENT_TYPE</th>';
        htmlContent += '<th style="width: 300px; background-color: #d9e2f3;">REPORT_SPEC</th>';
        for (String detailHeader : detailHeaderSet) {
            List<String> splitHeader = detailHeader.split('/');
            htmlContent += '<th style="width: 150px; background-color: #d9e2f3;">' + splitHeader[1] + '</th>';
        }
        htmlContent += '</tr>';

        // Add row data
        Integer totalCount = 0;
        Map<String, Integer> finalRowMap = new Map<String, Integer>();

        for (String pivotRowKey : keyMap.keySet()) {
            htmlContent += '<tr style="text-align: center;">';
            String[] splitRowKey = pivotRowKey.split(',');
            htmlContent += '<td style="text-align: center;">' + splitRowKey[0] + '</td>';
            htmlContent += '<td style="text-align: center;">' + splitRowKey[1] + '</td>';

            Map<String, Integer> countMap = keyMap.get(pivotRowKey);
            Integer rowTotalCount = 0;

            for (String detailHeader : detailHeaderSet) {
                Integer count = countMap.containsKey(detailHeader) ? countMap.get(detailHeader) : 0;
                htmlContent += '<td style="text-align: center;">' + count + '</td>';
                rowTotalCount += count;

                Integer finalRowCount = count;
                if (finalRowMap.containsKey(detailHeader)) {
                    finalRowCount = finalRowMap.get(detailHeader) + count;
                }
                finalRowMap.put(detailHeader, finalRowCount);
            }

            // Add total for the row
            htmlContent += '<td style="background-color: #f4f4f4;">' + rowTotalCount + '</td></tr>';
            totalCount += rowTotalCount;
        }

        // Add final row
        htmlContent += '<tr style="font-weight: bold; text-align: center;">';
        htmlContent += '<td colspan="2" style="background-color: #d9e2f3;">Total Count</td>';
        for (String rowKey : detailHeaderSet) {
            Integer finalCount = finalRowMap.containsKey(rowKey) ? finalRowMap.get(rowKey) : 0;
            htmlContent += '<td style="background-color: #d9e2f3;">' + finalCount + '</td>';
        }
        htmlContent += '<td style="background-color: #d9e2f3;">' + totalCount + '</td></tr>';

        htmlContent += '</table>';
        htmlContent += '</body></html>';

        return htmlContent;
    }

    /*
    private Messaging.EmailFileAttachment returnCSVSummary() {
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();

        // key : SegmentType, ReportSpec / value : Map
        //                              key : Ship-ETA, Value : Integer
        Set<String> detailHeaderSet = new Set<String>();
        Map<String, Map<String, Integer>> keyMap = new Map<String, Map<String, Integer>>();
        for(AvisOrderInfo__c newInfo : newList) {
            // Row : Segment, ReportSpec, Col : Ship, ETA
            String pivotRowKey = newInfo.fm_Segment2__c + ',' + newInfo.fm_SpecShort__c + ',';
            String pivotColKey = newInfo.Ship__c + '/' + String.valueOf(newInfo.ETA__c);

            Map<String, Integer> countMap = new Map<String, Integer>();
            if(keyMap.containsKey(pivotRowKey)) countMap = keyMap.get(pivotRowKey);

            Integer count = 0;
            if(countMap.containsKey(pivotColKey)) count = countMap.get(pivotColKey);

            detailHeaderSet.add(pivotColKey);
            countMap.put(pivotColKey, ++count);
            keyMap.put(pivotRowKey, countMap);
        }

        String firstHeader = 'Count of ORDER INTAKE NO, ,';
        String secondHeader = 'SEGMENT_TYPE, REPORT_SPEC,';
        for(String detailHeader : detailHeaderSet) {
            List<String> splitHeader = detailHeader.split('/');
            firstHeader += splitHeader.get(0) + ',';
            secondHeader += splitHeader.get(1) + ',';
        }
        firstHeader += 'Count\n';
        secondHeader += ',\n';

        Integer totalCount = 0;
        List<String> rowDataList = new List<String>();
        Map<String, Integer> finalRowMap = new Map<String, Integer>();
        for(String pivotRowKey : keyMap.keySet()) {
            String rowData = pivotRowKey;
            Map<String, Integer> countMap = keyMap.get(pivotRowKey);

            Integer rowTotalCount = 0;
            for(String detailHeader : detailHeaderSet) {
                Integer count = 0;
                if(countMap.containsKey(detailHeader)) count = countMap.get(detailHeader);

                rowData += count + ',';
                rowTotalCount += count;

                Integer finalRowCount = count;
                if(finalRowMap.containsKey(detailHeader)) finalRowCount = finalRowMap.get(detailHeader) + count;
                finalRowMap.put(detailHeader, finalRowCount);
            }
            rowData += rowTotalCount + '\n';
            totalCount += rowTotalCount;

            rowDataList.add(rowData);
        }

        String finalRow = 'Total Count, ,';
        for(String rowKey : finalRowMap.keySet()) {
            finalRow += finalRowMap.get(rowKey) + ',';
        }
        finalRow += totalCount;

        String csvData = firstHeader + secondHeader + String.join(rowDataList, '') + finalRow;
        Blob csvBlob = Blob.valueOf(csvData);

        attachment.setFileName('Summary.csv');
        attachment.setBody(csvBlob);
        attachment.setContentType('text/csv');

        return attachment;
    }
    */

    @TestVisible
    private void test(List<AvisOrderInfo__c> infos) {
        newList = new List<AvisOrderInfo__c>();
        for(AvisOrderInfo__c info : infos) {
            info.IsMail__c = true;
        }
        newList.addAll(infos);

        oldList = new List<AvisOrderInfo__c>();
        oldMap = new Map<Id, AvisOrderInfo__c>();
        for(AvisOrderInfo__c info : infos) {
            AvisOrderInfo__c oldInfo = info.clone(false);
            oldInfo.IsMail__c = false;

            oldList.add(oldInfo);
            oldMap.put(info.Id, oldInfo);
        }
    }
}