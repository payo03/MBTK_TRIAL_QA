public without sharing class MIG_PDIStepUpdate_ba implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext context) {
        String selectFields =       'Id, VehicleStock__r.Name, Stage__c, IsPass__c, StepStart__c, StepEnd__c, StepWorker__c';
        String fromObject =         'PDIStep__c';
        String whereConditions =    'VehicleStock__r.AvisOrderInfo__r.CreatedDate >= YESTERDAY';

        String buildQuery = CommonUtilController.buildQuery(selectFields, fromObject, whereConditions, 'LastModifiedDate');
        return Database.getQueryLocator(buildQuery);
    }

    public void execute(Database.BatchableContext context, List<PDIStep__c> objList) {
        Map<String, List<PDIStep__c>> stepMap = new Map<String, List<PDIStep__c>>();
        for(PDIStep__c step : objList) {
            String key = step.VehicleStock__r.Name;

            List<PDIStep__c> steps = stepMap.containsKey(key)
                    ? stepMap.get(key)
                    : new List<PDIStep__c>();
            steps.add(step);

            stepMap.put(key, steps);
        }

        List<TruckMaster__c> trucks = [
                SELECT ChassisFrameNo__c,
                        St1Start__c, St1End__c, St1Worker__c,
                        St3Start__c, St3End__c, St3Worker__c,
                        St4Start__c, St4End__c, St4Worker__c,
                        St5Start__c, St5End__c, St5Worker__c,
                        St6Start__c, St6End__c, St6Worker__c,
                        St7Start__c, St7End__c, St7Worker__c,
                        ETA__c, Status__c, PDIEntryDate__c, DriveDistance__c, Remark__c, Engine__c, Shasi__c, Washing__c, Exterior__c, Function__c
                FROM TruckMaster__c
        ];

        // PDI Step데이터들 Update
        List<PDIStep__c> updateList = new List<PDIStep__c>();
        for(TruckMaster__c truck : trucks) {
            String key = truck.ChassisFrameNo__c;
            List<PDIStep__c> stepList = stepMap.get(key);

            if(stepList != null) {
                Map<String, PDIStep__c> stepStageMap = new Map<String, PDIStep__c>();
                for (PDIStep__c step : stepList) {
                    stepStageMap.put(step.Stage__c, step);
                }
                if (truck.St1Start__c != null) {
                    PDIStep__c step = stepStageMap.get('STEP1');
                    if(step != null) {
                        step.IsPass__c = true;
                        step.StepStart__c = truck.St1Start__c;
                        step.StepEnd__c = truck.St1End__c;
                        step.StepWorker__c = truck.St1Worker__c;
                        updateList.add(step);
                    }
                }
                if (truck.St3Start__c != null) {
                    PDIStep__c step = stepStageMap.get('STEP2');
                    if(step != null) {
                        step.IsPass__c = true;
                        step.StepStart__c = truck.St3Start__c;
                        step.StepEnd__c = truck.St3End__c;
                        step.StepWorker__c = truck.St3Worker__c;
                        updateList.add(step);
                    }
                }
                if (truck.St4Start__c != null) {
                    PDIStep__c step = stepStageMap.get('STEP3');
                    if(step != null) {
                        step.IsPass__c = true;
                        step.StepStart__c = truck.St4Start__c;
                        step.StepEnd__c = truck.St4End__c;
                        step.StepWorker__c = truck.St4Worker__c;
                        updateList.add(step);
                    }
                }
                if (truck.St5Start__c != null) {
                    PDIStep__c step = stepStageMap.get('STEP4');
                    if(step != null) {
                        step.IsPass__c = true;
                        step.StepStart__c = truck.St5Start__c;
                        step.StepEnd__c = truck.St5End__c;
                        step.StepWorker__c = truck.St5Worker__c;
                        updateList.add(step);
                    }
                }
                if (truck.St6Start__c != null) {
                    PDIStep__c step = stepStageMap.get('STEP5');
                    if(step != null) {
                        step.IsPass__c = true;
                        step.StepStart__c = truck.St6Start__c;
                        step.StepEnd__c = truck.St6End__c;
                        step.StepWorker__c = truck.St6Worker__c;
                        updateList.add(step);
                    }
                }
            }
        }
        update updateList;

    }

    public void finish(Database.BatchableContext context) {

        Database.executeBatch(new MIG_ProductUpdate_ba(), 1000);
        System.debug('########## MIG_PDIStepUpdate_ba Migration Finish ##########');
    }
}