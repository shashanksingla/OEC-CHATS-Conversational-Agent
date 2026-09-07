/***********************************************************
*  @author         Deloitte Consulting LLP.
*  @date           02/17/2018
*  @description    Adjustment Payment Detail Trigger Test
*  * Version: 1.0
*  * Date: 02/17/2018
*  * Author: Gaurav Dharra
*  * Description: Initial version
***********************************************************/
@isTest
public class adjustmentPaymentDetailTriggerTest {

    public static testMethod void testStampSalesforceIdToExternalId(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('Denver', 'Denver', 16, false);
        Insert countyObj;
        TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        T_ADJMT__c adjObj = TestClassUtility.createAdjustment(false, countyObj.Id, null, null);
        adjObj.IDN_PROVR__c = providerObj.Id;
        adjObj.CDE_STATUS_ADJMT__c = '2';
        adjObj.CDE_TYPE_ADJMT__c = '2';
        adjObj.RecordtypeId = recordTypeId;
        adjObj.DTE_DISCV_ADJMT_ORIG__c = System.today();
        insert adjObj;
        T_ADJMT_DETAIL__c adjDetail = TestClassUtility.createAdjustmentDetail(false, adjObj.Id);
        adjDetail.AMT_DETAIL_ADJMT__c = 10;
        T_ADJMT_PMT__c adjPayment = TestClassUtility.createAdjustmentPayment(false, null, providerObj.Id);
        Insert adjPayment;
        Tax_Intercept__c ti = new Tax_Intercept__c(Adjustment__c = adjObj.Id);
        Insert ti;
        Test.startTest();
        List<T_ADJMT_PMT_DETAIL__c> adjPmtDetList = new List<T_ADJMT_PMT_DETAIL__c>();
        T_ADJMT_PMT_DETAIL__c adjPmtDet1 = TestClassUtility.createAdjustmentPaymentDetail(false, adjDetail.Id, adjObj.Id, adjPayment.Id);
        adjPmtDet1.IDN_ADJMT__c = adjObj.Id;
        adjPmtDet1.CDE_STATUS_DETAIL_PMT_ADJMT__c = '4';
        adjPmtDet1.AMT_PMT_DETAIL_ADJMT__c = 10;
        adjPmtDetList.add(adjPmtDet1);
        T_ADJMT_PMT_DETAIL__c adjPmtDet2 = TestClassUtility.createAdjustmentPaymentDetail(false, adjDetail.Id, adjObj.Id, adjPayment.Id);
        adjPmtDet2.IDN_ADJMT__c = adjObj.Id;
        adjPmtDet2.CDE_STATUS_DETAIL_PMT_ADJMT__c = '4';
        adjPmtDet2.AMT_PMT_DETAIL_ADJMT__c = 5;
        adjPmtDetList.add(adjPmtDet2);
        Insert adjPmtDetList;
        Test.stopTest();
    }
}