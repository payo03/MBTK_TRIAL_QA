/*************************************************************
 * @author : San.Kang
 * @date : 2025-03-20
 * @description : Light Consent 스케쥴러
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-03-20        San.Kang           Created
**************************************************************/
public without sharing class SendLightConsent_sc {

    public static void scheduleBatchWithParam(String customerConsentId) {
        String jobName = 'SendLightConsent_ba(' + customerConsentId + ')';
        List<CronTrigger> jobs = [
                SELECT Id, CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE '%SendLightConsent_ba(%' AND State ='DELETED'
        ];
        for (CronTrigger job : jobs) {
            System.abortJob(job.Id);
        }
        // 현재 시간에서 1시간 뒤 크론 표현식 생성
        Datetime dt = System.now().addMinutes(3);
//        Datetime dt = System.now().addHours(1);
        String cronExp = dt.format('s m H d M ? yyyy');

        // 배치 스케줄 실행

        System.schedule(jobName, cronExp, new SendLightConsent_ba(customerConsentId));

        System.debug('스케줄 등록됨: ' + cronExp + ' (CustomerConsentId: ' + jobName + ')');
    }
}