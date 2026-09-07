@isTest
private class AdjustmentServices_Test {
public static final String newRecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
       @testSetup static void setup() {
        List<T_ADJMT_RESPBL_PARTY__c> adjmtRespblPartyList = new List<T_ADJMT_RESPBL_PARTY__c>();
        List<T_ADJMT_ADDR__c> adjmtAddressList = new List<T_ADJMT_ADDR__c>();
        List<T_ADJMT_CMT__c> adjmtCmtList = new List<T_ADJMT_CMT__c>();
        List<T_ADJMT__c> adjmtList = new List<T_ADJMT__c>();
        List<T_CHATS_PROVR_STATUS__c> providerList= new List<T_CHATS_PROVR_STATUS__c>();
        
        for(Integer i=0;i<201;i++) {
            providerList.add(new T_CHATS_PROVR_STATUS__c());
        }
        
        insert providerList;
        
        for(Integer i=0;i<201;i++) {
            adjmtList.add(new T_ADJMT__c(CDE_STATUS_ADJMT__c='1',CDE_TYPE_ADJMT__c='2',CDE_TYPE_CLSFN__c='3',CDE_AGNST_ADJMT__c='1',IDN_PROVR__c=providerList[i].Id,DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8),RecordtypeId=newRecordTypeId,DTE_DISCV_ADJMT_ORIG__c=System.today()));
        }
        insert adjmtList;
        
        for(Integer i=0;i<201;i++) {
            adjmtCmtList.add(new T_ADJMT_CMT__c(TXT_SUBJ__c='subject test',IDN_ADJMT__c=adjmtList[i].Id));
        }
        insert adjmtCmtList;
        
        for(Integer i=0;i<201;i++) {
            adjmtAddressList.add(new T_ADJMT_ADDR__c(IDN_ADJMT__c=adjmtList[i].Id));
        
        }
        insert adjmtAddressList;
        
        for(Integer i=0;i<201;i++) {
            adjmtRespblPartyList.add(new T_ADJMT_RESPBL_PARTY__c(IDN_PROVR__c=providerList[i].Id,IDN_ADJMT__c=adjmtList[i].Id));
        
        }
        insert adjmtRespblPartyList;
        
    }
     
    
    static testMethod void deleteAllChildAdjustmentRecordsBulkTest() {
        List<T_ADJMT_RESPBL_PARTY__c> adjmtRespblPartyList =[select Id from T_ADJMT_RESPBL_PARTY__c Limit 202];
        List<T_ADJMT_ADDR__c> adjmtAddressList =[select Id from T_ADJMT_ADDR__c Limit 202];
        List<T_ADJMT_CMT__c> adjmtCmtList =[select Id from T_ADJMT_CMT__c Limit 202];
        List<T_ADJMT__c> adjmtList=[select Id from T_ADJMT__c Limit 202];
        
        
        system.assert(adjmtList.size()>200,'Records count mismatch');
        system.assert(adjmtCmtList.size()>200,'Records count mismatch');
        system.assert(adjmtAddressList.size()>200,'Records count mismatch');
        system.assert(adjmtRespblPartyList.size()>200,'Records count mismatch');
        
        delete adjmtList;
        
        List<T_ADJMT_RESPBL_PARTY__c> adjmtRespblPartyList2 =[select Id from T_ADJMT_RESPBL_PARTY__c Limit 202];
        List<T_ADJMT_ADDR__c> adjmtAddressList2 =[select Id from T_ADJMT_ADDR__c Limit 202];
        List<T_ADJMT_CMT__c> adjmtCmtList2 =[select Id from T_ADJMT_CMT__c Limit 202];
        List<T_ADJMT__c> adjmtList2=[select Id from T_ADJMT__c Limit 202];
        
        system.assertEquals(0,adjmtList2.size(),'Records are not deleted');
        system.assertEquals(0,adjmtCmtList2.size(),'Records are not deleted');
        system.assertEquals(0,adjmtAddressList2.size(),'Records are not deleted');
        system.assertEquals(0,adjmtRespblPartyList2.size(),'Records are not deleted');
        
        
    }


}