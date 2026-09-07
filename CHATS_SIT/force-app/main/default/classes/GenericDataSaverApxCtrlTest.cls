/**********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/29/2017                                                          
*  @description    Test class for Generic Data Saver
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 29-Nov-2017                                                             
*  * Author: Shubham Jain                                                      
*  * Description: Initial version                                                 
*  * JIRA Ticket: 
*                                                                                 
*********************************************************************************************/

@isTest
public class GenericDataSaverApxCtrlTest {
    public static testmethod void testUpsertRecords(){
        List<Account> accountsToBeUpdated = new List<Account>();         
        List<Account> existingAccounts = [SELECT Id, Name FROM Account limit 1000]; 
        //System.assertEquals(true, existingAccounts.size()>0, 'existingAccounts should not be empty');
        for(Account existingAccount:existingAccounts){
            existingAccount.Name = 'Updated '+existingAccount.Name;
            accountsToBeUpdated.add(existingAccount);
        }
        LightningServerResponse lsr = GenericDataSaverApxCtrl.upsertRecords(accountsToBeUpdated);
        System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
        
        lsr = GenericDataSaverApxCtrl.upsertRecords(new List<SObject>{new Contact(FirstName = 'FName')});
        System.assertEquals(false, lsr.isSuccessful, 'lsr.isSuccessful should be false');
    }

    public static testmethod void testUpsertRecordsFinal(){
        List<Account> accountsToBeUpdated = new List<Account>();         
        List<Account> existingAccounts = [SELECT Id, Name FROM Account limit 1000];
        //System.assertEquals(true, existingAccounts.size()>0, 'existingAccounts should not be empty');
        for(Account existingAccount:existingAccounts){
            existingAccount.Name = 'Updated '+existingAccount.Name;
            accountsToBeUpdated.add(existingAccount);
        }
        LightningServerResponse lsr = GenericDataSaverApxCtrl.upsertRecordsFinal(accountsToBeUpdated, true);
        System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
        
        lsr = GenericDataSaverApxCtrl.upsertRecordsFinal(new List<SObject>{new Contact(FirstName = 'FName')},true);
        System.assertEquals(false, lsr.isSuccessful, 'lsr.isSuccessful should be false');
        
        Contact tempContactToBedeleted = new Contact(FirstName = 'FName', LastName='test'); 
        insert tempContactToBedeleted;
        
        GenericDataSaverApxCtrl.deleteRecords(new List<SObject>{tempContactToBedeleted});
        List<Contact> conList = [SELECT Id FROM Contact WHERE Id = :tempContactToBedeleted.Id];
        System.assertEquals(true, conList.isEmpty(), 'conList should be empty');

        GenericDataSaverApxCtrl.deleteRecords(new List<SObject>{tempContactToBedeleted});
        
    }

    public static testmethod void testDeleteJunkRecords(){
        List<Account> accountsToBeUpdated = new List<Account>();         
        List<Account> existingAccounts = [SELECT Id, Name FROM Account limit 1000];
        //System.assertEquals(true, existingAccounts.size()>0, 'existingAccounts should not be empty');
        for(Account existingAccount:existingAccounts){
            existingAccount.Name = 'Updated '+existingAccount.Name;
            accountsToBeUpdated.add(existingAccount);
        }
        LightningServerResponse lsr = GenericDataSaverApxCtrl.upsertRecordsFinal(accountsToBeUpdated, true);
        System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
        
        lsr = GenericDataSaverApxCtrl.upsertRecordsFinal(new List<SObject>{new Contact(FirstName = 'FName')},true);
        System.assertEquals(false, lsr.isSuccessful, 'lsr.isSuccessful should be false');
        
        Contact tempContactToBedeleted = new Contact(FirstName = 'FName', LastName='test'); 
        insert tempContactToBedeleted;
        
        GenericDataSaverApxCtrl.deleteJunkRecords(new List<SObject>{tempContactToBedeleted});
        List<Contact> conList = [SELECT Id FROM Contact WHERE Id = :tempContactToBedeleted.Id];
        System.assertEquals(true, conList.isEmpty(), 'conList should be empty');
        
    }

    public static testmethod void testDeleteJunkRecordsByIds(){
        List<Account> accountsToBeUpdated = new List<Account>();         
        List<Account> existingAccounts = [SELECT Id, Name FROM Account limit 1000];
        //System.assertEquals(true, existingAccounts.size()>0, 'existingAccounts should not be empty');
        for(Account existingAccount:existingAccounts){
            existingAccount.Name = 'Updated '+existingAccount.Name;
            accountsToBeUpdated.add(existingAccount);
        }
        LightningServerResponse lsr = GenericDataSaverApxCtrl.upsertRecordsFinal(accountsToBeUpdated, true);
        System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
        
        lsr = GenericDataSaverApxCtrl.upsertRecordsFinal(new List<SObject>{new Contact(FirstName = 'FName')},true);
        System.assertEquals(false, lsr.isSuccessful, 'lsr.isSuccessful should be false');
        
        Contact tempContactToBedeleted = new Contact(FirstName = 'FName', LastName='test'); 
        insert tempContactToBedeleted;
        
        GenericDataSaverApxCtrl.deleteJunkRecordsByIds(new List<Id>{tempContactToBedeleted.Id});
        List<Contact> conList = [SELECT Id FROM Contact WHERE Id = :tempContactToBedeleted.Id];
        System.assertEquals(true, conList.isEmpty(), 'conList should be empty');

        
    }
    
    public static testmethod void testgetCrudResponseFromSaveResults(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.DTE_APPLN__c = System.today().addDays(-10);
        insert caseRec;
        Id recordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        List<T_ADJMT__c> adjustmentList= new List<T_ADJMT__c>();
        adjustmentList.add( new T_ADJMT__c(IDN_CASE__c=caseRec.Id,RecordtypeId=recordTypeId,CDE_STATUS_ADJMT__c='1',CDE_TYPE_ADJMT__c='1',CDE_TYPE_CLSFN__c='3',CDE_AGNST_ADJMT__c='1',DTE_END_ADJMT__c=date.newInstance(2018, 1, 10),DTE_START_ADJMT__c=date.newInstance(2018, 1, 8)));
        List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
        lstSaveResult.addAll(Database.insert(adjustmentList, false));
        CrudResponseApxCtrl.getCrudResponseFromSaveResults(adjustmentList, lstSaveResult);
        system.assert([select Id from T_ADJMT__c].size()==0,'Adjustment records');
    }
    
    public static testmethod void testUpsertRecordsAuth() {
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        Date dob = date.newInstance(datetoday.year()-20, datetoday.month(), 1);
        Date enddate = begindate.addDays(25);
        begindate = begindate.addDays(21);
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true, dob, 'firstName', '1', 'lastName', '123', 'CC');
        T_SBSD_CASE__c case1 = TestClassUtility.createCase(true, county.Id);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 3');
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,null);
        authorization.IDN_CASE__c= case1.Id;
        authorization.IDN_CLIENT__c= individual.Id;
        authorization.IDN_PROVR__c= provider.Id;
        insert authorization;
       
        LightningServerResponse lsr1 = GenericDataSaverApxCtrl.upsertRecordAuth(new List<T_AUTH__C>{authorization},string.valueOf(system.today()),true);
        System.assertEquals(true, lsr1.isSuccessful, 'lsr.isSuccessful should be true');
    
    }
    
    public static testmethod void testDeleteJunkRecords2() {
         Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
         T_SBSD_INDIV_MIL__c mil= new T_SBSD_INDIV_MIL__c(CDE_STATUS_MIL__c='0',IDN_CLIENT__c=caseData.get('individual').Id);
         insert mil;
         T_SBSD_INDIV_INFO__c info= new T_SBSD_INDIV_INFO__c(CDE_TYPE_INFO_INDIV__c='CS',IDN_CLIENT__c=caseData.get('individual').Id,IDN_CASE__c=caseData.get('caseRec').Id);
         insert info;
         T_INDIV_VERIF__c verif= new T_INDIV_VERIF__c(IDN_CLIENT__c=info.Id);
         insert verif;
         
         LightningServerResponse lsr = GenericDataSaverApxCtrl.deleteJunkRecords(new List<SObject>{caseData.get('individual')});
         System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
    
        
    }
    
    public static testMethod void testLogException(){
        Exception_Logging_Framework_Settings__c exceptionFrameworkSetting = new Exception_Logging_Framework_Settings__c(SetupOwnerId=UserInfo.getOrganizationId(), Enable_Exception_Log__c = true);
        insert exceptionFrameworkSetting;
    	
    	
        Exception_Log__c xLog = new Exception_Log__c();
        xLog.Class__c = 'Test';
        xLog.Method__c = 'Test';
        GenericDataSaverApxCtrl.logException(xLog);
        Integer xLogCount = [SELECT Count() FROM Exception_Log__c];
        System.assertEquals(1, xLogCount, 'xLogCount should be 1');
    }
    
    @testSetup
    public static void setUpData(){
        List<Account> accounts = new List<Account>();
        for(integer i = 0; i<10; i++){
            accounts.add(new Account(Name = 'Test'+i));
        }
        insert accounts;
    }
}