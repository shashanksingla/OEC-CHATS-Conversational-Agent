/**********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    CW Details Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class CWDetailsTriggerTest {
    
    public static testMethod void testStampSalesforceIdToExternalId(){
        
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        TestClassUtility.createProvider(true, 'Test');
        T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC'); 
        
        T_CW_ADDNL_INFO__c cwdetails = new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseObj.Id,
                                                              IDN_CASE_REFERAL__c = 124,
                                                              IDN_CLIENT__c = indivObj.Id,
                                                              TANF_RCVNG__c = 'Y',
                                                              CDE_PROG_AREA__c = 'OTH',
                                                              DTE_BEGIN_EFFEV__c = system.today());
        
        Test.startTest();
        insert cwdetails;
        T_CW_ADDNL_INFO__c cwAfterInsert = [Select Id,IDN_EXTNL__c FROM T_CW_ADDNL_INFO__c WHERE Id = :cwdetails.Id];
        Test.stopTest();

    }
    

}