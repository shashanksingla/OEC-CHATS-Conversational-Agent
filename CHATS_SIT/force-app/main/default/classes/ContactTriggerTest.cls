@isTest
public class ContactTriggerTest {
    public static testmethod void testContact (){
        Contact c1 = new Contact(LastName = 'Lname', CI_Client_Id__c = 123456,Last_Successful_Login__c = system.now(), Pin_Reset_Code_Generated_Time__c = system.now(), PIN_Status__c = 'Expired');
        
        test.startTest();
        insert c1;
        system.assertNotEquals('Exp', c1.PIN_Status__c, 'Status mismatch as the contact gets deleted');
        test.stopTest();
    }
}