/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-12
 * @description : 
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-12        San.Kang           Created
**************************************************************/
public with sharing class SignatureController {

    @AuraEnabled
    public static void signSave(String url, String param, String type){
        System.debug('url'+url);
        if(!param.equals('') && param!=null){
            if(!sObjectQuery(param, type).isEmpty()) delete sObjectQuery(param, type);
            Id document = saveImg(url, param+'&n='+type);

            Signature__c signature = new Signature__c();
//            signature.Opportunity__c = !sObjectQuery(param,'').isEmpty()?param:null;
//            signature.Account__c = !sObjectQuery(param,'').isEmpty()?param:null;
//            signature.Lead__c = !sObjectQuery(param,'').isEmpty()?param:null;
//            signature.Contact__c = !sObjectQuery(param,'').isEmpty()?param:null;
//            signature.User__c = !sObjectQuery(param,'').isEmpty()?param:null;
            signature.VehicleStock__c = [SELECT COUNT() FROM VehicleStock__c WHERE Id =:param]>0?param:null;
            signature.Url__c = '/servlet/servlet.FileDownload?file=' + document;
            signature.SignType__c = type;
            insert signature;
            System.debug('type:'+type);
            System.debug('signature:'+signature);
            if(type=='차량재고-차량인수서명'){
                VehicleStock__c vehicleStock = [SELECT Id, SignComplete__c FROM VehicleStock__c WHERE Id=:param];
                vehicleStock.SignComplete__c = true;

                List<Opportunity> opportunity = [SELECT Id, AccountId, Account.RecordType.Name FROM Opportunity WHERE VehicleStock__c =:vehicleStock.Id];

                if(!opportunity.isEmpty()){
                    if(opportunity[0].AccountId != null){
                        Id document2 = saveImg(url, param+'&n=2');
                        Signature__c signature2 = new Signature__c();
                        signature2.Url__c = '/servlet/servlet.FileDownload?file=' + document2;
                        signature2.SignType__c = '고객-서명';
                        if(opportunity[0].Account.RecordType.Name.equals('법인사업자')){
                            List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId =:opportunity[0].AccountId ORDER BY CreatedDate];
                            if(!contacts.isEmpty()){
                                signature2.Contact__c = contacts[0].Id;
                            }else{
                                signature2.Account__c = opportunity[0].AccountId;
                            }
                        }else{
                            signature2.Account__c = opportunity[0].AccountId;
                        }
                        insert signature2;
                    }
                }
                update vehicleStock;
            }
            if(type=='차량관리-주유상품권서명'){
                VehicleStock__c vehicleStock = [SELECT Id, SignComplete_oil__c FROM VehicleStock__c WHERE Id=:param];
                vehicleStock.SignComplete_oil__c = true;
                update vehicleStock;
                System.debug('vehicleStock:'+vehicleStock);
            }
        }
    }

    public static List<SObject> sObjectQuery(String recordId, String type){
        String objName = Id.valueOf(recordId).getSobjectType().getDescribe().getName();
        String selectFields = ' Id ';
        String whereConditions = objName + ' = \'' + recordId + '\'' +  ' AND SignType__c = \'' + type + '\'';
        String query = CommonUtilController.buildQuery(selectFields, 'Signature__c', whereConditions);

        return Database.query(query);
//        if([SELECT COUNT() FROM Signature__c WHERE Opportunity__c = :param AND SignType__c =:type]>0)
//            delete [SELECT Id FROM Signature__c WHERE Opportunity__c = :param AND SignType__c =:type];
//
//        if([SELECT COUNT() FROM Signature__c WHERE Account__c = :param AND SignType__c =:type]>0)
//            delete [SELECT Id FROM Signature__c WHERE Account__c = :param AND SignType__c =:type];
//
//        if([SELECT COUNT() FROM Signature__c WHERE Truck__c = :param AND SignType__c =:type]>0)
//            delete [SELECT Id FROM Signature__c WHERE Truck__c = :param AND SignType__c =:type];
//
//        if([SELECT COUNT() FROM Signature__c WHERE Lead__c = :param AND SignType__c =:type]>0)
//            delete [SELECT Id FROM Signature__c WHERE Lead__c = :param AND SignType__c =:type];
//
//        if([SELECT COUNT() FROM Signature__c WHERE User__c = :param AND SignType__c =:type]>0)
//            delete [SELECT Id FROM Signature__c WHERE User__c = :param AND SignType__c =:type];
    }

    public static Id saveImg(String url, String param){
        Document document = new Document();
        document.FolderId=UserInfo.getUserId();
        document.IsPublic=true;
        document.Name=param;
        document.Body=EncodingUtil.base64Decode(url.remove('data:image/png;base64,'));
        document.Type='png';
        insert document;
        return document.Id;
    }
//    @RemoteAction
//    public static void deleteAll(){
//        List<Signature__c> signatures = [SELECT Id, Url__c FROM Signature__c];
//        List<String> opid = new List<String>();
//        for(Signature__c sg : signatures)
//            opid.add((sg.Url__c).remove('/servlet/servlet.FileDownload?file='));
//        List<Document> docs = [SELECT Id FROM Document WHERE Id IN :opid];
//        delete signatures;
//        delete docs;
//    }
}