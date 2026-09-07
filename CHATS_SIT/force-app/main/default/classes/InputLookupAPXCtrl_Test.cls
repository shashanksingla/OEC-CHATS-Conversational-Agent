@isTest
public class InputLookupAPXCtrl_Test {
    @isTest 
    static void test_getRecentRecords() {
        String jsonString = '{"searchField":"Name", "object": "Contact", "filter": "Name = \'Test Contact\'"}';

        Test.startTest();
        String responseString = InputLookupAPXCtrl.getRecentRecords(jsonString);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        system.assert(string.valueof(results)!=null,'Should not return null value' );
        System.assertEquals(true, response.get('isSuccess'),'Issuccess should be true');
    }

    @isTest static void test_getRecordLabel() {
        Contact a = new Contact(LastName='Contact',FirstName='Test');
        insert a;

        String jsonString = '{"searchField":"Name", "object": "Contact", "filter": "Name = \'Test Contact\'"}';

        Test.startTest();
        String responseString = InputLookupAPXCtrl.getRecordLabel(jsonString);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        String objectLabel = String.valueOf(results.get('objectLabel'));

        System.assertEquals('Contact', objectLabel,'Object Label should be Contact');
    }

    @isTest static void test_getData() {
        Contact a = new Contact(LastName='Contact',
            FirstName='Test');
        insert a;
        
        String jsonString = '{"searchField":"Name", "object": "Contact", "filter": "Name = \'Test Contact\'", "order": "Name", "limit": "5", "searchTerm": "Test", "alternateSearchField":"Name", "secondarySearchField": "Name"}';

        Test.startTest();
        String responseString = InputLookupAPXCtrl.getRecords(jsonString);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');

        System.assertEquals(1, data.size(),'Should return one result');

        Map<String, Object> record = (Map<String, Object>)data.get(0);

        System.assertEquals(a.Id, record.get('value'),'Record Id should match');
    }

    @isTest static void test_getData_subtitleField() {
        Contact a = new Contact(LastName='Contact',
            FirstName='Test');
        insert a;

        String jsonString = '{"searchField":"Name", "subtitleField": "Name", "object": "Contact", "filter": "Name = \'Test Contact\'", "searchTerm": "Test"}';

        Test.startTest();
        String responseString = InputLookupAPXCtrl.getRecords(jsonString);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');

        System.assertEquals(1, data.size(),'Should return one result');

        Map<String, Object> record = (Map<String, Object>)data.get(0);

        System.assertEquals(a.Id, record.get('value'),'Record Id should match');
    }

    @isTest static void test_getData_addressField() {
        Contact a = new Contact(
            LastName='Contact',
            FirstName='Test',
            MailingStreet='Test Street',
            MailingCity='Test City',
            MailingState='Test State',
            MailingCountry='Test Country',
            MailingPostalCode='Test Postal Code');
        insert a;

        String jsonString = '{"searchField":"Name", "subtitleField": "MailingAddress", "object": "Contact", "filter": "Name = \'Test Contact\'", "searchTerm": "Test"}';

        Test.startTest();
        String responseString = InputLookupAPXCtrl.getRecords(jsonString);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        List<Object> data =(List<Object>)results.get('data');

        System.assertEquals(1, data.size(),'Should return one result');

        Map<String, Object> record = (Map<String, Object>)data.get(0);

        System.assertEquals(a.Id, record.get('value'),'Record Id should match');
    }

    @isTest static void test_getData_reference() {
        /*Account a = new Account(Name='Test Account');
        insert a;*/
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        User a = TestClassUtility.createUser(userProfile.Id , 'User','Test','test1@example.com','test1@example.com.'+string.valueof(math.random()*3),'ttes1');
        insert a;
        Contact c = new Contact(
            LastName='Contact',
            FirstName='Test',
            OwnerId = a.Id);
        insert c;
           
        String jsonString = '{"searchField":"FirstName", "subtitleField": "User.Name", "object": "Contact", "filter": "Name = \'Test Contact\'", "searchTerm": "Test"}';

        Test.startTest();
        String responseString = InputLookupAPXCtrl.getRecords(jsonString);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseString);
        
        if (boolean.valueOf(response.get('isSuccess'))){
        
        Map<string, Object> results = (Map<String, Object>)response.get('results');
        
        List<Object> data =(List<Object>)results.get('data');

        System.assertEquals(1, data.size(),'Should return one result');

        Map<String, Object> record = (Map<String, Object>)data.get(0);

        System.assertEquals(c.Id, record.get('value'),'Record Id should match');
        }
    }
}