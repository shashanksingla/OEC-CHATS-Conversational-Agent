/************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           09/07/2017
*  @description    Utility classe to test classes
*  @test class     TestClassUtility_Test
*
*  Modification Log:
*  * Version: 1.0
*  * Date: 9-Sept-2017
*  * Author: Shubham Khandelwal
*  * Description: Initial version
*
*  * Version: 1.1
*  * Date: 15-June-2022
*  * Author: Rishav Maji
*  * Description: API Upgrade, Code cleanup, Test Coverage
************************************************************/
public class TestClassUtility {
    
    public static T_COUNTY_PLAN__c  createCountyPlan(String status, Boolean doInsert) {
        T_COUNTY_PLAN__c aCountyPlan = new T_COUNTY_PLAN__c();
        aCountyPlan.CDE_STATUS__c = status;
        aCountyPlan.CDE_COUNTY_PLAN_TEMPLT__c = '1';
        aCountyPlan.DTE_BEGIN_EFFEV__c = System.today().addDays(1);
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{aCountyPlan}, null);
        }
        return aCountyPlan;
    }
    
    public static T_COUNTY_RATE_AMT__c  createCountyRateAmount(Id countyRatePlanId, Boolean doInsert) {
        T_COUNTY_RATE_AMT__c aCountyRateAmt = new T_COUNTY_RATE_AMT__c();
        aCountyRateAmt.CDE_AGE_GROUP__c = '1';
        aCountyRateAmt.NBR_AMOUNT__c = 100;
        aCountyRateAmt.CDE_UNIT__c = '2';
        aCountyRateAmt.IDN_COUNTY_RATE__c = countyRatePlanId;
        aCountyRateAmt.CDE_RATE_TEMPLT__c = '1';
        aCountyRateAmt.IND_RATE_TEMPLT__c = false;
        aCountyRateAmt.CDE_PROVR_TYPE__c = 'HOM';
        aCountyRateAmt.CDE_RATE_TYPE__c = '1';
        aCountyRateAmt.CDE_TIER__c = '2';
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{aCountyRateAmt}, null);
        }
        return aCountyRateAmt;
    }
    
    public static T_COUNTY__c createCounty(String countyName, String countyDepartmentName, Integer countyCode, Boolean doInsert) {
        T_COUNTY__c aCounty=new T_COUNTY__c(CNTY_DEPT_NAME__c = countyDepartmentName, CDE_COUNTY__c = countyCode);
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{aCounty}, null);
        }
        return aCounty;
    }
    
    public static User createUser(Id idProfile, String strLastname, String strFirstName, String strEmail, String strUsername, String strAlias) {
        User aUser = new User(Alias = strAlias, Email = strEmail, FirstName = strFirstName,
                              EmailEncodingKey = 'UTF-8', LastName = strLastname, LanguageLocaleKey = 'en_US', 
                              LocaleSidKey = 'en_US', ProfileId = idProfile, 
                              TimeZoneSidKey = 'America/Los_Angeles', UserName = strUsername);
        return aUser;
    }

    public static User createUserwithPS(Id idProfile, String permSet, String strLastname, String strFirstName, String strEmail, String strUsername, String strAlias) {
        List<PermissionSet> psList = [SELECT Id FROM PermissionSet WHERE Name=:permSet LIMIT 1];
        User aUser = new User(Alias = strAlias, Email = strEmail, FirstName = strFirstName,
                              EmailEncodingKey = 'UTF-8', LastName = strLastname, LanguageLocaleKey = 'en_US', 
                              LocaleSidKey = 'en_US', ProfileId = idProfile, 
                              TimeZoneSidKey = 'America/Los_Angeles', UserName = strUsername);
        insert aUser;
        if(!psList.isEmpty()){
        	PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = psList[0].Id, AssigneeId =aUser.Id);
            insert psa;
        }
        return aUser;
    }
    
    public static User createUserWithRole(Id idProfile, String strLastname, String strFirstName, String strEmail, String strUsername, String strAlias, Id roleId) {
        User aUser = new User(Alias = strAlias, Email = strEmail, FirstName = strFirstName,
                              EmailEncodingKey = 'UTF-8', LastName = strLastname, LanguageLocaleKey = 'en_US', 
                              LocaleSidKey = 'en_US', ProfileId = idProfile, 
                              TimeZoneSidKey = 'America/Los_Angeles', UserName = strUsername, UserRoleId = roleId);
        return aUser;
    }
    
    public static T_COUNTY_RATE__c createCountyRatePlan(String status, Boolean doInsert) {
        T_COUNTY_RATE__c aCountyRatePlan = new T_COUNTY_RATE__c();
        aCountyRatePlan.CDE_STATUS__c = status;
        aCountyRatePlan.DTE_BEGIN_EFFV_RATE__c = Date.newInstance(System.today().Year(), System.today().Month()+1, 1);
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{aCountyRatePlan}, null);
        }
        return aCountyRatePlan;
    }
    
    
    public static T_PROVR_PREF__c createCorrespondanceAndLanguagePref(boolean status, String corresPref, String langPref) {
        T_PROVR_PREF__c aCorrespondanceAndLanguagePref = new T_PROVR_PREF__c();
        aCorrespondanceAndLanguagePref.IND_ACTIVE__c = status;
        aCorrespondanceAndLanguagePref.CDE_PREF_CORR_PROVR__c = corresPref;
        aCorrespondanceAndLanguagePref.CDE_PREF_LANG_PROVR__c = langPref;
        return aCorrespondanceAndLanguagePref;
    }
    
    public static T_AUTH__c createAuthorization(Boolean doInsert, Date enddate, Date begindate, string cdeCounty, string provider) {
        T_AUTH__c authorization = new T_AUTH__c();
        authorization.DTE_END_EFFV_AUTH__c = enddate;
        authorization.DTE_BEGIN_EFFV_AUTH__c = begindate;
        authorization.CDE_COUNTY__c = cdeCounty;
        authorization.IDN_PROVR__c = provider;
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{authorization}, null);
        }
        return authorization;
    }
    
    public static T_SBSD_CASE__c createCase(Boolean doInsert, String cdeCounty) {
        T_SBSD_CASE__c sbsdcase = new T_SBSD_CASE__c();
        sbsdcase.CDE_COUNTY__c = cdeCounty;
        sbsdcase.IND_ASSIST_PROVR__c = 'N';
        sbsdcase.IND_ELG_PRE_PROVR__c = false;
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{sbsdcase}, null);
        }
        return sbsdcase;
    }
    
    public static T_SBSD_INDIV__c createIndividual(Boolean doInsert, Date DOB, string firstname, string gender, string lastname, string SSN, string cdeSourceVerfyd) {
        T_SBSD_INDIV__c sbsdIndiv = new T_SBSD_INDIV__c();
        sbsdIndiv.DTE_DOB__c = DOB;
        sbsdIndiv.NAM_FIRST__c = firstname;
        sbsdIndiv.CDE_GENDER__c = gender;
        sbsdIndiv.NAM_LAST__c = lastname;
        sbsdIndiv.NBR_SSN__c = SSN;
        sbsdIndiv.CDE_SOURCE_VRFYD_IDNTY__c = cdeSourceVerfyd;
        sbsdIndiv.IND_CDE_TYPE_VERIF_DOB__c = 'NA';
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{sbsdIndiv}, null);
        }
        return sbsdIndiv;
    }
    
    public static T_INDIV_DSBLTY__c createIndivDisability(Boolean doInsert, String indivId) {
        T_INDIV_DSBLTY__c sbsdIndivDis = new T_INDIV_DSBLTY__c();
        sbsdIndivDis.IDN_CLIENT__c = indivId;
        sbsdIndivDis.IND_CC_GIVE_ABLE__c = 'Y';
        sbsdIndivDis.CDE_SOURCE_DSBLTY_CHILD__c = 'DST';
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{sbsdIndivDis}, null);
        }
        return sbsdIndivDis;
    }
    
    public static T_APPEAL__c createAppeal(Boolean doInsert, String caseId, String countyId, String providerId) {
        T_APPEAL__c appealObj = new T_APPEAL__c();
        appealObj.IDN_CASE__c = caseId;
        appealObj.CDE_COUNTY__c = countyId;
        appealObj.IDN_PROVR__c = providerId;
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{appealObj}, null);
        }
        return appealObj;
    }
    
    public static T_INDIV_DISQLN__c createIndivDisqln(Boolean doInsert, String appealId) {
        T_INDIV_DISQLN__c indivDisqln = new T_INDIV_DISQLN__c(IDN_APPEAL__c = appealId, CDE_DECN_IPV__c = 'TIP', CDE_TYPE_ASSIGN__c = 'Y', DTE_BEGIN_EFFV__c = System.today());
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{indivDisqln}, null);
        }
        return indivDisqln;
    }
    
    public static T_APPLN_INDIV__c createApplicationIndividual(Boolean doInsert, Date DOB, string firstname, string gender, string lastname, string SSN, String appCaseId) {
        T_APPLN_INDIV__c appIndiv = new T_APPLN_INDIV__c();
        appIndiv.DTE_DOB__c = DOB;
        appIndiv.NAM_FIRST__c = firstname;
        appIndiv.CDE_GENDER__c = gender;
        appIndiv.NAM_LAST__c = lastname;
        appIndiv.NBR_SSN__c = SSN;
        appIndiv.IDN_APPLN__c = appCaseId;
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{appIndiv}, null);
        }
        return appIndiv;
    }
    
    public static T_SBSD_CASE_INDIV__c createCaseIndividual(Boolean doInsert, String caseId, String individualId, Boolean isPrimaryCaretaker) {
        T_SBSD_CASE_INDIV__c caseIndiv = new T_SBSD_CASE_INDIV__c();
        caseIndiv.IDN_CASE__c = caseId;
        caseIndiv.IDN_CLIENT__c = individualId;
        caseIndiv.IND_CRTKR__c = isPrimaryCaretaker;
        caseIndiv.Individual_Status__c = isPrimaryCaretaker== true? 'PC' : 'Child';
        caseIndiv.DTE_BEGIN_EFFV__c = system.today();
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{caseIndiv}, null);
        }
        return caseIndiv;
    }
    
    public static T_PROVR_FISCAL_AGREMENT__c createFiscaAgreement(Boolean doInsert, String name, Date begindate, String cdecounty) {
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = new T_PROVR_FISCAL_AGREMENT__c();
        fiscalAgreement.DTE_BEGIN_AGRMT__c = begindate;
        fiscalAgreement.CDE_COUNTY__c = cdecounty;
        fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c = begindate;
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{fiscalAgreement}, null);
        }
        return fiscalAgreement;
    }
    
    public static T_CHILD_SUP__c createChildSupport(Boolean doInsert, String indivId) {
        T_CHILD_SUP__c childSupp = new T_CHILD_SUP__c(IDN_CLIENT__c = indivId, NAM_FIRST_CUST_NON__c = 'Test', NAM_LAST_CUST_NON__c = 'Last', IND_COOP_PARENT__c = 'N');
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{childSupp}, null);
        }
        return childSupp;
    }
    
    public static T_COPAY_DELINQC__c createparentFeelDelinq(Boolean doInsert, String caseId, String indivId, Double copayAmt) {
        T_COPAY_DELINQC__c parentFeelDelinq = new T_COPAY_DELINQC__c(IDN_CASE__c = caseId, IDN_CLIENT__c = indivId, AMT_DELINQC_COPAY_ENRLMT__c = copayAmt);
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{parentFeelDelinq}, null);
        }
        return parentFeelDelinq;
    }
    
    public static T_PMT_PLAN__c createPaymentPlan(Boolean doInsert, String providerId, Integer planamount, Integer percentage, Integer minimumdeduction) {
        T_PMT_PLAN__c paymentPlan = new T_PMT_PLAN__c();
        paymentPlan.IDN_PROVR__c = providerId;
        paymentPlan.AMT_PLAN_PMT__c = planamount;
        paymentPlan.NBR_PCTG__c = percentage;
        paymentPlan.AMT_PLAN_PMT_PCT_MIN__c = minimumdeduction;
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{paymentPlan}, null);
        }
        return paymentPlan;
    }
    
    public static T_PRIM_ACTV__c createPrimaryActivity(Boolean doInsert, String caseId, String clientId, Date begindate, Date enddate, String type) {
        T_PRIM_ACTV__c primaActiv = new T_PRIM_ACTV__c();
        primaActiv.IDN_CASE__c = caseId;
        primaActiv.IDN_CLIENT__c = clientId;
        primaActiv.DTE_BEGIN_ACTV_PRIM__c = begindate;
        primaActiv.DTE_END_ACTV_PRIM__c = enddate;
        primaActiv.CDE_TYPE_ACTV__c = type;
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{primaActiv}, null);
        }
        return primaActiv;
    }
    
    public static T_PRIM_ACTV_CNTR__c createPrimaryActivityCNTR(Boolean doInsert, String clientId, String primActivId, Integer cntweeks) {
        T_PRIM_ACTV_CNTR__c primaActivCntr = new T_PRIM_ACTV_CNTR__c();
        primaActivCntr.IDN_CLIENT__c = clientId;
        primaActivCntr.IDN_PRIM_ACTV__c = primActivId;
        primaActivCntr.CNT_WEEKS__c =  cntweeks;
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{primaActivCntr}, null);
        }
        return primaActivCntr;
    }
    
    public static T_FISCAL_SCH__c createRateSchedule(Boolean doInsert, Date begindate, Date enddate, String FAId, String ratetype) {
        T_FISCAL_SCH__c rateschedule = new T_FISCAL_SCH__c();
        rateschedule.DTE_BEGIN_EFFV__c = begindate;
        rateschedule.DTE_END_EFFV__c = enddate;
        rateschedule.IDN_AGRMT_FISCAL__c = FAId;
        rateschedule.CDE_RATE_TYPE__c = ratetype;
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{rateschedule}, null);
        }
        return rateschedule;
    }
    
    public static T_FISCAL_RAT_FEES__c createRATFees(Boolean doInsert) {
        T_FISCAL_RAT_FEES__c rateFees = new T_FISCAL_RAT_FEES__c();
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{rateFees}, null);
        }
        return rateFees;
    }
    
    public static T_CHATS_PROVR_STATUS__c createProvider(Boolean doInsert, String providerQuality) {
        T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c();
        provider.TXT_CHATS_RATING__c = providerQuality;
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{provider}, null);
        }
        return provider;
    }
    
    public static T_SBSD_CASE_STATUS_MODE__c createCaseStatusMode(Boolean doInsert, String caseId) {
        T_SBSD_CASE_STATUS_MODE__c caseStaMod = new T_SBSD_CASE_STATUS_MODE__c();
        caseStaMod.IDN_CASE__c = caseId;
        caseStaMod.CDE_MODE_CASE__c = 'INT';
        caseStaMod.CDE_STATUS_CASE__c = 'OPN';
        caseStaMod.DTE_BEGIN_EFFV__c = System.today()-5;
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{caseStaMod}, null);
        }
        return caseStaMod;
    }
    
    public static batchsit_t_eligty_run__x createEligibilityRunRecord(Boolean doInsert, String caseId) {
        batchsit_t_eligty_run__x eligibilityRun = new batchsit_t_eligty_run__x();
        eligibilityRun.idn_run_eligty__c = 1234;
        eligibilityRun.IDN_CASE__c = caseId;
        if(doInsert && batchsit_t_eligty_run__x.sObjectType.getDescribe().isCreateable()) {
            Database.insertAsync(eligibilityRun);
        }
        return eligibilityRun;
    }
    
    public static T_ADJMT__c createAdjustment(Boolean doInsert, String countyId, String caseId, String providerId) {
        T_ADJMT__c adjustment = new T_ADJMT__c(CDE_COUNTY__c = countyId, IDN_CASE__c = caseId, CDE_AGNST_ADJMT__c = '2', CDE_STATUS_ADJMT__c = '1', 
                                               DTE_END_ADJMT__c = Date.valueOf(Date.newInstance(2018, 01, 15)),
                                               DTE_START_ADJMT__c = Date.valueOf(Date.newInstance(2018, 01, 01))
                                              );
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{adjustment}, null);
        }
        return adjustment;
    }
    
    public static T_ADJMT_ADDR__c createAdjustmentAddress(Boolean doInsert, String adjustmentId) {
        T_ADJMT_ADDR__c adjustmentAddr = new T_ADJMT_ADDR__c(IDN_ADJMT__c = adjustmentId);
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{adjustmentAddr}, null);
        }
        return adjustmentAddr;
    }
    
    public static T_ADJMT_DETAIL__c createAdjustmentDetail(Boolean doInsert, String adjustmentId) {
        T_ADJMT_DETAIL__c adjDetail = new T_ADJMT_DETAIL__c(IDN_ADJMT__c = adjustmentId);
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{adjDetail}, null);
        }
        return adjDetail;
    }
    
    public static T_ADJMT_CMT__c createAdjustmentNote(Boolean doInsert, String adjustmentId) {
        T_ADJMT_CMT__c adjNote = new T_ADJMT_CMT__c(IDN_ADJMT__c = adjustmentId);
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{adjNote}, null);
        }
        return adjNote;
    }
    
    public static T_ADJMT_PMT__c createAdjustmentPayment(Boolean doInsert, String caseId, String provId) {
        T_ADJMT_PMT__c adjPmt = new T_ADJMT_PMT__c(IDN_CASE__c = caseId, IDN_PROVR__c = provId, AMT_PMT_ADJMT__c = 10,
                                                   CDE_TYPE_PMT_ADJMT__c = '1', DTE_PMT_ADJMT__c = Date.newInstance(2018, 02, 01));
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{adjPmt}, null);
        }
        return adjPmt;
    }
    
    public static T_ADJMT_PMT_DETAIL__c createAdjustmentPaymentDetail(Boolean doInsert, String adjustmentDetailId, String adjustmentId, String adjPaymentId) {
        T_ADJMT_PMT_DETAIL__c adjPayDetail = new T_ADJMT_PMT_DETAIL__c(IDN_ADJMT__c = adjustmentId, IDN_DETAIL_ADJMT__c = adjustmentDetailId, IDN_PMT_ADJMT__c = adjPaymentId);
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{adjPayDetail}, null);
        }
        return adjPayDetail;
    }
    
    public static T_ADJMT_RESPBL_PARTY__c createAdjustmentRespPart(Boolean doInsert, String caseId, String providerId, String individualId, String adjustmentId) {
        T_ADJMT_RESPBL_PARTY__c adjRespParty = new T_ADJMT_RESPBL_PARTY__c(IDN_ADJMT__c = adjustmentId, IDN_CASE__c = caseId, IDN_PROVR__c = providerId, IDN_CLIENT__c = individualId);
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{adjRespParty}, null);
        }
        return adjRespParty;
    }
    
    public static T_SBSD_CASE_WTLST__c createCaseWaitlist(Boolean doInsert, String caseId, Date beginEffectiveDate, Date endEffectiveDate, String waitlistStatus) {
        T_SBSD_CASE_WTLST__c caseWaitlist = new T_SBSD_CASE_WTLST__c(IDN_CASE__c = caseId, DTE_BEGIN_EFFV_WTLST__c = beginEffectiveDate,
                                                                     DTE_END_EFFV_WTLST__c = endEffectiveDate, CDE_STATUS_WTLST__c = waitlistStatus);
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{caseWaitlist}, null);
        }
        return caseWaitlist;
    }
    
    public static Task createTask(Boolean doInsert, String subject, String description, String status, String whatId,  String ownerId) {
        Task tsk = new Task(WhatId = whatId, Subject = subject, Description = description, Status = status, OwnerId = ownerID);
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{tsk}, null);
        }
        return tsk;
    }
    
    public static void createServicePeriod(Boolean doInsert, Date beginEffectiveDate, Date endEffectiveDate, Date paymentBatchFileDate, Date paymentBatchProcessedDate) {
        T_SERV_PERIOD__c servicePeriod = new T_SERV_PERIOD__c(DTE_BEGIN_EFFV__c = beginEffectiveDate, DTE_END_EFFV__c = endEffectiveDate,
                                                              DTE_BATCH_FILE_PMT__c = paymentBatchFileDate, DTE_BATCH_PRCS_PMT__c = paymentBatchProcessedDate);
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{servicePeriod}, null);
        } 
    }
    //added for CCCAP-10162 by Shashank S.
    public static Reverse_Referral_Interface_Report__c createReverseRef(Boolean doInsert, String cbmsCaseId, String cccapCaseId, Date dateSentToCBMS, String referralId) {
        Reverse_Referral_Interface_Report__c revRef = new Reverse_Referral_Interface_Report__c(CBMS_Case_Id__c = cbmsCaseId, CCCAP_Case_Id__c = cccapCaseId,
                                                              Date_Sent_to_CBMS__c = dateSentToCBMS, Referral_Id__c = referralId);
        if(doInsert) {
            GenericDMLHandler.insertRecords(new List<Sobject>{revRef}, null);
        } 
        return revRef;
    }
}