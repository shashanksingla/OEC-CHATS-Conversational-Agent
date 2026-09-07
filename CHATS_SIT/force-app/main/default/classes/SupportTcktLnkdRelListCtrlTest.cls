@IsTest(SeeAllData=false)
public class SupportTcktLnkdRelListCtrlTest {
    
    static testMethod void testSupportTicket(){
        
        CHATS_Support__c supportRec = new CHATS_Support__c();
        supportRec.Support_Category__c = 'Policy';
        supportRec.Status__c = 'Fixed/Completed';
        supportRec.Support_Type__c = 'Question/Clarification';
        supportRec.Root_Cause__c = 'Pending Triage';
        supportRec.Direct_Phone_Number__c = '876543';
        supportRec.County__c = '1';
        supportRec.CHATS_Area__c = 'Adjustment';
        supportRec.Description_Steps_to_Reproduce__c = 'jfyufy';
        
        insert supportRec;
        
        CHATS_Support__c supportRec1 = new CHATS_Support__c();
        supportRec1.Support_Category__c = 'Policy';
        supportRec1.Status__c = 'Fixed/Completed';
        supportRec1.Support_Type__c = 'Question/Clarification';
        supportRec1.Root_Cause__c = 'Pending Triage';
        supportRec1.Direct_Phone_Number__c = '876543';
        supportRec1.County__c = '1';
        supportRec1.CHATS_Area__c = 'Adjustment';
        supportRec1.Description_Steps_to_Reproduce__c = 'jfyufy';
        
        insert supportRec1;
        
        Linked_To__c linkedToRecord = new Linked_To__c();
        linkedToRecord.Linked_Issues__c = '	is duplicated by';
        linkedToRecord.Support_Ticket__c = supportRec.Id;
        linkedToRecord.Support_Ticket1__c = supportRec1.Id;
        
        
        Test.startTest();
        insert linkedToRecord;
        
        Linked_To__c linkedTicket = [Select Id, name, Support_Ticket__c, Support_Ticket1__c from Linked_To__c Where Support_Ticket__c = :supportRec.Id LIMIT 1 ];
        LightningServerResponse  lightserresobj = SupportTicketLinkedRelatedListAPXCtrl.fetchRelatedObjectdata(supportRec.Id);
		system.assertEquals(true,lightserresobj.isSuccessful,'It should be successful');
        Test.stopTest();
    }
    
    static testMethod void testSupportTicket1(){
        
        CHATS_Support__c supportRec = new CHATS_Support__c();
        supportRec.Support_Category__c = 'Policy';
        supportRec.Status__c = 'Fixed/Completed';
        supportRec.Support_Type__c = 'Question/Clarification';
        supportRec.Root_Cause__c = 'Pending Triage';
        supportRec.Direct_Phone_Number__c = '876543';
        supportRec.County__c = '1';
        supportRec.CHATS_Area__c = 'Adjustment';
        supportRec.Description_Steps_to_Reproduce__c = 'jfyufy';
        
        insert supportRec;
        
        CHATS_Support__c supportRec1 = new CHATS_Support__c();
        supportRec1.Support_Category__c = 'Policy';
        supportRec1.Status__c = 'Fixed/Completed';
        supportRec1.Support_Type__c = 'Question/Clarification';
        supportRec1.Root_Cause__c = 'Pending Triage';
        supportRec1.Direct_Phone_Number__c = '876543';
        supportRec1.County__c = '1';
        supportRec1.CHATS_Area__c = 'Adjustment';
        supportRec1.Description_Steps_to_Reproduce__c = 'jfyufy';
        
        insert supportRec1;
        
        Linked_To__c linkedToRecord = new Linked_To__c();
        linkedToRecord.Linked_Issues__c = '	is duplicated by';
        linkedToRecord.Support_Ticket1__c = supportRec.Id;
        linkedToRecord.Support_Ticket__c = supportRec1.Id;
         
        Test.startTest();
        insert linkedToRecord;
        
        Linked_To__c linkedTicket = [Select Id, name, Support_Ticket__c, Support_Ticket1__c from Linked_To__c Where Support_Ticket1__c = :supportRec.Id LIMIT 1 ];
        LightningServerResponse  lightserresobj = SupportTicketLinkedRelatedListAPXCtrl.fetchRelatedObjectdata(supportRec.Id);
        system.assertEquals(true,lightserresobj.isSuccessful,'It should be successful');
        Test.stopTest();
    }

}