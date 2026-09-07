/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Non Adjustment Detail Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class nonAdjustmentDetailTriggerTest {
    
    public static testMethod void testStampSalesforceIdToExternalId(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_ADJMT__c adjObj = TestClassUtility.createAdjustment(true, countyObj.Id, caseObj.Id, providerObj.Id);
        T_AUTH__c auth = TestClassUtility.createAuthorization(true, System.today()+31, System.today(), String.valueOf(countyObj.Id), String.valueOf(providerObj.Id));
        
        
        T_NON_ADJMT_DETAIL__c nonAdjusment = new T_NON_ADJMT_DETAIL__c(IDN_ADJMT__c = adjObj.Id,
                                                                      AMT_DETAIL_ADJMT__c = 22,
                                                                      IDN_AUTH__c = auth.Id);
        Test.startTest();
        insert nonAdjusment;
        T_NON_ADJMT_DETAIL__c adjDetailAfterInsert = [select Id,IDN_EXTNL__c from T_NON_ADJMT_DETAIL__c where Id=:nonAdjusment.Id];
        Test.stopTest();
        
        System.assert(adjDetailAfterInsert.IDN_EXTNL__c!=null && adjDetailAfterInsert.IDN_EXTNL__c == adjDetailAfterInsert.Id, 
                      'Salesforce ID was successfully stamped to external ID');
    }
}