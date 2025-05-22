public without sharing class MIG_VehicleStockUpdate_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext context) {
        String selectFields =       'Id, Name, VehicleStatus__c, Status__c, PDIEntryDate__c, DriveDistance__c, Shasi__c';
        String fromObject =         'VehicleStock__c';
        String whereConditions =    'AvisOrderInfo__r.CreatedDate >= YESTERDAY';

        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, whereConditions, 'LastModifiedDate');
        return Database.getQueryLocator(buildQuery);
    }

    public void execute(Database.BatchableContext context, List<VehicleStock__c> stockList) {
        Map<String, VehicleStock__c> stockMap = new Map<String, VehicleStock__c>();
        for(VehicleStock__c stock : stockList) {
            String key = stock.Name;

            stockMap.put(key, stock);
        }

        List<TruckMaster__c> trucks = [
                SELECT ChassisFrameNo__c,
                        St1Start__c, St1End__c, St1Worker__c,
                        St3Start__c, St3End__c, St3Worker__c,
                        St4Start__c, St4End__c, St4Worker__c,
                        St5Start__c, St5End__c, St5Worker__c,
                        St6Start__c, St6End__c, St6Worker__c,
                        St7Start__c, St7End__c, St7Worker__c,
                        ETA__c, Status__c, StockNoShow__c, PDIEntryDate__c, DriveDistance__c,
                        Remark__c, Engine__c, Shasi__c, Washing__c, Exterior__c, Function__c,
                        LongTermStock__c, LongtermDiscountRate__c, PromotionPrice__c
                FROM TruckMaster__c
        ];

        // VehicleStock 데이터 Update
        for(TruckMaster__c truck : trucks) {
            String key = truck.ChassisFrameNo__c;

            VehicleStock__c stock = stockMap.get(key);
            if(stock != null) {

                if(truck.ETA__c != null) {
                    if (truck.ETA__c <= Date.today()) {
                        stock.Status__c = '재고 미노출(임시)';
                        stock.StockNoShow__c = true;
                    } else {
                        stock.Status__c = '30일 재고';
                        if (truck.ETA__c > Date.today().addMonths(2)) stock.Status__c = '60일 재고';
                    }
                }
                if(!truck.StockNoShow__c) stock.Status__c = '재고 노출';

                if (truck.St7Start__c != null) {
                    stock = stockMap.get(key);

                    stock.VehicleStatus__c = '출고됨';
                    stock.Status__c = '판매완료';
                    stockMap.put(stock.Name, stock);
                }
                if (truck.St6Start__c != null) {
                    stock = stockMap.get(key);

                    stock.Engine__c = truck.Engine__c;
                    stock.Shasi__c = truck.Shasi__c;
                    stock.Washing__c = truck.Washing__c;
                    stock.Exterior__c = truck.Exterior__c;
                    stock.Function__c = truck.Function__c;
                    stockMap.put(stock.Name, stock);
                }
                if (truck.St1Start__c != null) {
                    stock = stockMap.get(key);

                    stock.PDIEntryDate__c = truck.PDIEntryDate__c;
                    stock.DriveDistance__c = truck.DriveDistance__c != null
                            ? Decimal.valueOf(truck.DriveDistance__c)
                            : 0;
                    stockMap.put(stock.Name, stock);
                }

                stock.LongTermStock__c = truck.LongTermStock__c;
                stock.LongtermDiscountRate__c = truck.LongtermDiscountRate__c != null ? Decimal.valueOf(truck.LongtermDiscountRate__c) : 0;
                stock.Promotion_Price__c = truck.PromotionPrice__c != null ? Decimal.valueOf(truck.PromotionPrice__c) : 0;
            }
        }
        update stockMap.values();
    }

    public void finish(Database.BatchableContext context) {

        Database.executeBatch(new MIG_PDIStepUpdate_ba(), 1000);
        System.debug('########## MIG_VehicleStockUpdate_ba Migration Finish ##########');
    }
}