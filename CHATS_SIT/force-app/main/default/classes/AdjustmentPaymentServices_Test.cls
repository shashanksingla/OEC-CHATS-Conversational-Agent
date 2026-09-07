@isTest
private class AdjustmentPaymentServices_Test {
    
    static testMethod void testCreateAdjustmentPaymentDetails() {
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        
        List<T_ADJMT__c> adjustmentList= new List<T_ADJMT__c>();
        adjustmentList.add( new T_ADJMT__c(RecordtypeId=recordTypeId,CDE_STATUS_ADJMT__c='2',CDE_TYPE_ADJMT__c='2',CDE_TYPE_CLSFN__c='3',CDE_AGNST_ADJMT__c='1',IDN_PROVR__c=provider.Id,DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8),DTE_DISCV_ADJMT_ORIG__c=date.newInstance(2018, 1, 8)));
        adjustmentList.add( new T_ADJMT__c(RecordtypeId=recordTypeId,CDE_STATUS_ADJMT__c='2',CDE_TYPE_ADJMT__c='2',CDE_TYPE_CLSFN__c='1',CDE_AGNST_ADJMT__c='2',IDN_PROVR__c=provider.Id,DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8),DTE_DISCV_ADJMT_ORIG__c=date.newInstance(2018, 1, 8)));
        adjustmentList.add( new T_ADJMT__c(RecordtypeId=recordTypeId,CDE_STATUS_ADJMT__c='2',CDE_TYPE_ADJMT__c='2',CDE_TYPE_CLSFN__c='1',CDE_AGNST_ADJMT__c='2',IDN_PROVR__c=provider.Id,DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8),DTE_DISCV_ADJMT_ORIG__c=date.newInstance(2018, 1, 8)));
        insert adjustmentList;
        
        List<T_ADJMT_DETAIL__c> adjustDetailList = new List<T_ADJMT_DETAIL__c>();
        adjustDetailList.add(new T_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=100,IDN_ADJMT__c=adjustmentList[0].Id));
        adjustDetailList.add(new T_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=200,IDN_ADJMT__c=adjustmentList[0].Id));
        adjustDetailList.add(new T_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=300,IDN_ADJMT__c=adjustmentList[0].Id));
        insert adjustDetailList;
        
        List<T_NON_ADJMT_DETAIL__c> nonAdjustDetailList = new List<T_NON_ADJMT_DETAIL__c>();
        nonAdjustDetailList.add(new T_NON_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=100,IDN_ADJMT__c=adjustmentList[1].Id));
        nonAdjustDetailList.add(new T_NON_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=200,IDN_ADJMT__c=adjustmentList[1].Id));
        nonAdjustDetailList.add(new T_NON_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=300,IDN_ADJMT__c=adjustmentList[1].Id));
        nonAdjustDetailList.add(new T_NON_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=10,IDN_ADJMT__c=adjustmentList[2].Id));
        insert nonAdjustDetailList;
        
        Test.startTest();
        
        T_ADJMT_PMT__c adjustmentPayment = new T_ADJMT_PMT__c(CDE_TYPE_PMT_ADJMT__c='1',AMT_PMT_ADJMT__c=600,IDN_PROVR__c=provider.Id,DTE_PMT_ADJMT__c=System.Today());
        insert adjustmentPayment;
        
        for(T_ADJMT_PMT_DETAIL__c adjutPaymDet:[Select Id,IDN_DETAIL_ADJMT_NON__r.AMT_DETAIL_ADJMT__c,IDN_DETAIL_ADJMT_NON__r.IDN_ADJMT__c,IDN_DETAIL_ADJMT_NON__r.CDE_STATUS_DETAIL_ADJMT__c, IDN_ADJMT__c,IDN_DETAIL_ADJMT_NON__c,IDN_PMT_ADJMT__c,AMT_PMT_DETAIL_ADJMT__c from T_ADJMT_PMT_DETAIL__c where IDN_PMT_ADJMT__c=:adjustmentPayment.Id and IDN_ADJMT__c=:adjustmentList[1].Id]) {
            system.assertEquals(adjutPaymDet.AMT_PMT_DETAIL_ADJMT__c,adjutPaymDet.IDN_DETAIL_ADJMT_NON__r.AMT_DETAIL_ADJMT__c,'Amount mismatch');
            system.assertEquals(adjutPaymDet.IDN_DETAIL_ADJMT_NON__r.IDN_ADJMT__c,adjutPaymDet.IDN_ADJMT__c,'Adjustment not Properly assigned');
            system.assertEquals(adjutPaymDet.IDN_DETAIL_ADJMT_NON__r.CDE_STATUS_DETAIL_ADJMT__c,'3','Status not changed to Satisfied');
        }
        system.assertEquals('2',[select CDE_STATUS_ADJMT__c from T_ADJMT__c where Id=:adjustmentList[1].Id Limit 1].CDE_STATUS_ADJMT__c ,'Adjustment not Satisfied');
        
        T_ADJMT_PMT__c adjustmentPayment2 = new T_ADJMT_PMT__c(CDE_TYPE_PMT_ADJMT__c='1',AMT_PMT_ADJMT__c=650,IDN_PROVR__c=provider.Id,DTE_PMT_ADJMT__c=System.Today());
        insert adjustmentPayment2;
        
        for(T_ADJMT_PMT_DETAIL__c adjutPaymDet:[Select Id,IDN_DETAIL_ADJMT__r.AMT_DETAIL_ADJMT__c,IDN_DETAIL_ADJMT__r.IDN_ADJMT__c,IDN_DETAIL_ADJMT__r.CDE_STATUS_DETAIL_ADJMT__c, IDN_ADJMT__c,IDN_DETAIL_ADJMT__c,IDN_PMT_ADJMT__c,AMT_PMT_DETAIL_ADJMT__c from T_ADJMT_PMT_DETAIL__c where IDN_PMT_ADJMT__c=:adjustmentPayment.Id and IDN_ADJMT__c=:adjustmentList[0].Id]) {
            system.assertEquals(adjutPaymDet.AMT_PMT_DETAIL_ADJMT__c,adjutPaymDet.IDN_DETAIL_ADJMT__r.AMT_DETAIL_ADJMT__c,'Amount mismatch');
            system.assertEquals(adjutPaymDet.IDN_DETAIL_ADJMT__r.IDN_ADJMT__c,adjutPaymDet.IDN_ADJMT__c,'Adjustment not Properly assigned');
            system.assertEquals(adjutPaymDet.IDN_DETAIL_ADJMT__r.CDE_STATUS_DETAIL_ADJMT__c,'3','Status not changed to Satisfied');
        }
        system.assertEquals('2',[select CDE_STATUS_ADJMT__c from T_ADJMT__c where Id=:adjustmentList[0].Id Limit 1].CDE_STATUS_ADJMT__c ,'Adjustment not Satisfied');
        // system.assertEquals(40,[Select AMT_PMT_SRPLUS_ADJMT__c from T_ADJMT_PMT__c where Id=:adjustmentPayment2.Id].AMT_PMT_SRPLUS_ADJMT__c, 'Surplus amount is not adjusted');
        Test.StopTest();
    }
    
    static testMethod void testCreateAdjustmentPaymentDetails2() {
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        
        List<T_ADJMT__c> adjustmentList= new List<T_ADJMT__c>();
        adjustmentList.add( new T_ADJMT__c(RecordtypeId=recordTypeId,CDE_STATUS_ADJMT__c='2',CDE_TYPE_ADJMT__c='2',CDE_TYPE_CLSFN__c='3',CDE_AGNST_ADJMT__c='1',IDN_PROVR__c=provider.Id,DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8),DTE_DISCV_ADJMT_ORIG__c=date.newInstance(2018, 1, 8)));
        adjustmentList.add( new T_ADJMT__c(RecordtypeId=recordTypeId,CDE_STATUS_ADJMT__c='2',CDE_TYPE_ADJMT__c='2',CDE_TYPE_CLSFN__c='1',CDE_AGNST_ADJMT__c='2',IDN_PROVR__c=provider.Id,DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8),DTE_DISCV_ADJMT_ORIG__c=date.newInstance(2018, 1, 8)));
        insert adjustmentList;
        
        List<T_ADJMT_DETAIL__c> adjustDetailList = new List<T_ADJMT_DETAIL__c>();
        adjustDetailList.add(new T_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=100,IDN_ADJMT__c=adjustmentList[0].Id));
        adjustDetailList.add(new T_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=200,IDN_ADJMT__c=adjustmentList[0].Id));
        adjustDetailList.add(new T_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=300,IDN_ADJMT__c=adjustmentList[0].Id));
        insert adjustDetailList;
        
        List<T_NON_ADJMT_DETAIL__c> nonAdjustDetailList = new List<T_NON_ADJMT_DETAIL__c>();
        nonAdjustDetailList.add(new T_NON_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=100,IDN_ADJMT__c=adjustmentList[1].Id));
        nonAdjustDetailList.add(new T_NON_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=200,IDN_ADJMT__c=adjustmentList[1].Id));
        nonAdjustDetailList.add(new T_NON_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=300,IDN_ADJMT__c=adjustmentList[1].Id));
        insert nonAdjustDetailList;
        
        Test.startTest();
        
        T_ADJMT_PMT__c adjustmentPayment = new T_ADJMT_PMT__c(CDE_TYPE_PMT_ADJMT__c='1',AMT_PMT_ADJMT__c=400,IDN_PROVR__c=provider.Id,DTE_PMT_ADJMT__c=System.Today());
        insert adjustmentPayment;
        T_ADJMT_PMT__c adjustmentPayment2 = new T_ADJMT_PMT__c(CDE_TYPE_PMT_ADJMT__c='1',AMT_PMT_ADJMT__c=200,IDN_PROVR__c=provider.Id,DTE_PMT_ADJMT__c=System.Today());
        insert adjustmentPayment2;
        
        for(T_ADJMT_PMT_DETAIL__c adjutPaymDet:[Select Id,IDN_DETAIL_ADJMT_NON__r.AMT_DETAIL_ADJMT__c,IDN_DETAIL_ADJMT_NON__r.IDN_ADJMT__c,IDN_DETAIL_ADJMT_NON__r.CDE_STATUS_DETAIL_ADJMT__c, IDN_ADJMT__c,IDN_DETAIL_ADJMT_NON__c,IDN_PMT_ADJMT__c,AMT_PMT_DETAIL_ADJMT__c from T_ADJMT_PMT_DETAIL__c where IDN_ADJMT__c=:adjustmentList[1].Id]) {
            system.assert(adjutPaymDet.AMT_PMT_DETAIL_ADJMT__c<=adjutPaymDet.IDN_DETAIL_ADJMT_NON__r.AMT_DETAIL_ADJMT__c,'Amount mismatch');
            system.assertEquals(adjutPaymDet.IDN_DETAIL_ADJMT_NON__r.IDN_ADJMT__c,adjutPaymDet.IDN_ADJMT__c,'Adjustment not Properly assigned');
            system.assertEquals(adjutPaymDet.IDN_DETAIL_ADJMT_NON__r.CDE_STATUS_DETAIL_ADJMT__c,'3','Status not changed to Satisfied');
        }
        system.assertEquals('2',[select CDE_STATUS_ADJMT__c from T_ADJMT__c where Id=:adjustmentList[1].Id Limit 1].CDE_STATUS_ADJMT__c ,'Adjustment not Satisfied');
        
        T_ADJMT_PMT__c adjustmentPayment3 = new T_ADJMT_PMT__c( CDE_TYPE_PMT_ADJMT__c='1',AMT_PMT_ADJMT__c=200,IDN_PROVR__c=provider.Id,DTE_PMT_ADJMT__c=System.Today());
        insert adjustmentPayment3;
        
        T_ADJMT_PMT__c adjustmentPayment4 = new T_ADJMT_PMT__c( CDE_TYPE_PMT_ADJMT__c='1',AMT_PMT_ADJMT__c=400,IDN_PROVR__c=provider.Id,DTE_PMT_ADJMT__c=System.Today());
        insert adjustmentPayment4;
        
        for(T_ADJMT_PMT_DETAIL__c adjutPaymDet:[Select Id,IDN_DETAIL_ADJMT__r.AMT_DETAIL_ADJMT__c,IDN_DETAIL_ADJMT__r.IDN_ADJMT__c,IDN_DETAIL_ADJMT__r.CDE_STATUS_DETAIL_ADJMT__c, IDN_ADJMT__c,IDN_DETAIL_ADJMT__c,IDN_PMT_ADJMT__c,AMT_PMT_DETAIL_ADJMT__c from T_ADJMT_PMT_DETAIL__c where IDN_ADJMT__c=:adjustmentList[0].Id]) {
            system.assert(adjutPaymDet.AMT_PMT_DETAIL_ADJMT__c<=adjutPaymDet.IDN_DETAIL_ADJMT__r.AMT_DETAIL_ADJMT__c,'Amount mismatch');
            system.assertEquals(adjutPaymDet.IDN_DETAIL_ADJMT__r.IDN_ADJMT__c,adjutPaymDet.IDN_ADJMT__c,'Adjustment not Properly assigned');
            system.assertEquals(adjutPaymDet.IDN_DETAIL_ADJMT__r.CDE_STATUS_DETAIL_ADJMT__c,'3','Status not changed to Satisfied');
        }
        system.assertEquals('2',[select CDE_STATUS_ADJMT__c from T_ADJMT__c where Id=:adjustmentList[0].Id Limit 1].CDE_STATUS_ADJMT__c ,'Adjustment not Satisfied');
        
        Test.StopTest();
    }
    
    static testMethod void testCreateAdjustmentPaymentDetailsonCase() {
        T_COUNTY__c countyObj =  new T_COUNTY__c (CNTY_DEPT_NAME__c = 'Arapahoe County', CDE_COUNTY__c = 3);
        insert countyObj;
        T_SBSD_CASE__c caseObj = new T_SBSD_CASE__c (CDE_COUNTY__c = countyObj.Id, IND_ASSIST_PROVR__c = 'N', CDE_ASST_HSNG__c = 'N');
        insert caseObj;
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        
        List<T_ADJMT__c> adjustmentList= new List<T_ADJMT__c>();
        adjustmentList.add( new T_ADJMT__c(RecordtypeId=recordTypeId,CDE_STATUS_ADJMT__c='2',CDE_TYPE_ADJMT__c='2',CDE_TYPE_CLSFN__c='3',CDE_AGNST_ADJMT__c='1',IDN_CASE__c=caseObj.Id,DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8),DTE_DISCV_ADJMT_ORIG__c=date.newInstance(2018, 1, 8)));
        adjustmentList.add( new T_ADJMT__c(RecordtypeId=recordTypeId,CDE_STATUS_ADJMT__c='2',CDE_TYPE_ADJMT__c='2',CDE_TYPE_CLSFN__c='1',CDE_AGNST_ADJMT__c='2',IDN_CASE__c=caseObj.Id,DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8),DTE_DISCV_ADJMT_ORIG__c=date.newInstance(2018, 1, 8)));
        adjustmentList.add( new T_ADJMT__c(RecordtypeId=recordTypeId,CDE_STATUS_ADJMT__c='2',CDE_TYPE_ADJMT__c='2',CDE_TYPE_CLSFN__c='1',CDE_AGNST_ADJMT__c='2',IDN_CASE__c=caseObj.Id,DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8),DTE_DISCV_ADJMT_ORIG__c=date.newInstance(2018, 1, 8)));
        insert adjustmentList;
        
        List<T_ADJMT_DETAIL__c> adjustDetailList = new List<T_ADJMT_DETAIL__c>();
        adjustDetailList.add(new T_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=100,IDN_ADJMT__c=adjustmentList[0].Id));
        adjustDetailList.add(new T_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=200,IDN_ADJMT__c=adjustmentList[0].Id));
        adjustDetailList.add(new T_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=300,IDN_ADJMT__c=adjustmentList[0].Id));
        insert adjustDetailList;
        
        List<T_NON_ADJMT_DETAIL__c> nonAdjustDetailList = new List<T_NON_ADJMT_DETAIL__c>();
        nonAdjustDetailList.add(new T_NON_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=100,IDN_ADJMT__c=adjustmentList[1].Id));
        nonAdjustDetailList.add(new T_NON_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=200,IDN_ADJMT__c=adjustmentList[1].Id));
        nonAdjustDetailList.add(new T_NON_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=300,IDN_ADJMT__c=adjustmentList[1].Id));
        nonAdjustDetailList.add(new T_NON_ADJMT_DETAIL__c(AMT_DETAIL_ADJMT__c=10,IDN_ADJMT__c=adjustmentList[2].Id));
        insert nonAdjustDetailList;
        
        Test.startTest();
        
        T_ADJMT_PMT__c adjustmentPayment = new T_ADJMT_PMT__c( CDE_TYPE_PMT_ADJMT__c='1',AMT_PMT_ADJMT__c=600,IDN_CASE__c=caseObj.Id,DTE_PMT_ADJMT__c=System.Today());
        insert adjustmentPayment;
        
        for(T_ADJMT_PMT_DETAIL__c adjutPaymDet:[Select Id,IDN_DETAIL_ADJMT_NON__r.AMT_DETAIL_ADJMT__c,IDN_DETAIL_ADJMT_NON__r.IDN_ADJMT__c,IDN_DETAIL_ADJMT_NON__r.CDE_STATUS_DETAIL_ADJMT__c, IDN_ADJMT__c,IDN_DETAIL_ADJMT_NON__c,IDN_PMT_ADJMT__c,AMT_PMT_DETAIL_ADJMT__c from T_ADJMT_PMT_DETAIL__c where IDN_PMT_ADJMT__c=:adjustmentPayment.Id and IDN_ADJMT__c=:adjustmentList[1].Id]) {
            system.assertEquals(adjutPaymDet.AMT_PMT_DETAIL_ADJMT__c,adjutPaymDet.IDN_DETAIL_ADJMT_NON__r.AMT_DETAIL_ADJMT__c,'Amount mismatch');
            system.assertEquals(adjutPaymDet.IDN_DETAIL_ADJMT_NON__r.IDN_ADJMT__c,adjutPaymDet.IDN_ADJMT__c,'Adjustment not Properly assigned');
            system.assertEquals(adjutPaymDet.IDN_DETAIL_ADJMT_NON__r.CDE_STATUS_DETAIL_ADJMT__c,'3','Status not changed to Satisfied');
        }
        system.assertEquals('2',[select CDE_STATUS_ADJMT__c from T_ADJMT__c where Id=:adjustmentList[1].Id Limit 1].CDE_STATUS_ADJMT__c ,'Adjustment not Satisfied');
        
        T_ADJMT_PMT__c adjustmentPayment2 = new T_ADJMT_PMT__c( CDE_TYPE_PMT_ADJMT__c='1',AMT_PMT_ADJMT__c=650,IDN_CASE__c=caseObj.Id,DTE_PMT_ADJMT__c=System.Today());
        insert adjustmentPayment2;
        
        for(T_ADJMT_PMT_DETAIL__c adjutPaymDet:[Select Id,IDN_DETAIL_ADJMT__r.AMT_DETAIL_ADJMT__c,IDN_DETAIL_ADJMT__r.IDN_ADJMT__c,IDN_DETAIL_ADJMT__r.CDE_STATUS_DETAIL_ADJMT__c, IDN_ADJMT__c,IDN_DETAIL_ADJMT__c,IDN_PMT_ADJMT__c,AMT_PMT_DETAIL_ADJMT__c from T_ADJMT_PMT_DETAIL__c where IDN_PMT_ADJMT__c=:adjustmentPayment.Id and IDN_ADJMT__c=:adjustmentList[0].Id]) {
            system.assertEquals(adjutPaymDet.AMT_PMT_DETAIL_ADJMT__c,adjutPaymDet.IDN_DETAIL_ADJMT__r.AMT_DETAIL_ADJMT__c,'Amount mismatch');
            system.assertEquals(adjutPaymDet.IDN_DETAIL_ADJMT__r.IDN_ADJMT__c,adjutPaymDet.IDN_ADJMT__c,'Adjustment not Properly assigned');
            system.assertEquals(adjutPaymDet.IDN_DETAIL_ADJMT__r.CDE_STATUS_DETAIL_ADJMT__c,'3','Status not changed to Satisfied');
        }
        system.assertEquals('2',[select CDE_STATUS_ADJMT__c from T_ADJMT__c where Id=:adjustmentList[0].Id Limit 1].CDE_STATUS_ADJMT__c ,'Adjustment not Satisfied');
        // system.assertEquals(40,[Select AMT_PMT_SRPLUS_ADJMT__c from T_ADJMT_PMT__c where Id=:adjustmentPayment2.Id].AMT_PMT_SRPLUS_ADJMT__c, 'Surplus amount is not adjusted');
        Test.StopTest();
    }
}