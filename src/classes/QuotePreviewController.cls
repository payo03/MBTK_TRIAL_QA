/*************************************************************
 * @author : th.kim
 * @date : 2025-01-08
 * @description : 현재 기회 레코드의 최신 견적 계산 데이터 가져오기
 * @target : quotePreview
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-08      th.kim          Created
**************************************************************/
public without sharing class QuotePreviewController {

    /**
     * @author th.kim
     * @description 현재 기회 레코드로 최신 견적 데이터 가져오기
     * @param oppId 현재 기회 레코드 Id
     *
     * @return 현재 기회의 최신 견적 데이터
     */
    @AuraEnabled
    public static Map<String, Object> getInit(String oppId) {

        QuoteCreatorController.oppId = oppId;
        return new Map<String, Object>{
            'oppData' => QuoteCreatorController.getOppData(),
            'quoteDetail' => QuoteCreatorController.getQuoteDetail(),
            'baseDiscount' => QuoteCreatorController.getBaseDiscount()
        };
    }
}