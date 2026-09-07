/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Adjustment Note Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class adjustmentCommentTriggerTest {
    
	public static testMethod void testStampSalesforceIdToExternalId(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_ADJMT__c adjObj = TestClassUtility.createAdjustment(true, countyObj.Id, caseObj.Id, providerObj.Id);
        
        Test.startTest();
        T_ADJMT_CMT__c adjNote = TestClassUtility.createAdjustmentNote(true, adjObj.Id);
        T_ADJMT_CMT__c adjNoteAfterInsert = [select Id,IDN_EXTNL__c from T_ADJMT_CMT__c where Id=:adjNote.Id];
        Test.stopTest();
        
        System.assert(adjNoteAfterInsert.IDN_EXTNL__c!=null && adjNoteAfterInsert.IDN_EXTNL__c == adjNoteAfterInsert.Id, 
                      'Salesforce ID was successfully stamped to external ID');
    }
    
}