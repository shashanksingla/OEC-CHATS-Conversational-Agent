/**********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Adjustment Responsible Party Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class adjustmentRespPartyTriggerTest {
    
	public static testMethod void testStampSalesforceIdToExternalId(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_ADJMT__c adjObj = TestClassUtility.createAdjustment(true, countyObj.Id, caseObj.Id, providerObj.Id);
        T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC');
        
        Test.startTest();
        T_ADJMT_RESPBL_PARTY__c adjRespParty = TestClassUtility.createAdjustmentRespPart(true, caseObj.Id, providerObj.id, indivObj.Id, adjObj.Id);
        T_ADJMT_RESPBL_PARTY__c adjRespPartyAfterInsert = [select Id,IDN_EXTNL__c from T_ADJMT_RESPBL_PARTY__c where Id=:adjRespParty.Id];
        Test.stopTest();
        
        System.assert(adjRespPartyAfterInsert.IDN_EXTNL__c!=null && adjRespPartyAfterInsert.IDN_EXTNL__c == adjRespPartyAfterInsert.Id, 
                      'Salesforce ID was successfully stamped to external ID');
    }
}