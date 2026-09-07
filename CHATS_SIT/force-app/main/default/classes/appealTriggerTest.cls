/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Appeal Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class appealTriggerTest {
	
    public static testMethod void testStampSalesforceIdToExternalId(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        
        Test.startTest();
        T_APPEAL__c appealObj = TestClassUtility.createAppeal(true, caseObj.Id, countyObj.Id,  providerObj.Id);
        T_APPEAL__c appealObjAfterInsert = [select Id,IDN_EXTNL__c from T_APPEAL__c where Id=:appealObj.Id];
        Test.stopTest();
        
        System.assert(appealObjAfterInsert.IDN_EXTNL__c!=null && appealObjAfterInsert.IDN_EXTNL__c == appealObjAfterInsert.Id, 
                      'Salesforce ID was successfully stamped to external ID');
    }

}