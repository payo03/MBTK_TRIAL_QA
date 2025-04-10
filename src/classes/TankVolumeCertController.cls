/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-10
 * @description : 임시운행허가신청서 PDF
 * @target :
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-10        San.Kang           Created
**************************************************************/
public class TankVolumeCertController {
    public String vehicleStockId {get; set;}
    public String docImage1 {get; set;}
    private ApexPages.StandardController ctrl;
    public VehicleStock__c vehicleStock {get; set;}
    public String vin {get; set;}
    public Decimal volume {get; set;}
    public Boolean checkDump {get;set;}
//    public String AccNo {get;set;}

    public TankVolumeCertController(){
    }

    public void init(){
        vehicleStockId = ApexPages.currentPage().getParameters().get('id');
        docImage1 = PDFCommonController.getDocumentId('MAN_Truck_Bus_Korea_LOGO');
        vehicleStock = PDFCommonController.getVehicleStock(vehicleStockId);

        vin = vehicleStock.Name != null ? vehicleStock.Name : '';
        if(vehicleStock.TankVolumeManual__c != null){
            volume = vehicleStock.TankVolumeManual__c;
        }else{
            Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get('AvisOrderInfo__c')
                    .getDescribe().fields.getMap().get('ref_TankVolumeList__c').getDescribe();
            System.debug('avisOrderInfo start');
            System.debug('avisOrderInfo start' + vin);
            List<AvisOrderInfo__c> avisOrderInfo = [SELECT Id, ref_TankVolumeList__c FROM AvisOrderInfo__c WHERE ChassisFrameNo__c =:vin ];
            if(!avisOrderInfo.isEmpty()){
                for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                    if (entry.getValue() == avisOrderInfo[0].ref_TankVolumeList__c) volume = Decimal.valueOf(CommonUtilController.sliceUBarBefore(entry.getLabel())); break;
                }
            }
        }

        //기존 덤프 조건
        checkDump = (('TGS_41.510_8X4_BB'.equals(vehicleStock.Product__r.VehicleCategory__r.Name) || 'TGS_41.470_8X4_BB'.equals(vehicleStock.Product__r.VehicleCategory__r.Name)) && 'M'.equals(vehicleStock.Product__r.VehicleCategory__r.CabMark__c));

        //신규 덤프 조건 추가 - 220114
        if(!checkDump){
            checkDump = (('TGS_41.510_8x4_BB_CH'.equals(vehicleStock.Product__r.VehicleCategory__r.Name) || 'TGS_41.470_8x4_BB_CH'.equals(vehicleStock.Product__r.VehicleCategory__r.Name)) && 'NN'.equals(vehicleStock.Product__r.VehicleCategory__r.CabMark__c));
        }

//        AccNo = String.isEmpty(vehicleStock.AcceptedNo_Formula__c) ? vehicleStock.CarType__r.AcceptedNo__c : vehicleStock.AcceptedNo_Formula__c;
    }
}