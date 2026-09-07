/******************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           05-03-2024
*  @description    Reverse Ref Interface Trigger Test
*********************************************************************************************/
@isTest
public class ReverseRefInterface_Test {
    public static testMethod void testStampSalesforceIdToExternalId(){
        Test.startTest();
        Reverse_Referral_Interface_Report__c revRef = TestClassUtility.createReverseRef(true,null,null,Date.today(),'323232');
        Reverse_Referral_Interface_Report__c refAfterInsert = [select Id,IDN_EXTNL__c from Reverse_Referral_Interface_Report__c where Id=:revRef.Id];
        Test.stopTest();
        System.assert(refAfterInsert.IDN_EXTNL__c!=null && refAfterInsert.IDN_EXTNL__c == revRef.Id, 
                      'Salesforce ID was successfully stamped to external ID');
    }
}