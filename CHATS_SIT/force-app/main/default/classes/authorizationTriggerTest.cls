/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Authorization Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class authorizationTriggerTest {
	
    public static testMethod void testStampSalesforceIdToExternalId(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        
        Test.startTest();
        T_AUTH__c authObj = TestClassUtility.createAuthorization(true, System.today() - 4, System.today() - 9, countyObj.Id, providerObj.Id);
        T_AUTH__c authObjAfterInsert = [select Id,IDN_EXTNL__c from T_AUTH__c where Id=:authObj.Id];
        Test.stopTest();
        
        System.assert(authObjAfterInsert.IDN_EXTNL__c!=null && authObjAfterInsert.IDN_EXTNL__c == authObjAfterInsert.Id, 
                      'Salesforce ID was successfully stamped to external ID');
    }

    @isTest
    static void testhandleUPKFieldsOnEnrollmentChange(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName', 10, true);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = new T_PROVR_FISCAL_AGREMENT__c();
        fiscalAgreement.DTE_BEGIN_AGRMT__c = System.today().addDays(-30);
        fiscalAgreement.CDE_COUNTY__c = countyObj.Id;
        fiscalAgreement.ID_SERVICE__c = providerObj.Id;
        fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c = System.today().addDays(-30);
        insert fiscalAgreement;
        T_AUTH__c authObj = new T_AUTH__c();
        authObj.DTE_BEGIN_EFFV_AUTH__c = System.today();
        authObj.DTE_END_EFFV_AUTH__c = System.today().addMonths(6);
        authObj.CDE_COUNTY__c = countyObj.Id;
        authObj.IDN_PROVR__c = providerObj.Id;
        authObj.CDE_CHILD_ENROLLED_IN_UPK__c = 'Yes';
        authObj.UPK_Awarded_Hours__c = 15;
        authObj.UPK_Start_date__c = System.today();
        authObj.Is_UPK_Stacked__c = 'Yes';
        insert authObj;
        T_AUTH__c insertedAuth = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c, UPK_Awarded_Hours__c, UPK_Start_date__c, Is_UPK_Stacked__c FROM T_AUTH__c WHERE Id = :authObj.Id];
        System.assertEquals('Yes', insertedAuth.CDE_CHILD_ENROLLED_IN_UPK__c, 'Initial UPK enrollment should be Yes');
        System.assertEquals(15, insertedAuth.UPK_Awarded_Hours__c, 'Initial UPK Awarded Hours should be 15');
        
        Test.startTest();
        authObj.CDE_CHILD_ENROLLED_IN_UPK__c = 'No';
        update authObj;
        Test.stopTest();
        
        T_AUTH__c updatedAuth = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c, UPK_Awarded_Hours__c, UPK_Start_date__c, Is_UPK_Stacked__c FROM T_AUTH__c WHERE Id = :authObj.Id];
        System.assertEquals('No', updatedAuth.CDE_CHILD_ENROLLED_IN_UPK__c, 'UPK enrollment should be No');
        System.assertEquals(null, updatedAuth.UPK_Awarded_Hours__c, 'UPK Awarded Hours should be cleared');
        System.assertEquals(null, updatedAuth.UPK_Start_date__c, 'UPK Start Date should be cleared');
        System.assertEquals('No', updatedAuth.Is_UPK_Stacked__c, 'Is UPK Stacked should be No');
    }
}