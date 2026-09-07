/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Adjustment Address Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class adjustmentAddressTriggerTest {
    
    public static testMethod void testStampSalesforceIdToExternalId(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_ADJMT__c adjObj = TestClassUtility.createAdjustment(true, countyObj.Id, caseObj.Id, providerObj.Id);
        
        Test.startTest();
        T_ADJMT_ADDR__c adjAddr = TestClassUtility.createAdjustmentAddress(true, adjObj.Id);
        T_ADJMT_ADDR__c adjAddrAfterInsert = [select Id,IDN_EXTNL__c from T_ADJMT_ADDR__c where Id=:adjAddr.Id];
        Test.stopTest();
        
        System.assert(adjAddrAfterInsert.IDN_EXTNL__c!=null && adjAddrAfterInsert.IDN_EXTNL__c == adjAddrAfterInsert.Id, 'Salesforce ID was successfully stamped to external ID');
    }

}