/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/8/2017                                                          
*  @description    Test class for Primary Activity Trigger                           
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 8-Dec-2017                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version                                                 
*                                                                                 
*********************************************************************************************/
@isTest
private class PrimaryActivityServices_Test {
        
    static testMethod void primActBeforeInsertCheckNullEnddateTest() {
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstNameA','1','lastNameA','1','CC');
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_CASE__c sbsdcase =TestClassUtility.createCase(true,county.Id);
        TestClassUtility.createPrimaryActivity(true,sbsdcase.Id,sbsdIndiv.Id,date.newInstance(2017, 1, 15),null,'DSB');
        try{
            TestClassUtility.createPrimaryActivity(true,sbsdcase.Id,sbsdIndiv.Id,date.newInstance(2017, 12, 4),null,'EDU');
        
        }catch(Exception ex) {
            system.assertEquals(true,string.valueOf(ex.getMessage()).contains(Label.Only_have_one_effective_Primary_Activity),'Failing not due validation code in trigger');
        }
        
       }
       
    static testMethod void primActBeforeInsertCheckTypeTest() {
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstNameA','1','lastNameA','1','CC');
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_CASE__c sbsdcase =TestClassUtility.createCase(true,county.Id);
        
        List<T_PRIM_ACTV__c> primActivList = new List<T_PRIM_ACTV__c>();
        primActivList.add((T_PRIM_ACTV__c)TestClassUtility.createPrimaryActivity(false,sbsdcase.Id,sbsdIndiv.Id,date.newInstance(2017, 1, 15),date.newInstance(2017, 1, 20),'GED'));
        primActivList.add((T_PRIM_ACTV__c)TestClassUtility.createPrimaryActivity(false,sbsdcase.Id,sbsdIndiv.Id,date.newInstance(2017, 1, 15),date.newInstance(2017, 1, 20),'POS'));
       
        insert primActivList;
        
        //testing after insert createPrimaryActivityCounter method to check uto created Primary activity counter records
        
        T_PRIM_ACTV_CNTR__c primActCnt1=[Select Id,IDN_CLIENT__c,CNT_WEEKS__c,IDN_PRIM_ACTV__c from T_PRIM_ACTV_CNTR__c where IDN_PRIM_ACTV__c =:primActivList[0].Id];
        system.assertEquals(primActivList[0].Id,primActCnt1.IDN_PRIM_ACTV__c,'Problem in Primary Activity');
        system.assertEquals(primActivList[0].IDN_CLIENT__c,primActCnt1.IDN_CLIENT__c,'Problem in Individual');
        system.assertEquals(0,primActCnt1.CNT_WEEKS__c,'Value is other than Zero');
        
        T_PRIM_ACTV_CNTR__c primActCnt2=[Select Id,IDN_CLIENT__c,CNT_WEEKS__c,IDN_PRIM_ACTV__c from T_PRIM_ACTV_CNTR__c where IDN_PRIM_ACTV__c =:primActivList[1].Id];
        system.assertEquals(primActivList[1].Id,primActCnt2.IDN_PRIM_ACTV__c,'Problem in Primary Activity');
        system.assertEquals(primActivList[1].IDN_CLIENT__c,primActCnt2.IDN_CLIENT__c,'Problem in Individual');
        system.assertEquals(0,primActCnt2.CNT_WEEKS__c,'Value is other than Zero');
        
        
        try{
           TestClassUtility.createPrimaryActivity(true,sbsdcase.Id,sbsdIndiv.Id,date.newInstance(2017, 1, 12),null,'GED'); 
           TestClassUtility.createPrimaryActivity(true,sbsdcase.Id,sbsdIndiv.Id,date.newInstance(2017, 1, 13),date.newInstance(2017, 1, 25),'GED'); 
           TestClassUtility.createPrimaryActivity(true,sbsdcase.Id,sbsdIndiv.Id,date.newInstance(2017, 1, 17),date.newInstance(2017, 1, 25),'GED');
        
        }catch(Exception ex) {
            system.assertEquals(true,string.valueOf(ex.getMessage()).contains(Label.The_Individual_already_has_an_existing_primary_activity_GED_ESL_ABE ),'Failing not due validation code in trigger');
        }
        
        try{
            TestClassUtility.createPrimaryActivity(true,sbsdcase.Id,sbsdIndiv.Id,date.newInstance(2017, 1, 17),date.newInstance(2017, 1, 25),'POS');
        
        }catch(Exception ex) {
            system.assertEquals(true,string.valueOf(ex.getMessage()).contains(Label.The_Individual_already_has_an_existing_primary_activity_POS),'Failing not due validation code in trigger');
        }
        
       }
       
    static testMethod void primActBeforeInsertCheckJobsearchUtilizeTest() {
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstNameA','1','lastNameA','1','CC');
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_CASE__c sbsdcase =TestClassUtility.createCase(true,county.Id);
        T_COUNTY_PLAN__c  countyPlan = TestClassUtility.createCountyPlan('',false);
        countyPlan.CDE_COUNTY__c=county.Id;
        countyPlan.ELIGIBILITY_Q4__c=10;
        countyPlan.DTE_BEGIN_EFFEV__c = system.today()+1;
        countyPlan.DTE_END_EFFEV__c = system.today()+11;
        countyPlan.CDE_COUNTY_PLAN_TEMPLT__c='1';
        insert countyPlan;
        
        T_PRIM_ACTV__c primActExisting=TestClassUtility.createPrimaryActivity(true,sbsdcase.Id,sbsdIndiv.Id,system.today()-350,null,'JS');
        TestClassUtility.createPrimaryActivityCNTR(true,sbsdIndiv.Id,primActExisting.Id,15);
        
        try{
            TestClassUtility.createPrimaryActivity(true,sbsdcase.Id,sbsdIndiv.Id,system.today(),null,'JS');
        
        }catch(Exception ex) {
            //Bharadwaj to fix
            system.assertEquals(false,string.valueOf(ex.getMessage()).contains(Label.The_Individual_has_already_reached_the_time_limit_for_Job_Search_in_the_past_yea),'Failing not due validation code in trigger');
        }
        
       }
       
       static testMethod void primActBeforeUpdateCheckNullEnddateTest() {
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstNameA','1','lastNameA','1','CC');
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_CASE__c sbsdcase =TestClassUtility.createCase(true,county.Id);
        
        List<T_PRIM_ACTV__c> primActivList = new List<T_PRIM_ACTV__c>();
        primActivList.add((T_PRIM_ACTV__c)TestClassUtility.createPrimaryActivity(false,sbsdcase.Id,sbsdIndiv.Id,system.today()-100,system.today()+20,'GED'));
        primActivList.add((T_PRIM_ACTV__c)TestClassUtility.createPrimaryActivity(false,sbsdcase.Id,sbsdIndiv.Id,system.today()+21,null,'POS'));
       
        insert primActivList;  
        
        try{
            primActivList[0].DTE_END_ACTV_PRIM__c=null;
            update primActivList[0];
        }catch(Exception ex) {
            system.assertEquals(true,string.valueOf(ex.getMessage()).contains(Label.Only_have_one_effective_Primary_Activity),'Failing not due validation code in trigger');
        }
        
       }
       
       static testMethod void primActBeforeInsertCheckBeginDateTest() {
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstNameA','1','lastNameA','1','CC');
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_CASE__c sbsdcase =TestClassUtility.createCase(true,county.Id);
        TestClassUtility.createPrimaryActivity(true,sbsdcase.Id,sbsdIndiv.Id,system.today()-100,system.today()+100,'DSB');
        try{
            TestClassUtility.createPrimaryActivity(true,sbsdcase.Id,sbsdIndiv.Id,system.today(),null,'EDU');
        
        }catch(Exception ex) {
            system.assertEquals(true,string.valueOf(ex).contains(Label.Only_have_one_effective_Primary_Activity),'Failing not due to expected validation error'+Label.Only_have_one_effective_Primary_Activity);
        }
        
       }
       
       static testMethod void primActBeforeUpdateCheckBeginDateTest() {
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstNameA','1','lastNameA','1','CC');
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_CASE__c sbsdcase =TestClassUtility.createCase(true,county.Id);
        List<T_PRIM_ACTV__c> primActivList = new List<T_PRIM_ACTV__c>();
        primActivList.add((T_PRIM_ACTV__c)TestClassUtility.createPrimaryActivity(false,sbsdcase.Id,sbsdIndiv.Id,system.today()-100,system.today()+20,'GED'));
        primActivList.add((T_PRIM_ACTV__c)TestClassUtility.createPrimaryActivity(false,sbsdcase.Id,sbsdIndiv.Id,system.today()+21,system.today()+110,'POS'));
       
        insert primActivList;  
        
        try{
            primActivList[1].DTE_BEGIN_ACTV_PRIM__c=system.today();
            update primActivList[1];
        }catch(Exception ex) {
            system.assertEquals(true,string.valueOf(ex.getMessage()).contains(Label.Only_have_one_effective_Primary_Activity),'Failing not due validation code in trigger');
        }
        
       }
       
}