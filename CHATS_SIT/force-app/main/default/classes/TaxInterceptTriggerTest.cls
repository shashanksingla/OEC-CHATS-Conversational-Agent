/*********************************************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           07/04/2023
*  @description    Tax Intercept Trigger Test
*  * Version: 1.0
*  * Date: 07/23/2023
*  * Author: Shashank S.
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class TaxInterceptTriggerTest {
    
	public static testMethod void testStampSalesforceIdToExternalId(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_ADJMT__c adjObj = TestClassUtility.createAdjustment(true, countyObj.Id, caseObj.Id, providerObj.Id);
        
        Test.startTest();
        Tax_Intercept__c tIntercept = new Tax_Intercept__c(County__c=countyObj.Id,Provider__c=providerObj.Id,Adjustment__c=adjObj.Id);
        insert tIntercept;
        Tax_Intercept__c txInterceptAfterInsert = [select Id,IDN_EXTNL__c from Tax_Intercept__c where Id=:tIntercept.Id];
        Test.stopTest();
        
        System.assert(txInterceptAfterInsert.IDN_EXTNL__c!=null && txInterceptAfterInsert.IDN_EXTNL__c == txInterceptAfterInsert.Id, 
                      'Salesforce ID was successfully stamped to external ID');
    }
    
}