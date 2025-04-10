/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-13
 * @description : MDS 가입서류 PDF
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-13        San.Kang           Created
**************************************************************/
public without sharing class MDSRegisterFormController {
    public Opportunity opportunity{get; set;}
    public String addressDetail{get; set;}
    public String replaceHP{get; set;}
    public String validationStr{get; set;}
    public String docImg{get; set;}
    public String addressDetailStyle{get; set;}

    public MDSRegisterFormController(){}

    public void init(){
        opportunity = PDFCommonController.getOpportunity(ApexPages.currentPage().getParameters().get('Id')).get(0);
        
        addressDetail = opportunity.Account.RoadAddress__c + opportunity.Account.DetailAddress__c;

        if(!String.isBlank(addressDetail) && addressDetail.length() > 25){
            addressDetailStyle = 'font-size:8pt; line-height:0.9em;';
            if(addressDetail.length() > 33){
                if(addressDetail.contains('(')){
                    List<String> spl = addressDetail.split('\\(');
                    addressDetail = spl[0] + '<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(' + spl[1];
                }else{
                    addressDetail = addressDetail.left(33) + '<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + addressDetail.right(addressDetail.length()-33);
                }
                addressDetailStyle += ' vertical-align:top;';
            }
            addressDetail = '&nbsp;&nbsp;&nbsp;' + addressDetail;
        }

        replaceHP = opportunity.Account.PersonMobilePhone;
        if(!String.isBlank(replaceHP)){
            replaceHP = '+82'+replaceHP.removeStart('0').replace('-','');
        }
        validationStr = validData();

        String server = ApexPages.currentPage().getHeaders().get('X-Salesforce-Forwarded-To');
        Boolean isSdbx = server!= null && server.toUpperCase().startsWith('C');
        docImg = PDFCommonController.getDocumentId('ActivationSheetBackground2');
    }

    private String validData(){
        String msg = '';

        if(String.isBlank(opportunity.Account.LastName) && String.isBlank(opportunity.Account.FirstName)){
            msg += ',실차주명이 없습니다.';
        }
        if(addressDetail == null){
            msg += ',도로명 주소가 없습니다.';
        }else{
            if(String.isBlank(opportunity.Account.PostalCode__c)){
                msg += ',우편번호가 없습니다.';
            }
        }
        if(String.isBlank(opportunity.NoMDSApprover__r.Email)){
            msg += ',MSD 가입용 이메일이 없습니다.';
        }
        if(String.isBlank(replaceHP)){
            msg += ',전화번호가 없습니다.';
        }
        if(String.isBlank(opportunity.Account.Owner.Name)){
            msg += ',판매담당자 이름이 없습니다.';
        }
        if(String.isBlank(opportunity.Account.Owner.Agency__c)){
            msg += ',지점명이 없습니다.';
        }
        return msg.removeStart(',');
    }
}