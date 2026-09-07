/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Payment Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class PaymentTriggerTest {
    public static testMethod void testStampSalesforceIdToExternalId(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        
        T_PAYMT__c payment = new T_PAYMT__c(CDE_COUNTY__c = countyObj.Id,
                                           	DTE_PAID_PMT__c= System.today(),
                                           	AMT_PMT__c = 22,
                                           	CDE_METHOD_PMT__c = 'EBT',
                                           	CDE_STATUS_PMT__c = '2',
                                           	IDN_PROVR__c = providerObj.Id);
        Test.startTest();
        insert payment;
        T_PAYMT__c paymentAfterInsert = [Select Id,IDN_EXTNL__c FROM T_PAYMT__c WHERE Id =:payment.Id];
        Test.stopTest();
        System.assert(paymentAfterInsert.IDN_EXTNL__c!=null && paymentAfterInsert.IDN_EXTNL__c == paymentAfterInsert.Id, 
                      'Salesforce ID was successfully stamped to external ID');
    }
}