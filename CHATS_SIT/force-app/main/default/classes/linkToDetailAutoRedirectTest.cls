@IsTest(SeeAllData=false)
public class linkToDetailAutoRedirectTest {

    static testMethod void testfetchObjectdata(){
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
        
        Linked_To__c linkedToRecord = new Linked_To__c();
        linkedToRecord.Linked_Issues__c = '	is duplicated by';
        linkedToRecord.Support_Ticket__c = supportRec.Id;
        linkedToRecord.Support_Ticket1__c = supportRec.Id;
        
        Test.startTest();
        insert linkedToRecord;
        
        Linked_To__c linkedTicket = [Select Id, name, Support_Ticket__c, Support_Ticket1__c from Linked_To__c LIMIT 1 ];
        Linked_To__c linkRec = linkToDetailAutoRedirectionCtrl.fetchObjectdata(linkedTicket.Id);
        system.assertEquals(linkRec != null, true);
        Test.stopTest();
    }
}