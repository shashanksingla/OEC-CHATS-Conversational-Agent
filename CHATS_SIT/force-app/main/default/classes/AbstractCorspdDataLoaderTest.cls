@isTest
public class AbstractCorspdDataLoaderTest 
{ 
	@testSetup 
    static void setup() {
        
        string corspdName= 'CR110';
        string caseId = '626262626';
        integer providerId = 123;
        string corrId = 'CR110_123';
        string corrLang ='ENG';
        string clientId='567';
		T_COUNTY__c countyObj = TestClassUtility.createCounty('Denver','Denver',1,true);
		T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        //T_ADJMT__c adjObj = TestClassUtility.createAdjustment(true, countyObj.Id, caseObj.Id, providerObj.Id);
		Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
		T_ADJMT__c adj1 = new T_ADJMT__c(RecordtypeId = recordTypeId, CDE_STATUS_ADJMT__c = '2', CDE_TYPE_ADJMT__c = '2', CDE_TYPE_CLSFN__c = '3',
                                          CDE_AGNST_ADJMT__c = '1', IDN_CASE__c = caseObj.Id, DTE_END_ADJMT__c = System.today(),
                                          DTE_START_ADJMT__c = System.today(), DTE_DISCV_ADJMT_ORIG__c = System.today(), CDE_COUNTY__c = countyObj.Id);
        Insert adj1;
		T_COUNTY_PLAN_ADR__c countyAddress = new T_COUNTY_PLAN_ADR__c();
        countyAddress.IDN_COUNTY__c = countyObj.Id;
		countyAddress.ADR_LINE_1__c = '123 Denver';
		countyAddress.ADR_LINE_2__c = '123 Denver';
		countyAddress.ADR_CITY__c = 'Denver';
		countyAddress.ADR_STATE__c = 'CO';
		countyAddress.ADR_ZIP__c = '81036';
		countyAddress.ADR_ZIP_EXTN__c = '1234';
		//countyAddress.IDN_COUNTY__r.Name = 'Denver';
		//countyAddress.IDN_COUNTY__r.CNTY_DEPT_NAME__c = 'Denver';
        countyAddress.RecordTypeId = Schema.SObjectType.T_COUNTY_PLAN_ADR__c.getRecordTypeInfosByName().get('Mailing').getRecordTypeId();
        insert countyAddress;
		T_COUNTY_PLAN_ADR__c countyAddress2 = new T_COUNTY_PLAN_ADR__c();
        countyAddress2.IDN_COUNTY__c = countyObj.Id;
		countyAddress2.ADR_LINE_1__c = '123 Denver';
		countyAddress2.ADR_LINE_2__c = '123 Denver';
		countyAddress2.ADR_CITY__c = 'Denver';
		countyAddress2.ADR_STATE__c = 'CO';
		countyAddress2.ADR_ZIP__c = '81036';
		countyAddress2.ADR_ZIP_EXTN__c = null;
        countyAddress2.RecordTypeId = Schema.SObjectType.T_COUNTY_PLAN_ADR__c.getRecordTypeInfosByName().get('Mailing').getRecordTypeId();
        insert countyAddress2;
        
    }
    
    public static testmethod void setProviderHeaderAdjmtCntyInfoTest()
    {
		string corspdName= 'CR110';
        string caseId = '626262626';
        integer providerId = 123;
        string corrId = 'CR110_123';
        string corrLang ='ENG';
        string clientId='567';
		String cntySfid;

        test.startTest();

        CR110DataLoader CR110 = new CR110DataLoader(corspdName, caseId, providerId, corrId, corrLang, clientId);
        XmlStreamWriter xmlWrtr = new XmlStreamWriter();
        system.assert(string.valueOf(CR110.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR110.setCorspdInfo(xmlWrtr);
		CR110.setProviderHeaderInfo(xmlWrtr);
		//CR110.setProviderHeaderAdjmtCntyInfo(xmlWrtr);
		CR110.setClientNameInfo();
        CR110.setKeyParameters(xmlWrtr);
        CR110.setProviderInfo(xmlWrtr);
        CR110.setAdjmtCountyInfo(xmlWrtr,'C');
		CR110.setResponsiblePartyProviderInfo(xmlWrtr);
		CR110.setResponsiblePartyCase(xmlWrtr);
		CR110.setprimarycaretakerAddr(xmlWrtr);
		//
		CR110DataLoader CR110v2 = new CR110DataLoader('CR207', caseId, providerId, corrId, corrLang, clientId);
		system.assert(string.valueOf(CR110v2.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR110v2.setCorspdInfo(xmlWrtr);
		CR110v2.setProviderHeaderInfo(xmlWrtr);
		//CR110v2.setProviderHeaderAdjmtCntyInfo(xmlWrtr);
		CR110v2.setClientNameInfo();
        CR110v2.setKeyParameters(xmlWrtr);
        CR110v2.setProviderInfo(xmlWrtr);
        CR110v2.setResponsiblePartyProviderInfo(xmlWrtr);
        CR110v2.setAdjmtCountyInfo(xmlWrtr,'C');
		CR110v2.setResponsiblePartyCase(xmlWrtr);
		CR110v2.setprimarycaretakerAddr(xmlWrtr);
		//
		CR110DataLoader CR110v3 = new CR110DataLoader('CR114', caseId, providerId, corrId, corrLang, clientId);
		system.assert(string.valueOf(CR110v3.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR110v3.setCorspdInfo(xmlWrtr);
		CR110v3.setProviderHeaderInfo(xmlWrtr);
		//CR110v3.setProviderHeaderAdjmtCntyInfo(xmlWrtr);
		CR110v3.setClientNameInfo();
        CR110v3.setKeyParameters(xmlWrtr);
        CR110v3.setProviderInfo(xmlWrtr);
        CR110v3.setResponsiblePartyProviderInfo(xmlWrtr);
        CR110v3.setAdjmtCountyInfo(xmlWrtr,'C');
		CR110v3.setResponsiblePartyCase(xmlWrtr);
		CR110v2.setprimarycaretakerAddr(xmlWrtr);
		//
		CR110DataLoader CR110v4 = new CR110DataLoader('CR207', caseId, providerId, corrId, corrLang, clientId);
		system.assert(string.valueOf(CR110v4.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR110v4.setCorspdInfo(xmlWrtr);
		CR110v4.setProviderHeaderInfo(xmlWrtr);
		//CR110v4.setProviderHeaderAdjmtCntyInfo(xmlWrtr);
		CR110v4.setClientNameInfo();
        CR110v4.setKeyParameters(xmlWrtr);
        CR110v4.setProviderInfo(xmlWrtr);
        CR110v4.setResponsiblePartyProviderInfo(xmlWrtr);
        CR110v4.setAdjmtCountyInfo(xmlWrtr,'C');
		CR110v4.setResponsiblePartyCase(xmlWrtr);
		CR110v2.setprimarycaretakerAddr(xmlWrtr);
		//
        test.stopTest();
	}
    public static testmethod void setProviderHeaderAdjmtCntyInfo_Test()
    {
        List<T_ADJMT__c> adjm = [Select Id, CDE_COUNTY__c from T_ADJMT__c LIMIT 1];
        String corspdName = 'CR207';
        String caseId = 'CA-1';
        Integer providerId = 123;
        String adjustmentId = adjm[0].Id;
        String corrId = 'Adams';
        String cntySfid;
        Boolean isCase = true;
        Boolean isProvider = true;
        String clientId = 'INDIV-1';
        
        
        T_COUNTY__c countyObj = TestClassUtility.createCounty('Trash','Trash',1,true);
		T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        //T_ADJMT__c adjObj = TestClassUtility.createAdjustment(true, countyObj.Id, caseObj.Id, providerObj.Id);
		Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
		T_ADJMT__c adj1 = new T_ADJMT__c(RecordtypeId = recordTypeId, CDE_STATUS_ADJMT__c = '2', CDE_TYPE_ADJMT__c = '2', CDE_TYPE_CLSFN__c = '3',
                                          CDE_AGNST_ADJMT__c = '1', IDN_CASE__c = caseObj.Id, DTE_END_ADJMT__c = System.today(),
                                          DTE_START_ADJMT__c = System.today(), DTE_DISCV_ADJMT_ORIG__c = System.today(), CDE_COUNTY__c = countyObj.Id);
        Insert adj1;
        T_COUNTY_PLAN_ADR__c countyAddress2 = new T_COUNTY_PLAN_ADR__c();
        countyAddress2.IDN_COUNTY__c = adjm[0].CDE_COUNTY__c;
		countyAddress2.ADR_LINE_1__c = '123 Denver';
		countyAddress2.ADR_LINE_2__c = '123 Denver';
		countyAddress2.ADR_CITY__c = 'Denver';
		countyAddress2.ADR_STATE__c = 'CO';
		countyAddress2.ADR_ZIP__c = '81036';
		countyAddress2.ADR_ZIP_EXTN__c = null;
        countyAddress2.RecordTypeId = Schema.SObjectType.T_COUNTY_PLAN_ADR__c.getRecordTypeInfosByName().get('Main Location').getRecordTypeId();
        insert countyAddress2;
        
        test.startTest();
        CR207DataLoader CR207 = new CR207DataLoader(corspdName, caseId, providerId, corrId, cntySfid, adjustmentId, isCase, isProvider, clientId);
        XmlStreamWriter xmlWrtr = new XmlStreamWriter();
        System.assert(String.valueOf(CR207.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR207.setCorspdInfo(xmlWrtr);
        CR207.setFlags(xmlWrtr);
        CR207.setKeyParameters(xmlWrtr);
		CR207.setResponsiblePartyProviderInfo(xmlWrtr);
		CR207.setprimarycaretakerAddr(xmlWrtr);
        
        CR207DataLoader CR207v1 = new CR207DataLoader(corspdName, caseId, providerId, corrId, cntySfid, adj1.Id, isCase, isProvider, clientId);
        XmlStreamWriter xmlWrtrv1 = new XmlStreamWriter();
        System.assert(String.valueOf(CR207v1.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR207v1.setCorspdInfo(xmlWrtrv1);
        CR207v1.setFlags(xmlWrtrv1);
        CR207v1.setKeyParameters(xmlWrtrv1);
		CR207v1.setprimarycaretakerAddr(xmlWrtrv1);
		CR207v1.setResponsiblePartyProviderInfo(xmlWrtrv1);
        test.stopTest();
    }
	public static testmethod void setProviderHeaderAdjmtCntyInfo_Test2()
    {
		string corspdName_cr107= 'CR107';
		string corspdName_cr108= 'CR108';
		string corspdName_cr109= 'CR109';
		string corspdName_cr110= 'CR110';
		string corspdName_cr114= 'CR114';
		string corspdName_cr212= 'CR212';
		string corspdName_cr702= 'CR702';
        string caseId = 'CA-1';
        integer providerId = 123;
        String corrId = 'Adams';
        
		String providerIdStr =TestClassUtility.createProvider(true,'Test').Id;
		T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c(Name = providerIdStr, NAM_FACILITY__c = 'abc', CDE_STATUS_PROVR__c='Open');
        insert provider;

        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        User fromUser = TestClassUtility.createUser(userProfile.Id , 'test1','test1','test1@example.com','test1@example.com.'+string.valueof(math.random()*3),'ttes1');
		insert fromUser;

		T_COUNTY__c county = TestClassUtility.createCounty('Denver','Denver',1,true);
		
		String cntySfid = county.Id;

		T_PROVR_FISCAL_AGREMENT__c providerFA1 = TestClassUtility.createFiscaAgreement(false,'Test FA 1',System.today().addYears(1),county.Id);
        providerFA1.OwnerId= fromUser.Id;
		providerFA1.CDE_COUNTY__c = county.Id;
        providerFA1.ID_SERVICE__c=provider.Id;
        //providerFA1.RecordtypeId=openRecordTypeId;
        providerFA1.DTE_RCV_AGRMT_FISCAL__c= System.today();
		providerFA1.DTE_BEGIN_AGRMT__c = System.today();
        //providerFA1.CDE_TYPE_STATUS__c='OPN';
        insert providerFA1;

		//Case insert
		T_SBSD_CASE__c cases = TestClassUtility.createCase(false, county.Id);
		insert cases;
		cases.IDN_EXTNL__c='12345';
		cases.Name = cases.Id;

		//Auth Authorization
		T_AUTH__c authObj = TestClassUtility.createAuthorization(false, null, System.today().addDays(-8), county.Id, provider.Id);
        authObj.IDN_CASE__c = cases.Id;
        authObj.IDN_EXTNL__c='123';
        insert authObj;
        
        test.startTest();
		//107
       	CR107DataLoader CR107 = new CR107DataLoader(corspdName_cr107, caseId, providerId, corrId, 'ENG');
        CR107DataLoader CR107_SPN = new CR107DataLoader(corspdName_cr107, caseId, providerId, corrId, 'SPN');
		XmlStreamWriter xmlWrtr = new XmlStreamWriter(); 
        
        system.assert(string.valueOf(CR107.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR107_SPN.getxmldata();
        CR107.setCorspdInfo(xmlWrtr);
        CR107.setKeyParameters(xmlWrtr);
		CR107.setSignatureInfo(xmlWrtr, 'D', caseId, providerIdStr, cntySfid);

		//108
       	CR107DataLoader CR108 = new CR107DataLoader(corspdName_cr108, caseId, providerId, corrId, 'ENG');
        CR107DataLoader CR108_SPN = new CR107DataLoader(corspdName_cr108, caseId, providerId, corrId, 'SPN');       	
		
		system.assert(string.valueOf(CR108.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR108_SPN.getxmldata();
        CR108.setCorspdInfo(xmlWrtr);
        CR108.setKeyParameters(xmlWrtr);
		CR108.setSignatureInfo(xmlWrtr, 'D', caseId, providerIdStr, cntySfid);

		//109
       	CR107DataLoader CR109 = new CR107DataLoader(corspdName_cr109, caseId, providerId, corrId, 'ENG');
        CR107DataLoader CR109_SPN = new CR107DataLoader(corspdName_cr109, caseId, providerId, corrId, 'SPN');       	
		
		system.assert(string.valueOf(CR109.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR109_SPN.getxmldata();
        CR109.setCorspdInfo(xmlWrtr);
        CR109.setKeyParameters(xmlWrtr);
		CR109.setSignatureInfo(xmlWrtr, 'D', caseId, providerIdStr, cntySfid);

		//110
       	CR107DataLoader CR110 = new CR107DataLoader(corspdName_cr110, caseId, providerId, corrId, 'ENG');
        CR107DataLoader CR110_SPN = new CR107DataLoader(corspdName_cr110, caseId, providerId, corrId, 'SPN');       	
		
		system.assert(string.valueOf(CR110.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR110_SPN.getxmldata();
        CR110.setCorspdInfo(xmlWrtr);
        CR110.setKeyParameters(xmlWrtr);
		CR110.setSignatureInfo(xmlWrtr, 'D', caseId, providerIdStr, cntySfid);

		//114
       	//CR107DataLoader CR114 = new CR107DataLoader(corspdName_cr114, caseId, providerId, corrId, 'ENG');
        //CR107DataLoader CR114_SPN = new CR107DataLoader(corspdName_cr114, caseId, providerId, corrId, 'SPN');       	
		
		//system.assert(string.valueOf(CR114.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        //CR114_SPN.getxmldata();
        //CR114.setCorspdInfo(xmlWrtr);
        //CR114.setKeyParameters(xmlWrtr);
		//CR114.setSignatureInfo(xmlWrtr, 'D', caseId, providerIdStr, cntySfid);
		//CR114.setCR114ProviderInfo(xmlWrtr);

		
		//work form line 540
		test.stopTest();
	}
	public static testmethod void setProviderHeaderAdjmtCntyInfo_Test3()
    {
		
		string corspdName_cr107= 'CR107';
		string corspdName_cr108= 'CR108';
		string corspdName_cr109= 'CR109';
		string corspdName_cr110= 'CR110';
		string corspdName_cr114= 'CR114';
		string corspdName_cr212= 'CR212';
		string corspdName_cr702= 'CR702';
        //string caseId = 'CA-1';
        integer providerId = 123;
        String corrId = 'Adams';

		String providerIdStr =TestClassUtility.createProvider(true,'Test').Id;
		T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c(Name = providerIdStr, NAM_FACILITY__c = 'abc', CDE_STATUS_PROVR__c='Open');
        insert provider;

        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        User fromUser = TestClassUtility.createUser(userProfile.Id , 'test1','test1','test1@example.com','test1@example.com.'+string.valueof(math.random()*3),'ttes1');
		insert fromUser;

		T_COUNTY__c county = TestClassUtility.createCounty('Denver','Denver',1,true);
		
		String cntySfid = county.Id;

		T_PROVR_FISCAL_AGREMENT__c providerFA1 = TestClassUtility.createFiscaAgreement(false,'Test FA 1',System.today().addYears(1),county.Id);
        providerFA1.OwnerId= fromUser.Id;
		providerFA1.CDE_COUNTY__c = county.Id;
        providerFA1.ID_SERVICE__c=provider.Id;
        //providerFA1.RecordtypeId=openRecordTypeId;
        providerFA1.DTE_RCV_AGRMT_FISCAL__c= System.today();
		providerFA1.DTE_BEGIN_AGRMT__c = System.today();
        //providerFA1.CDE_TYPE_STATUS__c='OPN';
        insert providerFA1;

		//Indiv Record
		T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
        insert indivRec;

		//
		string caseId = indivRec.Id;

		//Case insert
		T_SBSD_CASE__c cases = TestClassUtility.createCase(false, county.Id);
		insert cases;
		cases.IDN_EXTNL__c='12345';
		cases.Name = cases.Id;

		//Auth Authorization
		T_AUTH__c authObj = TestClassUtility.createAuthorization(false, null, System.today().addDays(-8), county.Id, provider.Id);
        authObj.IDN_CASE__c = cases.Id;
        authObj.IDN_EXTNL__c='123';
		//authObj.NAM_FACILITY__c='Lord';
		//authObj.IDN_PROVR__c=provider.Id;
		authObj.isFinishedFlow__c=true;
		authObj.IDN_CLIENT__c=caseId;//indivRec.Id;
		authObj.IDN_CASE__c=cases.Id;
        insert authObj;
		
		XmlStreamWriter xmlWrtr = new XmlStreamWriter();

		test.startTest();
		//114
       	CR107DataLoader CR114 = new CR107DataLoader(corspdName_cr114, caseId, providerId, corrId, 'ENG');
        CR107DataLoader CR114_SPN = new CR107DataLoader(corspdName_cr114, caseId, providerId, corrId, 'SPN');       	
		
		system.assert(string.valueOf(CR114.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR114_SPN.getxmldata();
        CR114.setCorspdInfo(xmlWrtr);
        CR114.setKeyParameters(xmlWrtr);
		CR114.setSignatureInfo(xmlWrtr, 'D', caseId, providerIdStr, cntySfid);
		CR114.setCR114ProviderInfo(xmlWrtr);
		test.stopTest();
	}
	public static testmethod void setProviderHeaderAdjmtCntyInfo_Test4()
    {
		
		string corspdName_cr107= 'CR107';
		string corspdName_cr108= 'CR108';
		string corspdName_cr109= 'CR109';
		string corspdName_cr110= 'CR110';
		string corspdName_cr114= 'CR114';
		string corspdName_cr212= 'CR212';
		string corspdName_cr702= 'CR702';
        string caseId = 'CA-1';
        integer providerId = 123;
        String corrId = 'Adams';

		String providerIdStr =TestClassUtility.createProvider(true,'Test').Id;
		T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c(Name = providerIdStr, NAM_FACILITY__c = 'abc', CDE_STATUS_PROVR__c='Open');
        insert provider;

        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        User fromUser = TestClassUtility.createUser(userProfile.Id , 'test1','test1','test1@example.com','test1@example.com.'+string.valueof(math.random()*3),'ttes1');
		insert fromUser;

		T_COUNTY__c county = TestClassUtility.createCounty('Denver','Denver',1,true);
		
		String cntySfid = county.Id;

		T_PROVR_FISCAL_AGREMENT__c providerFA1 = TestClassUtility.createFiscaAgreement(false,'Test FA 1',System.today().addYears(1),county.Id);
        providerFA1.OwnerId= fromUser.Id;
		providerFA1.CDE_COUNTY__c = county.Id;
        providerFA1.ID_SERVICE__c=provider.Id;
        //providerFA1.RecordtypeId=openRecordTypeId;
        providerFA1.DTE_RCV_AGRMT_FISCAL__c= System.today();
		providerFA1.DTE_BEGIN_AGRMT__c = System.today();
        //providerFA1.CDE_TYPE_STATUS__c='OPN';
        insert providerFA1;

		//Case insert
		T_SBSD_CASE__c cases = TestClassUtility.createCase(false, county.Id);
		insert cases;
		cases.IDN_EXTNL__c='12345';
		cases.Name = cases.Id;

		//Auth Authorization
		T_AUTH__c authObj = TestClassUtility.createAuthorization(false, null, System.today().addDays(-8), county.Id, provider.Id);
        authObj.IDN_CASE__c = cases.Id;
        authObj.IDN_EXTNL__c='123';
        insert authObj;
		
		XmlStreamWriter xmlWrtr = new XmlStreamWriter();

		test.startTest();
		//212
       	CR107DataLoader CR212 = new CR107DataLoader(corspdName_cr212, caseId, providerId, corrId, 'ENG');
        CR107DataLoader CR212_SPN = new CR107DataLoader(corspdName_cr212, caseId, providerId, corrId, 'SPN');       	
		
		//system.assert(string.valueOf(CR212.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR212_SPN.getxmldata();
        CR212.setCorspdInfo(xmlWrtr);
        CR212.setKeyParameters(xmlWrtr);
		CR212.setSignatureInfo(xmlWrtr, 'D', caseId, providerIdStr, cntySfid);

		//702
       	CR107DataLoader CR702 = new CR107DataLoader(corspdName_cr702, caseId, providerId, corrId, 'ENG');
        CR107DataLoader CR702_SPN = new CR107DataLoader(corspdName_cr702, caseId, providerId, corrId, 'SPN');       	
		
		//system.assert(string.valueOf(CR107.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR702_SPN.getxmldata();
        CR702.setCorspdInfo(xmlWrtr);
        CR702.setKeyParameters(xmlWrtr);
		CR702.setSignatureInfo(xmlWrtr, 'D', caseId, providerIdStr, cntySfid);
		CR702.getPayload();
		test.stopTest();
	}
	public static testmethod void setProviderHeaderAdjmtCntyInfo_Test5()
    {
		
		string corspdName_cr107= 'CR107';
		string corspdName_cr108= 'CR108';
		string corspdName_cr109= 'CR109';
		string corspdName_cr110= 'CR110';
		string corspdName_cr114= 'CR114';
		string corspdName_cr212= 'CR212';
		string corspdName_cr702= 'CR702';
        //string caseId = 'CA-1';
        integer providerId = 123;
        String corrId = 'Adams';

		String providerIdStr =TestClassUtility.createProvider(true,'Test').Id;
		T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c(Name = providerIdStr, NAM_FACILITY__c = 'abc', CDE_STATUS_PROVR__c='Open');
        insert provider;

        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        User fromUser = TestClassUtility.createUser(userProfile.Id , 'test1','test1','test1@example.com','test1@example.com.'+string.valueof(math.random()*3),'ttes1');
		insert fromUser;

		T_COUNTY__c county = TestClassUtility.createCounty('Denver','Denver',1,true);
		
		String cntySfid = county.Id;

		T_PROVR_FISCAL_AGREMENT__c providerFA1 = TestClassUtility.createFiscaAgreement(false,'Test FA 1',System.today().addYears(1),county.Id);
        providerFA1.OwnerId= fromUser.Id;
		providerFA1.CDE_COUNTY__c = county.Id;
        providerFA1.ID_SERVICE__c=provider.Id;
        //providerFA1.RecordtypeId=openRecordTypeId;
        providerFA1.DTE_RCV_AGRMT_FISCAL__c= System.today();
		providerFA1.DTE_BEGIN_AGRMT__c = System.today();
        //providerFA1.CDE_TYPE_STATUS__c='OPN';
        insert providerFA1;

		//Indiv Record
		T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
        insert indivRec;

		//
		String caseId = indivRec.Id;
		//
		String clientId = indivRec.Id;//'INDIV-1';

		//Case insert
		T_SBSD_CASE__c cases = TestClassUtility.createCase(false, county.Id);
		cases.Name = cases.Id;
		cases.IDN_EXTNL__c='12345';
		insert cases;

		//Auth Authorization
		T_AUTH__c authObj = TestClassUtility.createAuthorization(false, null, System.today().addDays(-8), county.Id, provider.Id);
        authObj.IDN_CASE__c = cases.Id;
        authObj.IDN_EXTNL__c='123';
		authObj.isFinishedFlow__c=true;
		authObj.IDN_CLIENT__c=caseId;//indivRec.Id;
		authObj.IDN_CASE__c=cases.Id;
        insert authObj;
		
		XmlStreamWriter xmlWrtr = new XmlStreamWriter();

		test.startTest();
		//114
       	CR114DataLoader CR114 = new CR114DataLoader(corspdName_cr114, caseId, providerId, corrId, 'ENG', clientId);
        CR114DataLoader CR114_SPN = new CR114DataLoader(corspdName_cr114, caseId, providerId, corrId, 'SPN', clientId);       	
		
		system.assert(string.valueOf(CR114.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR114_SPN.getxmldata();
        CR114.setCorspdInfo(xmlWrtr);
        CR114.setKeyParameters(xmlWrtr);
		CR114.setSignatureInfo(xmlWrtr, 'D', caseId, providerIdStr, cntySfid);
		CR114.setCR114ProviderInfo(xmlWrtr);
        
		test.stopTest();
	}
}