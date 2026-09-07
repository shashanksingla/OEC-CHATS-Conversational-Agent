public with sharing class linkToDetailAutoRedirectionCtrl {
    
    @AuraEnabled
    public static Linked_To__c fetchObjectdata(String recordId){
         return [Select Support_Ticket__c from Linked_To__c Where Id =: recordId LIMIT 1];
    }

}