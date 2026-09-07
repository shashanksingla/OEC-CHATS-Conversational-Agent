/***********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Parent Fee Delinquency Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class parentFeeDelinquencyTriggerTest {
    
    public static testMethod void testStampSalesforceIdToExternalId(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC'); 
        T_AUTH__c authObj = TestClassUtility.createAuthorization(true, System.today() - 4, System.today() - 9, countyObj.Id, providerObj.Id);
        
        Test.startTest();
        //T_COPAY_DELINQC__c parentFeeDelinq = TestClassUtility.createparentFeelDelinq(true,caseObj.Id, authObj.Id, indivObj.Id);
        T_COPAY_DELINQC__c parentFeeDelinq = new T_COPAY_DELINQC__c(IDN_CASE__c=caseObj.Id, IDN_CLIENT__c=indivObj.Id, AMT_DELINQC_COPAY_ENRLMT__c=1);
        GenericDMLHandler.insertRecords(new List<Sobject>{parentFeeDelinq},null);
        T_COPAY_DELINQC__c parentFeeDelinqAfterInsert = [select Id,IDN_EXTNL__c from T_COPAY_DELINQC__c where Id=:parentFeeDelinq.Id];
        Test.stopTest();
        
        System.assert(parentFeeDelinqAfterInsert.IDN_EXTNL__c!=null && parentFeeDelinqAfterInsert.IDN_EXTNL__c == parentFeeDelinqAfterInsert.Id, 
                      'Salesforce ID was successfully stamped to external ID');
    }
    
}