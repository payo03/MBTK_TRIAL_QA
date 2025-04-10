/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-07
 * @description : 개인정보활용동의서 랜딩페이지 이동
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-07        San.Kang           Created
**************************************************************/
public class Ctrl_AgreementLocatorController {
    private Id vehicleStockId;
    public String errMsg{get; set;}
    public String baseURL{get; set;}
    public Ctrl_AgreementLocatorController(ApexPages.StandardController controller){
        vehicleStockId = controller.getId();
        errMsg = '';
    }

    public PageReference Redirect(){
        List<Opportunity> opportunities = PDFCommonController.getOpportunity(vehicleStockId);

        if(!opportunities.isEmpty()){
            String baseURL = Url.getSalesforceBaseUrl().toExternalForm();
            Boolean checkSandbox = baseURL.contains('sandbox') ? true : false;
            Opportunity opportunity = opportunities[0];
            CustomerConsent__c customerConsent = new CustomerConsent__c(Account__c = opportunity.AccountId,
                    ConsentStatus__c = '링크 전송됨',
                    Type__c = '고객');
            insert customerConsent;
            baseURL = checkSandbox ? 'https://app-force-1035--partial.sandbox.my.salesforce-sites.com/extlanding?Id='+customerConsent.Id : '';
            System.debug('cc'+customerConsent);
            if(opportunity.Account.RecordType.Name.equals('법인사업자')){
                if (opportunity.Account.PersonMobilePhone == null){
                    return new PageReference(baseURL);
                }else{
                    errMsg = '법인고객의 대표자 연락처 정보가 없습니다.';
                }
            }else{
                return new PageReference(baseURL);
            }
        }else{
            errMsg = '영업기회가 없는 차량입니다.';
        }
        return null;
    }
}