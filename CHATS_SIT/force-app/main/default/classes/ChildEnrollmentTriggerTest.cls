/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           10/25/2022                                                          
*  @description    Child ENrollment batch test batch class for T555 generation                          
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 25-Oct-2022                                                             
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version                   
*********************************************************************************************/
@isTest
public class ChildEnrollmentTriggerTest {
    
    public static final String OPEN = 'OPN';
    public static final String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
    
    static testMethod void isCaseEligibletestScenario1() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        T_CHATS_PROVR_STATUS__c provider1= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 3');
        insert provider1;
        
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(false,county.Id);
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
        Test.startTest();
        T_CHATS_CHILD_ENROLLMENT__c enroll = new T_CHATS_CHILD_ENROLLMENT__c();
        enroll.IDN_CLIENT__c = authorization.IDN_CLIENT__c;
        enroll.IDN_PROVR__c = authorization.IDN_PROVR__c;
        enroll.Enroll_Flag__c='Enrolled';
        enroll.IsWavierProvider__c = true;
        enroll.DTE_BEGIN_EFFV__c=authorization.DTE_BEGIN_EFFV_AUTH__c;
        insert enroll;
        T_CHATS_CHILD_ENROLLMENT__c enroll1 = new T_CHATS_CHILD_ENROLLMENT__c();
        enroll1.IDN_CLIENT__c = authorization.IDN_CLIENT__c;
        enroll1.IDN_PROVR__c = authorization.IDN_PROVR__c;
        enroll1.Enroll_Flag__c='Enrolled';
        enroll1.IsWavierProvider__c = true;
        enroll1.DTE_BEGIN_EFFV__c=authorization.DTE_BEGIN_EFFV_AUTH__c;
        insert enroll1;
        enroll.Enrollment_Reason__c = 'Child never attended';
        update enroll;
        
        enroll1.Enrollment_Reason__c = 'Child stopped attending after previous attendance';
        update enroll1;
        AuthTaskBasedOnEnrollBatchApxCtrl obj = new AuthTaskBasedOnEnrollBatchApxCtrl();
        DataBase.executeBatch(obj); 
        Test.stopTest();
    }
}