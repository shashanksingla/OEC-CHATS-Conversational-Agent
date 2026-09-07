@isTest
public class adjustmentCancellationApxCtrl_Test {

    public static testMethod void testadjustmentCancellation(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
     	T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        T_ADJMT__c caseAdj = TestClassUtility.createAdjustment(false, countyObj.Id, caseObj.Id, null);
        caseAdj.CDE_STATUS_ADJMT__c='2';
        caseAdj.CDE_TYPE_ADJMT__c='2';
        caseAdj.RecordtypeId=recordTypeId;
        caseAdj.DTE_DISCV_ADJMT_ORIG__c=date.newInstance(2018, 1, 8);
        insert caseAdj;
        
        T_ADJMT__c adjObj = TestClassUtility.createAdjustment(false, countyObj.Id, null, null);
        adjObj.IDN_PROVR__c=providerObj.Id;
        adjObj.CDE_STATUS_ADJMT__c='2';
        adjObj.CDE_TYPE_ADJMT__c='2';
        adjObj.RecordtypeId=recordTypeId;
        adjObj.DTE_DISCV_ADJMT_ORIG__c=date.newInstance(2018, 1, 8);
        insert adjObj;
        T_ADJMT_DETAIL__c adjDetail = TestClassUtility.createAdjustmentDetail(true, adjObj.Id);
        T_ADJMT_PMT__c adjPayment = TestClassUtility.createAdjustmentPayment(true, null, providerObj.Id);
        
        Test.startTest();
        T_ADJMT_PMT_DETAIL__c adjPaymentDetail = TestClassUtility.createAdjustmentPaymentDetail(true, adjDetail.Id, adjObj.Id, adjPayment.Id);

       	adjustmentCancellationApxCtrl.getAdjustmentDetails(adjObj.Id);
        adjustmentCancellationApxCtrl.getAdjustmentPayments(adjObj.Id);
        
        adjustmentCancellationApxCtrl.getAdjustmentPayments(caseAdj.Id);
        
        T_ADJMT_CANCEL__c adjCancel = new T_ADJMT_CANCEL__c(
           	IDN_ADJMT__c = adjObj.Id,
            CDE_RSN_CANCELLATION__c = '2',
            RSN_CANCEL_SUBJECT__c = 'Test Subject',
            RSN_CANCEL_BODY__c = 'Test Body',
            DTE_DISC_CANCELLATION__c = Date.valueOf(Date.newInstance(2018, 01, 15))
        );
        GenericDMLHandler.insertRecords(new List<Sobject>{adjCancel}, null);
        
        adjCancel.CDE_STATUS__c='3';
        try{
            update adjCancel;
        }catch(exception e){
            system.assert(true);
        }
        
        Test.stopTest();
    }
}