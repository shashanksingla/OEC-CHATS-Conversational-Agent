/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    T_INDIV_DISQLN__c Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class INDIVDISQLNTriggerTest {
    
	  public static testMethod void testStampSalesforceIdToExternalId(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_APPEAL__c appealObj = TestClassUtility.createAppeal(true, caseObj.Id, countyObj.Id,  providerObj.Id);
          
        Test.startTest();
        T_INDIV_DISQLN__c indivDisqlnObj = TestClassUtility.createIndivDisqln(true, appealObj.Id);
        T_INDIV_DISQLN__c indivDisqlnObjAfterInsert = [select Id,IDN_EXTNL__c from T_INDIV_DISQLN__c where Id=:indivDisqlnObj.Id];
        Test.stopTest();
        
        System.assert(indivDisqlnObjAfterInsert.IDN_EXTNL__c!=null && indivDisqlnObjAfterInsert.IDN_EXTNL__c == indivDisqlnObjAfterInsert.Id, 
                      'Salesforce ID was successfully stamped to external ID');
    }
}