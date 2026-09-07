/**********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Adjustment Payment Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class jobSearchTriggerTest {
    public static testMethod void testStampSalesforceIdToExternalId(){
        T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC');
        T_JOB_SEARCH__c jobsearch = new T_JOB_SEARCH__c(IDN_CLIENT__c = indivObj.Id,
                                                        DTE_BEGIN_EFFV__c = System.today(),
                                                        DTE_END_EFFV__c = System.today()+31,
                                                       	Ignore__c = true);
        Test.startTest();
        insert jobsearch;
        T_JOB_SEARCH__c jobsearchAfterInsert = [select Id,IDN_EXTNL__c from T_JOB_SEARCH__c where Id=:jobsearch.Id];
        Test.stopTest();
        System.assert(jobsearchAfterInsert.IDN_EXTNL__c!=null && jobsearchAfterInsert.IDN_EXTNL__c == jobsearchAfterInsert.Id, 'Salesforce ID was successfully stamped to external ID');
    }
}