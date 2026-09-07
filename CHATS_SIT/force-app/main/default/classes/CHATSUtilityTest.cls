@isTest
public class CHATSUtilityTest {
    
    @TestSetup
    public static void testDataSetup(){
        CHATSUtility.createTemplateUser();
    }
    
    public static testMethod void testCheckCountyWithUserCounty(){
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        User user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
			user.Owner_County__c = '2';
            insert user; 
        }
        System.runAs(user){
            T_COUNTY__c countyRec = TestClassUtility.createCounty('Adams','Adams',2,true);
            System.assertEquals(true, CHATSUtility.checkCountyWithUserCounty(countyRec.Id), 'County matches and this method should return true');
        }
    }

    public static testMethod void testCheckCountyWithUserCountyNegetive(){
        Profile userProfile=[Select id from Profile where Name ='Eligibility Worker'];
        User user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            insert user; 
        }
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Adams','Adams',1,true);
        System.runAs(user){
            CHATSUtility.checkCountyWithUserCountyBulk(New Set<Id>{countyRec.Id});
            System.assertEquals(false, CHATSUtility.checkCountyWithUserCounty(countyRec.Id), 'County doesn\'t match and this method should return false');
        }
    }
    
    public static testMethod void testGetPicklistValuesToLabelList(){
        Profile userProfile = [Select id from Profile where Name ='System Administrator'];
        User user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        System.runAs(user){
            List<AgeGroupWrapper> lstPicklistValuesToLabel = CHATSUtility.getPicklistValuesToLabelList(Case.Status.getDescribe());
            String lstPicklistValuesToLabelString = JSON.serialize(lstPicklistValuesToLabel);
            System.assertEquals(true, lstPicklistValuesToLabelString.contains('Closed'));
        }
    }
    
    public static testMethod void testGetPicklistValuesToLabelMap(){
        Profile userProfile = [Select id from Profile where Name ='System Administrator'];
        User user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        System.runAs(user){
            Map<String, String> mapPicklistValuesToLabel = CHATSUtility.getPicklistValuesToLabelMap(Case.Status.getDescribe());
            System.assertEquals('Closed', mapPicklistValuesToLabel.get('Closed'));
        }
    }
    
    public static testMethod void testGetFieldDefinition(){
        Profile userProfile = [Select id from Profile where Name ='System Administrator'];
        User user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        List<String> fieldAPINames = new List<String>{'Name','OwnerId'};
            System.runAs(user){
                List<FieldInformationWrapper.fieldDefinition> mapOfObjectToField = CHATSUtility.getFieldDefinition('Account',fieldAPINames);
                String mapOfObjectToFieldString = JSON.serialize(mapOfObjectToField);
                System.assertEquals(true, mapOfObjectToFieldString.contains('Name'));
            }
    }
    
    public static testMethod void testMergeText(){
        Profile userProfile = [Select id from Profile where Name ='System Administrator'];
        User user = TestClassUtility.createUser(userProfile.Id , 'Smith','John','test@example.com','test@example.com.'+string.valueof(math.random()*3),'jsmith');
        insert user;
        String inputString = 'Hi, My name is [User.FirstName] and my Email is [User.Email], I am a [User.Profile.Name] with [User.Profile.UserLicense.Name] license';
        String expectedOutput = 'Hi, My name is John and my Email is test@example.com, I am a System Administrator with Salesforce license';
            System.runAs(user){
                user u = [SELECT Id, FirstName, Email, User.Profile.Name, User.Profile.UserLicense.Name FROM User WHERE id =: user.Id LIMIT 1];
                String actualOutput = CHATSUtility.mergeText(u, inputString);
                System.assertEquals(expectedOutput, actualOutput);
            }
    }
    
    public static testMethod void testMergeTextNegative(){
        Profile userProfile = [Select id from Profile where Name ='System Administrator'];
        List<User> usersToInsert = new List<User>();
        User user = TestClassUtility.createUser(userProfile.Id , 'Smith','John','test.jsmith@example.com','test.jsmith@example.com.'+string.valueof(math.random()*3),'jsmith');
        User user2 = TestClassUtility.createUser(userProfile.Id , 'Clark','Adam','test.aclark@example.com','test.aclark@example.com.'+string.valueof(math.random()*3),'aclark');
        User user3 = TestClassUtility.createUser(userProfile.Id , 'White','Ana','test.awhite@example.com','test.awhite@example.com.'+string.valueof(math.random()*3),'awhite');
        usersToInsert.add(user);
        user2.ManagerId = user.Id;
        usersToInsert.add(user2);
        user3.ManagerId = user2.Id;
        usersToInsert.add(user3);
        insert usersToInsert;
        String inputString = 'Hi, My company is [User.CompanyName] and my manager works for [User.Manager.CompanyName] company, and his manager is CEO of [User.Manager.Manager.CompanyName]';
        String expectedOutput = 'Hi, My company is  and my manager works for  company, and his manager is CEO of ';
            System.runAs(user){
                user u = [SELECT Id, User.CompanyName, User.Manager.CompanyName FROM User WHERE id =: user3.Id LIMIT 1];
                String actualOutput = CHATSUtility.mergeText(u, inputString);
                System.assertEquals(expectedOutput, actualOutput);
            }
    }
    
}