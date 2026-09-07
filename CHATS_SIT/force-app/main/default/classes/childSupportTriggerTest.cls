/**********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Child Support Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class childSupportTriggerTest {
	
	public static testMethod void testStampSalesforceIdToExternalId(){
        TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        Date childBirth = System.today().addYears(-10);
        T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, childBirth, 'firstName', '1', 'lastName', '01234567', 'CC');
        Test.startTest();
        T_CHILD_SUP__c adjPayment = TestClassUtility.createChildSupport(true, indivObj.Id);
        T_CHILD_SUP__c adjPaymentAfterInsert = [select Id,IDN_EXTNL__c from T_CHILD_SUP__c where Id=:adjPayment.Id];
        Test.stopTest();
        
        System.assert(adjPaymentAfterInsert.IDN_EXTNL__c!=null && adjPaymentAfterInsert.IDN_EXTNL__c == adjPaymentAfterInsert.Id, 
                      'Salesforce ID was successfully stamped to external ID');
    }

}