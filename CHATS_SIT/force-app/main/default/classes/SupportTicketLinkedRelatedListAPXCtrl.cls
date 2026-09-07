public with sharing class SupportTicketLinkedRelatedListAPXCtrl {
    
    @AuraEnabled
    public static LightningServerResponse fetchRelatedObjectdata(String recordId){
        Map<String, Boolean> objectData = new map<String, Boolean>();
        Boolean isSuccessful = true;
        String message;
        List<object> fetchedLinkedRecords = new List<object>();
        
        try{
            for(Linked_To__c linkedTicket : [Select Id, name, Support_Ticket__c, Support_Ticket__r.name, Support_Ticket1__c, Support_Ticket1__r.name, toLabel(Linked_Issues__c) from Linked_To__c where  Support_Ticket__c =:recordId OR Support_Ticket1__c =:recordId order by name ]){
                Map<String,object> linked = new Map<String,object>();
                
                if(linkedTicket.Support_Ticket__c ==recordId){
                    linked.put('Support_Ticket__c',linkedTicket.Support_Ticket1__c);
                    linked.put('Support_Ticket__rname',linkedTicket.Support_Ticket1__r.name);
                    linked.put('Linked_Issues__c',linkedTicket.Linked_Issues__c);
                    linked.put('name',linkedTicket.name); 
                    linked.put('Id',linkedTicket.Id);
                    fetchedLinkedRecords.add(linked); 
                }
                else if(linkedTicket.Support_Ticket1__c ==recordId){
                    linked.put('Support_Ticket__c',linkedTicket.Support_Ticket__c);
                    linked.put('Support_Ticket__rname',linkedTicket.Support_Ticket__r.name);
                    linked.put('Linked_Issues__c',linkedTicket.Linked_Issues__c);
                    linked.put('name',linkedTicket.name);
                    linked.put('Id',linkedTicket.Id);
                    fetchedLinkedRecords.add(linked); 
                }
            }
            
        }
        catch(Exception e){
            message = e.getMessage(); 
        }
        return new LightningServerResponse(isSuccessful,message,new Map<String, object>{'fetchedLinkedRecords' => fetchedLinkedRecords});
    }
 
}