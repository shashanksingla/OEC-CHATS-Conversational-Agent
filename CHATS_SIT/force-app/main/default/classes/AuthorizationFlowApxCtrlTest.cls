@isTest
public class AuthorizationFlowApxCtrlTest {
    
    public static final String OPEN = 'OPN';
    public static final String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();

    class MockCareLevel extends QueryExternalObjects {
        final List<batchsit_t_sbsd_indiv_care_level__x> externalRecords;
        MockCareLevel(List<batchsit_t_sbsd_indiv_care_level__x> externalRecords) {
            this.externalRecords = externalRecords;
        }
        protected override List<SObject> passThrough(List<SObject> records) {
            return externalRecords;
        }
    }
    
    static testMethod void isCaseEligibletestScenario1() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        T_CHATS_PROVR_STATUS__c provider1= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 3');
        insert provider1;
        
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(false,county.Id);
        T_SBSD_CASE_WTLST__c waitlist= new T_SBSD_CASE_WTLST__c(CDE_STATUS_WTLST__c ='RFS',IDN_CASE__c=sbsdcase.Id,DTE_BEGIN_EFFV_WTLST__c=System.Today(),DTE_END_EFFV_WTLST__c =System.Today());
        insert waitlist;
        
        Date datetoday=System.Today();
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today().addYears(4);
        sbsdcase.IDN_EXTNL__c='12345';
        upsert sbsdcase;
        
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        begindate = begindate.addDays(25);
        //Removed unused variable on 5/13/2018 BG        
        Date enddate = begindate.addDays(20);
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c=sbsdcase.Id;
        authorization.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization.CDE_TYPE_VERIF__c = 'NA';
        authorization.CDE_SOURCE_VRFYD_IMMU__c ='PRO';
        authorization.CDE_IMM__c ='NRL';
        insert authorization;

        T_SBSD_CASE_INDIV__c caseIndiv = new T_SBSD_CASE_INDIV__c(IDN_CASE__c=sbsdcase.Id,IDN_CLIENT__c=sbsdIndiv.Id, DTE_BEGIN_EFFV__c = System.today()-5);
        insert caseIndiv;  
        
        T_AUTH__c authorization1=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider1.Id);
        authorization1.IDN_CASE__c=sbsdcase.Id;
        authorization1.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization1.CDE_TYPE_VERIF__c = 'SD';
        authorization.CDE_SOURCE_VRFYD_IMMU__c ='PRO';
        authorization.CDE_IMM__c ='NRL';
        insert authorization1;
        AuthorizationFlowApxCtrl ctrl = new AuthorizationFlowApxCtrl();
        Test.startTest();
        AuthorizationFlowApxCtrl.getAuthorizationNotesStatusValidation(authorization.Id,authorization1);
        String params = JSON.serialize(new Map<String, Object>{ 'caseRecId' => sbsdcase.Id, 'individualRecId' => sbsdIndiv.id, 'providerId' => provider.Id, 'newAuthorizations'=> authorization1});
        ctrl.processRequest('isCaseEligible', params);
        //LightningServerResponse lightserresobj1= AuthorizationFlowApxCtrl.isCaseEligible(sbsdcase.Id,sbsdIndiv.Id,authorization1);
        Test.stopTest();
    }
    
    static testMethod void isCaseEligibletestScenario2() {
        T_COUNTY__c county= TestClassUtility.createCounty('Test Name','Department',2,true);
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(true,county.Id);
        T_SBSD_CASE_WTLST__c waitlist= new T_SBSD_CASE_WTLST__c(CDE_STATUS_WTLST__c ='WLT',CDE_REASON_REMOVAL__c='ATP',IDN_CASE__c=sbsdcase.Id,DTE_BEGIN_EFFV_WTLST__c=System.Today()-1,DTE_END_EFFV_WTLST__c =System.Today()+1);
        insert waitlist;
        
        T_Auth__c newAuthorizations = new T_Auth__c();
        LightningServerResponse lightserresobj= AuthorizationFlowApxCtrl.isCaseEligible(sbsdcase.Id,'',newAuthorizations);
        system.assertEquals(false,lightserresobj.isSuccessful);
    }
    
    static testMethod void isIndividualEligibleTest() {
        T_COUNTY__c county= TestClassUtility.createCounty('Test Name','Department',2,true);
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(false,county.Id);
        sbsdcase.IDN_EXTNL__c='12345';
        upsert sbsdcase;
        
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        begindate = begindate.addDays(25);
        String begDate = String.valueOf(begindate);
        Date enddate = begindate.addDays(20);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1', CDE_TYPE_PROVR__c='CCC');
        insert provider;
        
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.today().addYears(-1),'firstName','1','lastName','1','CC');
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c=sbsdcase.Id;
        authorization.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization.IDN_EXTNL__c='123';
        authorization.AMT_ACTV_AUTH__c =1;
        authorization.AMT_TRANSP_AUTH__c =11;
        insert authorization;
        List<T_Auth__c> newAuthorizations = new List<T_Auth__c>();
        newAuthorizations.add(authorization);
        List<Auth_Schedule_Recurrence__c> authRecurrList = new List<Auth_Schedule_Recurrence__c>();
        Auth_Schedule_Recurrence__c recurr = new Auth_Schedule_Recurrence__c();
        recurr.IDN_AUTH__c=authorization.Id;
        recurr.DTE_Begin_Date__c = system.today().addDays(25);
        recurr.DTE_End_Date__c = system.today().addDays(10);
        recurr.Recur_Type__c ='Daily/Weekly';
        recurr.Mon__c =true;
        recurr.Tue__c =true;
        recurr.DaysOfMonth__c = '5';
        Auth_Schedule_Recurrence__c recurr2 = new Auth_Schedule_Recurrence__c();
        recurr2.IDN_AUTH__c=authorization.Id;
        recurr2.DTE_Begin_Date__c = system.today().addDays(11);
        recurr2.DTE_End_Date__c = system.today().addDays(25);
        recurr2.Recur_Type__c ='Daily/Weekly';
        recurr2.Mon__c =true;
        recurr2.Tue__c =true;
        recurr2.DaysOfMonth__c = '5';
        Auth_Schedule_Recurrence__c recurr3 = new Auth_Schedule_Recurrence__c();
        recurr3.IDN_AUTH__c=authorization.Id;
        recurr3.DTE_Begin_Date__c = system.today().addDays(26);
        recurr3.DTE_End_Date__c = system.today().addDays(40);
        recurr3.Recur_Type__c ='Every Other Week';
        recurr3.Mon__c =true;
        recurr3.Tue__c =true;
        recurr3.DaysOfMonth__c = '5';
        Auth_Schedule_Recurrence__c recurr4 = new Auth_Schedule_Recurrence__c();
        recurr4.IDN_AUTH__c=authorization.Id;
        recurr4.DTE_Begin_Date__c = system.today().addDays(41);
        recurr4.DTE_End_Date__c = system.today().addDays(60);
        recurr4.Recur_Type__c ='Monthly';
        recurr4.RecurDay__c =1;
        recurr4.DaysOfMonth__c = '5';
        authRecurrList.add(recurr);
        authRecurrList.add(recurr2);
        authRecurrList.add(recurr3);
        authRecurrList.add(recurr4);
        insert authRecurrList;
        T_SBSD_CASE_WTLST__c waitlist= new T_SBSD_CASE_WTLST__c(CDE_STATUS_WTLST__c ='RFS',IDN_CASE__c=sbsdcase.Id,DTE_BEGIN_EFFV_WTLST__c=System.Today(),DTE_END_EFFV_WTLST__c =System.Today());
        insert waitlist;
        
        batchsit_t_eligty_run__x elgtyRun= new batchsit_t_eligty_run__x(IDN_CASE__c=sbsdcase.Id,CDE_ELIGTY_CFMD__c='CFM',DTE_RUN_ELIGTY__c=System.Today());
        Database.insertAsync(elgtyRun);
        
        T_SBSD_CASE_INDIV__c caseIndiv = new T_SBSD_CASE_INDIV__c(IDN_CASE__c=sbsdcase.Id,IDN_CLIENT__c=sbsdIndiv.Id, DTE_BEGIN_EFFV__c = System.today()-5);
        insert caseIndiv;
        
        batchsit_t_fcompsn_eligty__x householdelgty= new batchsit_t_fcompsn_eligty__x(IDN_RUN_ELIGTY__c=elgtyRun.Id);
        Database.insertAsync(householdelgty);
        String hoursPerWeekDayStr = '';
        String hoursPerWeekDayRecurrStr = '';
        List<batchsit_t_auth_encmbr__x> encumbList1 = new List<batchsit_t_auth_encmbr__x>();
        batchsit_t_fcompsn_indiv_eligty__x fcompsnIndivEligtyRec= new batchsit_t_fcompsn_indiv_eligty__x (IDN_CASE_INDIV__c=caseIndiv.Id,IDN_ELIGTY_FCOMPSN__c=householdelgty.Id);
        Database.insertAsync(fcompsnIndivEligtyRec);
        
        //Removed unused variable on 5/13/2018 BG         
        batchsit_t_auth_encmbr__x encumberenceRec = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='8',
            CNT_HOUR_CARE__c =6,
            cnt_hour_attnd_actual__c = 10,
            dte_care__c =system.today().addDays(40),
            CDE_TYPE_UNIT_CARE__c ='4',
            cde_status_encmbr__c = 'Tes');
        batchsit_t_auth_encmbr__x encumberenceRec2 = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='8',
            CNT_HOUR_CARE__c =7,
            cnt_hour_attnd_actual__c = 10,
            dte_care__c =system.today().addDays(38),
            CDE_TYPE_UNIT_CARE__c='3',
            cde_status_encmbr__c = 'Tes');
        batchsit_t_auth_encmbr__x encumberenceRec1 = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='8',
            CNT_HOUR_CARE__c =6,
            CDE_TYPE_UNIT_CARE__c = '6',
            cnt_hour_attnd_actual__c = 10,
            dte_care__c =system.today().addDays(30),
            cde_status_encmbr__c = 'Tes');
        batchsit_t_auth_encmbr__x encumberenceRec3 = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='8',
            CNT_HOUR_CARE__c =6,
            cnt_hour_attnd_actual__c = 10,
            CDE_TYPE_UNIT_CARE__c ='12',
            dte_care__c =system.today().addDays(31),
            cde_status_encmbr__c = 'Tes');
        batchsit_t_auth_encmbr__x encumberenceRec4 = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='6',
            CNT_HOUR_CARE__c =8,
            cnt_hour_attnd_actual__c = 10,
            CDE_TYPE_UNIT_CARE__c = '2',
            dte_care__c =system.today().addDays(32),
            cde_status_encmbr__c = 'Tes');
        batchsit_t_auth_encmbr__x encumberenceRec5 = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='9',
            CNT_HOUR_CARE__c =7,
            cnt_hour_attnd_actual__c = 10,
            CDE_TYPE_UNIT_CARE__c = '1',
            dte_care__c =system.today().addDays(33),
            cde_status_encmbr__c = 'Tes');
        batchsit_t_auth_encmbr__x encumberenceRec6 = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='21',
            CNT_HOUR_CARE__c =4,
            cnt_hour_attnd_actual__c = 10,
            CDE_TYPE_UNIT_CARE__c = '11',
            dte_care__c =system.today().addDays(34),
            cde_status_encmbr__c = 'Tes');
        batchsit_t_auth_encmbr__x encumberenceRec7 = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='21',
            CNT_HOUR_CARE__c =4,
            cnt_hour_attnd_actual__c = 10,
            CDE_TYPE_UNIT_CARE__c ='10',
            dte_care__c =system.today().addDays(35),
            cde_status_encmbr__c = 'Tes');
        batchsit_t_auth_encmbr__x encumberenceRec8 = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='2',
            CNT_HOUR_CARE__c =5,
            cnt_hour_attnd_actual__c = 10,
            CDE_TYPE_UNIT_CARE__c = '12',
            dte_care__c =system.today().addDays(36),
            cde_status_encmbr__c = 'Tes');
        batchsit_t_auth_encmbr__x encumberenceRec9 = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='12',
            CNT_HOUR_CARE__c =1,
            cnt_hour_attnd_actual__c = 10,
            dte_care__c =system.today().addDays(37),
            CDE_TYPE_UNIT_CARE__c ='12',
            cde_status_encmbr__c = 'Tes');
        encumbList1.add(encumberenceRec);
        encumbList1.add(encumberenceRec1);
        encumbList1.add(encumberenceRec2);
        encumbList1.add(encumberenceRec3);
        encumbList1.add(encumberenceRec4);
        encumbList1.add(encumberenceRec5);
        encumbList1.add(encumberenceRec6);
        encumbList1.add(encumberenceRec7);
        encumbList1.add(encumberenceRec8);
        encumbList1.add(encumberenceRec9);
        List<batchsit_t_auth_encmbr__x> encumbList = new List<batchsit_t_auth_encmbr__x>();
        encumbList.add(encumberenceRec);
        hoursPerWeekDayStr = JSON.serialize(encumbList1);
        hoursPerWeekDayRecurrStr = JSON.serialize(authRecurrList);
        batchsit_t_indiv_eligty_detail__x indivEligtyDetailRec= new batchsit_t_indiv_eligty_detail__x(IDN_INDIV_FCOMPSN__c=fcompsnIndivEligtyRec.Id,CDE_STATUS_DETAIL_ELIGTY_INDIV__c='IC');
        Database.insertAsync(indivEligtyDetailRec);
        batchsit_t_auth_status__x stat = new batchsit_t_auth_status__x(idn_auth__c = authorization.Id,cde_status_auth__c ='2');
        LightningServerResponse lightserresobj= AuthorizationFlowApxCtrl.isIndividualEligible(sbsdcase.Id,sbsdIndiv.Id, sbsdcase.IDN_EXTNL__c,authorization);
        String todayDate = String.valueOf(System.today());

        Date firstDayOfNextMonth = date.newInstance(datetoday.year(),datetoday.month()+1,1);
        Date nullDate;
        T_COUNTY_RATE__c crp = new T_COUNTY_RATE__c(PAYMENT_Q11_2__c = 'ALL', PAYMENT_Q11_3__c = 'Y', 
                                                    DTE_BEGIN_EFFV_RATE__c = firstDayOfNextMonth, DTE_END_EFFV_RATE__c = null, 
                                                    CDE_STATUS__c = 'APV',CFS_Q1__c='Y',CFS_Q1_2__c=0, IDN_COUNTY__c = county.Id, IND_RATE_PLAN_TEMPLT__c = false);
        insert crp;
        
        T_PROVR_CLOSURE__c provClosure = new T_PROVR_CLOSURE__c(IDN_PROVIDER__c=provider.Id, CDE_COUNTY__c = county.Id,IND_ACTIVE__c = true,DTE_BEGIN_CLOSURE__c=firstDayOfNextMonth);
        insert provClosure;
        
        T_SLOT_CONTRACT_ADDENDUM__c scAdd = new T_SLOT_CONTRACT_ADDENDUM__c();
        scAdd.CDE_COUNTY__c = county.Id;
        Insert scAdd;
        
        T_SLOT_CONTRACT__c sc = new T_SLOT_CONTRACT__c();
        sc.IDN_AUTH__c = authorization.Id;
        sc.CDE_COUNTY__c = county.Id;
        sc.IDN_PROVIDER__c = provider.Id;
        sc.IDN_ADDENDUM__c = scAdd.Id;
        sc.DTE_END_SLOT__c = enddate.addDays(1);
        sc.DTE_BEGIN_SLOT__c = begindate;
        sc.IND_AVAILABLE__c = true;
        Insert sc;
        AuthorizationFlowApxCtrl ctrl = new AuthorizationFlowApxCtrl();
        String params = JSON.serialize(new Map<String, Object>{ 'authId' => authorization.Id, 'isCreate' => false, 'providerId' => provider.Id, 'beginDate'=> '', 'clientId'=>sbsdIndiv.Id });
        ctrl.processRequest('getRateTypeOptions', params);
        //AuthorizationFlowApxCtrl.getRateTypeOptions(authorization.Id,false, provider.Id,'',sbsdIndiv.Id);
        params = JSON.serialize(new Map<String, Object>{'recordId' => sbsdcase.Id});
        ctrl.processRequest('getChildStateOptions', params);
        //AuthorizationFlowApxCtrl.getChildStateOptions(sbsdcase.Id);
        params = JSON.serialize(new Map<String, Object>{'providerId' => provider.Id, 'beginDate'=> begDate, 'caseObj'=> sbsdcase});
        ctrl.processRequest('validateProviders', params);
        //AuthorizationFlowApxCtrl.validateProviders(provider.Id,begDate,sbsdcase);
        params = JSON.serialize(new Map<String, Object>{'authRecId' => authorization.Id, 'hoursPerWeekDayStr'=> hoursPerWeekDayStr, 'hoursPerWeekDayRecurrStr'=> hoursPerWeekDayRecurrStr});
        ctrl.processRequest('createAuthEncmbrRecords', params);
        //AuthorizationFlowApxCtrl.createAuthEncmbrRecords(authorization.Id,hoursPerWeekDayStr,hoursPerWeekDayRecurrStr);
        params = JSON.serialize(new Map<String, Object>{'authRecId' => authorization.Id, 'hoursPerWeekDayStr'=> hoursPerWeekDayStr, 'hoursPerWeekDayRecurrStr'=> null});
        ctrl.processRequest('createAuthEncmbrRecords', params);
        //AuthorizationFlowApxCtrl.createAuthEncmbrRecords(authorization.Id,hoursPerWeekDayStr,null);
        params = JSON.serialize(new Map<String, Object>{'recordId' => authorization.Id});
        ctrl.processRequest('getScheduleRecurrences', params);
        params = JSON.serialize(new Map<String, Object>{'recordId' => authorization.Id});
        ctrl.processRequest('trackProviderRecordView', params);
        //AuthorizationFlowApxCtrl.getScheduleRecurrences(authorization.Id);
        AuthorizationFlowApxCtrl.getEncumberenceWrapper(encumberenceRec);
        params = JSON.serialize(new Map<String, Object>{'authRecId' => authorization.Id, 'hoursPerWeekDayStr'=>hoursPerWeekDayStr, 'isUpdate'=> false, 'hoursPerWeekDayRecurrStr'=>hoursPerWeekDayRecurrStr, 'currentMode'=> 'case'});
        ctrl.processRequest('updateAuthEncmbrRecordsBasedOnPatterns', params);
        //AuthorizationFlowApxCtrl.updateAuthEncmbrRecordsBasedOnPatterns(authorization.Id,hoursPerWeekDayStr,false,hoursPerWeekDayRecurrStr,'case');
        //AuthorizationFlowApxCtrl.updateAuthEncmbrRecordsBasedOnPatterns(authorization.Id,hoursPerWeekDayStr,true,hoursPerWeekDayRecurrStr,'case');
        params = JSON.serialize(new Map<String, Object>{'authRecId' => authorization.Id, 'hoursPerWeekDayStr'=>hoursPerWeekDayStr, 'isUpdate'=> true, 'hoursPerWeekDayRecurrStr'=>hoursPerWeekDayRecurrStr, 'currentMode'=> 'case'});
        ctrl.processRequest('updateAuthEncmbrRecordsBasedOnPatterns', params);
        params = JSON.serialize(new Map<String, Object>{'authId' => authorization.Id, 'authNew'=>authorization});
        ctrl.processRequest('getAuthorizationNotesStatusValidation', params);
        //AuthorizationFlowApxCtrl.getAuthorizationNotesStatusValidation(authorization.Id,authorization);
        AuthorizationFlowApxCtrl.encumbJsonString(encumbList);
        params = JSON.serialize(new Map<String, Object>{'recordId' => authorization.Id, 'fieldName'=>'CDE_COUNTY__c'});
        ctrl.processRequest('checkOwnerCountyMatch', params);
        //AuthorizationFlowApxCtrl.checkOwnerCountyMatch(authorization.Id,'CDE_COUNTY__c');
        //AuthorizationFlowApxCtrl.upsertAuthStatus(stat,true);
        params = JSON.serialize(new Map<String, Object>{'authStatus' => stat, 'isNew'=>true});
        ctrl.processRequest('upsertAuthStatus', params);
        AuthorizationFlowApxCtrl.getAuthEncmbrRecords(authorization.Id);
        //AuthorizationFlowApxCtrl.deleteSchedule(authRecurrList[0].Id);
        params = JSON.serialize(new Map<String, Object>{'recordId' => authRecurrList[0].Id});
        ctrl.processRequest('deleteSchedule', params);
        //AuthorizationFlowApxCtrl.getSelectedScheduleRecurrence(authRecurrList[1].Id);
        params = JSON.serialize(new Map<String, Object>{'recordId' => authRecurrList[1].Id});
        ctrl.processRequest('getSelectedScheduleRecurrence', params);
        // AuthorizationFlowApxCtrl.getAuthorizationNotesStatusValidation(stat, true);
        //AuthorizationFlowApxCtrl.disabilityCheck(provider.Id, begDate);        
        params = JSON.serialize(new Map<String, Object>{ 'individualRecId' => provider.Id, 'currentBeginDate' => begDate });
        ctrl.processRequest('disabilityCheck', params);
       // AuthorizationFlowApxCtrl.createAuthEncmbrRecurrRecords((String)authorization.Id, hoursPerWeekDayStr, authRecurrList);
        String hoursPerWeekDay = '[{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"0"},{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"8"},{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"8"},{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"8"},{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"8"},{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"8"},{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"0"}]';
        //AuthorizationFlowApxCtrl.careLevelOfferedByProvider(authorization.Id, authorization.Id, begDate, provider.Id, sbsdIndiv.Id, hoursPerWeekDay);
        params = JSON.serialize(new Map<String, Object>{'authId' => authorization.Id, 'recordId'=>authorization.Id, 'currentBeginDate'=>begDate, 'currentProviderId'=>provider.Id,
            'currentClientId'=> sbsdIndiv.Id, 'hoursPerWeekDayStr'=>hoursPerWeekDay });
        ctrl.processRequest('careLevelOfferedByProvider', params);
        params = JSON.serialize(new Map<String, Object>{'clientId' => sbsdIndiv.Id, 'providerId'=> provider.id});
        ctrl.processRequest('getLatestUPKInfo', params);
        params = JSON.serialize(new Map<String, Object>{'clientId' => sbsdIndiv.Id});
        ctrl.processRequest('getClientDetails', params);
        params = JSON.serialize(new Map<String, Object>{'authId' => authorization.Id});
        ctrl.processRequest('CR215CorrBulk', params);
        params = JSON.serialize(new Map<String, Object>{'authId' => authorization.Id});
        ctrl.processRequest('getLatestAuthDetails', params);
        AuthorizationFlowApxCtrl.createCR215CorrespondenceInvocable(new List<Id>{authorization.Id});
        //AuthorizationFlowApxCtrl.fetchSCAssociations(sc.Id,provider.Id,sbsdcase, authorization.DTE_BEGIN_EFFV_AUTH__c);
        params = JSON.serialize(new Map<String, Object>{'SCId' => sc.Id, 'providerId'=> provider.Id, 'caseObj'=> sbsdcase, 'authBeginDate'=> authorization.DTE_BEGIN_EFFV_AUTH__c});
        ctrl.processRequest('fetchSCAssociations', params);
        //AuthorizationFlowApxCtrl.fetchProviderClosureRecs((String)provider.Id, (String)county.Id);
        params = JSON.serialize(new Map<String, Object>{'provRecId' => (String)provider.Id, 'countyId'=>(String)county.Id});
        ctrl.processRequest('fetchProviderClosureRecs', params);
        //AuthorizationFlowApxCtrl.queryPopulateSCAssRecord(sc.Id);
        params = JSON.serialize(new Map<String, Object>{'scAssId' => sc.Id});
        ctrl.processRequest('queryPopulateSCAssRecord', params);
        params = JSON.serialize(new Map<String, Object>{ 'recordId' => sbsdcase.id});
        ctrl.processRequest('checkChildProgram', params);
        system.assertEquals(false,lightserresobj.isSuccessful);
    }
    
    static testMethod void isFinishTest() {
        T_COUNTY__c county= TestClassUtility.createCounty('Test Name','Department',2,true);
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(false,county.Id);
        sbsdcase.IDN_EXTNL__c='12345';
        upsert sbsdcase;
        
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        begindate = begindate.addDays(25);
        //Removed unused variable on 5/13/2018 BG        
        Date enddate = begindate.addDays(20);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c=sbsdcase.Id;
        authorization.IDN_CLIENT__c=sbsdIndiv.Id;
        insert authorization;
        
        List<T_Auth__c> newAuthorizations = new List<T_Auth__c>();
        newAuthorizations.add(authorization);
        T_SBSD_CASE_WTLST__c waitlist= new T_SBSD_CASE_WTLST__c(CDE_STATUS_WTLST__c ='RFS',IDN_CASE__c=sbsdcase.Id,DTE_BEGIN_EFFV_WTLST__c=System.Today(),DTE_END_EFFV_WTLST__c =System.Today());
        insert waitlist;
        
        batchsit_t_eligty_run__x elgtyRun= new batchsit_t_eligty_run__x(IDN_CASE__c=sbsdcase.Id,CDE_ELIGTY_CFMD__c='CFM',DTE_RUN_ELIGTY__c=System.Today());
        Database.insertAsync(elgtyRun);
        
        T_SBSD_CASE_INDIV__c caseIndiv = new T_SBSD_CASE_INDIV__c(IDN_CASE__c=sbsdcase.Id,IDN_CLIENT__c=sbsdIndiv.Id, DTE_BEGIN_EFFV__c = System.today()-5);
        insert caseIndiv;
        
        //Removed unused variable on 5/13/2018 BG  
        batchsit_t_fcompsn_eligty__x householdelgty= new batchsit_t_fcompsn_eligty__x(IDN_RUN_ELIGTY__c=elgtyRun.Id);
        Database.insertAsync(householdelgty);
        String hoursPerWeekDayStr = '';
        batchsit_t_fcompsn_indiv_eligty__x fcompsnIndivEligtyRec= new batchsit_t_fcompsn_indiv_eligty__x (IDN_CASE_INDIV__c=caseIndiv.Id,IDN_ELIGTY_FCOMPSN__c=householdelgty.Id);
        Database.insertAsync(fcompsnIndivEligtyRec);
        
        //Removed unused variable on 5/13/2018 BG         
        batchsit_t_auth_encmbr__x encumberenceRec = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='8',
            cnt_hour_attnd_actual__c = 10,
            cde_status_encmbr__c = 'Tes');
        List<batchsit_t_auth_encmbr__x> encumbList = new List<batchsit_t_auth_encmbr__x>();
        encumbList.add(encumberenceRec);
        batchsit_t_indiv_eligty_detail__x indivEligtyDetailRec= new batchsit_t_indiv_eligty_detail__x(IDN_INDIV_FCOMPSN__c=fcompsnIndivEligtyRec.Id,CDE_STATUS_DETAIL_ELIGTY_INDIV__c='IC');
        Database.insertAsync(indivEligtyDetailRec);
        
        batchsit_t_auth_status__x stat = new batchsit_t_auth_status__x(idn_auth__c = authorization.Id,cde_status_auth__c ='2');
        AuthorizationFlowApxCtrl ctrl = new AuthorizationFlowApxCtrl();
        String params = JSON.serialize(new Map<String, Object>{ 'authId' =>authorization.Id});
        ctrl.processRequest('finishAuthorization', params);
        //AuthorizationFlowApxCtrl.finishAuthorization(authorization.Id);
        params = JSON.serialize(new Map<String, Object>{ 'lstAuthEncumbRec' =>encumbList});
        ctrl.processRequest('callUpdate', params);
        //AuthorizationFlowApxCtrl.callUpdate(encumbList);
        AuthorizationFlowApxCtrl.getRateTypeOptions(sbsdcase.Id,true, provider.Id,'04-06-2018',sbsdIndiv.Id);
        system.assertEquals('2',stat.cde_status_auth__c,'Auth status should be Authorized'); 
        //AuthorizationFlowApxCtrl.setAuthorizationFlag(authorization.Id,true, false, false);
        params = JSON.serialize(new Map<String, Object>{'authId'=>authorization.Id, 'isCreate'=>true,'isCreateCorrp'=> false, 'createTaskT122'=>false });
        ctrl.processRequest('setAuthorizationFlag', params);
        AuthorizationFlowApxCtrl.setAuthorizationFlag(authorization.Id, false, false, false);
        AuthorizationFlowApxCtrl.deleteAuthorizationRecord(authorization.Id);
        List<batchsit_t_sbsd_indiv_care_level__x> careLevelList = new List<batchsit_t_sbsd_indiv_care_level__x>();
        batchsit_t_sbsd_indiv_care_level__x careLevel = new batchsit_t_sbsd_indiv_care_level__x();
        careLevel.cde_level_care__c = '8';
        careLevel.idn_client__c = sbsdIndiv.Id;
        careLevel.dte_begin_effv__c = begindate.addDays(1);
        careLevelList.add(careLevel);
        QueryExternalObjects.setMock(new MockCareLevel(careLevelList));
        //AuthorizationFlowApxCtrl ctrl = new AuthorizationFlowApxCtrl();
        params = JSON.serialize(new Map<String, Object>{ 'authBeginDate' =>String.valueOf(begindate), 'clientId'=>(String)sbsdIndiv.Id, 'hoursPerWeekDay'=>new List<batchsit_t_auth_encmbr__x>{encumberenceRec}});
        ctrl.processRequest('validateIfBelowSchoolAge', params);
        //LightningServerResponse res = AuthorizationFlowApxCtrl.validateIfBelowSchoolAge(String.valueOf(begindate), (String)sbsdIndiv.Id, new List<batchsit_t_auth_encmbr__x>{encumberenceRec});
        //System.assertEquals(true, res.isSuccessful);
        Try {
            AuthorizationFlowApxCtrl.validateIfBelowSchoolAge(null, null, new List<batchsit_t_auth_encmbr__x>());
        } catch (Exception ex){
            System.assertEquals('Argument cannot be null.', ex.getMessage());
        }
        Set<Date> provClosureDates = new Set<Date>{System.today()};
        Map<Date, String> dtVsStatus = new Map<Date, String>();
        dtVsStatus.put(System.today(), '2');
        Map<Date, String> dtVshour = new Map<Date, String>();
        dtVshour.put(System.today(), '8');
        Map<Date, String> dtVsauth = new Map<Date, String>();
        dtVsauth.put(System.today(), authorization.Id);
        AuthorizationFlowApxCtrl.insertAuthEncumSF(provClosureDates, dtVsStatus, dtVshour, dtVsauth);
    }
    
    static testMethod void testAuthProviderFA() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        provider.CDE_TYPE_PROVR__c = 'EFACH';
        insert provider;
        
        Date datetoday=System.Today();
        //Date begindate = date.newInstance(datetoday.year(),datetoday.month()+1,1);
        //Date enddate = begindate.addDays(20);
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today().addYears(4);
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(false,county.Id);
        sbsdcase.IDN_EXTNL__c='12345';
        upsert sbsdcase;
        
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        begindate = begindate.addDays(25);
        //Removed unused variable on 5/13/2018 BG        
        Date enddate = begindate.addDays(20);
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c=sbsdcase.Id;
        authorization.IDN_CLIENT__c=sbsdIndiv.Id;
        insert authorization;
        
        String dateStr = String.valueOf(begindate);
        
        Test.startTest();
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
        fiscalAgreement.RecordtypeId=openRecordTypeId;
        fiscalAgreement.CDE_TYPE_STATUS__c=OPEN;
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c=begindateOpn;
        insert fiscalAgreement;
        
        T_FISCAL_SCH__c fiscalRateSch = TestClassUtility.createRateSchedule(false,datetoday+10,null,fiscalAgreement.Id,'1');
        fiscalRateSch.TXT_CHATS_RATING__c ='Level 3';
        fiscalRateSch.DTE_BEGIN_EFFV__c = begindate;
        insert fiscalRateSch;
        
        AuthorizationFlowApxCtrl.finishAuthorization(authorization.Id);
        AuthorizationFlowApxCtrl.validateProviders(provider.Id,dateStr,sbsdcase);
        Test.stopTest();
    }
    
    static testMethod void testAuthorizationStatusValidation() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        T_CHATS_PROVR_STATUS__c provider1= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 3');
        insert provider1;
        
        Date datetoday=System.Today();
        //Date begindate = date.newInstance(datetoday.year(),datetoday.month()+1,1);
        //Date enddate = begindate.addDays(20);
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today().addYears(4);
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(false,county.Id);
        sbsdcase.IDN_EXTNL__c='12345';
        upsert sbsdcase;
        
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        begindate = begindate.addDays(25);
        //Removed unused variable on 5/13/2018 BG        
        Date enddate = begindate.addDays(20);
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c=sbsdcase.Id;
        authorization.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization.AMT_TRANSP_AUTH__c = 12;
        authorization.AMT_RGSTR_AUTH__c = 12;
        insert authorization;
        
        T_AUTH__c authorization1=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider1.Id);
        authorization1.IDN_CASE__c=sbsdcase.Id;
        authorization1.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization1.AMT_TRANSP_AUTH__c = 123;
        authorization1.AMT_RGSTR_AUTH__c = 123;
        insert authorization1;
        
        String dateStr = String.valueOf(begindate);
        Test.startTest();
        AuthorizationFlowApxCtrl.getAuthorizationNotesStatusValidation(authorization.Id,authorization1);
        Test.stopTest();
    }
    
    static testMethod void testAuthorizationStatusValidation1() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        T_CHATS_PROVR_STATUS__c provider1= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 3');
        insert provider1;
        
        Date datetoday=System.Today();
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today().addYears(4);
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(false,county.Id);
        sbsdcase.IDN_EXTNL__c='12345';
        upsert sbsdcase;
        
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        begindate = begindate.addDays(25);
        //Removed unused variable on 5/13/2018 BG        
        Date enddate = begindate.addDays(20);
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c=sbsdcase.Id;
        authorization.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization.AMT_RGSTR_AUTH__c = 12;
        insert authorization;
        
        T_AUTH__c authorization1=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider1.Id);
        authorization1.IDN_CASE__c=sbsdcase.Id;
        authorization1.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization1.AMT_RGSTR_AUTH__c = 123;
        insert authorization1;
        
        Test.startTest();
        AuthorizationFlowApxCtrl.getAuthorizationNotesStatusValidation(authorization.Id,authorization1);
        Test.stopTest();
    }
    
    static testMethod void testAuthorizationStatusValidation2() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        T_CHATS_PROVR_STATUS__c provider1= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 3');
        insert provider1;
        
        Date datetoday=System.Today();
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today().addYears(4);
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(false,county.Id);
        sbsdcase.IDN_EXTNL__c='12345';
        upsert sbsdcase;
        
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        begindate = begindate.addDays(25);
        //Removed unused variable on 5/13/2018 BG        
        Date enddate = begindate.addDays(20);
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c=sbsdcase.Id;
        authorization.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization.AMT_ACTV_AUTH__c = 12;
        insert authorization;
        
        T_AUTH__c authorization1=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider1.Id);
        authorization1.IDN_CASE__c=sbsdcase.Id;
        authorization1.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization1.AMT_ACTV_AUTH__c = 123;
        insert authorization1;
        
        Test.startTest();
        AuthorizationFlowApxCtrl.getAuthorizationNotesStatusValidation(authorization.Id,authorization1);
        Test.stopTest();
    }
    
    /*static testMethod void checkChildProgramTest(){
        //AuthorizationFlowApxCtrl ctrl = new AuthorizationFlowApxCtrl();
        Test.startTest();
        //String params = JSON.serialize(new Map<String, Object>{ 'recordId' => ''});
        //LightningServerResponse result = ctrl.processRequest('checkChildProgram', params);
        boolean result=AuthorizationFlowApxCtrl.checkChildProgram('');
        System.assertEquals(false, result);
        Test.stopTest();
    }*/
    
    static testMethod void checkCountyIndicatorTest(){
        T_COUNTY__c county=TestClassUtility.createCounty('TestCounty', 'TestCountyDeptt', 99, true);
        T_SBSD_CASE__c sbsdCase= TestClassUtility.createCase(false, county.id);
        insert sbsdCase;
        AuthorizationFlowApxCtrl ctrl = new AuthorizationFlowApxCtrl();
        Test.startTest();
        String jsonParam = JSON.serialize(new Map<String, Object>{ 'recordId' => sbsdCase.Id, 'beginDate' => '12-12-2012' });
        LightningServerResponse response = (LightningServerResponse) ctrl.processRequest('checkCountyIndicator', jsonParam);
        System.assertEquals(true, response.isSuccessful);
        //LightningServerResponse response=AuthorizationFlowApxCtrl.checkCountyIndicator(sbsdCase.Id,'12-12-2012');
        //System.assertEquals(true, response.isSuccessful);
        Test.stopTest();
    }
    
    static testMethod void getXlogTest(){
        Test.startTest();
        Exception_Log__c log=AuthorizationFlowApxCtrl.getXLog('TestMethod','TestExceptionMethod','TestType','TestRequest','TestResponse','Warning');
        System.assertEquals(log.Method__c, 'TestMethod');
        Test.stopTest();
    }
    
    static testMethod void transportationFeeLogicTest(){
        T_COUNTY__c county= TestClassUtility.createCounty('Test Name','Department',2,true);
        Date nullDate;
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        String begDate = String.valueOf(begindate);
        Date firstDayOfNextMonth = date.newInstance(datetoday.year(),datetoday.month()+1,1);
        String authBeginDate = firstDayOfNextMonth.year()+'-'+firstDayOfNextMonth.month()+'-'+(firstDayOfNextMonth.day());
        
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        T_COUNTY_RATE__c crp = new T_COUNTY_RATE__c(PAYMENT_Q11_2__c = 'ALL', PAYMENT_Q11_3__c = 'Y', 
                                                    DTE_BEGIN_EFFV_RATE__c = firstDayOfNextMonth, DTE_END_EFFV_RATE__c = nullDate, 
                                                    CDE_STATUS__c = 'APV', IDN_COUNTY__c = county.Id);
        insert crp;
        
        String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(false, 'FA1', firstDayOfNextMonth, county.Id);
        fiscalAgreement.RecordtypeId = openRecordTypeId;
        fiscalAgreement.CDE_TYPE_STATUS__c = OPEN;
        fiscalAgreement.ID_SERVICE__c = provider.Id;
        fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c = firstDayOfNextMonth;
        fiscalAgreement.DTE_END_AGRMT__c = nullDate;
        insert fiscalAgreement;
        
        T_FISCAL_SCH__c fiscalRateSch = TestClassUtility.createRateSchedule(false, firstDayOfNextMonth, null, fiscalAgreement.Id, '1');
        fiscalRateSch.DTE_END_EFFV__c = nullDate;
        fiscalRateSch.IDN_AGRMT_FISCAL__c = fiscalAgreement.Id;
        insert fiscalRateSch;
        
        T_FISCAL_RAT_FEES__c artFee = new T_FISCAL_RAT_FEES__c();
        artFee.IDN_FISCAL_SCH__c = fiscalRateSch.Id;
        artFee.AMT_TRANS_PROVR__c = 10;
        insert artFee;
        AuthorizationFlowApxCtrl ctrl = new AuthorizationFlowApxCtrl();
        String params = JSON.serialize(new Map<String, Object>{ 'beginDate' =>authBeginDate, 'providerId'=> provider.id, 'caseCountyId'=>county.id});
        ctrl.processRequest('executeTransportationFeeLogic', params);
        //AuthorizationFlowApxCtrl.executeTransportationFeeLogic(authBeginDate, provider.Id, county.Id);
        crp.PAYMENT_Q11_2__c = 'SCHOOL-AGE';
        update crp;
        params = JSON.serialize(new Map<String, Object>{ 'beginDate' =>authBeginDate, 'providerId'=> provider.id, 'caseCountyId'=>county.id});
        ctrl.processRequest('executeTransportationFeeLogic', params);
        //AuthorizationFlowApxCtrl.executeTransportationFeeLogic(authBeginDate, provider.Id, county.Id);
        crp.PAYMENT_Q11_2__c = null;
        update crp;
        params = JSON.serialize(new Map<String, Object>{ 'beginDate' =>authBeginDate, 'providerId'=> provider.id, 'caseCountyId'=>county.id});
        ctrl.processRequest('executeTransportationFeeLogic', params);
        //AuthorizationFlowApxCtrl.executeTransportationFeeLogic(authBeginDate, provider.Id, county.Id);
    }
    
    static testMethod void createT110TaskTest(){
        Date datetoday = System.Today();
        
        T_COUNTY__c county = TestClassUtility.createCounty('Test Name','Department',2,true);
        T_SBSD_CASE__c sbsdcase = TestClassUtility.createCase(false,county.Id);
        sbsdcase.IDN_EXTNL__c ='12345';
        upsert sbsdcase;
        
        T_SBSD_CASE__c sbsdcase2 = TestClassUtility.createCase(false,county.Id);
        sbsdcase2.IDN_EXTNL__c = '67890';
        upsert sbsdcase2;
        
        T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        begindate = begindate.addDays(25);
        Date enddate = begindate.addDays(20);
        
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        
        T_AUTH__c authorization = TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c = sbsdcase2.Id;
        authorization.IDN_CLIENT__c = sbsdIndiv.Id;
        authorization.IDN_EXTNL__c = '123';
        authorization.AMT_ACTV_AUTH__c = 1;
        authorization.AMT_TRANSP_AUTH__c = 11;
        insert authorization;
        
        T_SBSD_CASE_STATUS_MODE__c caseStatus = new T_SBSD_CASE_STATUS_MODE__c();
        caseStatus.CDE_STATUS_CASE__c = 'OPN';
        caseStatus.IDN_CASE__c = sbsdcase.Id;
        insert caseStatus;
                
        T_INDIV_CUST__c custody = new T_INDIV_CUST__c();
        custody.IDN_CLIENT__c = sbsdIndiv.Id;
        custody.Ignore__c = true;
        custody.DTE_BEGIN_EFFV__c = system.today();
        custody.DTE_END_EFFV__c = null;
        INSERT custody;
        
        T_SBSD_CASE_INDIV__c caseIndiv = new T_SBSD_CASE_INDIV__c(IDN_CASE__c=sbsdcase.Id, IDN_CLIENT__c=sbsdIndiv.Id, DTE_BEGIN_EFFV__c = System.today()-5);
        insert caseIndiv;
        
        AuthorizationFlowApxCtrl.createT110Task(authorization);
    }
}