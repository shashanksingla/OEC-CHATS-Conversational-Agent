@isTest
public class updateSupportTicketControllerTest {
    
    static testmethod void supportTicketControllerTest() {
        List<CHATS_Support__c> newSupportList= new List<CHATS_Support__c>();
        CHATS_Support__c newsupport = new CHATS_Support__c(Support_Category__c = 'Policy',
                                                           Support_Type__c='System Issue/Request',
                                                           Status__c='New',
                                                           Root_Cause__c='Pending Triage',
                                                           Page_URL__c='abc');
        insert newsupport;
        
        updateSupportTicketController.onCloseButtonClick(newsupport.Id);
        updateSupportTicketController.onReopenButtonClick(newsupport.Id, 'Reopen Test');
        
        newSupportList = [select id, Status__c From CHATS_Support__c where Id =: newsupport.Id];
        if(!newSupportList.isEmpty()){
            system.assertEquals('Reopened', newSupportList[0].Status__c);
        }
    }
}