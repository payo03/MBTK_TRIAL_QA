/**
* @Author            : payo03@solomontech.net
* @Description 		 : HTTP CallOut Transaction 분리를 위한 Queueable 호출
* @Target            : AsyncModuSignTemplate
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2024-12-20      payo03@solomontech.net           Created
  1.1      2024-12-30      payo03@solomontech.net           Kakao Template 일괄등록 추가
  1.2      2025-01-03      payo03@solomontech.net           Template Queueable로 구현
*/
public without sharing class Template_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    private static final Integer BATCH_SIZE = 50000;

    // Type. YYYYMMDDHHMMSS / ex, 20241215093000
    public String baseDate;
    public String templateType;

    public Template_ba(String templateType, String baseDate) {
        if(templateType == null) templateType = 'MODUSIGN';

        this.templateType = templateType;
        this.baseDate = baseDate;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        // Dummy Object조회. Schedule을 걸기위해서 Batch로 구현
        String selectFields =       'Id';
        String fromObject =         'Account LIMIT 1';

        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, '', '');
        return Database.getQueryLocator(buildQuery);
    }

    public void execute(SchedulableContext context) {
        String templateType = 'MODUSIGN';
        String baseDate = CommonUtilController.formatDate(Datetime.now().addDays(-7), 'C') + '000000';

        if(this.templateType != null) templateType = this.templateType;
        if(this.baseDate != null) baseDate = this.baseDate;

        Database.executeBatch(new Template_ba(templateType, baseDate), BATCH_SIZE);
    }

    public void execute(Database.BatchableContext context, List<SObject> records) {
        // ver1.2 Template Queueable로 구현
        switch on this.templateType.toUpperCase() {
            when 'MODUSIGN' { System.enqueueJob(new AsyncModuSignTemplate()); }
            when 'KAKAO' { System.enqueueJob(new AsyncKakaoTemplate(this.baseDate)); }
//            when 'KAKAO' { System.debug('위에 주석푸세요'); }
        }
    }

    public void finish(Database.BatchableContext context) {
        
        System.debug('########## Template_ba Finish ##########');
    }
}