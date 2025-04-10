/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2025-03-28      jh.jung           Created
*/
public with sharing class AsyncKakaoByCreatePDF implements Queueable, Database.AllowsCallouts {

    Map<String, Object> paramMap;

    public AsyncKakaoByCreatePDF(Map<String, Object> paramMap) {
        this.paramMap = paramMap;
    }

    public void execute(QueueableContext context) {
        InterfaceKakao.doCallOutKakaoAlimTalk(paramMap);
    }

//    String recordId;
//    String selectedOption;
//    Map<String, String> signInfo;
//    String language;
//
//    Map<String, String> kakaoNameMap = new Map<String, String> {
//            'all' => '계약서 및 MDS/RIO 동의서 서명 요청',
//            'contract' => '계약서 서명 요청',
//            'riomds' => 'MDS/RIO 동의서 서명 요청'
//    };
//
//    public AsyncModusignByCreatePDF(String recordId, String selectedOption, Map<String, String> signInfo, String language) {
//        this.recordId = recordId;
//        this.selectedOption = selectedOption;
//        this.signInfo = signInfo;
//        this.language = language;
//    }
//
//    public void execute(QueueableContext context) {
//        System.debug('AsyncModusignByCreatePDF ::: ' + recordId);
//
//        try {
//            // Visualforce 페이지 생성 및 데이터 전달
//            PageReference pdfPage = Page.ModusignPDFTemplate; // Visualforce 페이지 이름
//
//            pdfPage.getParameters().put('recordId', recordId);
//            pdfPage.getParameters().put('selectedOption', selectedOption);
//            pdfPage.getParameters().put('language', language);
//
//            // PDF 생성
//            Blob pdfBlob = pdfPage.getContentAsPDF();
//
//            String file = EncodingUtil.base64Encode(pdfBlob);
//            System.debug('이미지 인코딩 길이 ::: ' + file.length());
//            System.debug('PDF 생성 완료 - 언어: ' + language);
//
//            // Heroku 타고 PDF 페이지 수 알아오기
//            Integer lastPageNum = CommonUtilCustomController.getPDFPageNumber(file);
//
//            System.debug('total page :::' + lastPageNum);
//
//            IF_DTO.SigningRequestByPDF signingRequest = createRequest(file, selectedOption, recordId, signInfo, lastPageNum);
//
//            // 모두사인 요청
//            Map<String, Object> responseMap = InterfaceModuSign.doCallOutSignRequestByPDF(signingRequest, recordId);
//
//            System.debug('code ::: ' + responseMap.get('code'));
//
//            // 계약서가 포함된 경우에만 계약 상태 업데이트
//            if(responseMap != null &&
//                    Boolean.valueOf(responseMap.get('code')) &&
//                    ('all'.equals(selectedOption) || 'contract'.equals(selectedOption))) {
//
//                Contract contract = new Contract(Id = recordId);
//                contract.ConStatus__c = '모두싸인 발송';
//                update contract;
//            }
//
//            // 성공시 카카오톡
//            if (HttpCallOutConsts.SUCCESS_CODES.contains(Integer.valueOf(responseMap.get('statusCode')))) {
//                //this.recordId, this.selectedRowInfo["Id"], this.selectedOption
//                Map<Object, Object> infoMap = new Map<Object, Object>{
//                        'recordId' => signInfo.get('Id')
//                        , 'customerType' => '실차주'.equals(signInfo.get('Info')) ? 'realdriver' : 'owner'
//                };
//
//                Map<String, Object> paramMap = new Map<String, Object>{
//                        'templateTitle' => kakaoNameMap.get(selectedOption),
//                        'recordId' => recordId,
//                        'infoMapList' => new List<Object>{
//                                infoMap
//                        },
//                        'externalId' => recordId
//                };
//
//                Map<String, Object> resultMap = InterfaceKakao.doCallOutKakaoAlimTalk(paramMap);
//                System.debug('ModuSignPDFKakao ::: ' + JSON.serialize(resultMap));
//                // 실패시 로그 남기기
//                if (!HttpCallOutConsts.SUCCESS_CODES.contains(Integer.valueOf(resultMap.get('statusCode')))) {
//                    System.debug('카카오톡 에러... 따로 로그는 안남김');
//                }
//            }
//        } catch (AuraHandledException e) {
//            System.debug('error ::: ' + e.getMessage());
//            System.debug('error ::: ' + e.getStackTraceString());
//        } catch (Exception e) {
//            System.debug('error ::: ' + e.getMessage());
//            System.debug('error ::: ' + e.getStackTraceString());
//        }
//    }
}