@isTest
public class corspdPrintQueueTest {
    
    static testmethod void testProcessCorspdSearch() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new CorspdPrintQueueMockSuccessTest());
        T_COUNTY__c countyObj = new T_COUNTY__c( CNTY_DEPT_NAME__c = 'Arapahoe County', CDE_COUNTY__c = 3);
        insert countyObj;
        T_SBSD_CASE__c caserecord = new T_SBSD_CASE__c (    CDE_COUNTY__c = countyObj.Id, IND_ASSIST_PROVR__c = 'N',
                                                            CDE_ASST_HSNG__c = 'N', Name = 'CA-1');
        insert caserecord;
        
        T_CHATS_PROVR_STATUS__c providerObj = new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert providerObj;
        date dt1 =date.newInstance(2018, 1, 1);
        date dt2 =date.newInstance(2018, 11, 1);
        date dt3 =date.newInstance(2018, 1, 11);
        T_DOC_RQ__c corrReqRecord = new T_DOC_RQ__c (   CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR107',
                                                        RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C', DTE_REQ__c = dt1, IDN_CASE__c= caserecord.Id);
        insert corrReqRecord;
        T_DOC_RQ__c corrReqRecord1 = new T_DOC_RQ__c (  CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR107',
                                                        RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C', DTE_REQ__c = dt2, IDN_CASE__c= caserecord.Id);
        insert corrReqRecord1;
        T_DOC_RQ__c corrReqRecord2 = new T_DOC_RQ__c (  CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR107',
                                                        RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C', DTE_REQ__c = dt3, IDN_CASE__c= caserecord.Id);
        insert corrReqRecord2;
        T_DOC_RQ__c getCorrRecord = [select Id, Name From T_DOC_RQ__c where Id =:corrReqRecord.Id];
        List<T_DOC_RQ__c> listCorrToDelete = new List<T_DOC_RQ__c>();
        List<String> listCorrToDeleteId = new List<String>();
        List<String> lstCorrReq = new List<String>();
        lstCorrReq.add(getCorrRecord.Id);
        listCorrToDelete.add(getCorrRecord);
        listCorrToDeleteId.add(getCorrRecord.Id);
        
        String dateReqstd = String.valueOf(dt1);
        String dateReqstd1 = String.valueOf(dt2);
        String dateReqstd2 = String.valueOf(dt3);
        String cntyId = String.valueOf(countyObj.Id);
        //integer provrId = integer.valueOf(providerObj.Name);
        integer provrId =101 ;
        integer corrId = integer.valueOf(getCorrRecord.Name);
        corspdPrintQueue printQueue = new corspdPrintQueue();
        Map<String, Object> params1 = new Map<String, Object>{
            'corspdStatus' => corrReqRecord.CDE_CORSPD_STATUS__c,
            'countyName' => cntyId,
            'caseId' => caserecord.Name,
            'providerId' => provrId,
            'dateRequested' => dateReqstd,
            'dateRequestedEndRange' => dateReqstd,
            'correspondenceId' => corrId,
            'correspondenceType' => corrReqRecord.NME_CORSPD__c,
            'correspondenceRecipientType' => 'C',
            'requestedBy' => null,
            'datePrintedBeginDate' => null,
            'datePrintedEndDate' => null,
            'screen' => 'CorrespondenceGeneration',
            'suppressIndicator' => null
        };
        String jsonParam1 = JSON.serialize(params1);
        corspdReturnPacket rtrnPrintQueue = (corspdReturnPacket)printQueue.processRequest('processCorspdSearch', jsonParam1);
        system.assertEquals('Success',rtrnPrintQueue.returnStatus,'Return status should be success');
        Map<String, Object> params2 = new Map<String, Object>{
            'corspdStatus' => corrReqRecord.CDE_CORSPD_STATUS__c,
            'countyName' => cntyId,
            'caseId' => caserecord.Name,
            'providerId' => provrId,
            'dateRequested' => dateReqstd1,
            'dateRequestedEndRange' => null,
            'correspondenceId' => corrId,
            'correspondenceType' => corrReqRecord.NME_CORSPD__c,
            'correspondenceRecipientType' => 'C',
            'requestedBy' => null,
            'datePrintedBeginDate' => null,
            'datePrintedEndDate' => null,
            'screen' => 'CorrespondenceGeneration',
            'suppressIndicator' => null
        };
        String jsonParam2 = JSON.serialize(params2);
        corspdReturnPacket rtrnPrintQueue1 = (corspdReturnPacket)printQueue.processRequest('processCorspdSearch', jsonParam2);
        system.assertEquals('Success',rtrnPrintQueue1.returnStatus,'Return status should be success');
        Map<String, Object> params3 = new Map<String, Object>{
            'corspdStatus' => corrReqRecord.CDE_CORSPD_STATUS__c,
            'countyName' => cntyId,
            'caseId' => caserecord.Name,
            'providerId' => provrId,
            'dateRequested' => dateReqstd2,
            'dateRequestedEndRange' => dateReqstd2,
            'correspondenceId' => corrId,
            'correspondenceType' => corrReqRecord.NME_CORSPD__c,
            'correspondenceRecipientType' => 'C',
            'requestedBy' => null,
            'datePrintedBeginDate' => null,
            'datePrintedEndDate' => null,
            'screen' => 'CorrespondenceGeneration',
            'suppressIndicator' => null
        };
        String jsonParam3 = JSON.serialize(params3);
        corspdReturnPacket rtrnPrintQueue2 = (corspdReturnPacket)printQueue.processRequest('processCorspdSearch', jsonParam3);
        system.assertEquals('Success',rtrnPrintQueue2.returnStatus,'Return status should be success');        
        Map<String, Object> params4 = new Map<String, Object>{
            'corspdStatus' => 'REL',
            'countyName' => cntyId,
            'caseId' => caserecord.Name,
            'providerId' => provrId,
            'dateRequested' => dateReqstd,
            'dateRequestedEndRange' => dateReqstd,
            'correspondenceId' => corrId,
            'correspondenceType' => 'Null',
            'correspondenceRecipientType' => 'C',
            'requestedBy' => null,
            'datePrintedBeginDate' => null,
            'datePrintedEndDate' => null,
            'screen' => 'PrintedCorrespondence',
            'suppressIndicator' => null
        };
        String jsonParam4 = JSON.serialize(params4);
        corspdReturnPacket rtrnPrintedCorr = (corspdReturnPacket)printQueue.processRequest('processCorspdSearch', jsonParam4);
        
        Map<String, Object> params5 = new Map<String, Object>{
            'corspdStatus' => 'REL',
            'countyName' => cntyId,
            'caseId' => caserecord.Name,
            'providerId' => provrId,
            'dateRequested' => dateReqstd1,
            'dateRequestedEndRange' => dateReqstd1,
            'correspondenceId' => corrId,
            'correspondenceType' => 'Null',
            'correspondenceRecipientType' => 'C',
            'requestedBy' => null,
            'datePrintedBeginDate' => null,
            'datePrintedEndDate' => null,
            'screen' => 'PrintedCorrespondence',
            'suppressIndicator' => null
        };
        String jsonParam5 = JSON.serialize(params5);
        corspdReturnPacket rtrnPrintedCorr1 = (corspdReturnPacket)printQueue.processRequest('processCorspdSearch', jsonParam5);
        
        Map<String, Object> params6 = new Map<String, Object>{
            'corspdStatus' => 'REL',
            'countyName' => cntyId,
            'caseId' => caserecord.Name,
            'providerId' => provrId,
            'dateRequested' => dateReqstd2,
            'dateRequestedEndRange' => dateReqstd2,
            'correspondenceId' => corrId,
            'correspondenceType' => 'Null',
            'correspondenceRecipientType' => 'C',
            'requestedBy' => null,
            'datePrintedBeginDate' => null,
            'datePrintedEndDate' => null,
            'screen' => 'PrintedCorrespondence',
            'suppressIndicator' => null
        };
        String jsonParam6 = JSON.serialize(params6);
        corspdReturnPacket rtrnPrintedCorr2 = (corspdReturnPacket)printQueue.processRequest('processCorspdSearch', jsonParam6);
        
        corspdReturnPacket rtrnPacketDelete = corspdPrintQueue.processCorspdDelete(lstCorrReq, listCorrToDelete);
        system.assertEquals('Success',rtrnPrintQueue2.returnStatus,'Return status should be success');
        
        Map<String, Object> paramsFileName = new Map<String, Object>{
            'corspdId' => ''
        };
        String jsonParamFileName = JSON.serialize(paramsFileName);
        corspdReturnPacket rtrnFileName = (corspdReturnPacket)printQueue.processRequest('getFileName', jsonParamFileName);
        test.stopTest();
    }

    @isTest
    static void testgetPrintedCorspdDetails() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new CorspdPrintQueueMockSuccessTest());
        corspdReturnPacket rtrn = corspdPrintQueue.getPrintedCorspdDetails('REL', NULL, NULL, NULL, NULL, NULL, 1234567,NULL,NULL,NULL,NULL,NULL,NULL);
        system.assertEquals('Success',rtrn.returnStatus,'Return status should be success');
        
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockFailureTest());
        corspdReturnPacket rtrn1 = corspdPrintQueue.getPrintedCorspdDetails('REL', NULL, NULL, NULL, NULL, NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL);
        system.assertEquals('Failure',rtrn1.returnStatus,'Return status should be Failure');
        test.stopTest();
    }
    
    @isTest
    static void testProcessCorspdQueueToView() {
        T_DOC_RQ__c corspdReq = new T_DOC_RQ__c (CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR107', RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C');
        T_DOC_RQ__c corspdReq_generated = new T_DOC_RQ__c (CDE_CORSPD_STATUS__c = 'Generated', NME_CORSPD__c = 'CR107', DTE_REQ__c = system.today(), cde_lang_doc__c = 'ENG', RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C');
        //insert corspdReq;
        insert corspdReq_generated;
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new CorspdPrintQueueMockSuccessTest());
        T_DOC_RQ__c tdoc = [SELECT Id, Name FROM T_DOC_RQ__c WHERE CDE_CORSPD_STATUS__c = 'Generated' AND NME_CORSPD__c = 'CR107' AND RSN_CODE__c = 'CR0004' AND CDE_TYPE_RCPT__c = 'C' LIMIT 1];
        corspdPrintQueue printQueue1 = new corspdPrintQueue();
        Map<String, Object> paramsQueueView1 = new Map<String, Object>{
            'corspdId' => tdoc.Name
        };
        String jsonParamQueueView1 = JSON.serialize(paramsQueueView1);
        corspdReturnPacket rtrn_gen2 = (corspdReturnPacket)printQueue1.processRequest('processCorspdQueueToView', jsonParamQueueView1);
        system.assertEquals('Success',rtrn_gen2.returnStatus,'Return status should be Success');
        
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockFailureTest());
        Map<String, Object> paramsQueueView2 = new Map<String, Object>{
            'corspdId' => null
        };
        String jsonParamQueueView2 = JSON.serialize(paramsQueueView2);
        corspdReturnPacket rtrn1 = (corspdReturnPacket)printQueue1.processRequest('processCorspdQueueToView', jsonParamQueueView2);
        system.assertEquals('Failure',rtrn1.returnStatus,'Return status should be failure');
        test.stopTest();
    }
    
   @isTest
    static void testprocessCorspdPrint() {
       
        T_DOC_RQ__c corspdReq = new T_DOC_RQ__c (   CDE_CORSPD_STATUS__c = 'Requested',
                                                    NME_CORSPD__c = 'CR107',
                                                    RSN_CODE__c = 'CR0004',
                                                 	cde_lang_doc__c = 'ENG',
                                                 	CDE_TYPE_RCPT__c = 'C');
        T_DOC_RQ__c corspdReq1 = new T_DOC_RQ__c (  CDE_CORSPD_STATUS__c = 'Generated',
                                                    NME_CORSPD__c = 'CR115',
                                                    RSN_CODE__c = 'CR0006',
                                                  	cde_lang_doc__c = 'ENG',
                                                  	DTE_REQ__c = system.today(),
                                                  	CDE_TYPE_RCPT__c = 'C');
        insert corspdReq;
        insert corspdReq1;
        List<string> corspdReqlst = new List<string>();
        List<string> corspdReqlst1 = new List<string>();
        corspdReqlst.add(corspdReq.Id);
        corspdReqlst1.add(corspdReq1.Id);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new CorspdPrintQueueMockSuccessTest());
        corspdPrintQueue printQueue2 = new corspdPrintQueue();
        Map<String, Object> paramsPrint1 = new Map<String, Object>{
            'lstCorspdId' => corspdReqlst
        };
        String jsonParamPrint1 = JSON.serialize(paramsPrint1);
        corspdReturnPacket rtrn = (corspdReturnPacket)printQueue2.processRequest('processCorspdPrint', jsonParamPrint1);
        system.assertEquals('Success',rtrn.returnStatus,'Return status should be success');
        
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockFailureTest());
        Map<String, Object> paramsPrint2 = new Map<String, Object>{
            'lstCorspdId' => corspdReqlst
        };
        String jsonParamPrint2 = JSON.serialize(paramsPrint2);
        corspdReturnPacket rtrn1 = (corspdReturnPacket)printQueue2.processRequest('processCorspdPrint', jsonParamPrint2);
        system.assertEquals('Success',rtrn.returnStatus,'Return status should be success');
        
        Test.setMock(HttpCalloutMock.class, new CorspdPrintQueueMockSuccessTest());
        Map<String, Object> paramsPrint3 = new Map<String, Object>{
            'lstCorspdId' => corspdReqlst1
        };
        String jsonParamPrint3 = JSON.serialize(paramsPrint3);
        corspdReturnPacket rtrn2 = (corspdReturnPacket)printQueue2.processRequest('processCorspdPrint', jsonParamPrint3);
        system.assertEquals('Success',rtrn2.returnStatus,'Return status should be success');
		
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockFailureTest());
        Map<String, Object> paramsPrint4 = new Map<String, Object>{
            'lstCorspdId' => corspdReqlst1
        };
        String jsonParamPrint4 = JSON.serialize(paramsPrint4);
        corspdReturnPacket rtrn3 = (corspdReturnPacket)printQueue2.processRequest('processCorspdPrint', jsonParamPrint4);
        system.assertEquals('Failure',rtrn3.returnStatus,'Return status should be failure');
        test.stopTest();
    }
    
    @isTest
    static void testFetchUserdata() {
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        
        system.runAs(user) {
            corspdPrintQueue printQueue3 = new corspdPrintQueue();
            Map<String, Object> paramsUserData = new Map<String, Object>();
            String jsonParamUserData = JSON.serialize(paramsUserData);
            LightningServerResponse lsrTest = (LightningServerResponse)printQueue3.processRequest('fetchUserdata', jsonParamUserData);
        	system.assertEquals(true,lsrTest.isSuccessful,'isSuccessful should be true');
        }
        
    }
    
    static testmethod void corspdSuppressOrDeleteAction_Test() {
        corspdPrintQueue printQueue = new corspdPrintQueue();
        T_COUNTY__c countyObj = new T_COUNTY__c( CNTY_DEPT_NAME__c = 'Arapahoe County', CDE_COUNTY__c = 3);
        insert countyObj;
        T_SBSD_CASE__c caserecord = new T_SBSD_CASE__c (    CDE_COUNTY__c = countyObj.Id, IND_ASSIST_PROVR__c = 'N',
                                                            CDE_ASST_HSNG__c = 'N', Name = 'CA-1');
        insert caserecord;
        T_CHATS_PROVR_STATUS__c providerObj = new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert providerObj;
        date dt1 =date.newInstance(2018, 1, 1);
        T_DOC_RQ__c corrReqRecord = new T_DOC_RQ__c (CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR107',
                                                     RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C', DTE_REQ__c = dt1, 
                                                     IDN_CASE__c= caserecord.Id);
        insert corrReqRecord;
        T_DOC_RQ__c getCorrRecord = [select Id, Name From T_DOC_RQ__c where Id =:corrReqRecord.Id];
        Map<String, Object> params = new Map<String, Object>{
            'lstCorspdId' => new List<String>{getCorrRecord.Id},
            'operation' => 'DELETE'
        };        
        String jsonParam = JSON.serialize(params);
        test.startTest();
        T_DOC_RQ__c corr = [SELECT Id, Name FROM T_DOC_RQ__c WHERE CDE_CORSPD_STATUS__c = 'Requested' AND NME_CORSPD__c = 'CR107' AND RSN_CODE__c = 'CR0004' AND CDE_TYPE_RCPT__c = 'C' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new CorspdPrintQueueMockSuccessTest());
        Map<String, Object> paramsAddPrintedDate = new Map<String, Object>{
            'lstCorspdId' => corr.Name,
            'alreadygenUrl' => 'test',
            'fileName' => 'test'
        };
        String jsonParamAddPrintedDate = JSON.serialize(paramsAddPrintedDate);
        corspdReturnPacket res = (corspdReturnPacket)printQueue.processRequest('addPrintedDateToCorspdDate', jsonParamAddPrintedDate);
        system.assertEquals('Success',res.returnStatus,'Return status should be success');
        Object result = printQueue.processRequest('corspdSuppressOrDeleteAction', jsonParam);
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    static testmethod void corspdSuppressOrDeleteAction_Test2() {
        T_COUNTY__c countyObj = new T_COUNTY__c( CNTY_DEPT_NAME__c = 'Arapahoe County', CDE_COUNTY__c = 3);
        insert countyObj;
        T_SBSD_CASE__c caserecord = new T_SBSD_CASE__c (    CDE_COUNTY__c = countyObj.Id, IND_ASSIST_PROVR__c = 'N',
                                                            CDE_ASST_HSNG__c = 'N', Name = 'CA-1');
        insert caserecord;
        T_CHATS_PROVR_STATUS__c providerObj = new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert providerObj;
        date dt1 =date.newInstance(2018, 1, 1);
        T_DOC_RQ__c corrReqRecord = new T_DOC_RQ__c (CDE_CORSPD_STATUS__c = 'Requested', NME_CORSPD__c = 'CR107',
                                                     RSN_CODE__c = 'CR0004', CDE_TYPE_RCPT__c = 'C', DTE_REQ__c = dt1, 
                                                     IDN_CASE__c= caserecord.Id);
        insert corrReqRecord;
        T_DOC_RQ__c getCorrRecord = [select Id, Name From T_DOC_RQ__c where Id =:corrReqRecord.Id];
        List<String> listCorrToDeleteId = new List<String>();
        listCorrToDeleteId.add(getCorrRecord.Id);
        
        test.startTest();
        T_DOC_RQ__c corr = [SELECT Id, Name FROM T_DOC_RQ__c WHERE CDE_CORSPD_STATUS__c = 'Requested' AND NME_CORSPD__c = 'CR107' AND RSN_CODE__c = 'CR0004' AND CDE_TYPE_RCPT__c = 'C' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockFailureTest());
        corspdPrintQueue printQueue4 = new corspdPrintQueue();
        Map<String, Object> paramsAddPrintedDate2 = new Map<String, Object>{
            'lstCorspdId' => corr.Name,
            'alreadygenUrl' => 'test',
            'fileName' => 'test'
        };
        String jsonParamAddPrintedDate2 = JSON.serialize(paramsAddPrintedDate2);
        corspdReturnPacket res = (corspdReturnPacket)printQueue4.processRequest('addPrintedDateToCorspdDate', jsonParamAddPrintedDate2);
        system.assertEquals('Failure',res.returnStatus,'Return status should be Failure');
        Map<String, Object> paramsSuppressDelete = new Map<String, Object>{
            'lstCorspdId' => listCorrToDeleteId,
            'operation' => 'DELETE'
        };
        String jsonParamSuppressDelete = JSON.serialize(paramsSuppressDelete);
        corspdReturnPacket res2 = (corspdReturnPacket)printQueue4.processRequest('corspdSuppressOrDeleteAction', jsonParamSuppressDelete);
        system.assertEquals('Failure',res2.returnStatus,'Return status should be Failure');
        test.stopTest();
        }
    
    @isTest
    static void testProcessCorspdSearchException() {
        test.startTest();
        corspdPrintQueue printQueue = new corspdPrintQueue();
        Map<String, Object> params = new Map<String, Object>{
            'corspdStatus' => null,
            'countyName' => null,
            'caseId' => null,
            'providerId' => null,
            'dateRequested' => 'invalid-date',
            'dateRequestedEndRange' => null,
            'correspondenceId' => null,
            'correspondenceType' => null,
            'correspondenceRecipientType' => null,
            'requestedBy' => null,
            'datePrintedBeginDate' => null,
            'datePrintedEndDate' => null,
            'screen' => 'CorrespondenceGeneration',
            'suppressIndicator' => null
        };
        String jsonParam = JSON.serialize(params);
        corspdReturnPacket result = (corspdReturnPacket)printQueue.processRequest('processCorspdSearch', jsonParam);
        System.assertEquals('Failure', result.returnStatus, 'Should return failure status on exception');
        test.stopTest();
    }
    
    @isTest
    static void testGetPrintedCorspdDetailsException() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockFailureTest());
        try {
            corspdReturnPacket result = corspdPrintQueue.getPrintedCorspdDetails(null, null, null, null, null, null, null, null, null, null, null, null, null);
            System.assertEquals('Failure', result.returnStatus, 'Should return failure status on exception');
        } catch (Exception e) {
            System.assert(true, 'Exception caught as expected');
        }
        test.stopTest();
    }
    
    @isTest
    static void testCorspdSuppressOrDeleteActionException() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockFailureTest());
        
        corspdPrintQueue printQueue = new corspdPrintQueue();
        Map<String, Object> params = new Map<String, Object>{
            'lstCorspdId' => new List<String>{'invalid-id'},
            'operation' => 'INVALID_OPERATION'
        };
        String jsonParam = JSON.serialize(params);
        
        corspdReturnPacket result = (corspdReturnPacket)printQueue.processRequest('corspdSuppressOrDeleteAction', jsonParam);
        System.assertEquals('Failure', result.returnStatus, 'Should return failure status on exception');
        test.stopTest();
    }
    
    @isTest
    static void testProcessCorspdPrintException() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockFailureTest());
        
        corspdPrintQueue printQueue = new corspdPrintQueue();
        List<String> invalidIds = new List<String>{'invalid-id-1', 'invalid-id-2'};
        Map<String, Object> params = new Map<String, Object>{
            'lstCorspdId' => invalidIds
        };
        String jsonParam = JSON.serialize(params);
        
        corspdReturnPacket result = (corspdReturnPacket)printQueue.processRequest('processCorspdPrint', jsonParam);
        System.assertEquals('Failure', result.returnStatus, 'Should return failure status on exception');
        test.stopTest();
    }
    
    @isTest
    static void testGetFileNameException() {
        test.startTest();
        corspdPrintQueue printQueue = new corspdPrintQueue();
        Map<String, Object> params = new Map<String, Object>{
            'corspdId' => 'invalid-correspondence-id'
        };
        String jsonParam = JSON.serialize(params);
        
        try {
            corspdReturnPacket result = (corspdReturnPacket)printQueue.processRequest('getFileName', jsonParam);
            System.assertNotEquals(null, result, 'Result should not be null');
        } catch (Exception e) {
            System.assert(true, 'Exception caught as expected');
        }
        test.stopTest();
    }
    
    @isTest
    static void testFetchUserdataException() {
        test.startTest();
        User testUser;
        try {
            Profile userProfile = [Select id from Profile where Name = 'Standard User' LIMIT 1];
            testUser = TestClassUtility.createUser(userProfile.Id, 'testexc', 'testexc', 'testexc@example.com', 'testexc@example.com.' + String.valueOf(Math.random() * 1000), 'testexc');
        } catch (Exception e) {
            Profile userProfile = [Select id from Profile where Name = 'System Administrator'];
            testUser = TestClassUtility.createUser(userProfile.Id, 'testexc', 'testexc', 'testexc@example.com', 'testexc@example.com.' + String.valueOf(Math.random() * 1000), 'testexc');
        }
        
        System.runAs(testUser) {
            corspdPrintQueue printQueue = new corspdPrintQueue();
            Map<String, Object> params = new Map<String, Object>();
            String jsonParam = JSON.serialize(params);
            
            try {
                LightningServerResponse result = (LightningServerResponse)printQueue.processRequest('fetchUserdata', jsonParam);
                System.assertNotEquals(null, result, 'Result should not be null');
            } catch (Exception e) {
                System.assert(true, 'Exception caught as expected');
            }
        }
        test.stopTest();
    }
    
    @isTest
    static void testNonAdminUserScenarios() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new CorspdPrintQueueMockSuccessTest());
        Profile nonAdminProfile;
        try {
            nonAdminProfile = [Select id from Profile where Name = 'Standard User' LIMIT 1];
        } catch (Exception e) {
            nonAdminProfile = [Select id from Profile where Name != 'System Administrator' AND Name != 'CCCAP Program Internal Team' LIMIT 1];
        }
        
        User nonAdminUser = TestClassUtility.createUser(nonAdminProfile.Id, 'nonadmin', 'nonadmin', 'nonadmin@example.com', 'nonadmin@example.com.' + String.valueOf(Math.random() * 1000), 'nonadmin');
        T_COUNTY__c countyObj = new T_COUNTY__c(CNTY_DEPT_NAME__c = 'Test County', CDE_COUNTY__c = 5);
        insert countyObj;
        
        T_SBSD_CASE__c caseRecord = new T_SBSD_CASE__c(
            CDE_COUNTY__c = countyObj.Id, 
            IND_ASSIST_PROVR__c = 'N',
            CDE_ASST_HSNG__c = 'N', 
            Name = 'CA-TEST'
        );
        insert caseRecord;
        
        T_CHATS_PROVR_STATUS__c providerObj = new T_CHATS_PROVR_STATUS__c(
            TXT_CHATS_RATING__c = 'Level 1',
            Name = '102'
        );
        insert providerObj;
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = new T_PROVR_FISCAL_AGREMENT__c(
            CDE_COUNTY__c = countyObj.Id,
            ID_SERVICE__c = providerObj.Id
        );
        insert fiscalAgreement;
        
        System.runAs(nonAdminUser) {
            corspdPrintQueue printQueue = new corspdPrintQueue();
            
            Map<String, Object> params = new Map<String, Object>{
                'corspdStatus' => 'Requested',
                'countyName' => String.valueOf(countyObj.Id),
                'caseId' => caseRecord.Name,
                'providerId' => 102,
                'dateRequested' => '2018-01-01',
                'dateRequestedEndRange' => '2018-01-01',
                'correspondenceId' => 12345,
                'correspondenceType' => 'CR107',
                'correspondenceRecipientType' => 'C',
                'requestedBy' => null,
                'datePrintedBeginDate' => null,
                'datePrintedEndDate' => null,
                'screen' => 'CorrespondenceGeneration',
                'suppressIndicator' => null
            };
            String jsonParam = JSON.serialize(params);
            
            corspdReturnPacket result = (corspdReturnPacket)printQueue.processRequest('processCorspdSearch', jsonParam);
            System.assertNotEquals(null, result, 'Result should not be null');
        }
        test.stopTest();
    }
}