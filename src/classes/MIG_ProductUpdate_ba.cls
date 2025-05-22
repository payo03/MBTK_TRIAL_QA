public without sharing class MIG_ProductUpdate_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext context) {
        String selectFields =       'Id, AvisOrderInfo__c, Product__c, ' +
                                    'Name, VehicleStatus__c, Status__c, PDIEntryDate__c, DriveDistance__c, Shasi__c,' +
                                    'AvisOrderInfo__r.LION_S__c, AvisOrderInfo__r.TrimLevel__c, AvisOrderInfo__r.Optiview__c, AvisOrderInfo__r.MY__c';
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
                        ETA__c, Status__c, PDIEntryDate__c, DriveDistance__c, Remark__c, Engine__c, Shasi__c, Washing__c, Exterior__c, Function__c,
                        CarAmt__c, PurePrice__c, PurePriceWsc__c, PurePriceWscCfx__c
                FROM TruckMaster__c
        ];

        // VehicleStock 데이터 Update
        Map<String, Product2> p2Map = new Map<String, Product2>();
        for(TruckMaster__c truck : trucks) {
            String key = truck.ChassisFrameNo__c;

            VehicleStock__c stock = stockMap.get(key);
            if(stock != null && stock.Product__c != null) {
                System.debug(stock);
                Product2 p2 = p2Map.containsKey(stock.Product__c)
                        ? p2Map.get(stock.Product__c)
                        : new Product2(Id = stock.Product__c);

                p2.CarAmt__c = truck.CarAmt__c != null ? Decimal.valueOf(truck.CarAmt__c) : 0;
                p2.PurePrice__c = truck.PurePrice__c != null ? Decimal.valueOf(truck.PurePrice__c) : 0;
                p2.PurePriceWsc__c = truck.PurePriceWsc__c != null ? Decimal.valueOf(truck.PurePriceWsc__c) : 0;
                p2.PurePriceWscCfx__c = truck.PurePriceWscCfx__c != null ? Decimal.valueOf(truck.PurePriceWscCfx__c) : 0;

                AvisOrderInfo__c info = stock.AvisOrderInfo__r;
                if(info != null) {
                    System.debug(info);
                    List<String> additionalList = new List<String>();

                    if(info.LION_S__c != 0) additionalList.add('LNS');
                    if(info.TrimLevel__c != null) additionalList.add(info.TrimLevel__c.toUpperCase());
                    if(info.Optiview__c != 0) additionalList.add('OTV');

                    p2.Styling__c = String.join(additionalList, '_');
                }

                p2Map.put(stock.Product__c, p2);
            }
        }
        update p2Map.values();
    }

    public void finish(Database.BatchableContext context) {

        System.debug('########## MIG_ProductUpdate_ba Migration Finish ##########');
    }
}