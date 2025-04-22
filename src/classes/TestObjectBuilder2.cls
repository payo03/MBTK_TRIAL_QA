/**
* @Author            : payo03@solomontech.net
* @Description 		 :
* @Target            :
* @Modification Log
  Ver      Date            Author                           Modification
  ===================================================================================
  1.0      2025-04-01      payo03@solomontech.net           Created
*/

public class TestObjectBuilder2 {

    @TestVisible static Account                         accountPerson;
    @TestVisible static Account                         accountCompany;
    @TestVisible static Account                         accountLicense;
    @TestVisible static ConfigMaster__c                 configCondition;
    @TestVisible static ConfigMaster__c                 configPLCalcInfo;
    @TestVisible static ConfigMaster__c                 configEmail;
    @TestVisible static ConfigMaster__c                 configManCode;
    @TestVisible static ConfigMaster__c                 configHandover;
    @TestVisible static Map<String, ConfigMaster__c>    configManCodeMap;
    @TestVisible static Map<String, ConfigMaster__c>    configEmailMap;
    @TestVisible static Map<String, ConfigMaster__c>    configMasterMap;
    @TestVisible static List<ConfigDetail__c>           configDetailList;
    @TestVisible static List<AvisOrderInfo__c>          infoList;
    @TestVisible static List<AvisConfig__c>             configList;
    @TestVisible static List<IF_Master__c>              ifMasterList;
    @TestVisible static List<AssignRequest__c>          requestList;
    @TestVisible static VehicleCategory__c              vehicleCategory;
    @TestVisible static Product2                        product;
    @TestVisible static Pricebook2                      pricebook;
    @TestVisible static PricebookEntry                  pricebookEntry;
    @TestVisible static Lead                            lead;
    @TestVisible static Lead                            dupLead;
    @TestVisible static CampaignMaster__c               amtCampaign;
    @TestVisible static CampaignMaster__c               percentCampaign;
    @TestVisible static CampaignPreventDuplicate__c     campaignPreventDup;
    @TestVisible static CampaignJunction__c             campaignJunction;
    @TestVisible static Contract                        contract;
    @TestVisible static Contract                        contractAdvance;
    @TestVisible static Opportunity                     opportunity;
    @TestVisible static Opportunity                     opportunityAdvance;
    @TestVisible static VehicleStock__c                 vehicleStock;
    @TestVisible static VirtualAccountMaster__c         virtualAccountMaster;
    @TestVisible static List<VirtualAccountMaster__c>   virtualAccountMasterList;
    @TestVisible static VirtualAccount__c               virtualAccount;
    @TestVisible static VirtualAccount__c               virtualAccountAdvance;
    @TestVisible static Template__c                     templateModuSign;
    @TestVisible static Template__c                     templateKakao;
    @TestVisible static List<TemplateButton__c>         templateButtonList;
    @TestVisible static APIDocument__c                  apiDocument;
    @TestVisible static Quote                           quote;
    @TestVisible static Quote                           quoteCopy;
    @TestVisible static Contact                         contact;
    @TestVisible static VehicleOptionMaster__c          option;
    @TestVisible static ProductOption__c                productOption;
//    @TestVisible static OilCouponMaster__c              oilCoupon;
    @TestVisible static List<QuoteDetail__c>            quoteDetailList;
    @TestVisible static List<QuoteDetail__c>            quoteDetailListCopy;
    @TestVisible static Finance__c                      finance;
    @TestVisible static ServiceItemsMaster__c           serviceItem;
    @TestVisible static SalesConditionMaster__c         salesConditionMaster;
    @TestVisible static DefermentRequest__c             defermentRequest;
    @TestVisible static DefermentRequest__c             defermentRequest2;
    @TestVisible static User                            user;
    @TestVisible static User                            managerUser;
    @TestVisible static PaymentLog__c                   paymentLog;
    @TestVisible static PaymentType__c                  paymentTypeDeposit;
    @TestVisible static List<PaymentType__c>            paymentTypeList;
    @TestVisible static PaymentTracker__c               paymentTracker;
    @TestVisible static Handover__c                     handover;
    @TestVisible static List<SpoilerPart__c>            spoilerList;
    @TestVisible static SpoilerPartsJuntion__c          spoilerPartsJuntion;
    @TestVisible static List<IncentiveTargetMaster__c>  incentiveTargetMasterList;
    @TestVisible static List<Document>                  documentList;
    @TestVisible static AvgLocalCost__c                 avgLocalCost;
    @TestVisible static SpecTypeNo__c                   specTypeNo;
    @TestVisible static List<CustomerConsent__c>        customerConsent;
    @TestVisible static List<Signature__c>              signature;
    @TestVisible static CustomCalendar__c               customCalendar;
    @TestVisible static GoodWillMaster__c               goodWillMaster;
    @TestVisible static GoodWillSaving__c               goodWillSaving;
    @TestVisible static GoodWillUsing__c                goodWillUsing;
    @TestVisible static List<PDIStep__c>                pdiStepList;
    @TestVisible static ApprovalHierarchy__c            approvalHierarchy;
    @TestVisible static SelfCertWeightLabel__c          selfCertWeightLabel;
    @TestVisible static SelfCertWeightLabelDtl__c       selfCertWeightLabelDtl;
    @TestVisible static CommissionManagement__c         commissionManagement;
    @TestVisible static CommissionHistory__c            commissionHistory;
    @TestVisible static IncentiveHistory__c             incentiveHistory;

    public static Account createAccountPerson() {
        if(accountPerson == null) {
            accountPerson = new Account();
            accountPerson.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACCOUNT_PERSON').getRecordTypeId();
            accountPerson.LastName = '테스트 개인 계정';
            accountPerson.IDNumber__pc = '880420-1231232';
            accountPerson.PersonMobilePhone = '090-9999-1919';
            accountPerson.BusinessNumber__c = '878-87-03231';
            accountPerson.BusinessName__c = 'TEST 사업자 명';
            accountPerson.RoadAddress__c = '서울 금천구 디지털로 178';
            accountPerson.DetailAddress__c = '가산퍼블릭 719';
            accountPerson.Description = 'Test Description';
            accountPerson.Phone = '090-9999-1919';
            accountPerson.PersonEmail = 'test@example.com';
            accountPerson.PostalCode__c = '123456';
        }
        return accountPerson;
    }

    public static Account createAccountCompany() {
        if(accountCompany == null) {
            accountCompany = new Account();
            accountCompany.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACCOUNT_CORPORATE').getRecordTypeId();
            accountCompany.Name = '테스트 회사 계정';
            accountCompany.Phone = '02-9899-7875';
            accountCompany.NumberOfEmployees = 999;
            accountCompany.BusinessNumber__c = '987-65-43210';
        }
        return accountCompany;
    }

    public static Account createAccountLicense() {
        if(accountLicense == null) {
            accountLicense = new Account();
            accountLicense.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACCOUNT_PERSON').getRecordTypeId();
            accountLicense.LastName = 'TEST';
            accountLicense.AccountType__c = 'LICENSE';
            accountLicense.User__c = UserInfo.getUserId();
            accountLicense.IDNumber__pc = '880420-1231233';
            accountLicense.PersonMobilePhone = '090-9999-1919';
            accountLicense.BusinessNumber__c = '878-87-03231';
            accountLicense.BusinessName__c = 'TEST 사업자 명';
            accountLicense.RoadAddress__c = '서울 금천구 디지털로 178';
            accountLicense.DetailAddress__c = '가산퍼블릭 719';
            accountLicense.Description = 'Test Description';
            accountLicense.Phone = '090-9999-1919';
            accountLicense.PersonEmail = 'test@example.com';
            accountLicense.PostalCode__c = '123456';
        }
        return accountLicense;
    }

    public static List<AvisOrderInfo__c> createAvisOrderInfoList() {
        if(infoList == null) {
            infoList = new List<AvisOrderInfo__c>();

            for(Integer i = 1; i <= 2; i++) {
                Integer idx = 100 + i;
                String idxStr = String.valueOf(idx);

                AvisOrderInfo__c info = new AvisOrderInfo__c();
                info.SpecShort__c = 'TGL 10.220 4x2 BL CH';
                info.ChassisFrameNo__c = 'A00' + i;
                info.EmissionLevelEu__c = 'EURO6D';
                info.InvoiceNumber__c = 'I00' + i;
                info.CabMark__c = 'GX';
                info.WheelBase__c = '4405';
                info.TrimLevel__c = 'EL';
                info.Cab_Color__c = 'MYSTIC OCEAN';
                info.IsSpoiler__c = 1;

                info.BuyingPrice__c = idx;
                info.RAL_Code__c = idxStr;
                info.WeightKg__c = idxStr;

                info.IsMail__c = false;
                info.ETA__c = Date.today();

                info.OrderIntakeNo__c = idxStr;
                if(!infoList.isEmpty()) {
                    info.OrderConfirmSAP__c = 'Y';
                    info.PurchaseInvoiceSAP__c = 'N';
                    info.InvoiceNumber__c = '123456';
                }
                infoList.add(info);
            }
        }
        return infoList;
    }

    public static List<SpoilerPart__c> createSpoilerList() {
        if(spoilerList == null) {
            spoilerList = new List<SpoilerPart__c>();
            if(infoList == null) insert createAvisOrderInfoList();


            Integer i = 100;
            for(AvisOrderInfo__c info : [
                    SELECT Id, fm_SpoilerText__c
                    FROM AvisOrderInfo__c
            ]) {
                SpoilerPart__c spoiler = new SpoilerPart__c();
                spoiler.Name = info.fm_SpoilerText__c;
                spoiler.SpoilerCode__c = 'ML' + i;
                spoiler.Price__c = i;

                i += 100;
                spoilerList.add(spoiler);
            }
        }
        return spoilerList;
    }

    public static SpoilerPartsJuntion__c createSpoilerPartsJuntion() {
        if(spoilerPartsJuntion == null) {
            spoilerPartsJuntion = new SpoilerPartsJuntion__c();
            if(spoilerList == null) insert createSpoilerList();

            spoilerPartsJuntion.Name = 'Test';
            spoilerPartsJuntion.SpoilerParts__c = spoilerList[0].Id;

        }
        return spoilerPartsJuntion;
    }

    public static List<AvisConfig__c> createAvisConfigList() {
        if(configList == null) {
            configList = new List<AvisConfig__c>();
            if(infoList == null) insert createAvisOrderInfoList();

            for(Integer i = 1; i <= infoList.size(); i++) {
                Integer idx = 100 + i;
                String idxStr = String.valueOf(idx);

                AvisConfig__c config = new AvisConfig__c();
                config.OrderIntakeNo__c = idxStr;
                config.CodeNo__c = '0P0JX'; // EURO6D
                config.IsActive__c = true;

                if(infoList.size() == i) config.CodeNo__c = '0PHZN'; // EURO6E
                configList.add(config);
            }

            for(Integer i = 1; i <= infoList.size(); i++) {
                Integer idx = 100 + i;
                String idxStr = String.valueOf(idx);
                
                AvisConfig__c config = new AvisConfig__c();
                config.OrderIntakeNo__c = idxStr;
                config.CodeNo__c = '0PHOQ';    // MY20
                config.IsActive__c = true;

                if(infoList.size() == i) config.CodeNo__c = '0PHOR'; // MY24
                configList.add(config);
            }
        }
        return configList;
    }

    public static ConfigMaster__c createConfigEmail() {
        if(configEmail == null) {
            configEmail = new ConfigMaster__c();

            configEmail.RecordTypeId = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('EMAIL').getRecordTypeId();
            configEmail.Name = 'MAN2000';
            configEmail.Value__c = 'EMAIL INFO';
        }
        return configEmail;
    }

    public static ConfigMaster__c createConfigCondition() {
        if(configCondition == null) {
            configCondition = new ConfigMaster__c();

            configCondition.RecordTypeId = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('SALES_CONDITION').getRecordTypeId();
            configCondition.Name = 'MAN1000';
            configCondition.Value__c = '판매조건';
        }
        return configCondition;
    }

    public static ConfigMaster__c createConfigPLCalcInfo() {
        if(configPLCalcInfo == null) {
            configPLCalcInfo = new ConfigMaster__c();

            configPLCalcInfo.RecordTypeId = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('PL_CAL_INFO').getRecordTypeId();
            configPLCalcInfo.Name = 'MAN6000';
            configPLCalcInfo.Value__c = '리포트 스펙별 평균 코스트';
        }
        return configPLCalcInfo;
    }

    public static ConfigMaster__c createConfigManCode() {
        if(configManCode == null) {
            configManCode = new ConfigMaster__c();

            configManCode.RecordTypeId = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('MAN_CODE').getRecordTypeId();
            configManCode.Name = 'MAN5000';
            configManCode.Value__c = 'MAN CODE SETTING';
        }
        return configManCode;
    }

    public static ConfigMaster__c createConfigHandoverDate() {
        if(configHandover == null) {
            configHandover = new ConfigMaster__c();

            configHandover.RecordTypeId = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('HANDOVER').getRecordTypeId();
            configHandover.Name = 'MAN3000';
            configHandover.Value__c = '출고일 SETTING';
        }
        return configHandover;
    }

    public static Map<String, ConfigMaster__c> createConfigModuSignMap() {
        if(configMasterMap == null) {

            configMasterMap = new Map<String, ConfigMaster__c>();
            ConfigMaster__c master = new ConfigMaster__c();
            for(Integer i = 1; i <= 2; i++) {
                ConfigMaster__c detailM = new ConfigMaster__c();
                if(i==1) {
                    master.RecordTypeId = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('MODUSIGN').getRecordTypeId();
                    master.Name = 'MAN9000';
                    master.Value__c = '모두싸인 템플릿 등록';

                    insert master;
                } else if(i==2) {
                    detailM.Parent__c = master.Id;
                    detailM.RecordTypeId = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('MODUSIGN').getRecordTypeId();
                    detailM.Name = 'MAN9001';
                    detailM.Value__c = '개인정보 수집 이용 동의서';

                    configMasterMap.put(detailM.Name, detailM);
                }
            }
        }
        return configMasterMap;
    }

    public static Map<String, ConfigMaster__c> createConfigEmailMap() {
        if(configEmailMap == null) {
            configEmailMap = new Map<String, ConfigMaster__c>();
            if(configEmail == null) insert createConfigEmail();

            for(Integer i = 1; i <= 2; i++) {
                ConfigMaster__c detailM = new ConfigMaster__c();
                if(i==1) {
                    detailM.Parent__c = configEmail.Id;
                    detailM.RecordTypeId = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('EMAIL_TARGET').getRecordTypeId();
                    detailM.Name = 'MAN2001';
                    detailM.Value__c = '선박 ARRIVAL LIST 공유대상';

                    configEmailMap.put(detailM.Name, detailM);
                } else if(i==2) {
                    detailM.Parent__c = configEmail.Id;
                    detailM.RecordTypeId = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('EMAIL_TARGET').getRecordTypeId();
                    detailM.Name = 'MAN2002';
                    detailM.Value__c = 'I/F 실패목록 공유대상';

                    configEmailMap.put(detailM.Name, detailM);
                }
            }
        }
        return configEmailMap;
    }

    public static Map<String, ConfigMaster__c> createConfigManCodeMap() {
        if(configManCodeMap == null) {
            configManCodeMap = new Map<String, ConfigMaster__c>();
            if(configManCode == null) insert createConfigManCode();

            for(Integer i = 1; i <= 1; i++) {
                ConfigMaster__c detailM = new ConfigMaster__c();
                if(i==1) {
                    detailM.Parent__c = configManCode.Id;
                    detailM.RecordTypeId = Schema.SObjectType.ConfigMaster__c.getRecordTypeInfosByDeveloperName().get('MAN_CODE').getRecordTypeId();
                    detailM.Name = 'MAN5001';
                    detailM.Value__c = 'TRP CODE SETTING';

                    configManCodeMap.put(detailM.Name, detailM);
                }
            }
        }
        return configManCodeMap;
    }

    public static List<ConfigDetail__c> createConfigDetailList() {
        if(configDetailList == null) {
            configDetailList = new List<ConfigDetail__c>();

            for(Integer i = 0; i <= 12; i++) {
                ConfigDetail__c detail = new ConfigDetail__c();
                if(i==0) {
                    if(configEmail == null) insert createConfigEmail();

                    detail.ConfigMaster__c = configEmail.Id;
                    detail.Name = 'MAN2001';
                    detail.Attribute1__c = 'AvisOrderInfo 메일전송 정보';
                } else if(i==1) {
                    if(configEmail == null) insert createConfigEmail();

                    detail.ConfigMaster__c = configEmail.Id;
                    detail.Name = 'MAN2002';
                    detail.Attribute1__c = 'I/F 실패목록 이메일 정보';
                } else if(i==2) {
                    if(configCondition == null) insert createConfigCondition();
                    if(product == null) insert createProduct();

                    detail.ConfigMaster__c = configCondition.Id;
                    detail.Name = product.Name;
                    detail.Attribute1__c = product.Generation__c;
                    detail.Attribute2__c = product.Segment2__c;
                    detail.Attribute3__c = product.LocalYear__c;
                    detail.Attribute4__c = product.ModelYear__c;
                    detail.Attribute5__c = 'EURO6C';
                    detail.Attribute6__c = '2.5';
                    detail.Attribute7__c = '2.5';
                    detail.Attribute8__c = String.valueOf(Date.today());
                    detail.Attribute9__c = String.valueOf(Date.today());
                    detail.Attribute10__c = CommonUtilController.formatDate(Datetime.now(), 'C').substring(0, 6);
                } else if(i==3) {
                    if(configMasterMap == null) insert createConfigModuSignMap().values();

                    detail.ConfigMaster__c = [SELECT Id FROM ConfigMaster__c WHERE Name = 'MAN9000'].Id;
                    detail.Name = 'MAN9001';
                    detail.Attribute1__c = '[샘플] 개인정보 수집 이용 동의서';
                } else if(i==4) {
                    if(configMasterMap == null) insert createConfigModuSignMap().values();

                    detail.ConfigMaster__c = configMasterMap.get('MAN9001').Id;
                    detail.Name = 'CustomInput1';
                    detail.Attribute1__c = 'Test Label';
                } else if(i==5) {
                    if(configEmailMap == null) insert createConfigEmailMap().values();

                    detail.ConfigMaster__c = configEmailMap.get('MAN2001').Id;
                    detail.Name = '선박 Arrival List 공유대상';
                    detail.Attribute1__c = 'sender@address.net';
                    detail.Attribute2__c = 'subject';
                    detail.Attribute3__c = 'body text';
                    detail.Attribute4__c = 'body end ';
                    detail.Attribute5__c = 'test.csv';
                    detail.Attribute6__c = 'Column1';
                    detail.Attribute7__c = 'SpecShort__c';
                    detail.Attribute20__c = 'receive@address.net';
                } else if(i==6) {
                    if(configEmailMap == null) insert createConfigEmailMap().values();

                    detail.ConfigMaster__c = configEmailMap.get('MAN2002').Id;
                    detail.Name = 'AvisOrderInfo__c';
                    detail.Attribute1__c = 'sender@address.net';
                    detail.Attribute2__c = 'subject';
                    detail.Attribute3__c = 'body text';
                    detail.Attribute4__c = 'body end ';
                    detail.Attribute5__c = 'test.csv';
                    detail.Attribute6__c = 'Column1';
                    detail.Attribute7__c = 'Id';
                    detail.Attribute20__c = 'receive@address.net';
                } else if(i==7) {
                    if(configPLCalcInfo == null) insert createConfigPLCalcInfo();

                    detail.ConfigMaster__c = configPLCalcInfo.Id;
                    detail.Name = 'TGX 44.520 10x4-6 BL CH GM 4405';
                    detail.Attribute1__c = String.valueOf(100 + i);
                    detail.Attribute2__c = String.valueOf(100 + i);
                    detail.Attribute3__c = String.valueOf(100 + i);
                    detail.Attribute4__c = 'true';
                } else if(i==8) {
                    if(configManCode == null) insert createConfigManCode();

                    detail.ConfigMaster__c = configManCode.Id;
                    detail.Name = 'MAN5001';
                    detail.Attribute1__c = 'TRPCode';
                } else if(i==9) {
                    if(configManCodeMap == null) insert createConfigManCodeMap().values();

                    detail.ConfigMaster__c = configManCodeMap.get('MAN5001').Id;
                    detail.Name = 'TG3L <= 10t';
                    detail.Attribute1__c = String.valueOf(100 + i);
                } else if(i==10) {
                    if(configHandover == null) insert createConfigHandoverDate();
                    detail.ConfigMaster__c = configHandover.Id;
                    detail.Name = 'CustomNormal';
                    detail.Attribute1__c = '일반차량';
                    detail.Attribute2__c = '3';
                } else if(i==11) {
                    if(configHandover == null) insert createConfigHandoverDate();
                    detail.ConfigMaster__c = configHandover.Id;
                    detail.Name = 'CustomPTO';
                    detail.Attribute1__c = 'PTO 장착';
                    detail.Attribute2__c = '7';
                } else if(i==12) {
                    if(configHandover == null) insert createConfigHandoverDate();
                    detail.ConfigMaster__c = configHandover.Id;
                    detail.Name = 'Product__r.VehicleCategory__r.AxleConfiguration__c';
                    detail.Attribute1__c = '특수차량';
                    detail.Attribute2__c = '5';
                    detail.Attribute20__c = '10x4, 4x2';
                }
                configDetailList.add(detail);
            }
        }
        return configDetailList;
    }

    public static List<IF_Master__c> createIfMasterList() {
        if(ifMasterList == null) {
            ifMasterList = new List<IF_Master__c>();

            for(Integer i = 0; i <= 25; i++) {
                IF_Master__c ifMaster = new IF_Master__c();

                ifMaster.PrefixURL__c = 'https://test.com';
                if(i==0) {
                    ifMaster.IF_Id__c = 'HEROKU_SMS000';
                    ifMaster.Method__c = 'GET';
                    ifMaster.Endpoint__c = 'https://test.com/api/check';
                    ifMaster.IsSendParameter__c = false;
                    ifMaster.IsLogInsert__c = false;
                } else if(i==1) {
                    ifMaster.IF_Id__c = 'HEROKU_SMS001';
                    ifMaster.Method__c = 'GET';
                    ifMaster.Endpoint__c = 'https://test.com/api/check';
                    ifMaster.IsSendParameter__c = false;
                    ifMaster.IsLogInsert__c = false;
                } else if(i==2) {
                    ifMaster.IF_Id__c = 'HEROKU_SMS004';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/stock/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = false;
                } else if(i==3) {
                    ifMaster.IF_Id__c = 'API_BIZ_CHK';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/biz/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = false;
                } else if(i==4) {
                    ifMaster.IF_Id__c = 'MDSIGN_003';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/modusign/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = true;
                } else if(i==5) {
                    ifMaster.IF_Id__c = 'MDSIGN_004';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/modusign/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = true;
                } else if(i==6) {
                    ifMaster.IF_Id__c = 'MDSIGN_006';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/modusign/request';
                    ifMaster.IsSendParameter__c = false;
                    ifMaster.IsLogInsert__c = true;
                } else if(i==7) {
                    ifMaster.IF_Id__c = 'MDSIGN_007';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/modusign/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = true;
                } else if(i==8) {
                    ifMaster.IF_Id__c = 'HEROKU_KAKAO_000';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/kakao/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = true;
                } else if(i==9) {
                    ifMaster.IF_Id__c = 'API_KAKAO_MAP';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/kakao/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = true;
                } else if(i==10) {
                    ifMaster.IF_Id__c = 'HEROKU_WSMOKA_001';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/wsmoka/request';
                    ifMaster.IsSendParameter__c = false;
                    ifMaster.IsLogInsert__c = true;
                } else if(i==11) {
                    ifMaster.IF_Id__c = 'MDSIGN_001';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/modusign/request';
                    ifMaster.IsSendParameter__c = false;
                    ifMaster.IsLogInsert__c = true;
                } else if(i==12) {
                    ifMaster.IF_Id__c = 'MDSIGN_002';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/modusign/request';
                    ifMaster.IsSendParameter__c = false;
                    ifMaster.IsLogInsert__c = true;
                } else if(i==13) {
                    ifMaster.IF_Id__c = 'MDSIGN_008';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/modusign/request';
                    ifMaster.IsSendParameter__c = false;
                    ifMaster.IsLogInsert__c = true;
                } else if(i==14) {
                    ifMaster.IF_Id__c = 'HEROKU_SFDC_PDF';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/stock/request';
                    ifMaster.IsSendParameter__c = false;
                    ifMaster.IsLogInsert__c = true;
                } else if(i==15) {
                    ifMaster.IF_Id__c = 'API_HOLIDAY';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/biz/request';
                    ifMaster.IsSendParameter__c = false;
                    ifMaster.IsLogInsert__c = true;
                } else if(i==16) {
                    ifMaster.IF_Id__c = 'API_EXCHANGE_RATE';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/biz/request';
                    ifMaster.IsSendParameter__c = false;
                    ifMaster.IsLogInsert__c = true;
                } else if(i==17) {
                    ifMaster.IF_Id__c = 'HEROKU_SMS010(Async)';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/stock/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = false;
                } else if(i==18) {
                    ifMaster.IF_Id__c = 'HEROKU_SMS011(Async)';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/stock/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = false;
                } else if(i==19) {
                    ifMaster.IF_Id__c = 'HEROKU_SMS012(Async)';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/stock/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = false;
                } else if(i==20) {
                    ifMaster.IF_Id__c = 'HEROKU_SMS013';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/stock/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = false;
                } else if(i==21) {
                    ifMaster.IF_Id__c = 'HEROKU_SMS014';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/stock/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = false;
                } else if(i==22) {
                    ifMaster.IF_Id__c = 'HEROKU_SMS015';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/stock/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = false;
                } else if(i==23) {
                    ifMaster.IF_Id__c = 'HEROKU_SMS016';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/stock/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = false;
                } else if(i==24) {
                    ifMaster.IF_Id__c = 'HEROKU_SMS017';
                    ifMaster.Method__c = 'POST';
                    ifMaster.Endpoint__c = 'https://test.com/api/stock/request';
                    ifMaster.IsSendParameter__c = true;
                    ifMaster.IsLogInsert__c = false;
                } else if(i==25) {
                    ifMaster.IF_Id__c = 'HEROKU_SMS002';
                    ifMaster.Method__c = 'GET';
                    ifMaster.Endpoint__c = 'https://test.com/api/check';
                    ifMaster.IsSendParameter__c = false;
                    ifMaster.IsLogInsert__c = false;
                }

                ifMasterList.add(ifMaster);
            }
        }
        return ifMasterList;
    }

    public static VehicleCategory__c createVehicleCategory() {
        if(vehicleCategory == null) {
            vehicleCategory = new VehicleCategory__c();
//            vehicleCategory.Name = 'TGL 10.190 4x2 BL CH TN 4850';
            vehicleCategory.ModelType__c = 'TGL';
            vehicleCategory.WeightCapacity__c = '10';
            vehicleCategory.HorsePower__c = '190';
            vehicleCategory.AxleConfiguration__c = '4x2';
            vehicleCategory.Suspension__c = 'BL';
//            vehicleCategory.Kind__c = 'CH';
            vehicleCategory.CabMark__c = 'J__2';
            vehicleCategory.WheelBase__c = '0';
            vehicleCategory.ERPCode__c = 'TEST';
        }
        return vehicleCategory;
    }

    public static Product2 createProduct() {
        if(product == null) {
            product = new Product2();
            if(vehicleCategory == null) insert createVehicleCategory();
            if(selfCertWeightLabel == null) insert createSelfCertWeightLabel();

            product.Name = 'TGL 10.190 4x2 BL CH TN 4850_t';
            product.SpecShort__c = 'TGL 10.190 4x2 BL CH TN 4850_t';
            product.Generation__c = 'TG3';
            product.Quantity__c = 10;
            product.CarAmt__c = 100000000;
            product.VehicleCategory__c = vehicleCategory.Id;
            product.Segment2__c = 'TPP';
            product.LocalYear__c = 'LMY25';
            product.ModelYear__c = '2025';
            product.EmissionLevel__c = 'A';
            product.TRPCategory__c = 'TG3S/X Tractor';
            product.SelfCertWeightLabel__c = selfCertWeightLabel.Id;
        }
        return product;
    }

    public static Pricebook2 createPricebook() {

        if (pricebook == null) {
            pricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
        }
        return pricebook;
    }

    public static PricebookEntry createPricebookEntry() {
        if(pricebookEntry == null) {
            pricebookEntry = new PricebookEntry();
            if(product == null) insert createProduct();

            Id standardPricebookId = Test.getStandardPricebookId();
            pricebookEntry.Product2Id = product.Id;
            pricebookEntry.Pricebook2Id = standardPricebookId;
            pricebookEntry.UnitPrice = 0;
            pricebookEntry.IsActive = true;
        }
        return pricebookEntry;
    }

    public static Lead createLead() {
        if(lead == null) {
            lead = new Lead();
            if(product == null) insert createProduct();

            lead.LastName = '도채범';
            lead.Company = 'Test Company';
            lead.MobilePhone = '010-1234-0987';
            lead.BusinessNumber__c = '878-87-03231';
            lead.RoadAddress__c = '서울 금천구 디지털로 178';
            lead.DetailAddress__c = '가산퍼블릭 719';
            lead.Description = 'Test Description';
            lead.ProductId__c = product.Id;
        }
        return lead;
    }
    public static Lead createDupLead() {
        if(dupLead == null) {
            dupLead = new Lead();
            if(product == null) insert createProduct();
            if(user == null) insert createUser();

            dupLead.LastName = '테스트 개인 계정';
            dupLead.Company = 'Test Company';
            dupLead.MobilePhone = '090-9999-1919';
            dupLead.BusinessNumber__c = '878-87-03231';
            dupLead.RoadAddress__c = '서울 금천구 디지털로 178';
            dupLead.DetailAddress__c = '가산퍼블릭 719';
            dupLead.Description = 'Test Description';
            dupLead.ProductId__c = product.Id;
            dupLead.ApprovalUser__c = user.Id;
        }
        return dupLead;
    }

    public static CampaignMaster__c createAmtCampaign() {
        if(amtCampaign == null) {
            amtCampaign = new CampaignMaster__c();

            amtCampaign.Name = 'Amt Campaign';
            amtCampaign.Status__c = '진행중';
            amtCampaign.DiscountPrice__c = 3000000;
            amtCampaign.DiscountRate__c = null;
            amtCampaign.AllModelCheck__c = true;
            amtCampaign.ExpireDate__c = Date.valueOf('2025-12-31');
        }
        return amtCampaign;
    }

    public static CampaignMaster__c createPercentCampaign() {
        if(percentCampaign == null) {
            percentCampaign = new CampaignMaster__c();

            percentCampaign.Name = 'Percent Campaign';
            percentCampaign.Status__c = '진행중';
            percentCampaign.DiscountPrice__c = null;
            percentCampaign.DiscountRate__c = 10;
            percentCampaign.AllModelCheck__c = true;
        }
        return percentCampaign;
    }

    /**
     * @return 중복불가 캠페인 - CampaignPreventDuplicate__c
     */
    public static CampaignPreventDuplicate__c createCampaignPreventDuplicate() {

        if (campaignPreventDup == null) {
            if (amtCampaign == null) insert createAmtCampaign();
            if (percentCampaign == null) insert createPercentCampaign();
            campaignPreventDup = new CampaignPreventDuplicate__c(
                CampaignMaster__c = amtCampaign.Id,
                CampaignMaster2__c = percentCampaign.Id,
                StartDate__c = System.today(),
                ExpireDate__c = System.today() + 1,
                IsActive__c = true
            );
        }
        return campaignPreventDup;
    }

    /**
     * @return 캠페인 정션 - CampaignJunction__c
     */
    public static CampaignJunction__c createCampaignJunction() {

        if (campaignJunction == null) {
            if (amtCampaign == null) insert createAmtCampaign();
            if (product == null) insert createProduct();
            campaignJunction = new CampaignJunction__c(
                Product__c = product.Id,
                CampaignMaster__c = amtCampaign.Id
            );
        }
        return campaignJunction;
    }

    public static Contract createContract() {
        if(contract == null) {
            contract = new Contract();
            if(opportunity == null) insert createOpportunity();
            if(vehicleStock == null) insert createVehicleStock();
            if(accountPerson == null) insert createAccountPerson();
            if(quote == null) insert createQuote();

            contract.Name = 'Test';
            contract.AccountId = accountPerson.Id;
            contract.Quote__c = quote.Id;
            contract.Opportunity__c = opportunity.Id;
            contract.VehicleStock__c = vehicleStock.Id;
            contract.ApprovalStatus__c = '승인됨';
        }
        return contract;
    }

    public static Contract createContractAdvance() {
        if(contractAdvance == null) {
            contractAdvance = new Contract();
            if(opportunityAdvance == null) insert createOpportunityAdvance();
            if(vehicleStock == null) insert createVehicleStock();
            if(accountPerson == null) insert createAccountPerson();
            if(quote == null) insert createQuote();

            contractAdvance.Name = 'Test';
            contractAdvance.AccountId = accountPerson.Id;
            contractAdvance.Quote__c = quote.Id;
            contractAdvance.Opportunity__c = opportunityAdvance.Id;
            contractAdvance.VehicleStock__c = vehicleStock.Id;
            contractAdvance.ApprovalStatus__c = '승인됨';
        }
        return contractAdvance;
    }

    public static Opportunity createOpportunity() {
        if(opportunity == null) {
            opportunity = new Opportunity();
            if(accountPerson == null) insert createAccountPerson();
            if(vehicleStock == null) insert createVehicleStock();

            opportunity.StageName = 'Closed Won';
            opportunity.Name ='test';
            opportunity.CloseDate = System.today();
            opportunity.AccountId = accountPerson.Id;
            opportunity.HandoverDate__c = System.today();
            opportunity.VehicleStock__c = vehicleStock.Id;
            opportunity.TaxInvoiceDate__c = System.today();
            opportunity.OwnerId = UserInfo.getUserId();
        }
        return opportunity;
    }

    public static Opportunity createOpportunityAdvance() {
        if(opportunityAdvance == null) {
            opportunityAdvance = new Opportunity();
            if(accountPerson == null) insert createAccountPerson();
//            if(contract == null) insert createContract();
            if(vehicleStock == null) insert createVehicleStock();
            if(virtualAccountAdvance == null) insert createVirtualAccountAdvance();

            opportunityAdvance.StageName = 'Closed Won';
            opportunityAdvance.VirtualAccount__c = virtualAccountAdvance.Id;
            opportunityAdvance.Name ='test';
            opportunityAdvance.CloseDate = System.today();
            opportunityAdvance.AccountId = accountPerson.Id;
            opportunityAdvance.HandoverDate__c = System.today().addDays(+3);
//            opportunityAdvance.ContractId = contract.Id;
            opportunityAdvance.VehicleStock__c = vehicleStock.Id;
            opportunityAdvance.TaxInvoiceDate__c = System.today();
            opportunityAdvance.OwnerId = UserInfo.getUserId();
        }
        return opportunityAdvance;
    }

    public static VehicleStock__c createVehicleStock() {
        if(vehicleStock == null) {
            if (product == null) insert createProduct();
            if (spoilerList == null) insert createSpoilerList();

            vehicleStock = new VehicleStock__c(
                Product__c = product.Id,
                Status__c = '재고 노출',
                LongTermStock__c = true,
                IsSpecial__c = false,
                IsOptionDiscount__c = false,
                LongtermDiscountRate__c = 0.2,
                SpecialDiscountRate__c = 0,
                OptionDiscountRate__c = 0,
                SpecShort__c = 'TGL 10.220 4x2 BL CH',
                SpoilerPart__c = spoilerList.get(0).Id,
                VehicleNo__c = '39SH118',
                Name = 'A001',
                EmissionLevelEu__c = '2,300/6,871',
                HorsePower__c = 'EURO6/341',
                ModelYear__c = String.valueOf(System.today().year())
            );
        }
        return vehicleStock;
    }

    public static List<AssignRequest__c> createAssignRequestList() {
        if(requestList == null) {
            if(opportunity == null) insert createOpportunity();
            if(vehicleStock == null) insert createVehicleStock();
            requestList = new List<AssignRequest__c>();
            for(Integer i = 10; i >= 7; i--) {
                AssignRequest__c assignRequestObj = new AssignRequest__c();
                assignRequestObj.Type__c = '계약금 요청';
                assignRequestObj.RequestDate__c = System.today().addDays(-(i));
                assignRequestObj.Opportunity__c = opportunity.Id;
                assignRequestObj.VehicleStock__c = vehicleStock.Id;

                requestList.add(assignRequestObj);
                System.debug('requestList :: ' + requestList);
            }
            System.debug('requestList :: ' + requestList);
        }
        return requestList;
    }

    public static List<VirtualAccountMaster__c> createVirtualAccountMasterList() {
        if(virtualAccountMasterList == null) {
            virtualAccountMasterList = new List<VirtualAccountMaster__c>();

            for(Integer i = 0; i < 10; i++) {
                VirtualAccountMaster__c master = new VirtualAccountMaster__c();

                master.VirtualAccountNum__c = String.valueOf(100 + i);
                master.Status__c = '사용가능';

                virtualAccountMasterList.add(master);
            }
        }
        return virtualAccountMasterList;
    }

    public static VirtualAccount__c createVirtualAccount() {
        if(virtualAccount == null) {
            virtualAccount = new VirtualAccount__c();
            if(accountPerson == null) insert createAccountPerson();
            if(opportunity == null) insert createOpportunity();
            if(virtualAccountMasterList == null) insert createVirtualAccountMasterList();

            VirtualAccountMaster__c vam = virtualAccountMasterList.remove(0);
            virtualAccount.Opportunity__c = opportunity.Id;
            virtualAccount.Account__c = accountPerson.Id;
            virtualAccount.VirtualAccountMaster__c = vam.Id;

            vam.Status__c = '할당중';
            update vam;
        }
        return virtualAccount;
    }

    public static VirtualAccount__c createVirtualAccountAdvance() {
        if(virtualAccountAdvance == null) {
            virtualAccountAdvance = new VirtualAccount__c();
            if(accountPerson == null) insert createAccountPerson();
            if(opportunityAdvance == null) insert createOpportunityAdvance();
            if(virtualAccountMasterList == null) insert createVirtualAccountMasterList();

            VirtualAccountMaster__c vam2 = virtualAccountMasterList.remove(0);
            virtualAccountAdvance.Opportunity__c = opportunityAdvance.Id;
            virtualAccountAdvance.Account__c = accountPerson.Id;
            virtualAccountAdvance.VirtualAccountMaster__c = vam2.Id;

            vam2.Status__c = '할당중';
            update vam2;
        }
        return virtualAccountAdvance;
    }

    public static Template__c createTemplateModuSign() {
        if(templateModuSign == null) {
            templateModuSign = new Template__c();
            templateModuSign.Name = '[샘플] 개인정보 수집 이용 동의서';
            templateModuSign.TemplateId__c = '123456';
            templateModuSign.Body__c =
                    '{' +
                    '  "requesterInputs" : [ {' +
                    '    "dataLabel" : "CustomInput1"' +
                    '  }, {' +
                    '    "dataLabel" : "Name"' +
                    '  }, {' +
                    '    "dataLabel" : "Opportunity__r.Name"' +
                    '  }, {' +
                    '    "dataLabel" : "Copy_Opportunity__r.Name2"' +
                    '  }, {' +
                    '    "dataLabel" : "_APIDocuments__r.Name"' +
                    '  } ]' +
                    '}';
            templateModuSign.RecordTypeId = Schema.SObjectType.Template__c.getRecordTypeInfosByDeveloperName().get('MODUSIGN').getRecordTypeId();
        }
        return templateModuSign;
    }

    public static Template__c createTemplateKakao() {
        if(templateKakao == null) {
            templateKakao = new Template__c();

            templateKakao.Name = '카카오톡 샘플_URL';
            templateKakao.TemplateId__c = '456789';
            templateKakao.Body__c = '#{Name} 고객님. #{Opportunity__r.Name}. #{_APIDocuments__r.Name}';
            templateKakao.RecordTypeId = Schema.SObjectType.Template__c.getRecordTypeInfosByDeveloperName().get('KAKAO').getRecordTypeId();
        }
        return templateKakao;
    }

    public static List<TemplateButton__c> createTemplateButtons() {
        if(templateButtonList == null) {
            templateButtonList = new List<TemplateButton__c>();

            for(Integer i = 1; i <= 2; i++) {
                if(templateKakao == null) insert createTemplateKakao();
                TemplateButton__c button = new TemplateButton__c();

                button.ButtonName__c = 'WebButton';
                button.LinkType__c = 'WL';
                button.MobileURL__c = '#{opportunityId}';
                button.PCURL__c = '#{opportunityId}';
                button.Template__c = templateKakao.Id;

                templateButtonList.add(button);
            }
        }
        return templateButtonList;
    }

    public static APIDocument__c createAPIDocument() {
        if(apiDocument == null) {
            if(contract == null) insert createContract();
            apiDocument = new APIDocument__c();

            apiDocument.Name = 'Test';
            apiDocument.Status__c = 'COMPLETED';
            apiDocument.Contract__c = contract.Id;
            apiDocument.FileName__c = '계약서';
        }
        return apiDocument;
    }

    /**
     * @return 견적 - Quote
     */
    public static Quote createQuote() {

        if (quote == null) {
            quote = new Quote();
            if (opportunity == null) insert createOpportunity();
            if (finance == null) insert createFinance();
            if (product == null) insert createProduct();
            if (vehicleStock == null) insert createVehicleStock();
            if (user == null) insert createUser();

            quote.OpportunityId = opportunity.Id;
            quote.Finance__c = finance.Id;
            quote.Product__c = product.Id;
            quote.AdvancePayment__c = 10000000;
            quote.SalesconditionDiscountAmt__c = 1000000;
            quote.DiscountAmt__c = 1000000;
            quote.AdditionalLossPrice__c = 0;
            quote.TotalVehiclePrice__c  = 150000000;
            quote.VehicleStock__c = vehicleStock.Id;
            quote.Segment__c = 'TPP';
            quote.Approver__c = user.Id;
            quote.Status = 'Published';
        }
        return quote;
    }

    public static Quote createQuoteCopy() {

        if (quoteCopy == null) {
            if(quote == null) insert createQuote();

            quoteCopy = quote.clone(false);
            quoteCopy.Status = 'Published';
        }
        return quoteCopy;
    }

    public static Contact createContact() {
        if (contact == null) {
            contact = new Contact();
            if(accountCompany == null) insert createAccountCompany();
            contact.LastName = 'testName';
            contact.AccountId = accountCompany.Id;
        }
        return contact;
    }

    /**
     * @return 차량옵션마스터 - VehicleOptionMaster__c
     */
    public static VehicleOptionMaster__c createOption() {

        if(option == null) {
            if (serviceItem == null) insert createServiceItem();
            option = new VehicleOptionMaster__c(
                Name = 'CareFree 5 - TGX 510,470 6X2 (EW-WSC)(RMC)',
                Division__c = '서비스품목',
                ServiceItemsMaster__c = serviceItem.Id,
                EwWscPrice__c = 100,
                RmcPrice__c = 100,
                OptionCodeRMC__c = 'ML100'
            );
        }
        return option;
    }

    /**
     * @return 차종 옵션 - ProductOption__c
     */
    public static ProductOption__c createProductOption() {

        if (productOption == null) {
            if (product == null) insert createProduct();
            if (option == null) insert createOption();
            productOption = new ProductOption__c(
                Product__c = product.Id,
                VehicleOptionMaster__c = option.Id
            );
        }
        return productOption;
    }

    /**
     * @return 견적 세부사항 - QuoteDetail__c (리스트)
     */
    public static List<QuoteDetail__c> createQuoteDetail() {

        if (quoteDetailList == null) {
            if (quote == null) insert createQuote();
            if (product == null) insert createProduct();
            if (option == null) insert createOption();
            if (amtCampaign == null) insert createAmtCampaign();
            if (accountCompany == null) insert createAccountCompany();
            List<String> typeList = new List<String>{'차종', '옵션', '캠페인', '주유상품권', '특장'};
            quoteDetailList = new List<QuoteDetail__c>();
            for(String type : typeList) {
                QuoteDetail__c quoteDetail = new QuoteDetail__c(
                    Quote__c = quote.Id,
                    Type__c = type
                );
                switch on type {
                    when '차종' {
                        quoteDetail.Product__c = product.Id;
                    }
                    when '옵션' {
                        quoteDetail.VehicleOptionMaster__c = option.Id;
                    }
                    when '캠페인' {
                        quoteDetail.CampaignMaster__c = amtCampaign.Id;
                    }
                    when '주유상품권' {
                        quoteDetail.OilCouponCount__c = 100;
                    }
                    when '특장' {
                        quoteDetail.SpecialAccount__c = accountCompany.Id;
                        quoteDetail.SpecialOption__c = '캡섀시 - 미완성';
                        quoteDetail.SpecialSubOption__c = '윙바디';
                        quoteDetail.SpecialPrice__c = 2000000;
                    }
                }
                quoteDetailList.add(quoteDetail);
            }
        }
        return quoteDetailList;
    }

    public static List<QuoteDetail__c> createQuoteDetailCopy() {

        if (quoteDetailListCopy == null) {
            quoteDetailListCopy = new List<QuoteDetail__c>();

            if(quoteCopy == null) insert createQuoteCopy();
            if(quoteDetailList == null) insert createQuoteDetail();
            if (option == null) insert createOption();

            for(QuoteDetail__c quoteDetail : quoteDetailList) {
                QuoteDetail__c cloneDetail = quoteDetail.clone(false);
                cloneDetail.Quote__c = quoteCopy.Id;
                cloneDetail.VehicleOptionMaster__c = option.Id;

                quoteDetailListCopy.add(cloneDetail);
            }
        }
        return quoteDetailListCopy;
    }

    /**
     * @return 파이낸셜 관리 - Finance__c
     */
    public static Finance__c createFinance() {

        if (finance == null) {
            finance = new Finance__c(
                Name = '신한카드',
                SubventionRate__c = 0.5
            );
        }
        return finance;
    }

    /**
     * @return 서비스 품목 - ServiceItemsMaster__c
     */
    public static ServiceItemsMaster__c createServiceItem() {

        if (serviceItem == null) {
            serviceItem = new ServiceItemsMaster__c();
        }
        return serviceItem;
    }

    public static DefermentRequest__c createDefermentRequest() {
        if(defermentRequest == null) {
            if (opportunity == null) insert createOpportunity();
            Map<String, String> paramMap = new Map<String, String>{
                    'recordId' => opportunity.Id,
                    'apiName' => 'PaymentDeferred',
                    'comment' => 'test',
                    'updateField' => 'TaxDeferredAmount__c',
                    'opportunityName' => opportunity.Name,
                    'deferredAmount' => '100',
                    'dueDate' => String.valueOf(Date.today()),
                    'isCheck' => String.valueOf(true)
            };
            defermentRequest = FinancialDefermentRequest.createDefermentRequest(paramMap);
        }
        return defermentRequest;
    }

    public static DefermentRequest__c createStatusDefermentRequest() {

        // String DUEDATE = String.valueOf(System.today().addDays(+3));

        if (defermentRequest2 == null) {
            if (opportunityAdvance == null) insert createOpportunityAdvance();

            defermentRequest2 = new DefermentRequest__c();
            defermentRequest2.Opportunity__c = opportunityAdvance.Id;
            defermentRequest2.RequestDays__c = 0;
            defermentRequest2.Status__c = 'COMPLETED';
            defermentRequest2.Type__c = 'VATDeferred';
        }
        return defermentRequest2;
    }

    public static SalesConditionMaster__c createSalesConditionMaster() {

        if (salesConditionMaster == null) {
            salesConditionMaster = new SalesConditionMaster__c();

            if(product == null) insert createProduct();
            salesConditionMaster.Model__c = product.Name;
            salesConditionMaster.Generation__c = product.Generation__c;
            salesConditionMaster.Segment2__c = product.Segment2__c;
            salesConditionMaster.LocalYear__c = product.LocalYear__c;
            salesConditionMaster.ModelYear__c = product.ModelYear__c;
            salesConditionMaster.EmissionLevel__c = 'A';
            salesConditionMaster.ListPrice__c = 2.5;
            salesConditionMaster.Discount__c = 2.5;
            salesConditionMaster.StartDate__c = Date.today();
            salesConditionMaster.EndDate__c = Date.today();
            salesConditionMaster.YearMonth__c = CommonUtilController.formatDate(Datetime.now(), 'C').substring(0, 6);
        }
        return salesConditionMaster;
    }

/**
     * @return 매니저 유저 - User
     */
    public static User createManagerUser() {
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'MTBK Agent' LIMIT 1];

        if (managerUser == null) {
            managerUser = new User(
                LastName = '테스트용 매니저',
                Email = 'testManageruser@example.com',
                Username = 'testManageruser' + System.currentTimeMillis() + '@example.com',
                Alias = 'tmuser',
                TimeZoneSidKey = 'Asia/Seoul',
                LocaleSidKey = 'ko_KR',
                EmailEncodingKey = 'UTF-8',
                ProfileId = userProfile.Id,
                LanguageLocaleKey = 'en_US',
                MobilePhone = '010-1234-9876',
                IsActive = true
            );
        }
        return managerUser;
    }

    /**
     * @return 유저 - User
     */
    public static User createUser() {
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'MTBK Agent' LIMIT 1];
        if (managerUser == null) insert createManagerUser();
        if (user == null) {
            user = new User(
                LastName = '테스트용 유저',
                Email = 'testuser@example.com',
                Username = 'testuser' + System.currentTimeMillis() + '@example.com',
                Alias = 'tuser',
                TimeZoneSidKey = 'Asia/Seoul',
                LocaleSidKey = 'ko_KR',
                EmailEncodingKey = 'UTF-8',
                ProfileId = userProfile.Id,
                LanguageLocaleKey = 'en_US',
                ManagerId = managerUser.Id,
                IsActive = true
            );
        }
        return user;
    }

    /**
     * @return 입금현황관리 - PaymentTracker__c
     */
    public static PaymentTracker__c createPaymentTracker() {

        if (paymentTracker == null) {
            if (opportunity == null) insert createOpportunity();
            if (accountCompany == null) insert createAccountCompany();
            paymentTracker = new PaymentTracker__c(
                Opportunity__c = opportunity.Id,
                Account__c = accountCompany.Id,
                Status__c = 'NEW',
                TotalAmount__c = 10000000,
                IsValid__c = true
            );
        }
        return paymentTracker;
    }

    /**
     * @return 입금현황 종류 - PaymentType__c
     */
    public static PaymentType__c createPaymentType() {

        if (paymentTypeDeposit == null) {
            if (paymentTracker == null) insert createPaymentTracker();
            paymentTypeDeposit = new PaymentType__c(
                PaymentTracker__c = paymentTracker.Id,
                Type__c = '1_DEPOSIT',
                RequestAmount__c = 1000
            );
        }
        return paymentTypeDeposit;
    }

    public static List<PaymentType__c> createPaymentTypeList() {
        Map<String, String> typeMap = CommonUtilController.getPickListMap('PaymentType__c', 'Type__c');

        if (paymentTypeList == null) {
            paymentTypeList = new List<PaymentType__c>();

            PaymentType__c depositType = createPaymentType();
            Map<String, Decimal> amountMap = new Map<String, Decimal>{
                '인도금' => 100,
                '인도금 유예' => 100,
                '부가세후취' => 100,
                '대출금' => 100,
                '대출금 할인금액' => 100,
                'MFS 캠페인 할인금액' => 100,
                '초과금' => 100
            };

            for(String key : amountMap.keySet()) {
                PaymentType__c type = new PaymentType__c();

                type.PaymentTracker__c = paymentTracker.Id;
                type.Type__c = typeMap.get(key);
                type.RequestAmount__c = amountMap.get(key);
                type.DepositAmount__c = 0;
                type.DiscountAmount__c = 10;

                paymentTypeList.add(type);
            }
            paymentTypeList.add(depositType);
        }

        return paymentTypeList;
    }

    /**
     * @return 입금 로그 - PaymentLog__c
     */
    public static PaymentLog__c createPaymentLog() {

        if (paymentLog == null) {
            if (paymentTracker == null) insert createPaymentTracker();
            paymentLog = new PaymentLog__c(
                Name= 'TEST',
                Amount__c = 1000000,
                PaymentTracker__c = paymentTracker.Id,
                InternalDocumentId__c = '1'
            );
        }
        return paymentLog;
    }

    /**
     * @return 핸드오버 - Handover__c
     */
    public static Handover__c createHandover() {

        if (handover == null) {
            if (opportunity == null) insert createOpportunity();
//            if (vehicleStock == null) insert createVehicleStock();
            if (paymentTracker == null) insert createPaymentTracker();
            handover = new Handover__c(
                Opportunity__c = opportunity.Id,
                // VehicleStock__c = vehicleStock.Id,
                PaymentTracker__c = paymentTracker.Id,
                IsActive__c = true
            );
        }
        return handover;
    }

    /**
     * @return 인센티브 타겟 마스터 - IncentiveTargetMaster__c
     */
    public static List<IncentiveTargetMaster__c> createIncentiveTargetMaster() {

        if (incentiveTargetMasterList == null) {
            incentiveTargetMasterList = new List<IncentiveTargetMaster__c>();
            List<String> typeList = new List<String>{'Annual', 'Quarterly'};
            for (String type : typeList) {
                incentiveTargetMasterList.add(new IncentiveTargetMaster__c(
                    TargetType__c = type,
                    Quarter__c = 'Q1',
                    Year__c = '2025',
                    TargetAmount__c = 1000000,
                    MinSalesTarget__c = 1
                ));
            }
        }
        return incentiveTargetMasterList;
    }

    /**
     * @return 굿윌 마스터 - GoodWillMaster__c
     */
    public static GoodWillMaster__c createGoodWillMaster() {

        if(user == null) insert createUser();

        if (goodWillMaster == null) {
            goodWillMaster = new GoodWillMaster__c();
            goodWillMaster.User__c = user.Id;
        }
        return goodWillMaster;
    }

    /**
     * @return 굿윌 적립 - GoodWillSaving__c
     */
    public static GoodWillSaving__c createGoodWillSaving() {

        if(goodWillMaster == null) insert createGoodWillMaster();

        if (goodWillSaving == null) {
            goodWillSaving = new GoodWillSaving__c();
            goodWillSaving.GoodWillMaster__c = goodWillMaster.Id;
            goodWillSaving.SavingPoints__c = 500000;
            goodWillSaving.AvailablePoint__c = 500000;
            goodWillSaving.IsValid__c = false;
        }
        return goodWillSaving;
    }

    /**
     * @return 굿윌 사용 - GoodWillUsing__c
     */
    public static GoodWillUsing__c createGoodWillUsing() {

        if(goodWillMaster == null) insert createGoodWillMaster();

        if (goodWillUsing == null) {
            goodWillUsing = new GoodWillUsing__c();
            goodWillUsing.GoodWillMaster__c = goodWillMaster.Id;
            goodWillUsing.GoodWillVIN__c = 'WMA46DZZ4RP270817';
            goodWillUsing.UsingGoodWill__c = 800000;
            goodWillUsing.ApprovalStatus__c = '초안';
        }
        return goodWillUsing;
    }

    public static List<Document> createDocument() {

        if (documentList == null) {
            documentList = new List<Document>();
            if(user == null) insert createUser();
            List<String> nameList = new List<String>{'doc_profidrive_img1', 'doc_covertable_img2','doc_covertable_img1','MAN_Truck_Bus_Korea_LOGO',
                                                     'man_useingam','man_bizingam','VehicleCheckReport_100','VehicleCheckReport','ActivationSheetBackground2'};
            for (String name : nameList) {
                documentList.add(new Document(
                    Name = name,
                    DeveloperName = name,
                    FolderId = user.Id
                ));
            }
        }
        return documentList;
    }
    public static AvgLocalCost__c createAvgLocalCost() {

        if (avgLocalCost == null) {
            avgLocalCost = new AvgLocalCost__c();
            avgLocalCost.ReportSpec__c = 'TGL 10.190 4x2 BL CH TN 4850';
            avgLocalCost.LocalCostAvg__c = 1231231;
            avgLocalCost.PdiCostAvg__c = 2312312;
            avgLocalCost.OtherCostAvg__c = 3123123;
            avgLocalCost.Active__c = true;
        }
        return avgLocalCost;
    }

    public static SpecTypeNo__c createSpecTypeNo() {

        if (specTypeNo == null) {
            specTypeNo = new SpecTypeNo__c();
            specTypeNo.Form__c = 'TGL 10.220 4x2 BL CH';
            specTypeNo.ModelYear__c = '2019';
            specTypeNo.Type__c = '제원관리번호';
            specTypeNo.MngNo__c = '016-1-11111-1111-1111';
            specTypeNo.SCNTAN__c = '016-1-11111-1111-1111';
        }
        return specTypeNo;
    }

    public static List<CustomerConsent__c> createCustomerConsent() {

        if (customerConsent == null) {
            customerConsent = new List<CustomerConsent__c>();

            List<Date> dateList = new List<Date>{
                    null,
                    Date.today().addDays(-84), // Light Consent 만료일
                    Date.today().addYears(-2) // Full Consent 만료일
            };
            if(lead == null) insert createLead();
            if(opportunity == null) insert createOpportunity();
            for (Date consentDate : dateList) {
                customerConsent.add(new CustomerConsent__c(
                        Lead__c = lead.Id,
                        Opportunity__c = consentDate == Date.today().addYears(-2) ? opportunity.Id : null,
                        ConsentStatus__c = consentDate == null ? '링크 전송됨' : '작성완료됨',
                        ConsentDate__c = consentDate
                ));
            }
        }
        return customerConsent;
    }

    public static List<Signature__c> createSignature() {

        if (signature == null) {
            if(vehicleStock == null) insert createVehicleStock();
            signature = new List<Signature__c>();
            List<String> typeList = new List<String>{'차량재고-차량인수서명', '차량관리-주유상품권서명'};
            for (String type : typeList) {
                signature.add(new Signature__c(
                        Url__c = 'test',
                        SignType__c = type,
                        VehicleStock__c = vehicleStock.Id
                ));
            }

        }
        return signature;
    }

    public static CustomCalendar__c createCustomCalendar() {
        if (customCalendar == null) {
            customCalendar = new CustomCalendar__c();
            customCalendar.Date__c = Date.today();
        }
        return customCalendar;
    }

    /**
     * @return PDI Step - PDIStep__c
     */
    public static List<PDIStep__c> createPDIStep() {

        if(vehicleStock == null) insert createVehicleStock();
        if (pdiStepList == null) {
            pdiStepList = new List<PDIStep__c>();
            List<String> stageList = new List<String>{'STEP1', 'STEP2', 'STEP3', 'STEP4', 'STEP5'};
            for (String stage : stageList) {
                pdiStepList.add(new PDIStep__c(
                    VehicleStock__c = vehicleStock.Id,
                    IsPass__c = true,
                    Stage__c = stage,
                    StepStart__c = Date.today(),
                    StepEnd__c = Date.today(),
                    StepWorker__c = 'test 유저'
                ));
            }
        }
        return pdiStepList;
    }

    public static ApprovalHierarchy__c createApprovalHierarchy() {
        if(managerUser == null) insert createManagerUser();
        if (approvalHierarchy == null) {
            approvalHierarchy = new ApprovalHierarchy__c();
            approvalHierarchy.Approver1__c = managerUser.Id;
            approvalHierarchy.Stage__c = 'Contract Modusign Final';
        }
        return approvalHierarchy;
    }

    public static SelfCertWeightLabel__c createSelfCertWeightLabel() {
        if (selfCertWeightLabel == null) {
            selfCertWeightLabel = new SelfCertWeightLabel__c();
            selfCertWeightLabel.TotalWeight__c = '500';
        }
        return selfCertWeightLabel;
    }

    public static SelfCertWeightLabelDtl__c createSelfCertWeightLabelDtl() {
        if (selfCertWeightLabelDtl == null) {
            if(selfCertWeightLabel == null) insert createSelfCertWeightLabel();
            selfCertWeightLabelDtl = new SelfCertWeightLabelDtl__c();
            selfCertWeightLabelDtl.SelfCertWeightLabel__c = selfCertWeightLabel.Id;
            selfCertWeightLabelDtl.Year__c = String.valueOf(System.today().year());
            selfCertWeightLabelDtl.TotalWeight__c = '500';
        }
        return selfCertWeightLabelDtl;
    }

    public static CommissionManagement__c createCommissionManagement() {
        if (commissionManagement == null) {
            commissionManagement = new CommissionManagement__c();
            commissionManagement.Period__c = Date.today();
            commissionManagement.OwnerId = UserInfo.getUserId();
        }
        return commissionManagement;
    }

    public static CommissionHistory__c createCommissionHistory() {
        if (commissionHistory == null) {
            if(commissionManagement == null) insert createCommissionManagement();
            if(opportunity == null) insert createOpportunity();
            commissionHistory = new CommissionHistory__c();
            commissionHistory.CommissionManagement__c = commissionManagement.Id;
            commissionHistory.Opportunity__c = opportunity.Id;
        }
        return commissionHistory;
    }

    public static IncentiveHistory__c createIncentiveHistory() {
        if (incentiveHistory == null) {
            if(opportunity == null) insert createOpportunity();
            if(incentiveTargetMasterList == null) insert createIncentiveTargetMaster();
            incentiveHistory = new IncentiveHistory__c(
                IncentiveTargetMaster__c = incentiveTargetMasterList[0].Id
            );
        }
        return incentiveHistory;
    }

    /* ======================================================================================================================= */
    /* ======================================================================================================================= */
    /* ======================================================================================================================= */

    public static void createLeadBundle() {
        if(lead == null) insert createLead();
        if(dupLead == null) insert createDupLead();
    }

    public static void createOpportunityBundle() {
        if(configList == null) insert createAvisConfigList();
        if(opportunity == null) insert createOpportunity();
        if(opportunityAdvance == null) insert createOpportunityAdvance();
        if(defermentRequest == null) insert createDefermentRequest();
        if(defermentRequest2 == null) insert createStatusDefermentRequest();
    }

    public static void createAccountBundle() {
        if(accountPerson == null) insert createAccountPerson();
        if(accountCompany == null) insert createAccountCompany();
        if(accountLicense == null) insert createAccountLicense();
        if(contact == null) insert createContact();
    }

    public static void createOrderBundle() {
        if(infoList == null) insert createAvisOrderInfoList();
        if(configList == null) insert createAvisConfigList();
        if(spoilerList == null) insert createSpoilerList();
    }

    public static void createConfigBundle() {
        if(configDetailList == null) insert createConfigDetailList();
    }

    public static void createIfBundle() {
        if(ifMasterList == null) insert createIfMasterList();

        if(templateModuSign == null) insert createTemplateModuSign();
        if(templateKakao == null) insert createTemplateKakao();
        if(templateButtonList == null) insert createTemplateButtons();
        if(apiDocument == null) insert createAPIDocument();
    }

    public static void createStockBundle() {
        createOpportunityBundle();

        if(vehicleStock == null) insert createVehicleStock();
        if(pricebook == null) update createPricebook();
        if(pricebookEntry == null) insert createPricebookEntry();
        if(serviceItem == null) insert createServiceItem();
        if(option == null) insert createOption();
        if(productOption == null) insert createProductOption();
        if(salesConditionMaster == null) insert createSalesConditionMaster();
        if(selfCertWeightLabelDtl == null) insert createSelfCertWeightLabelDtl();
        if(signature == null) insert createSignature();
    }

    public static void createVirtualAccountBundle() {
        createAccountBundle();

        if(virtualAccount == null) insert createVirtualAccount();
        if(virtualAccountAdvance == null) insert createVirtualAccountAdvance();

        List<Opportunity> updateList = new List<Opportunity>();
        opportunity.VirtualAccount__c = virtualAccount.Id;
        opportunityAdvance.VirtualAccount__c = virtualAccountAdvance.Id;
        updateList.add(opportunity);
        updateList.add(opportunityAdvance);

        update updateList;
    }

    public static void createQuoteBundle() {
        createOpportunityBundle();

        if(salesConditionMaster == null) insert createSalesConditionMaster();
        if(finance == null) insert createFinance();
        if(quoteDetailList == null) insert createQuoteDetail();
        if(quoteDetailListCopy == null) insert createQuoteDetailCopy();
        if(serviceItem == null) insert createServiceItem();
        if(option == null) insert createOption();
        if(productOption == null) insert createProductOption();
        if(defermentRequest == null) insert createDefermentRequest();
        if(defermentRequest2 == null) insert createStatusDefermentRequest();
    }

    public static void createContractBundle() {
        createQuoteBundle();

        if(contract == null) {
            insert createContract();

            List<SObject> SObjectList = new List<SObject>();
            opportunity.ContractId = contract.Id;
            quote.ContractId = contract.Id;

            SObjectList.add(opportunity);
            SObjectList.add(quote);

            update SObjectList;
        }

        if(contractAdvance == null) {
            insert createContractAdvance();

            opportunityAdvance.ContractId = contractAdvance.Id;
            update opportunityAdvance;
        }
        if(requestList == null) insert createAssignRequestList();
        if(defermentRequest == null) insert createDefermentRequest();
        if(defermentRequest2 == null) insert createStatusDefermentRequest();
    }

    public static void createCampaignBundle() {
        if(campaignPreventDup == null) insert createCampaignPreventDuplicate();
        if(campaignJunction == null) insert createCampaignJunction();
    }

    public static void createPaymentBundle() {
        createContractBundle();

        if(paymentTracker == null) insert createPaymentTracker();
        if(paymentTypeList == null) insert createPaymentTypeList();
        if(paymentLog == null) insert createPaymentLog();
    }

    public static void createHandoverBundle() {
        createContractBundle();

        if(pdiStepList == null) insert createPDIStep();
        if(handover == null) insert createHandover();
    }

    public static void createGoodWillBundle() {
        if(goodWillMaster == null) insert createGoodWillMaster();
        if(goodWillSaving == null) insert createGoodWillSaving();
        if(goodWillUsing == null) insert createGoodWillUsing();
    }

    public static void createCommissionBundle() {
        createContractBundle();

        if(commissionManagement == null) insert createCommissionManagement();
        if(commissionHistory == null) insert createCommissionHistory();
    }

    public static void createConsentBundle() {
        createLeadBundle();
        createOpportunityBundle();

        if(customerConsent == null) insert createCustomerConsent();
    }

    public static void createSpoilerBundle() {
        createSpoilerList();

        if(spoilerPartsJuntion == null) insert createSpoilerPartsJuntion();
    }

    public static void createObjects() {
        if(incentiveTargetMasterList == null) insert createIncentiveTargetMaster();
        if(documentList == null) insert createDocument();
        if(avgLocalCost == null) insert createAvgLocalCost();
        if(specTypeNo == null) insert createSpecTypeNo();
        if(customCalendar == null) insert createCustomCalendar();
        if(approvalHierarchy == null) insert createApprovalHierarchy();
    }

}