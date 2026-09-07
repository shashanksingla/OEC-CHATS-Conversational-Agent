@isTest
public class corspdTriggerTest {
    public static integer countyCode = 20;
    public static string caseId = 'CA-1';
    public static integer providerId = 123;
    public static string clientId = '567';
	//public static string IPVRecordId = '123';
	//public static string faId = '567';
    
    @testSetup 
    static void setup() {
        // Creating a case record and County Record
        T_COUNTY__c countyObject = new T_COUNTY__c();
        countyObject.CNTY_DEPT_NAME__c = 'Denver County';
        countyObject.CDE_COUNTY__c = countyCode; //20;
        insert countyObject;
        
        T_SBSD_CASE__c caseObject = new T_SBSD_CASE__c();
        caseObject.CDE_COUNTY__c = countyObject.Id;
        caseObject.IND_ASSIST_PROVR__c = 'N';
        caseObject.CDE_ASST_HSNG__c = 'N';
        caseObject.Name = caseId;
        insert caseObject;
        
        // creating 3 sample records in Corspd Reason Table (C-P-C,P)
        T_DOC_RSN__c clientCorspdRsnObj = new T_DOC_RSN__c();
        clientCorspdRsnObj.Name ='CR0004';
        clientCorspdRsnObj.NME_CORSPD__c = 'CR107';
        clientCorspdRsnObj.CDE_TYPE_RCPT__c = 'C';
        clientCorspdRsnObj.Is_Manual__c = true;
        
        T_DOC_RSN__c prvCorspdRsnObj = new T_DOC_RSN__c();
        prvCorspdRsnObj.Name ='CR0013';
        prvCorspdRsnObj.NME_CORSPD__c = 'CR702';
        prvCorspdRsnObj.CDE_TYPE_RCPT__c = 'P';
        prvCorspdRsnObj.Is_Manual__c = true;
        
        T_DOC_RSN__c clientCorspdRsnObj2 = new T_DOC_RSN__c();
        clientCorspdRsnObj2.Name ='CR0013';
        clientCorspdRsnObj2.NME_CORSPD__c = 'CR702';
        clientCorspdRsnObj2.CDE_TYPE_RCPT__c = 'C';
        clientCorspdRsnObj2.Is_Manual__c = true;
        
        T_DOC_RSN__c bothCorspdRsnObj2 = new T_DOC_RSN__c();
        bothCorspdRsnObj2.Name ='CR0013';
        bothCorspdRsnObj2.NME_CORSPD__c = 'CR702';
        bothCorspdRsnObj2.CDE_TYPE_RCPT__c = 'C;P';
        bothCorspdRsnObj2.Is_Manual__c = true;
        
        T_DOC_RSN__c bothCorspdRsnObj = new T_DOC_RSN__c();
        bothCorspdRsnObj.Name ='CR0010';
        bothCorspdRsnObj.NME_CORSPD__c = 'CR213';
        bothCorspdRsnObj.CDE_TYPE_RCPT__c = 'C;P';
        bothCorspdRsnObj.Is_Manual__c = true;
        insert new List<T_DOC_RSN__c>{clientCorspdRsnObj, clientCorspdRsnObj2, prvCorspdRsnObj, bothCorspdRsnObj, bothCorspdRsnObj2};
        
        T_CHATS_PROVR_STATUS__c prvObject = new T_CHATS_PROVR_STATUS__c();        
        prvObject.Name = '123';
        insert prvObject;
        
        TestClassUtility.createAuthorization(true, date.today().addDays(30), date.today().addDays(-3), countyObject.Id, prvObject.Id);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        //T_SBSD_INDIV__c indiv = TestClassUtility.createIndividual(true, System.today().addYears(-4), 'firstName', '2', 'lastName','111222333','CWF');
    }
    
    // BG 2/18/18
    static testmethod void testCorspdTrigger(){   
		//
		T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_CASE__c sbsdcase =TestClassUtility.createCase(true,county.Id);
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(false,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
		//sbsdIndiv.Name = sbsdIndiv.Id;
		insert sbsdIndiv;
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        Date enddate = begindate.addDays(25);
        begindate = begindate.addDays(21);

		T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c=sbsdcase.Id;
        authorization.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization.isFinishedFlow__c=true;
        insert authorization;
		String authId =authorization.Id;

		String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(true, 'FA1', begindate, county.Id);
		String faId = fiscalAgreement.Id;
		
        T_COUNTY__c countyObj = new T_COUNTY__c( CNTY_DEPT_NAME__c = 'Arapahoe County', CDE_COUNTY__c = 3);
        insert countyObj;
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
		T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        caseRec.CDE_CBMS_REF_TYP__c = 'Change';
        caseRec.DTE_APPLN__c = System.today();
        update caseRec;
        //List<T_SBSD_CASE__c> caserecord = [Select Id from T_SBSD_CASE__c LIMIT 1];
		
		List<T_CHATS_PROVR_STATUS__c> providerObj = [Select Id from T_CHATS_PROVR_STATUS__c LIMIT 1];

		T_DOC_RQ__c corrReqRecord = new T_DOC_RQ__c (CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR107', RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C', IDN_AUTH__c= authId, DTE_REQ__c =system.today(), IDN_PROVR__C = providerObj[0].Id);
        insert corrReqRecord;
        
		String IPVRecordId;
        for(IPV_Information__c ipv : [SELECT Id FROM IPV_Information__c ORDER BY lastModifiedDate DESC LIMIT 1])
		{
            IPVRecordId = ipv.Id;
        }
		system.debug('ipvrec Id: ' + IPVRecordId);
		//        
        Test.startTest();
        
        Map<String, String> casePrvMap = new Map<String, String>();
		/*Map<String, String> casePrvMap2 = new Map<String, String>();
		Map<String, String> casePrvMap3 = new Map<String, String>();
		Map<String, String> casePrvMap4 = new Map<String, String>();
		Map<String, String> casePrvMap5 = new Map<String, String>();
		Map<String, String> casePrvMap6 = new Map<String, String>();
		Map<String, String> casePrvMap7 = new Map<String, String>();
		Map<String, String> casePrvMap8 = new Map<String, String>();*/
        //Map to store vales for caseID and Provider Id
        casePrvMap.put('caseId',caseId);
        casePrvMap.put('providerId',string.valueof(providerId));
		//
		casePrvMap.put('clientId',clientId);
		casePrvMap.put('authId', authId);
		casePrvMap.put('faId',faId);
		casePrvMap.put('IPVRecordId',IPVRecordId);
		/*casePrvMap2.put('clientId',sbsdIndiv.Id);
		casePrvMap3.put('DQBeginDate', String.valueOf(Date.today().addDays(-3)));
		casePrvMap4.put('DQEndDate', String.valueOf(Date.today().addDays(-1)));
		casePrvMap5.put('DQHearingDate', String.valueOf(Date.today().addDays(-3)));
		casePrvMap6.put('numOfOccurrences', '6');
		casePrvMap7.put('ContactPhoneNumber', '12345');
		casePrvMap8.put('IPVRecordId', '123');*/
		//
        /*CorspdTrigger.createCorspdRequest('CR0004', 'CR107', 'C', 20, casePrvMap8);
		//
        CorspdTrigger.createCorspdRequest('CR0004', 'CR107', 'C', 20, casePrvMap7);
		//
        CorspdTrigger.createCorspdRequest('CR0004', 'CR107', 'C', 20, casePrvMap6);
		//
        CorspdTrigger.createCorspdRequest('CR0004', 'CR107', 'C', 20, casePrvMap5);
		//
        CorspdTrigger.createCorspdRequest('CR0004', 'CR107', 'C', 20, casePrvMap4);
		//
        CorspdTrigger.createCorspdRequest('CR0004', 'CR107', 'C', 20, casePrvMap3);
		//
        CorspdTrigger.createCorspdRequest('CR0004', 'CR107', 'C', 20, casePrvMap2);*/
        // corspdName and sendTo are not null
        CorspdTrigger.createCorspdRequest('CR0004', 'CR107', 'C', 20, casePrvMap);
        //corspdName is not null and sendTo - null
        CorspdTrigger.createCorspdRequest('CR0004', 'CR107', NULL, 20, casePrvMap);
        //corspdName - null and sendTo - not null
        CorspdTrigger.createCorspdRequest('CR0004', NULL, 'C', 20, casePrvMap);
        //both are null
        CorspdTrigger.createCorspdRequest('CR0004', NULL, NULL, 20, casePrvMap);
        
        //similarly creating a record in corspdReason for provider
        CorspdTrigger.createCorspdRequest('CR0013', 'CR702', 'P', 20, casePrvMap); 
        
        List<String> result = CorspdTrigger.createCorspdRequest('CR0010', 'CR213', 'C;P', 20, casePrvMap);
        //This multiselect picklist - creates two records in correspondence request
        //system.assert(result.size() > 0);
        
        casePrvMap.put('providerId',null);
        CorspdTrigger.createCorspdRequest('CR0013', null, null, 20, casePrvMap);
        
        casePrvMap.put('caseId',null);
        CorspdTrigger.createCorspdRequest('CR0013', null, null, 20, casePrvMap);
        
        casePrvMap.put('providerId',string.valueof(providerId));
        CorspdTrigger.createCorspdRequest('CR0013', null, null, 20, casePrvMap);
        
        casePrvMap.put('providerId',providerObj[0].Id);
        casePrvMap.put('clientId','firstName lastName');
        CorspdTrigger.createCorspdRequest('CR0013', null, null, 20, casePrvMap);
        Test.stopTest();        
    }
    //BG 2/18/18 */
    
    static testmethod void testCorspdTrigger_Bulk(){    
        T_AUTH__c auth = [SELECT Id FROM T_AUTH__c Limit 1];
		Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        User fromUser = TestClassUtility.createUser(userProfile.Id , 'test1','test1','test1@example.com','test1@example.com.'+string.valueof(math.random()*3),'ttes1');
		insert fromUser;
		//Indiv Record
		T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
		indivRec.OwnerId = fromUser.Id;
        insert indivRec;
		T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
		T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(true, 'FA1', System.today(), county.Id);
		String faId = fiscalAgreement.Id;
		
		T_SBSD_CASE__c caseObj = [SELECT Id FROM T_SBSD_CASE__c Limit 1];	
		T_CHATS_PROVR_STATUS__c prvder=TestClassUtility.createProvider(true, 'Level 2');
		T_ADJMT__c adjObj = TestClassUtility.createAdjustment(true, county.Id, caseObj.Id, prvder.Id);
		String adjObjID = adjObj.Id;
		T_ADJMT_ADDR__c adjAddr = TestClassUtility.createAdjustmentAddress(true, adjObj.Id);
		//
		T_ADJMT__c adjObj2 = TestClassUtility.createAdjustment(true, county.Id, caseObj.Id, prvder.Id);
		T_ADJMT_ADDR__c adjAddr2 = TestClassUtility.createAdjustmentAddress(true, adjObj2.Id);
		String AdjustmentAddress  = adjAddr.Id;

			
		//String providerIdStr =TestClassUtility.createProvider(true,'Test').Id;
		//T_DOC_RQ__c corrReqRecord = new T_DOC_RQ__c (CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR107', RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C', IDN_AUTH__c= auth.Id, DTE_REQ__c =system.today(), IDN_PROVR__C = providerIdStr, IDN_CASE__c = caseObj.Id );
        //insert corrReqRecord;
        
        Test.startTest();
        //Map to store vales for caseID and Provider Id
        Map<String, String> casePrvMap = new Map<String, String>();
        casePrvMap.put('caseId',caseId);
        casePrvMap.put('providerId',string.valueof(providerId));
        casePrvMap.put('authId',string.valueof(auth.Id));
		casePrvMap.put('clientId',string.valueof(indivRec.Id));
		casePrvMap.put('faId', faId);
		casePrvMap.put('adjmtId', adjObjID);
		casePrvMap.put('DQBeginDate', String.valueOf(system.today()));
		casePrvMap.put('DQHearingDate', String.valueOf(system.today()));
		casePrvMap.put('DQEndDate', String.valueOf(system.today()));
		casePrvMap.put('ContactPhoneNumber', String.valueOf(system.today()));
		casePrvMap.put('numOfOccurrences', '6');
		casePrvMap.put('AdjustmentAddress', AdjustmentAddress);
        
        //T_SBSD_CASE__c caseObj = [SELECT Id FROM T_SBSD_CASE__c Limit 1];
        Set<Id> recordKeySet = new Set<Id>{caseObj.Id};
        Map<Id, String> rsnCodeMap = new Map<Id, String>{caseObj.Id => 'CR0013'};
        Map<Id, String> crspdNameMap = new Map<Id, String>{caseObj.Id => null};
        Map<Id, String> sendToMap = new Map<Id, String>{caseObj.Id => null};     
        Map<Id, Integer> countyCodeMap = new Map<Id, Integer>{caseObj.Id => 20}; 
        Map<Id, Map<String, String>> keyParamMap = new Map<Id, Map<String, String>>{caseObj.Id => casePrvMap};
         Map<Id, Set<Id>> adjustmentAddressMap = new Map<Id, Set<Id>>();
		Map<Id, Set<Id>> adjustmentAddressMap2 = new Map<Id, Set<Id>>();
		//
		Set<Id> SadjAddrSet = new Set<Id>();
		SadjAddrSet.add(adjAddr2.Id);
		SadjAddrSet.add(adjAddr.Id);
		adjustmentAddressMap2.put(adjObj.Id, SadjAddrSet);
        // corspdName and sendTo are not null
        CorspdTrigger.createCorspdRequestBulk(recordKeySet, rsnCodeMap, crspdNameMap, sendToMap, countyCodeMap, keyParamMap,adjustmentAddressMap2);
        //CorspdTrigger.createCorspdRequestBulk(recordKeySet, rsnCodeMap, crspdNameMap, sendToMap, countyCodeMap, keyParamMap,adjustmentAddressMap);

        casePrvMap.put('providerId',null);
        CorspdTrigger.createCorspdRequestBulk(recordKeySet, rsnCodeMap, crspdNameMap, sendToMap, countyCodeMap, keyParamMap,adjustmentAddressMap2);
        
        casePrvMap.put('caseId',null);
        CorspdTrigger.createCorspdRequestBulk(recordKeySet, rsnCodeMap, crspdNameMap, sendToMap, countyCodeMap, keyParamMap,adjustmentAddressMap2);
        
        casePrvMap.put('providerId',string.valueof(providerId));
        CorspdTrigger.createCorspdRequestBulk(recordKeySet, rsnCodeMap, crspdNameMap, sendToMap, countyCodeMap, keyParamMap,adjustmentAddressMap2);

		Map<String, String> casePrvMap2 = new Map<String, String>();
        casePrvMap2.put('caseId',caseId);
        casePrvMap2.put('providerId',string.valueof(providerId));
        casePrvMap2.put('authId', null);
		casePrvMap2.put('clientId',string.valueof(indivRec.Id));
		casePrvMap2.put('faId', faId);
		casePrvMap2.put('adjmtId', adjObjID);
		casePrvMap2.put('DQBeginDate', String.valueOf(system.today()));
		casePrvMap2.put('DQHearingDate', String.valueOf(system.today()));
		casePrvMap2.put('DQEndDate', String.valueOf(system.today()));
		casePrvMap2.put('ContactPhoneNumber', String.valueOf(system.today()));
		casePrvMap2.put('numOfOccurrences', '6');
		casePrvMap2.put('AdjustmentAddress', AdjustmentAddress);
		Map<Id, Map<String, String>> keyParamMap2 = new Map<Id, Map<String, String>>{caseObj.Id => casePrvMap2};
        CorspdTrigger.createCorspdRequestBulk(recordKeySet, rsnCodeMap, crspdNameMap, sendToMap, countyCodeMap, keyParamMap2,adjustmentAddressMap2);
                
        Test.stopTest();        
    }
	public static testmethod void createCorspdRequestTEST()
    {
		T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
		T_SBSD_CASE__c caseObj = [SELECT Id FROM T_SBSD_CASE__c Limit 1];	
		T_ADJMT__c adjObj = TestClassUtility.createAdjustment(true, county.Id, caseObj.Id, null);

		String adjObjID = adjObj.Id;
		Map<String, String> casePrvMap = new Map<String, String>();
		casePrvMap.put('DQBeginDate', String.valueOf(system.today()));
		casePrvMap.put('DQHearingDate', String.valueOf(system.today()));
		casePrvMap.put('DQEndDate', String.valueOf(system.today()));
		casePrvMap.put('ContactPhoneNumber', String.valueOf(system.today()));
		casePrvMap.put('adjmtId', adjObjID);
		//casePrvMap.put('numOfOccurrences', String.valueOf(system.today()));
		String IPVRecordId;
        for(IPV_Information__c ipv : [SELECT Id FROM IPV_Information__c ORDER BY lastModifiedDate DESC LIMIT 1])
		{
            IPVRecordId = ipv.Id;
        }
		casePrvMap.put('IPVRecordId', IPVRecordId);
		test.startTest();
        CorspdTrigger.createCorspdRequest('CR0004', 'CR107', NULL, 20, casePrvMap);
		CorspdTrigger.createCorspdRequest('CR0013', 'CR702', 'p', 20, casePrvMap);
		test.stopTest();
	}
    
}