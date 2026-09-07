/******************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           05-03-2024
*  @description    CBMS Reverse Snapshot Batch Test
*********************************************************************************************/
@isTest
public class CBMSReverseRefSnapshotBatch_Test {
    public static testMethod void testCBMSSnapshotBatch(){
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(false,county.Id);
        
        sbsdcase.program_type__c = 'LI';
        upsert sbsdcase;
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        Date begindate = date.newInstance(date.today().year(),date.today().month(),1);
        begindate = begindate.addDays(25);
        //Removed unused variable on 5/13/2018 BG        
        Date enddate = begindate.addDays(20);
        
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c=sbsdcase.Id;
        authorization.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization.CDE_TYPE_VERIF__c = 'NA';
        authorization.CDE_SOURCE_VRFYD_IMMU__c ='PRO';
        authorization.CDE_IMM__c ='NRL';
        insert authorization;
        T_SBSD_CASE_STATUS_MODE__c caseStaMod = TestClassUtility.createCaseStatusMode(true, sbsdcase.Id);
        Test.startTest();	
        
        Database.executeBatch(new CBMSReverseRefSnapshotBatch(),200);
        Test.stopTest();
    }
}