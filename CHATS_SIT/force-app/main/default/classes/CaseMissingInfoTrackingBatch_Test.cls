/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           5/09/2023                                                         
*  @description    Case batch class for tracking missing information letter and creating eligibility run data                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 9-May-2023                                                            
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version                   
*********************************************************************************************/
@isTest
public class CaseMissingInfoTrackingBatch_Test {
    
    public static testMethod void testMethod1(){
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
        sbsdcase.IND_MissingInfo_Status__c = 'OPEN';
        insert sbsdcase;
        T_SBSD_CASE_STATUS_MODE__c caseStaMod = TestClassUtility.createCaseStatusMode(true, sbsdcase.Id);
        caseStaMod.CDE_MODE_CASE__c='INT';
        UPDATE caseStaMod;
        List<T_CBMS_ADDNL_INFO__c> tanfDataList = new List<T_CBMS_ADDNL_INFO__c>();
            T_CBMS_ADDNL_INFO__c cs1 = new T_CBMS_ADDNL_INFO__c();
            cs1.IDN_CASE_INTFC__c = 'test1';
            cs1.CDE_CAT_ACTIV__c = 'CMA';
            cs1.IDN_CASE_CHATS__c = sbsdcase.Id;
            cs1.DTE_BEGIN_EFFEV__c = system.today();
            cs1.DTE_END_EFFEV__c = system.today() +10;
            tanfDataList.add(cs1);
        insert tanfDataList;
        //GenericDMLHandler.updateRecords(new List<SObject>{sbsdcase}, null);
        Test.startTest();
        CaseMissingInfoTrackingBatch obj = new CaseMissingInfoTrackingBatch();
        DataBase.executeBatch(obj); 
        Test.stopTest();
    }
}