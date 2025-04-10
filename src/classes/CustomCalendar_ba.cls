/**
* @Author            : payo03@solomontech.net
* @Description 		 : 공휴일 데이터생성 batch
* @Target            : HandOver
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-02-11      payo03@solomontech.net           Created
*/
public without sharing class CustomCalendar_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    private static final String HOLIDAY_IF_ID = 'API_HOLIDAY';
    private static final String HOLIDAY_API_KEY = Label.HolidayAPIKey;
    public Integer baseNumber;
    public Map<String, String> paramMap = new Map<String, String>();

    public CustomCalendar_ba(Integer baseNumber) {
        this.baseNumber = baseNumber != null ? baseNumber : 3;
        initParam();
    }

    private void initParam() {
        Date baseDate = Date.today().addMonths(this.baseNumber);
        paramMap.put('serviceKey', HOLIDAY_API_KEY);
        paramMap.put('numOfRows', '50');
        paramMap.put('solYear', String.valueOf(baseDate.year()));
        paramMap.put('solMonth', (baseDate.month() < 10 ? '0' : '') + baseDate.month());
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        // Dummy Object조회. Schedule을 걸기위해서 Batch로 구현
        String selectFields =       'Id';
        String fromObject =         'Account LIMIT 1';

        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, '', '');
        System.debug(buildQuery);
        return Database.getQueryLocator(buildQuery);
    }

    public void execute(SchedulableContext context) {
        Database.executeBatch(new CustomCalendar_ba(baseNumber), 100);
    }

    public void execute(Database.BatchableContext context, List<SObject> records) {
        Map<String, Map<String, Object>> externalMap = fetchHolidayMap(this.paramMap);

        String year = this.paramMap.get('solYear');
        String month = this.paramMap.get('solMonth');
        Integer loopNumber = Date.daysInMonth(Integer.valueOf(year), Integer.valueOf(month));

        // ExternalId 기준 Upsert
//        List<HandOverDateManagement__c> upsertList = new List<HandOverDateManagement__c>();
        List<CustomCalendar__c> upsertList = new List<CustomCalendar__c>();
        for(Integer idx = 1; idx <= loopNumber; idx++) {
            String day = (idx < 10 ? '0' : '') + idx;
            String key = year + month + day;
            System.debug(key);

            Map<String, Object> infoMap = externalMap.containsKey(key) ? externalMap.get(key) : new Map<String, Object>();

            Date dateValue = Date.newInstance(Integer.valueOf(year), Integer.valueOf(month), Integer.valueOf(day));
            String dateKind = !infoMap.isEmpty()
                    ? String.valueOf(infoMap.get('dateKind'))
                    : CommonUtilController.isWeekend(dateValue)
                            ? '10'
                            : '00';
            String dateName = !infoMap.isEmpty()
                    ? String.join((List<String>) infoMap.get('dateNameList'), ',')
                    : CommonUtilController.isWeekend(dateValue)
                            ? '주말'
                            : '평일';
            Boolean isHolidy = externalMap.containsKey(key)
                    ? true
                    : CommonUtilController.isWeekend(dateValue);

            CustomCalendar__c customCalendar = new CustomCalendar__c();
            customCalendar.Name = year + month;
            customCalendar.DateKind__c = dateKind;
            customCalendar.DateName__c = dateName;
            customCalendar.Date__c = dateValue;
            customCalendar.IsHoliday__c = isHolidy;
            customCalendar.ExternalId__c = key;

            upsertList.add(customCalendar);
        }
        if(!upsertList.isEmpty()) upsert upsertList ExternalId__c;
    }

    private static Map<String, Map<String, Object>> fetchHolidayMap(Map<String, String> paramMap) {
        Map<String, Map<String, Object>> externalMap = new Map<String, Map<String, Object>>();
        IF_Util ifUtil = new IF_Util(HOLIDAY_IF_ID);
        String body = '';
        for(String key : paramMap.keySet()) {
            body += key + '=' + paramMap.get(key) + '&';
        }
        body = body.substring(0, body.length() - 1);
        System.debug(body);

        HttpResponse response = ifUtil.webCallout(body);
        if (HttpCallOutConsts.SUCCESS_CODES.contains(response.getStatusCode())) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            Map<String, Object> responseInner = (Map<String, Object>) responseMap.get('response');
            Map<String, Object> bodyMap = (Map<String, Object>) responseInner.get('body');
            Object items = bodyMap.get('items');
            // 공휴일이 존재할 경우.
            if(items != null && items instanceof Map<String, Object>) {
                Map<String, Object> itemsMap = (Map<String, Object>) items;

                Object objItem = itemsMap.get('item');
                List<Object> itemList = new List<Object>();
                if (objItem instanceof Map<String, Object>) {
                    Map<String, Object> itemMap = (Map<String, Object>) objItem;

                    itemList.add(itemMap);
                } else if (objItem instanceof List<Object>) {
                    itemList = (List<Object>) objItem;
                }
                for(Object item : itemList) {
                    Map<String, Object> itemMap = (Map<String, Object>) item;

                    String externalId = String.valueOf(itemMap.get('locdate')); // 20250505
                    String dateKind = String.valueOf(itemMap.get('dateKind'));  // 01
                    String dateName = String.valueOf(itemMap.get('dateName'));  // 어린이날

                    // 기존재 데이터 확인. 공휴일이 겹칠 수 있음(ex, 어린이날-부처님 오신 날)
                    Map<String, Object> existMap = externalMap.containsKey(externalId) ? externalMap.get(externalId) : new Map<String, Object>();
                    List<String> dateNameList = !existMap.isEmpty() ? (List<String>) existMap.get('dateNameList') : new List<String>();
                    dateNameList.add(dateName);

                    existMap.put('locDate', externalId);
                    existMap.put('dateKind', dateKind);
                    existMap.put('dateNameList', dateNameList);

                    externalMap.put(externalId, existMap);
                }
            }
        }
        return externalMap;
    }

    public void finish(Database.BatchableContext context) {

        System.debug('########## CustomCalendar_ba Finish ##########');
        System.debug('paramMap : ' + paramMap);
    }
}