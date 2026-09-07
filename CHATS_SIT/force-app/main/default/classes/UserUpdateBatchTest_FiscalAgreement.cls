@isTest
public class UserUpdateBatchTest_FiscalAgreement {
    static list<User> activeUserList;
	private static void DataSetup(){
        Profile activeUserProfile=[Select id from Profile where Name ='System Administrator'];
        User activeUser = TestClassUtility.createUserwithPS(activeUserProfile.Id,'System_Administrator_PS', 'Greer','Danielle','active@example.com','active@example.com.'+string.valueof(math.random()*3),'act');
        activeUser.isActive = true;
        activeUser.Owner_County__c = '10';
        update activeUser;

        List<Profile> profileList = [Select id, Name from Profile where Name In ('Eligibility Worker', 'Eligibility Worker Supervisor',
                                                'Universal User','Provider Worker','Provider Worker Supervisor',
                                                'Fiscal Worker','Fiscal Worker Supervisor','Business Office Worker',
                                                'Business Office Supervisor','Read Only User')];
        Map<String,Id> profileMap = new Map<String,Id>();
        for(Profile profObj : profileList){
            if(profileMap.get(profObj.Name) == null){
                profileMap.put(profObj.Name, profObj.Id);
            }
        }

        activeUserList = new List<User>();
        Integer randInd = 1;
        for (String key : profileMap.keySet()) {
                    User profActiveUser = TestClassUtility.createUser(profileMap.get(key), key,'UserUpdateBatchTest','active@example.com','active@example.com.'+string.valueof(randInd),'act'+String.valueOf(randInd));
                    profActiveUser.isActive = true;
                    profActiveUser.Owner_County__c = '10';
                    activeUserList.add(profActiveUser);
                    randInd += 1;
                    User profActiveUser2 = TestClassUtility.createUser(profileMap.get(key), key,'UserUpdateBatchTest2','active2@example.com','active2@example.com.'+string.valueof(randInd),'act2'+String.valueOf(randInd));
                    profActiveUser2.isActive = true;
                    profActiveUser2.Owner_County__c = '10';
                    activeUserList.add(profActiveUser2);
                    randInd += 1;
        }
        insert activeUserList;
        system.runAs(activeUser){
             String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        Date begindateOpn=System.Today()-10;

        T_PROVR_FISCAL_AGREMENT__c testFiscal = TestClassUtility.createFiscaAgreement(false,'FA1',System.Today(),countyObj.Id);
        Profile userProfile=[Select id from Profile where Name ='Read Only User'];
        User inActiveUser = TestClassUtility.createUser(userProfile.Id, 'inactive','inactive','inactive@example.com','inactive@example.com.'+string.valueof(math.random()*3),'inact');
        inActiveUser.isActive = true;
        inActiveUser.Owner_County__c = '10';
        insert inActiveUser;		
        ByPass_Validation_Setting__c byPass=new ByPass_Validation_Setting__c();
        byPass.Is_Batch_Excluded__c=false;
        insert byPass;
        testFiscal.OwnerId = inActiveUser.Id;
        testFiscal.RecordtypeId=openRecordTypeId;
        testFiscal.CDE_TYPE_STATUS__c='OPN';
        testFiscal.ID_SERVICE__c=provider.Id;
        testFiscal.DTE_RCV_AGRMT_FISCAL__c=begindateOpn;

        // insert testCase;
        insert testFiscal;
            Map<String,Id> psMap = new Map<String,id>();
            for(PermissionSet ps : [SELECT Id,Name FROM PermissionSet WHERE Name IN('Eligibility_Worker_PS','Eligibility_Worker_Supervisor_PS',
                                                                                    'Provider_Worker_PS','Provider_Worker_Supervisor_PS',
                                                                                    'Fiscal_Worker_PS','Fiscal_Worker_Supervisor_PS')]){
                                                                                        psMap.put(ps.name,ps.Id);
                                                                                    }
            if(!psMap.isEmpty()){ 
                List<PermissionSetAssignment> psList = new List<PermissionSetAssignment>();
                for(User us: [select id,profile.name from user where id in: activeUserList]){
                    PermissionSetAssignment psa = new PermissionSetAssignment();
                    psa.AssigneeId = us.Id;
                    if(us.profile.name == 'Eligibility Worker'){
                        psa.PermissionSetId = psMap.get('Eligibility_Worker_PS');
                    }else if(us.profile.name == 'Eligibility Worker Supervisor'){
                        psa.PermissionSetId = psMap.get('Eligibility_Worker_Supervisor_PS');
                    }else if(us.profile.name == 'Provider Worker'){
                        psa.PermissionSetId = psMap.get('Provider_Worker_PS');
                    }else if(us.profile.name == 'Provider Worker Supervisor'){
                        psa.PermissionSetId = psMap.get('Provider_Worker_Supervisor_PS');
                    }else if(us.profile.name == 'Fiscal Worker'){
                        psa.PermissionSetId = psMap.get('Fiscal_Worker_PS');
                    }else if(us.profile.name == 'Fiscal Worker Supervisor'){
                        psa.PermissionSetId = psMap.get('Fiscal_Worker_Supervisor_PS');
                    }
                    if(psa.PermissionSetId!=null){
                        psList.add(psa);
                    }
                }
                insert psList;
            }
        }
    }

    @isTest
    private static void testLevel1UserUpdateBatch(){
		
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true limit 1];
        
            DataSetup();
        
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        
        
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];

		
        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];
        system.assertEquals(fiscalList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(fiscalList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel2UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true limit 1];
        DataSetup();
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;

        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In:activeUserList and Profile.Name = 'Provider Worker'];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];

        system.assertEquals(fiscalList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(fiscalList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel3UserUpdateBatch(){

        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true limit 1];
        DataSetup();
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;

        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In:activeUserList and Profile.Name In ('Provider Worker','Provider Worker Supervisor')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];

        system.assertEquals(fiscalList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(fiscalList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel4UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true limit 1];
        DataSetup();
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;

        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In:activeUserList and Profile.Name In ('Provider Worker','Provider Worker Supervisor','Business Office Worker')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];

        system.assertEquals(fiscalList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(fiscalList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel5UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true limit 1];
        DataSetup();
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In:activeUserList and Profile.Name In ('Provider Worker','Provider Worker Supervisor','Business Office Worker','Business Office Supervisor')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];

        system.assertEquals(fiscalList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(fiscalList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel6UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true limit 1];
        DataSetup();
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In:activeUserList and Profile.Name In ('Provider Worker','Provider Worker Supervisor','Business Office Worker','Business Office Supervisor','Universal User')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];

        system.assertEquals(fiscalList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(fiscalList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel7UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true limit 1];
        DataSetup();
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In:activeUserList and Profile.Name In ('Provider Worker','Provider Worker Supervisor','Business Office Worker','Business Office Supervisor','Universal User','Fiscal Worker')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];

        system.assertEquals(fiscalList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(fiscalList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel8UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true limit 1];
        DataSetup();
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In:activeUserList and Profile.Name In ('Provider Worker','Provider Worker Supervisor','Business Office Worker','Business Office Supervisor','Universal User','Fiscal Worker','Fiscal Worker Supervisor')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];

        system.assertEquals(fiscalList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(fiscalList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel9UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true limit 1];
        DataSetup();
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In:activeUserList and Profile.Name In ('Provider Worker','Provider Worker Supervisor','Business Office Worker','Business Office Supervisor','Universal User','Fiscal Worker','Fiscal Worker Supervisor','Eligibility Worker')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];
        
        
        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];

        system.assertEquals(fiscalList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(fiscalList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel10UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true limit 1];
        DataSetup();
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In:activeUserList and Profile.Name In ('Provider Worker','Provider Worker Supervisor','Business Office Worker','Business Office Supervisor','Universal User','Fiscal Worker','Fiscal Worker Supervisor','Eligibility Worker','Eligibility Worker Supervisor')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];

        system.assertEquals(fiscalList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(fiscalList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testDefaultUserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true limit 1];
        DataSetup();
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        
        
        
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In:activeUserList and Profile.Name In ('Provider Worker','Provider Worker Supervisor','Business Office Worker','Business Office Supervisor','Universal User','Fiscal Worker','Fiscal Worker Supervisor','Eligibility Worker','Eligibility Worker Supervisor','Read Only User')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_PROVR_FISCAL_AGREMENT__c> fiscalList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_PROVR_FISCAL_AGREMENT__c];

        system.assertEquals(fiscalList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(fiscalList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

}