/*************************************************************
 * @author : San.Kang
 * @date : 2025-02-13
 * @description : 국세환급금양도요구서 PDF
 * @target : 
==============================================================
 * Ver          Date            Author          Modification
 * 1.0       2025-02-13        San.Kang           Created
**************************************************************/
public class TaxRefundController {
//    public Opportunity op{get; set;}
    public TaxRefundController(){}
    public String bzIngam{get; set;}

    public void init() {
        bzIngam = PDFCommonController.getDocumentId('man_bizingam');
    }
}