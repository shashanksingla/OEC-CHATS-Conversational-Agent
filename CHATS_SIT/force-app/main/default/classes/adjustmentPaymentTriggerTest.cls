/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Adjustment Payment Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class adjustmentPaymentTriggerTest {
    
    public static testMethod void testMethod1(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 16, false);
        Insert countyRec;
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_CHATS_PROVR_STATUS__c provRec = TestClassUtility.createProvider(true, 'Test');
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        
        T_ADJMT__c adj1 = new T_ADJMT__c(RecordtypeId = recordTypeId, CDE_STATUS_ADJMT__c = '2', CDE_TYPE_ADJMT__c = '2', CDE_TYPE_CLSFN__c = '3',
                                          CDE_AGNST_ADJMT__c = '1', IDN_CASE__c = caseRec.Id, DTE_END_ADJMT__c = System.today(),
                                          DTE_START_ADJMT__c = System.today(), DTE_DISCV_ADJMT_ORIG__c = System.today(), CDE_COUNTY__c = countyRec.Id);
        Insert adj1;
        T_ADJMT__c adj2 = new T_ADJMT__c(RecordtypeId = recordTypeId, CDE_STATUS_ADJMT__c = '2', CDE_TYPE_ADJMT__c = '2', CDE_TYPE_CLSFN__c = '3',
                                          CDE_AGNST_ADJMT__c = '1', IDN_PROVR__c = provRec.Id, DTE_END_ADJMT__c = System.today(),
                                          DTE_START_ADJMT__c = System.today(), DTE_DISCV_ADJMT_ORIG__c = System.today(), CDE_COUNTY__c = countyRec.Id);
        Insert adj2;
        
        T_ADJMT_DETAIL__c adjDet1 = TestClassUtility.createAdjustmentDetail(false, adj1.Id);
        adjDet1.AMT_DETAIL_ADJMT__c = 1000;
        Insert adjDet1;
        T_ADJMT_DETAIL__c adjDet2 = TestClassUtility.createAdjustmentDetail(false, adj2.Id);
        adjDet2.AMT_DETAIL_ADJMT__c = 100;
        Insert adjDet2;
        
        T_NON_ADJMT_DETAIL__c nonAdjDet1 = new T_NON_ADJMT_DETAIL__c(IDN_ADJMT__c = adj1.Id);
        T_NON_ADJMT_DETAIL__c nonAdjDet2 = new T_NON_ADJMT_DETAIL__c(IDN_ADJMT__c = adj2.Id);
        
        T_ADJMT_PMT__c adjPmtOld1 = TestClassUtility.createAdjustmentPayment(true, caseRec.Id, null);
        T_ADJMT_PMT__c adjPmtOld2 = TestClassUtility.createAdjustmentPayment(true, null, provRec.Id);
        
        List<T_ADJMT_PMT_DETAIL__c> adjPmtDetList = new List<T_ADJMT_PMT_DETAIL__c>();
        T_ADJMT_PMT_DETAIL__c  adjPmtDet1 = TestClassUtility.createAdjustmentPaymentDetail(false, adjDet1.Id, adj1.Id, adjPmtOld1.Id);
        adjPmtDet1.AMT_PMT_DETAIL_ADJMT__c = 500;
        adjPmtDetList.add(adjPmtDet1);
        T_ADJMT_PMT_DETAIL__c  adjPmtDet2 = TestClassUtility.createAdjustmentPaymentDetail(false, adjDet2.Id, adj2.Id, adjPmtOld2.Id);
        adjPmtDet2.AMT_PMT_DETAIL_ADJMT__c = 90;
        adjPmtDetList.add(adjPmtDet2);
        Insert adjPmtDetList;
        
        Test.startTest();
        List<T_ADJMT_PMT__c> adjPmtList = new List<T_ADJMT_PMT__c>();
        T_ADJMT_PMT__c adjPmt1 = new T_ADJMT_PMT__c();
        adjPmt1.IDN_CASE__c = caseRec.Id; adjPmt1.AMT_PMT_ADJMT__c = 100; adjPmt1.CDE_TYPE_PMT_ADJMT__c = '1';
        adjPmt1.DTE_PMT_ADJMT__c = System.today(); adjPmt1.CDE_COUNTY__c = '16'; adjPmt1.AMT_PMT_SRPLUS_ADJMT__c = 1;
        adjPmtList.add(adjPmt1); // Case Type
        T_ADJMT_PMT__c adjPmt2 = new T_ADJMT_PMT__c();
        adjPmt2.IDN_PROVR__c = provRec.Id; adjPmt2.AMT_PMT_ADJMT__c = 20; adjPmt2.CDE_TYPE_PMT_ADJMT__c = '1';
        adjPmt2.DTE_PMT_ADJMT__c = System.today(); adjPmt2.CDE_COUNTY__c = '16'; adjPmt2.AMT_PMT_SRPLUS_ADJMT__c = 1;
        adjPmtList.add(adjPmt2); // Provider Type
        Insert adjPmtList;
        AdjustmentPaymentServices.validationForSurplusAmount(adjPmtList);
        Test.stopTest();
    }
    
    public static testMethod void testMethod2(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 16, false);
        Insert countyRec;
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        
        T_ADJMT__c adj1 = new T_ADJMT__c(RecordtypeId = recordTypeId, CDE_STATUS_ADJMT__c = '2', CDE_TYPE_ADJMT__c = '2', CDE_TYPE_CLSFN__c = '3',
                                          CDE_AGNST_ADJMT__c = '1', IDN_CASE__c = caseRec.Id, DTE_END_ADJMT__c = System.today(),
                                          DTE_START_ADJMT__c = System.today(), DTE_DISCV_ADJMT_ORIG__c = System.today(), CDE_COUNTY__c = countyRec.Id);
        Insert adj1;

        T_NON_ADJMT_DETAIL__c nonAdjDet1 = new T_NON_ADJMT_DETAIL__c(IDN_ADJMT__c = adj1.Id, AMT_DETAIL_ADJMT__c = 100);
        Insert nonAdjDet1;
        
        T_ADJMT_PMT__c adjPmtOld1 = TestClassUtility.createAdjustmentPayment(true, caseRec.Id, null);

        Test.startTest();
        List<T_ADJMT_PMT__c> adjPmtList = new List<T_ADJMT_PMT__c>();
        T_ADJMT_PMT__c adjPmt1 = new T_ADJMT_PMT__c();
        adjPmt1.IDN_CASE__c = caseRec.Id; adjPmt1.AMT_PMT_ADJMT__c = 200; adjPmt1.CDE_TYPE_PMT_ADJMT__c = '1';
        adjPmt1.DTE_PMT_ADJMT__c = System.today(); adjPmt1.CDE_COUNTY__c = '16'; adjPmt1.AMT_PMT_SRPLUS_ADJMT__c = 1;
        adjPmtList.add(adjPmt1); // Case Type
        Insert adjPmtList;
        AdjustmentPaymentServices.validationForSurplusAmount(adjPmtList);
        Test.stopTest();
    }
}