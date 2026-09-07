/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/15/2017                                                          
*  @description    Test class for Rate Schedule Flow
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 15-Dec-2017                                                             
*  * Author: Gaurav Dharra                                                      
*  * Description: Initial version                                                 
*                                                                                 
*********************************************************************************************/
@isTest
public class RateScheduleFlowApxCtrl_Test {
    
    testMethod static void testgetInitData(){
        
        //Create Provider 
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'ProvName');
        
        //Create County
        T_COUNTY__c county = TestClassUtility.createCounty('Provider Flow County Test', 'Provider Flow County Department Test', 20, true);
        
        //Create Country Rate Plan
        T_COUNTY_RATE__c countryRatePlan = TestClassUtility.createCountyRatePlan('APV', false);
        countryRatePlan.IDN_COUNTY__c = county.Id;
        countryRatePlan.CDE_RATE_PLAN_TEMPLT__c = '1';
        countryRatePlan.PAYMENT_Q9_1__c = 1000;
        countryRatePlan.PAYMENT_Q10_1__c = 200;
        countryRatePlan.PAYMENT_Q11_1__c = 500;
        countryRatePlan.DTE_BEGIN_EFFV_RATE__c = System.today().addMonths(1).toStartOfMonth();
        countryRatePlan.DTE_END_EFFV_RATE__c = null;
        countryRatePlan.IND_RATE_PLAN_TEMPLT__c = false; 
        countryRatePlan.RATE_TYPE__c = '1;13;31';
        upsert countryRatePlan;
            
        //Create Fiscal Agreement
        T_PROVR_FISCAL_AGREMENT__c provrFiscalAgre = TestClassUtility.createFiscaAgreement(false, 'Provider Management Flow Test', 
                                                                                           Date.newInstance(2017, 12, 10), county.Id);
        provrFiscalAgre.ID_SERVICE__c = provider.Id;
       
        upsert provrFiscalAgre;
       
        
        //Create Rate Scheduler
        List<T_FISCAL_SCH__c> rateScheduler = new List<T_FISCAL_SCH__c>();
        rateScheduler.add(TestClassUtility.createRateSchedule(false,System.today().addMonths(1).toStartOfMonth() , 
                                                              System.today().addMonths(1).toStartOfMonth().addDays(30), provrFiscalAgre.Id,'1'));
        rateScheduler.add(TestClassUtility.createRateSchedule(false,System.today().addMonths(2).toStartOfMonth() , 
                                                              System.today().addMonths(2).toStartOfMonth().addDays(30), provrFiscalAgre.Id,'1'));
        upsert rateScheduler;
        
        //Create T_FISCAL_RAT_FEES__c 
        List<T_FISCAL_RAT_FEES__c> rateFees = new List<T_FISCAL_RAT_FEES__c>();
        rateFees.add(TestClassUtility.createRATFees(false));
        rateFees.get(0).IDN_FISCAL_SCH__c = rateScheduler.get(0).Id;
        
        rateFees.add(TestClassUtility.createRATFees(false));
        rateFees.get(1).AMT_TRANS_FA__c = 10;
        rateFees.get(1).CDE_TRANS_FREQ__c = 'MTH';
        rateFees.get(1).AMT_ACT_FA__c = 30;
        rateFees.get(1).CDE_ACT_FREQ__c = 'ANN';
        rateFees.get(1).AMT_REG_FA__c = 80;
        rateFees.get(1).CDE_REG_FREQ__c = 'ANN';
        rateFees.get(1).IDN_FISCAL_SCH__c = rateScheduler.get(1).Id;
       
        upsert rateFees;
        
        //Execute main logic
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        LightningServerResponse returnedResponse = RateScheduleFlowApxCtrl.getInitData(provrFiscalAgre.Id,string.valueOf(System.today().addMonths(1).toStartOfMonth()));
        Test.stopTest();
        
        T_FISCAL_RAT_FEES__c returnedRATFees = (T_FISCAL_RAT_FEES__c)returnedResponse.objectData.get('ratFeesRec');
        //Functionality Assertion
        System.assert(returnedResponse.isSuccessful == true, 'Server response was successful');
        System.assert(returnedResponse.objectData.get('providerQualityRating') == 'ProvName', 'Provider Quality Rating retrieved');
        //System.assert(returnedResponse.objectData.get('countyName') == 'Provider Flow County Test', 'County Name retrieved');
        System.assert(returnedRATFees != null, 'RAT Fees retrieved');
        System.assert(returnedRATFees.Id == rateFees.get(1).Id, 'RAT Fees retrieved');
    }
    
    testMethod static void testgetInitDataWithoutRateSchedules(){
        //Create Provider 
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'ProvName');
        
        //Create County
        T_COUNTY__c county = TestClassUtility.createCounty('Provider Flow County Test', 'Provider Flow County Department Test', 20, true);
        
        //Create Country Rate Plan
        T_COUNTY_RATE__c countryRatePlan = TestClassUtility.createCountyRatePlan('PEN', false);
        countryRatePlan.IDN_COUNTY__c = county.Id;
        countryRatePlan.CDE_RATE_PLAN_TEMPLT__c = '1';
        countryRatePlan.PAYMENT_Q9_1__c = 1000;
        countryRatePlan.PAYMENT_Q10_1__c = 200;
        countryRatePlan.PAYMENT_Q11_1__c = 500;
        countryRatePlan.DTE_BEGIN_EFFV_RATE__c = System.today().addMonths(1).toStartOfMonth();
        countryRatePlan.DTE_END_EFFV_RATE__c = null;
        countryRatePlan.IND_RATE_PLAN_TEMPLT__c = false;
        countryRatePlan.RATE_TYPE__c = '1;13;31';
        upsert countryRatePlan;
            
        //Create Fiscal Agreement
        T_PROVR_FISCAL_AGREMENT__c provrFiscalAgre = TestClassUtility.createFiscaAgreement(false, 'Provider Management Flow Test', 
                                                                                           Date.newInstance(2017, 12, 10), county.Id);
        provrFiscalAgre.ID_SERVICE__c = provider.Id;
        
        upsert provrFiscalAgre;
        
        //Execute main logic
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        LightningServerResponse returnedResponse = RateScheduleFlowApxCtrl.getInitData(provrFiscalAgre.Id,string.valueOf(System.today().addMonths(1).toStartOfMonth()));
        Test.stopTest();
        
        Object returnedRATFees = returnedResponse.objectData.get('ratFeesRec');
        
        //Functionality Assertion
        System.assert(returnedResponse.objectData.get('effectiveBeginDate') == Date.newInstance(2017, 12, 10), 'County Name retrieved');
        System.assert(returnedRATFees == null, 'No RAT Fees was retrieved');
    }
    testMethod static void testGetCeilingAmount(){
        
        T_COUNTY__c county = TestClassUtility.createCounty('Provider Flow County Test', 'Provider Flow County Department Test', 20, true);
        T_COUNTY_RATE__c countryRatePlan = TestClassUtility.createCountyRatePlan('PEN', false);
        countryRatePlan.IDN_COUNTY__c = county.Id;
        countryRatePlan.CDE_RATE_PLAN_TEMPLT__c = '1';
        countryRatePlan.PAYMENT_Q9_1__c = 1000;
        countryRatePlan.PAYMENT_Q10_1__c = 200;
        countryRatePlan.PAYMENT_Q11_1__c = 500;
        countryRatePlan.DTE_BEGIN_EFFV_RATE__c = System.today().addMonths(1).toStartOfMonth();
        countryRatePlan.DTE_END_EFFV_RATE__c = null;
        countryRatePlan.IND_RATE_PLAN_TEMPLT__c = false;
        countryRatePlan.RATE_TYPE__c = '1;13;31';
        upsert countryRatePlan;
         T_COUNTY_RATE_AMT__c countyRateAmt = TestClassUtility.createCountyRateAmount(countryRatePlan.Id, true);
        List<T_COUNTY_RATE_AMT__c> returnedCountyAmt=(List<T_COUNTY_RATE_AMT__c>)RateScheduleFlowApxCtrl.GetCeilingAmount(countryRatePlan.Id, 'HOM', '2').objectData.get('lstCountyRateAmt');
        List<T_COUNTY_RATE_AMT__c> returnedCountyAmtNull=(List<T_COUNTY_RATE_AMT__c>)RateScheduleFlowApxCtrl.GetCeilingAmount(countryRatePlan.Id, 'HOM', '').objectData.get('lstCountyRateAmt');
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'ProvName');
        
        T_PROVR_FISCAL_AGREMENT__c provrFiscalAgre = TestClassUtility.createFiscaAgreement(false, 'Provider Management Flow Test', 
                                                                                           Date.newInstance(2017, 12, 10), county.Id);
        provrFiscalAgre.ID_SERVICE__c = provider.Id;
        upsert provrFiscalAgre;
        
        List<T_FISCAL_SCH__c> rateScheduler = new List<T_FISCAL_SCH__c>();
        rateScheduler.add(TestClassUtility.createRateSchedule(false,Date.newInstance(2017, 12, 01) , 
                                                              Date.newInstance(2017, 12, 10), provrFiscalAgre.Id,countryRatePlan.RATE_TYPE__c));
        
        upsert rateScheduler;
        List<String> rateTypeLst = new List<String>();
        rateTypeLst.add(rateScheduler[0].CDE_RATE_TYPE__c);
        List<T_COUNTY_RATE_AMT__c> returnedCountyAmtExe=(List<T_COUNTY_RATE_AMT__c>)RateScheduleFlowApxCtrl.getCeilingAmountForExe(countryRatePlan.Id, 'HOM', '1', rateTypeLst).objectData.get('lstCountyRateAmt');
        system.assertEquals(1000,[select PAYMENT_Q9_1__c from T_COUNTY_RATE__c where id=:countryRatePlan.Id].PAYMENT_Q9_1__c,'Should be matching with updated value' );
    }
    testMethod static void testGetInitDataView(){
    //Create Provider 
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'ProvName');
        
        //Create County
        T_COUNTY__c county = TestClassUtility.createCounty('Provider Flow County Test', 'Provider Flow County Department Test', 20, true);
        
        //Create Country Rate Plan
        T_COUNTY_RATE__c countryRatePlan = TestClassUtility.createCountyRatePlan('PEN', false);
        countryRatePlan.IDN_COUNTY__c = county.Id;
        countryRatePlan.CDE_RATE_PLAN_TEMPLT__c = '1';
        countryRatePlan.PAYMENT_Q9_1__c = 1000;
        countryRatePlan.PAYMENT_Q10_1__c = 200;
        countryRatePlan.PAYMENT_Q11_1__c = 500;
        countryRatePlan.DTE_BEGIN_EFFV_RATE__c = System.today().addMonths(1).toStartOfMonth();
        countryRatePlan.DTE_END_EFFV_RATE__c = null;
        countryRatePlan.IND_RATE_PLAN_TEMPLT__c = false;
        countryRatePlan.RATE_TYPE__c = '1;13;31';
        upsert countryRatePlan;
            
        //Create Fiscal Agreement
        T_PROVR_FISCAL_AGREMENT__c provrFiscalAgre = TestClassUtility.createFiscaAgreement(false, 'Provider Management Flow Test', 
                                                                                           Date.newInstance(2017, 12, 10), county.Id);
        provrFiscalAgre.ID_SERVICE__c = provider.Id;
        upsert provrFiscalAgre;
       
        
        //Create Rate Scheduler
        List<T_FISCAL_SCH__c> rateScheduler = new List<T_FISCAL_SCH__c>();
        rateScheduler.add(TestClassUtility.createRateSchedule(false,Date.newInstance(2017, 12, 01) , 
                                                              Date.newInstance(2017, 12, 10), provrFiscalAgre.Id,'1'));
        rateScheduler.add(TestClassUtility.createRateSchedule(false,Date.newInstance(2017, 12, 11) , 
                                                              Date.newInstance(2017, 12, 25), provrFiscalAgre.Id,'1'));
        upsert rateScheduler;
        
        //Create T_FISCAL_RAT_FEES__c 
        List<T_FISCAL_RAT_FEES__c> rateFees = new List<T_FISCAL_RAT_FEES__c>();
        rateFees.add(TestClassUtility.createRATFees(false));
        rateFees.get(0).IDN_FISCAL_SCH__c = rateScheduler.get(0).Id;
        
        rateFees.add(TestClassUtility.createRATFees(false));
        rateFees.get(1).AMT_TRANS_FA__c = 10;
        rateFees.get(1).CDE_TRANS_FREQ__c = 'MTH';
        rateFees.get(1).AMT_ACT_FA__c = 30;
        rateFees.get(1).CDE_ACT_FREQ__c = 'ANN';
        rateFees.get(1).AMT_REG_FA__c = 80;
        rateFees.get(1).CDE_REG_FREQ__c = 'ANN';
        rateFees.get(1).IDN_FISCAL_SCH__c = rateScheduler.get(1).Id;
       
        upsert rateFees;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        LightningServerResponse returnedResponse=RateScheduleFlowAPXCtrl.getInitDataView(rateScheduler.get(1).Id);
        LightningServerResponse lsr = RateScheduleFlowAPXCtrl.finishRateSchedule(provider.Id,rateScheduler.get(1));
        LightningServerResponse lsr1 = RateScheduleFlowAPXCtrl.triggerCorspdCR707(rateScheduler.get(1).Id);
        system.assertEquals(true,lsr.isSuccessful,'isSuccessful should be true' );
        Test.stopTest();
    }
    testMethod static void testCreateFiscalRates(){
       T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 3');
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(false, '1234', system.today(), county.Id);
        fiscalAgreement.ID_SERVICE__c = provider.Id;
        insert fiscalAgreement;
        T_FISCAL_SCH__c fiscalSchedule = TestClassUtility.createRateSchedule(true, system.today(), null, fiscalAgreement.Id, '1');
        List<Id>fiscalScheduleIdLst = new List<Id>();
        fiscalScheduleIdLst.add(fiscalSchedule.Id);
        batchsit_t_fiscal_rate__x fiscalRate = new batchsit_t_fiscal_rate__x();
        fiscalRate.amt_fa__c= 10;
        fiscalRate.amt_provr__c= 15;
        fiscalRate.cde_age_group__c= '1';
        fiscalRate.cde_care_unit__c= '2';
        fiscalRate.cde_rate_type__c= '1';
        fiscalRate.idn_fiscal_sch__c = fiscalSchedule.Id;
        List<batchsit_t_fiscal_rate__x> lstFiscalRates = new List<batchsit_t_fiscal_rate__x>();
        lstFiscalRates.add(fiscalRate);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        system.assertEquals(true, RateScheduleFlowAPXCtrl.insertFiscalRateRecords(lstFiscalRates).isSuccessful);
        Test.setMock(HttpCalloutMock.class, new HerokuServiceUnSuccessfullCalloutMock());
        system.assertEquals(false, RateScheduleFlowAPXCtrl.insertFiscalRateRecords(lstFiscalRates).isSuccessful);
        Test.stopTest();
    }
}