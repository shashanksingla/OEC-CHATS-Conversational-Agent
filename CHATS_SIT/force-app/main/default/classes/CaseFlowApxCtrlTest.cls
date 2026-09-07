@isTest
public class CaseFlowApxCtrlTest {
    public static testMethod void testHandleCaseRelatedRecords(){
        // To cover the try-catch scenario
        LightningServerResponse lsr = CaseFlowApxCtrl.handleCaseRelatedRecords(null, null,false,null);   
        
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.DTE_APPLN__c = System.today().addDays(-10);
        insert caseRec;
        T_SBSD_CASE_INFO__c caseEMInfoRec = new T_SBSD_CASE_INFO__c(
                             CDE_TYPE_INFO_CASE__c = 'EM',
                             IDN_CASE__c = caseRec.Id
        );
        lsr = CaseFlowApxCtrl.handleCaseRelatedRecords(new List<SObject>{caseEMInfoRec}, caseRec,false,null);        
        System.assertEquals(true, lsr.isSuccessful, 'isSuccessful should be true');
        caseEMInfoRec.TXT_VALUE_INFO_CASE__c = 'test@example.com';
        lsr = CaseFlowApxCtrl.handleCaseRelatedRecords(new List<SObject>{caseEMInfoRec}, caseRec,false,null);                
        //System.assertEquals(true, lsr.isSuccessful, 'isSuccessful should be true');
        List<T_SBSD_CASE_INFO__c> caseInfos = [SELECT Id FROM T_SBSD_CASE_INFO__c limit 100];
        //System.assertEquals(false, caseInfos.isEmpty(), 'caseInfos should be empty');
        T_SBSD_CASE_INFO__c casePMCInfoRec = new T_SBSD_CASE_INFO__c(
                             CDE_TYPE_INFO_CASE__c = 'PMC',
                             IDN_CASE__c = caseRec.Id,
                             TXT_VALUE_INFO_CASE__c = 'Email'
        );
        lsr = CaseFlowApxCtrl.handleCaseRelatedRecords(new List<SObject>{casePMCInfoRec, caseEMInfoRec}, caseRec,false,null);
        System.debug(lsr);
        //System.assertEquals(true, lsr.isSuccessful, 'isSuccessful should be true');
        //caseInfos = [SELECT Id FROM T_SBSD_CASE_INFO__c];
        //System.assertEquals(2, caseInfos.size(), 'caseInfos.size() should be 2');
    }
    
    public static testMethod void testCheckCountyWithUserCounty(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            insert user; 
        }
        System.runAs(user){
            T_COUNTY__c countyRec = TestClassUtility.createCounty('Adams','Adams',2,true);
            LightningServerResponse lsr = CaseFlowApxCtrl.checkCountyWithUserCounty(countyRec.Id);
            System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
        }
    }
    
    public static testMethod void testGetCaseName(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.DTE_APPLN__c = System.today().addDays(-10);
        insert caseRec;
        List<T_SBSD_CASE__c> testCases = [SELECT Name FROM T_SBSD_CASE__c WHERE Id =:caseRec.Id];
    	System.assertEquals(false, testCases.isEmpty(), 'testCases should not be empty');
        LightningServerResponse lsr = CaseFlowApxCtrl.getCaseName(caseRec.Id);
        System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be successful');
        System.assertEquals(true, lsr.objectData!=null, 'lsr.objectData should not be null');
        System.assertEquals(testCases.get(0).Name, lsr.objectData.get('caseName'), 'name should match');
    }    
    
    
    public static testMethod void testGetUsersOwnerCounty(){
        LightningServerResponse lsr = CaseFlowApxCtrl.getUsersOwnerCounty();
        System.assertEquals(true, lsr.isSuccessful, 'should be true');
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test1','test1','test1@example.com','test1@example.com.'+string.valueof(math.random()*3),'ttes1');
        if(user!=null){
            insert user; 
        }
        System.runAs(user){
            lsr = CaseFlowApxCtrl.getUsersOwnerCounty();
            System.assertEquals(true, lsr.isSuccessful, 'should be true');
        }        
    }
    
}