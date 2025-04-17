/*************************************************************
 * @author : th.kim
 * @date : 2025-01-07
 * @description : QuoteLineItem 트리거 핸들러 (현재 사용 XXX, 삭제 예정)
 * @target : QuoteLineItem
==============================================================
 * Ver          Date            Author          Modification
 * 1.0          2025-01-07      th.kim          Created
 * 1.1          2025-03-26      th.kim          사용 안함으로 인한 주석 처리
**************************************************************/
public with sharing class QuoteLineItem_tr extends TriggerHandler {

    private final List<QuoteLineItem> newList { get; set; }
    private final List<QuoteLineItem> oldList { get; set; }
    private final Map<Id, QuoteLineItem> newMap { get; set; }
    private final Map<Id, QuoteLineItem> oldMap { get; set; }

    public QuoteLineItem_tr() {
        newList = Trigger.new;
        oldList = Trigger.old;
        newMap = (Map<Id, QuoteLineItem>) Trigger.newMap;
        oldMap = (Map<Id, QuoteLineItem>) Trigger.oldMap;
    }

//    public override void afterInsert() {
//        updateQuoteProduct();
//    }

//    public override void afterUpdate() {
//        updateQuoteProduct();
//    }

    /**
     * @description Quote Line Item 생성 시 견적의 차종 필드 업데이트
     */
//    private void updateQuoteProduct() {
//
//        Map<Id, Id> quoteProductMap = new Map<Id, Id>();
//        for (QuoteLineItem item : newList) {
//            QuoteLineItem oldItem = Trigger.isUpdate ? oldMap.get(item.Id) : null;
//            if(Trigger.isInsert || (oldItem != null && oldItem.Product2Id != item.Product2Id)) {
//                quoteProductMap.put(item.QuoteId, item.Product2Id);
//            }
//        }
//        List<Quote> quoteList = [SELECT Id, Product__c FROM Quote WHERE Id IN :quoteProductMap.keySet()];
//        for (Quote quote : quoteList) {
//            quote.Product__c = quoteProductMap.get(quote.Id);
//        }
//        if(!quoteList.isEmpty()) update quoteList;
//    }
}