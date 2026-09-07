@isTest
public class OutputRollupSummaryApxCtrlTest {

    public static testMethod void testGetRollupSummaryValueCOUNT(){
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c limit 1000];
        System.assertEquals(false, counties.isEmpty(), 'counties should not be empty');
        String query = 'SELECT Id FROM T_SBSD_CASE_STATUS_MODE__c WHERE IDN_CASE__r.CDE_COUNTY__c = :recordId AND CDE_STATUS_CASE__c = \'OPN\'';
        Decimal lsr = OutputRollupSummaryApxCtrl.getRollupSummaryValue(query, 'Id', 'COUNT', counties.get(0).Id,false);
        System.debug(lsr);
       // System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
        System.assertEquals(1, lsr, 'lsr.objectDate.value should be equal to 1');
    }

    public static testMethod void testGetRollupSummaryValueMAX(){
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c limit 1000];
        System.assertEquals(false, counties.isEmpty(), 'counties should not be empty');
       //System.debug([SELECT ACTIVE_AUTH_STATUS__c FROM T_AUTH__c]);
        String query = 'SELECT AMT_ACTV_AUTH__c FROM T_AUTH__c WHERE CDE_COUNTY__c = :recordId';
        Decimal lsr = OutputRollupSummaryApxCtrl.getRollupSummaryValue(query, 'AMT_ACTV_AUTH__c', 'MAX', counties.get(0).Id,false);
        System.debug(lsr);
       
        System.assertEquals(20.00, lsr, 'value should be 20');
    }

    public static testMethod void testGetRollupSummaryValueMIN(){
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c limit 1000];
        System.assertEquals(false, counties.isEmpty(), 'counties should not be empty');
        //System.debug([SELECT ACTIVE_AUTH_STATUS__c FROM T_AUTH__c]);
        String query = 'SELECT AMT_ACTV_AUTH__c FROM T_AUTH__c WHERE CDE_COUNTY__c = :recordId';
        Decimal lsr = OutputRollupSummaryApxCtrl.getRollupSummaryValue(query, 'AMT_ACTV_AUTH__c', 'MIN', counties.get(0).Id,false);
        System.debug(lsr);
        
        System.assertEquals(10.00, lsr, 'value should be 10');
    }

    public static testMethod void testGetRollupSummaryValueSUM(){
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c limit 1000];
        System.assertEquals(false, counties.isEmpty(), 'counties should not be empty');
        //System.debug([SELECT ACTIVE_AUTH_STATUS__c FROM T_AUTH__c]);
        String query = 'SELECT AMT_ACTV_AUTH__c FROM T_AUTH__c WHERE CDE_COUNTY__c = :recordId';
        Decimal lsr = OutputRollupSummaryApxCtrl.getRollupSummaryValue(query, 'AMT_ACTV_AUTH__c', 'SUM', counties.get(0).Id,false);
        System.debug(lsr);
        
        System.assertEquals(30.00, lsr, 'value should be 30');
    }

    
    public static testMethod void testGetRollupSummaryValueException(){
        String query = 'blah blah query';
        Decimal lsr = OutputRollupSummaryApxCtrl.getRollupSummaryValue(query, 'blah blah Summarized field', 'blah blah type', 'xxxxxWrongId',false);
        System.assertEquals(0, lsr,'value should be zero');
    }
    
    @testSetup
    public static void setUpdata(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserWithPS(userProfile.Id ,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.uesername','ttes');
            
        System.runAs(user){
            T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
            T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true,countyRec.Id);
            T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(NAM_FACILITY__c = 'Provider Test', TXT_CHATS_RATING__c ='Level 1');
        	insert provider;
            T_AUTH__c authorization = TestClassUtility.createAuthorization(false, System.today()+5, System.today()-5, countyRec.Id, provider.Id);
            authorization.AMT_ACTV_AUTH__c = 10;
            T_AUTH__c authorization2 = TestClassUtility.createAuthorization(false, System.today()+5, System.today()-5, countyRec.Id, provider.Id);
            authorization2.AMT_ACTV_AUTH__c = 20;
            insert new List<SObject>{authorization, authorization2};
            insert new List<SObject>{
                new T_SBSD_CASE_STATUS_MODE__c(IDN_CASE__c = caseRec.Id, DTE_BEGIN_EFFV__c = System.today()-5, CDE_STATUS_CASE__c = 'OPN'),
                    new T_SBSD_CASE_STATUS_MODE__c(IDN_CASE__c = caseRec.Id, DTE_BEGIN_EFFV__c = System.today()-5, DTE_END_EFFV__c = System.today()-2, CDE_STATUS_CASE__c = 'CLS')
                };
        }
    }
}