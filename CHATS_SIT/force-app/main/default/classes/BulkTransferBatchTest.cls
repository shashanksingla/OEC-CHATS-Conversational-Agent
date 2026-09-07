@isTest
public class BulkTransferBatchTest {
    @testSetup
    private static void TestSetup(){
        
        T_COUNTY__c county = TestClassUtility.createCounty('Denver','Denver',1,true);
        User fromUser;
        User toUser;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        fromUser = TestClassUtility.createUser(userProfile.Id , 'test1','test1','test1@example.com','test1@example.com.'+string.valueof(math.random()*3),'ttes1');
        if(fromUser!=null){
            insert fromUser; 
        }
        
        toUser = TestClassUtility.createUser(userProfile.Id , 'test2','test2','test2@example.com','test2@example.com.'+string.valueof(math.random()*3),'ttes2');
        if(toUser!=null){
            insert toUser; 
        }
        
       	String OPEN = 'OPN';
    	String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        Date begindateOpn=System.Today()-10;
       
        //CASEes Setup
        List<T_SBSD_Case__c> setupCaseList = new List<T_SBSD_Case__c>();
        for(Integer i = 0 ; i < 100 ; i++){
            T_SBSD_Case__c singleCase = new T_SBSD_Case__c();
            singleCase.Name = 'TestCase ' + String.valueOf(i);
            singleCase.ownerId = fromUser.Id;
            singleCase.CDE_COUNTY__c = county.Id;
            setupCaseList.add(singleCase);
        }
        insert setupCaseList;
        
        //FISCAL AGREEMENTs Setup
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(CDE_STATUS_PROVR__c='Open');
        insert provider;
        List<T_PROVR_FISCAL_AGREMENT__c> setupFiscalList = new List<T_PROVR_FISCAL_AGREMENT__c>();
        for(Integer i = 0 ; i < 100 ; i++){
            T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
            fiscalAgreement.RecordtypeId=openRecordTypeId;
            fiscalAgreement.CDE_TYPE_STATUS__c=OPEN;
            fiscalAgreement.ID_SERVICE__c=provider.Id;
            fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c=begindateOpn;
            fiscalAgreement.ownerId = fromUser.Id;
            setupFiscalList.add(fiscalAgreement);
        }
        insert setupFiscalList;
        
        //TASKs Setup
        List<Task> setupTaskList = new List<Task>();
        for(Integer i = 0 ; i < 100 ; i++){
            Task task1 = TestClassUtility.createTask(false, 'T10','description1', 'Not started', setupCaseList[0].Id , fromUser.Id);
            setupTaskList.add(task1);
        }
        insert setupTaskList;
        
        
    }
    
    @isTest
    private static void testBulkCaseTransfer(){
		//CASE TRANSFER TEST
        User fromUser = [Select Id, Name from User where Name = 'test1 test1' ];
        User toUser = [Select Id, Name from User where Name = 'test2 test2' ];
        
        
        List<T_SBSD_Case__c> setupCaseList = [select Id, Name, CDE_COUNTY__c from T_SBSD_Case__c where ownerId =: fromUser.Id];
        List<Id> caseIdList = new List<Id>();
        
        for(T_SBSD_Case__c cse: setupCaseList){
            caseIdList.add(cse.Id);
        }
        
        system.assertEquals(setupCaseList.size(), 100);
        
        Test.startTest();
        BulkTransferBatch batchprocess = new BulkTransferBatch(caseIdList, toUser.Id,'1');
        Database.executeBatch(batchprocess);
        Test.stopTest();
        
        setupCaseList = [select Id, Name, CDE_COUNTY__c from T_SBSD_Case__c where ownerId =: fromUser.Id];
        system.assertEquals(setupCaseList.size(), 0, 'Did not transfer case records');
        
    }
    
    @isTest
    private static void testBulkFiscalTransfer(){
        // FISCAL AGREEMENT TRANSFER TEST
        User fromUser = [Select Id, Name from User where Name = 'test1 test1' ];
        User toUser = [Select Id, Name from User where Name = 'test2 test2' ];
        List<T_PROVR_FISCAL_AGREMENT__c> setupFiscalList = [select Id, Name from T_PROVR_FISCAL_AGREMENT__c where ownerId =: fromUser.Id];
        List<Id> fiscalIdList = new List<Id>();
        
        for(T_PROVR_FISCAL_AGREMENT__c cse: setupFiscalList){
            fiscalIdList.add(cse.Id);
        }
        
        system.assertEquals(setupFiscalList.size(), 100);
        system.debug('FISCALS '+setupFiscalList.size());
        Test.startTest();
        BulkTransferBatch batchprocess2 = new BulkTransferBatch(fiscalIdList, toUser.Id,'2');
        Database.executeBatch(batchprocess2);
        Test.stopTest();
        
        setupFiscalList = [select Id, Name from T_PROVR_FISCAL_AGREMENT__c where ownerId =: fromUser.Id];
        system.debug('FINAL FISCALS ' + setupFiscalList.size());
        system.assertEquals(setupFiscalList.size(), 0, 'Did not transfer Fiscal records');
        
    }
    
    @isTest
    private static void testBulkTaskTransfer(){
        
        User fromUser = [Select Id from User where Name = 'test1 test1' ];
        User toUser = [Select Id from User where Name = 'test2 test2' ];
        List<Task> setupTaskList = [select Id from Task where ownerId =: fromUser.Id];
        List<Id> taskIdList = new List<Id>();
        
        for(Task tsk: setupTaskList){
            taskIdList.add(tsk.Id);
        }
        
        system.assertEquals(setupTaskList.size(), 100);
        system.debug('FISCALS '+setupTaskList.size());
        Test.startTest();
        BulkTransferBatch batchprocess3 = new BulkTransferBatch(taskIdList, toUser.Id,'3');
        Database.executeBatch(batchprocess3);
        Test.stopTest();
        
        setupTaskList = [select Id from Task where ownerId =: fromUser.Id];
        system.debug('FINAL FISCALS ' + setupTaskList.size());
        system.assertEquals(setupTaskList.size(), 0, 'Did not transfer Task records');
        
    }

}