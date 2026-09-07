@isTest
public class AccountServicesTest {
    
static testmethod void testAccount(){
        
        T_COUNTY__c cnty = new T_COUNTY__c (    CDE_COUNTY__c = 03, CNTY_DEPT_NAME__c = 'Arapahoe County');
        
        Account acc = new Account(  Name = 'Acc', License_Number__c = '12345', License_Expiration_Date__c = date.today() + 1,
                                    License_Certification_Date__c = date.today(), Licensing_Status__c = 'Closed',
                                    Phone_Program_Site_Phone__c = '1234567891', QRIS_Rating__c = 'Level 3',
                                    Primary_Email__c = 'testacc@acc.com', County_Lookup__c = 'Arapahoe' ); 
        
        Account acc1 = new Account(  Name = 'Act', License_Number__c = '123456', License_Expiration_Date__c = date.today() + 2,
                                    License_Certification_Date__c = date.today(), Licensing_Status__c = 'Closed',
                                    Phone_Program_Site_Phone__c = '9988998899', QRIS_Rating__c = 'Level 2',
                                    Primary_Email__c = 'testacc@acc.com', County_Lookup__c = 'Arapahoe' ); 
        
        T_CHATS_PROVR_STATUS__c provr = new T_CHATS_PROVR_STATUS__c (Name = '12345');
        
        test.startTest();
        insert cnty;
        insert provr;
        insert acc;
        
        system.assertEquals('Acc', acc.Name,'Account Name Mismatch');
        system.assertEquals('12345', acc.License_Number__c,'License Numer Mismatch');
        system.assertEquals('Closed', acc.Licensing_Status__c,'License Status Mismatch');
        system.assertEquals('1234567891', acc.Phone_Program_Site_Phone__c,'Phone program Site Phone Mismatch');
        system.assertEquals('Level 3', acc.QRIS_Rating__c,'QRIS Rating Mismatch');
        system.assertEquals('testacc@acc.com', acc.Primary_Email__c,'Primary Email Mismatch');
        
        insert acc1;

        test.stopTest();
    }
}