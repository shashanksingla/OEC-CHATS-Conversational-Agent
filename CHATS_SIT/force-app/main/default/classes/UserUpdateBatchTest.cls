@isTest
public class UserUpdateBatchTest {
	static list<User> activeUserList;
    private static void DataSetup(){
        String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        Date begindateOpn=System.Today()-10;

        T_SBSD_CASE__c testCase = TestClassUtility.createCase(false,countyObj.Id);
        Profile userProfile=[Select id from Profile where Name ='Read Only User'];
        User inActiveUser = TestClassUtility.createUser(userProfile.Id, 'inactive','inactive','inactive@example.com','inactive@example.com.'+string.valueof(math.random()*3),'inact');
        inActiveUser.isActive = true;
        inActiveUser.Owner_County__c = '10';
        insert inActiveUser;
        testCase.OwnerId = inActiveUser.Id;
        insert testCase;
        
        ByPass_Validation_Setting__c byPass=new ByPass_Validation_Setting__c();
        byPass.Is_Batch_Excluded__c=false;
        insert byPass;
        
        T_SBSD_CASE_STATUS_MODE__c testCaseMode = TestClassUtility.createCaseStatusMode(false,testCase.Id); 
		insert testCaseMode;
        
        Profile activeUserProfile=[Select id from Profile where Name ='System Administrator'];
        User activeUser = TestClassUtility.createUser(activeUserProfile.Id, 'Greer','Danielle','active@example.com','active@example.com.'+string.valueof(math.random()*3),'act');
        activeUser.isActive = true;
        activeUser.Owner_County__c = '10';
        insert activeUser;

        List<Profile> profileList = [Select id, Name from Profile where Name In ('Eligibility Worker', 'Eligibility Worker Supervisor',
                                                'Universal User','Provider Worker','Provider Worker Supervisor',
                                                'Fiscal Worker','Read Only User')];
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
            Map<String,Id> psMap = new Map<String,id>();
            for(PermissionSet ps : [SELECT Id,Name FROM PermissionSet WHERE Name IN('Eligibility_Worker_PS','Eligibility_Worker_Supervisor_PS',
                                                                               'Provider_Worker_PS','Provider_Worker_Supervisor_PS','Fiscal_Worker_PS')]){
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
                    }
                    if(psa.PermissionSetId!=null){
                        psList.add(psa);
                    }
                }
                insert psList;
            }
        }


    }

  /*  @isTest
    private static void testLevel1UserUpdateBatch(){
		
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true];
        System.runAs(adminList[0]){
            DataSetup();
        }
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        
        
        List<T_SBSD_CASE__c> caseList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];

		
        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_SBSD_CASE__c> caseList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];
        system.assertEquals(caseList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(caseList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel2UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true];
        System.runAs(adminList[0]){
            DataSetup();
        }
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;

        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Profile.Name = 'Eligibility Worker'];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_SBSD_CASE__c> caseList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_SBSD_CASE__c> caseList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];

        system.assertEquals(caseList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(caseList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel3UserUpdateBatch(){

        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true];
        System.runAs(adminList[0]){
            DataSetup();
        }
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;

        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Profile.Name In ('Eligibility Worker','Eligibility Worker Supervisor')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_SBSD_CASE__c> caseList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_SBSD_CASE__c> caseList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];

        system.assertEquals(caseList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(caseList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel4UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true];
        System.runAs(adminList[0]){
            DataSetup();
        }
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;

        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Profile.Name In ('Eligibility Worker','Eligibility Worker Supervisor','Universal User')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_SBSD_CASE__c> caseList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_SBSD_CASE__c> caseList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];

        system.assertEquals(caseList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(caseList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }*/

    @isTest
    private static void testLevel5UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true Limit 1];
        System.runAs(adminList[0]){
            DataSetup();
        }
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In :activeUserList and Profile.Name In ('Eligibility Worker','Eligibility Worker Supervisor','Universal User','Provider Worker')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_SBSD_CASE__c> caseList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_SBSD_CASE__c> caseList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];
		
        system.assertEquals(caseList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(caseList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel6UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true Limit 1];
        System.runAs(adminList[0]){
            DataSetup();
        }
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In :activeUserList and Profile.Name In ('Eligibility Worker','Eligibility Worker Supervisor','Universal User','Provider Worker','Provider Worker Supervisor')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_SBSD_CASE__c> caseList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_SBSD_CASE__c> caseList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];

        system.assertEquals(caseList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(caseList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel7UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true Limit 1];
        System.runAs(adminList[0]){
            DataSetup();
        }
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In :activeUserList and Profile.Name In ('Eligibility Worker','Eligibility Worker Supervisor','Universal User','Provider Worker','Provider Worker Supervisor','Fiscal Worker')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_SBSD_CASE__c> caseList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_SBSD_CASE__c> caseList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];

        system.assertEquals(caseList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(caseList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel8UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true Limit 1];
        System.runAs(adminList[0]){
            DataSetup();
        }
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In :activeUserList and Profile.Name In ('Eligibility Worker','Eligibility Worker Supervisor','Universal User','Provider Worker','Provider Worker Supervisor','Fiscal Worker','Fiscal Worker Supervisor')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_SBSD_CASE__c> caseList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_SBSD_CASE__c> caseList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];

        system.assertEquals(caseList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(caseList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel9UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true Limit 1];
        System.runAs(adminList[0]){
            DataSetup();
        }
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In :activeUserList and Profile.Name In ('Eligibility Worker','Eligibility Worker Supervisor','Universal User','Provider Worker','Provider Worker Supervisor','Fiscal Worker','Fiscal Worker Supervisor','Business Office Worker')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_SBSD_CASE__c> caseList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_SBSD_CASE__c> caseList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];

        system.assertEquals(caseList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(caseList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

    @isTest
    private static void testLevel10UserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true Limit 1];
        System.runAs(adminList[0]){
            DataSetup();
        }
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Id In :activeUserList and Profile.Name In ('Eligibility Worker','Eligibility Worker Supervisor','Universal User','Provider Worker','Provider Worker Supervisor','Fiscal Worker','Fiscal Worker Supervisor','Business Office Worker','Business Office Supervisor')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        List<T_SBSD_CASE__c> caseList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_SBSD_CASE__c> caseList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];

        system.assertEquals(caseList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(caseList2[0].Owner.IsActive, true, 'New Owner Not Active');
    }

  /*  @isTest
    private static void testDefaultUserUpdateBatch(){
        List<User> adminList = [Select Id, Name from User where Profile.Name = 'System Administrator' AND IsActive=true];
        System.runAs(adminList[0]){
            DataSetup();
        }
        List<User> inactiveUserList = [Select Id, Name , IsActive from User where Name = 'inactive inactive'];
        for(User inactiveUserObj : inactiveUserList){
            inactiveUserObj.isActive = false;
        }
        update inactiveUserList;
        
        
        
        List<User> disableTheseUsers = [Select Id, IsActive, Name, Profile.Name from User where Profile.Name In ('Eligibility Worker','Eligibility Worker Supervisor','Universal User','Provider Worker','Provider Worker Supervisor','Fiscal Worker','Fiscal Worker Supervisor','Business Office Worker','Business Office Supervisor','Read Only User')];
        for(User uObj : disableTheseUsers ){
            uObj.IsActive = false;
        }
        update disableTheseUsers;
        
        List<T_SBSD_CASE__c> caseList = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];


        Test.startTest();
        UserUpdateBatch batchprocess = new UserUpdateBatch();
        Database.executeBatch(batchprocess);
        Test.stopTest();

        List<T_SBSD_CASE__c> caseList2 = [Select Id, Name, OwnerId, Owner.Name, Owner.IsActive from  T_SBSD_CASE__c];

        system.assertEquals(caseList[0].Owner.IsActive, false, 'New Owner Not Active');
        system.assertEquals(caseList2[0].Owner.IsActive, true, 'New Owner Not Active');
    } */
    
}