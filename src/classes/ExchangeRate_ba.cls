/**
* @Author            : payo03@solomontech.net
* @Description 		 : 환율정보 생성 batch
* @Target            : CustomCalendar
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-03-18      payo03@solomontech.net           Created
*/
public without sharing class ExchangeRate_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    private static final String EXCHANGE_RATE_IF_ID = 'API_EXCHANGE_RATE';
    private static final String EXCHANGE_RATE_API_KEY = Label.ExchangeRateAPIKey;
    public Integer baseNumber;
    public String dateTimeStr;
    public Map<String, String> paramMap = new Map<String, String>();

    public ExchangeRate_ba(Integer baseNumber, String dateTimeStr) {
        this.baseNumber = baseNumber != null ? baseNumber : -1;
        
        String calDatetimeStr = CommonUtilController.formatDate(Datetime.now().addDays(this.baseNumber), 'C');
        this.dateTimeStr = dateTimeStr != null ? dateTimeStr : calDatetimeStr;

        initParam();
    }

    private void initParam() {
        paramMap.put('authkey', EXCHANGE_RATE_API_KEY);
        paramMap.put('data', 'AP01');
        paramMap.put('searchdate', this.dateTimeStr);
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
        Integer baseNumber = -1;
        String dateTimeStr = null;
        
        if(this.baseNumber != null) baseNumber = this.baseNumber;
        if(this.dateTimeStr != null) dateTimeStr = this.dateTimeStr;
        
        Database.executeBatch(new ExchangeRate_ba(baseNumber, dateTimeStr), 100);
    }

    public void execute(Database.BatchableContext context, List<SObject> records) {
        List<CustomCalendar__c> calendarList = [SELECT Id FROM CustomCalendar__c WHERE ExternalId__c = :dateTimeStr];
        String dateTimeStr = this.dateTimeStr;
        CustomCalendar__c calendar = calendarList.isEmpty() ? new CustomCalendar__c() : calendarList.get(0);

        IF_Util ifUtil = new IF_Util(EXCHANGE_RATE_IF_ID);
        String body = '';
        for(String key : paramMap.keySet()) {
            body += key + '=' + paramMap.get(key) + '&';
        }
        body = body.substring(0, body.length() - 1);
        System.debug(body);

        List<ExchangeRate__c> upsertList = new List<ExchangeRate__c>();
        HttpResponse response = ifUtil.webCallout(body);
        if (HttpCallOutConsts.SUCCESS_CODES.contains(response.getStatusCode())) {
            String responseBody = response.getBody();
            if(Test.isRunningTest()) responseBody = testJSONBody();
            List<Object> objList = (List<Object>) JSON.deserializeUntyped(responseBody);

            for(Object obj : objList) {
                Map<String, Object> responseMap = (Map<String, Object>) obj;
                ExchangeRate__c rate = new ExchangeRate__c();
                rate.CustomCalendar__c = calendar.Id;

                String dealBasR = String.valueOf(responseMap.get('deal_bas_r')).replace(',', '');
                String curUnit = String.valueOf(responseMap.get('cur_unit'));
                Decimal dealBasRNum = Decimal.valueOf(dealBasR);

                rate.Name = String.valueOf(responseMap.get('cur_nm'));
                rate.CurUnit__c = curUnit;
                rate.TTB__c = String.valueOf(responseMap.get('ttb'));
                rate.TTS__c = String.valueOf(responseMap.get('tts'));
                rate.BKPR__c = String.valueOf(responseMap.get('bkpr'));
                rate.YyEfeeR__c = String.valueOf(responseMap.get('yy_efee_r'));
                rate.TenDdEfeeR__c = String.valueOf(responseMap.get('ten_dd_efee_r'));
                rate.KftcBKPR__c = String.valueOf(responseMap.get('kftc_bkpr'));
                rate.KftcDealBasR__c = String.valueOf(responseMap.get('kftc_deal_bas_r'));
                rate.DealBasR__c = dealBasRNum;
                rate.ExternalId__c = dateTimeStr + '_' + curUnit;
                upsertList.add(rate);
            }
        }
        if(!upsertList.isEmpty()) upsert upsertList ExternalId__c;
    }

    public void finish(Database.BatchableContext context) {

        System.debug('########## ExchangeRate_ba Finish ##########');
        System.debug('paramMap : ' + paramMap);
    }

    private static String testJSONBody() {
        return
            '[' +
            '  {' +
            '    "result": 1,' +
            '    "cur_unit": "AED",' +
            '    "ttb": "392.14",' +
            '    "tts": "400.07",' +
            '    "deal_bas_r": "396.11",' +
            '    "bkpr": "396",' +
            '    "yy_efee_r": "0",' +
            '    "ten_dd_efee_r": "0",' +
            '    "kftc_bkpr": "396",' +
            '    "kftc_deal_bas_r": "396.11",' +
            '    "cur_nm": "아랍에미리트 디르함"' +
            '  },' +
            '  {' +
            '    "result": 1,' +
            '    "cur_unit": "AUD",' +
            '    "ttb": "911.17",' +
            '    "tts": "929.58",' +
            '    "deal_bas_r": "920.38",' +
            '    "bkpr": "920",' +
            '    "yy_efee_r": "0",' +
            '    "ten_dd_efee_r": "0",' +
            '    "kftc_bkpr": "920",' +
            '    "kftc_deal_bas_r": "920.38",' +
            '    "cur_nm": "호주 달러"' +
            '  }' +
            ']';
    }
}