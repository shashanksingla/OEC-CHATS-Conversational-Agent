// Test class for ContentVersion and ContentDocumentLink triggers
@IsTest
public class ContentDocumentLinkTrigger_Test {
    
    static testmethod void testmethod1(){        
        T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c(Name = 'Demo', NAM_FACILITY__c = 'abc');
        insert provider; 
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Universal User' limit 1];
        User u = TestClassUtility.createUser(p.Id, 'LN', 'FN', 'testfln@mail.com', 'testfln@mail.com', 'testfln');
        
        system.runAs(u){
            Test.startTest();
            ContentVersion content = new ContentVersion(); 
            content.Title = 'Header_Picture1'; 
            content.PathOnClient = '/' + content.Title + '.jpg'; 
            Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body'); 
            content.VersionData = bodyBlob; 
            content.origin = 'H';
            insert content;
            
            ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId = provider.id;
            contentlink.contentdocumentid = [SELECT contentdocumentid from contentversion where id =:content.id].contentdocumentid;
            contentlink.ShareType = 'I';
            contentlink.Visibility = 'AllUsers'; 
            try{
                insert contentlink;
            }catch(Exception e){
                string errMsg = e.getMessage();
                system.assert(errMsg.contains('You do not have permission to perform this action.'));
            }
            Test.stopTest();
        }
    }
}