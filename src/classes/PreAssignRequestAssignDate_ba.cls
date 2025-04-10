/*************************************************************
 * @author : San.Kang
 * @date : 2025-01-08
 * @description : 배정완료 상태이면서 타입이 사전배정, 10일 경과된 배정날짜인 사전배정요청 레코드 자동취소 상태값 업데이트 배치
 *              1. Implements Schedulable 등록
 *              2. 생성자, SchedulableContext 인자를 갖는 execute함수 생성
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-01-08        San.Kang           Created
**************************************************************/
public without sharing class PreAssignRequestAssignDate_ba {
//    //오늘부터 10일 경과된 배정날짜
//    private final static Date AssignmentDate = System.today().addDays(-10);
//
//    //배정완료 상태이면서 타입이 사전배정, 10일 경과된 배정날짜인 사전배정요청 레코드 쿼리
//    public Database.QueryLocator start(Database.BatchableContext context) {
//        String SelectQuery =  getField();
//        String WhereQuery = '  AssignmentDate__c =:AssignmentDate AND Status__c = \'배정완료\' AND Type__c = \'사전배정\' AND Opportunity__r.StageName = \'Contract\' ' ;
//
//        String query = CommonUtilController.buildQuery(SelectQuery, 'PreAssignRequest__c' , WhereQuery);
//        return Database.getQueryLocator(query);
//    }
//
//    public PreAssignRequestAssignDate_ba() {
//
//    }
//
//    public void execute(SchedulableContext context) {
//        Database.executeBatch(new PreAssignRequestAssignDate_ba(), 200);
//    }
//
//    //쿼리된 레코드들의 status를 자동취소로 업데이트
//    public void execute(Database.BatchableContext context, List<PreAssignRequest__c> records) {
//        try {
//            List<PreAssignRequest__c> UpdatePreAssignRequestList = new List<PreAssignRequest__c>();
//            List<VehicleStock__c> UpdateVehicleStockList = new List<VehicleStock__c>();
//            Set<Id> VehicleStockId = new Set<Id>();
//
//            for(PreAssignRequest__c pa : records){
//                VehicleStockId.add(pa.VehicleStock__c);
//                pa.Status__c = '자동취소';
//                pa.CancelDate__c = system.today();
//                UpdatePreAssignRequestList.add(pa);
//            }
//            List<VehicleStock__c> VehicleStockList = [SELECT Id, AssignmentStatus__c FROM VehicleStock__c WHERE Id IN:VehicleStockId ];
//            for(VehicleStock__c vs : VehicleStockList){
//                vs.AssignmentStatus__c = '배정 취소';
//                UpdateVehicleStockList.add(vs);
//            }
//
//            if(UpdatePreAssignRequestList.size()>0) Update UpdatePreAssignRequestList;
//            if(UpdateVehicleStockList.size()>0) Update UpdateVehicleStockList;
//
//        } catch (Exception e) {
//            System.debug('Error => ' + e.getStackTraceString() + ' msg ' + e.getMessage());
//        }
//    }
//    public void finish(Database.BatchableContext BC){
//        System.debug('#####Finish!!#####');
//    }
//
//    public String getField(){
//        String Field = ' Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, ' +
//                ' SystemModstamp, LastActivityDate, LastViewedDate, LastReferencedDate, Opportunity__c, VehicleStock__c, Submitter__c, ' +
//                ' Status__c, Type__c, VehicleCategory__c, RequestDate__c ';
//
//        return Field;
//    }
}