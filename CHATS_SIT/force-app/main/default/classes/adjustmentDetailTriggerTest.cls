/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Adjustment Detail Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class adjustmentDetailTriggerTest {

	public static testMethod void testStampSalesforceIdToExternalId(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_ADJMT__c adjObj = TestClassUtility.createAdjustment(true, countyObj.Id, caseObj.Id, providerObj.Id);
        
        Test.startTest();
        T_ADJMT_DETAIL__c adjDetail = TestClassUtility.createAdjustmentDetail(true, adjObj.Id);
        T_ADJMT_DETAIL__c adjDetailAfterInsert = [select Id,IDN_EXTNL__c from T_ADJMT_DETAIL__c where Id=:adjDetail.Id];
        Test.stopTest();
        
        System.assert(adjDetailAfterInsert.IDN_EXTNL__c!=null && adjDetailAfterInsert.IDN_EXTNL__c == adjDetailAfterInsert.Id, 
                      'Salesforce ID was successfully stamped to external ID');
    }
}