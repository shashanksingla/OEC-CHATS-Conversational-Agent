public class LinkSupportServices {
    public static void avoidDuplication(List<Linked_To__c> newLinkedToList){
        map<Id, Set<String>> linkSupportMap = new map<Id, Set<string>>();
        Map<Id, Set<String>> linkChildSupportMap = new Map<Id, Set<string>>();
        for(Linked_To__c linkRec : newLinkedToList){
            if(linkRec.Support_Ticket__c != null){
                linkSupportMap.put(linkRec.Support_Ticket__c, new set<String>());
                linkChildSupportMap.put(linkRec.Support_Ticket__c, new set<String>());
            }
        }
        if(!linkSupportMap.isEmpty()){
            for(Linked_To__c linkRec : [Select Id, Support_Ticket__c, Support_Ticket1__c from Linked_To__c where Support_Ticket__c =: linkSupportMap.keySet() or Support_Ticket1__c =: linkSupportMap.keySet()]){
                if(linkSupportMap.containsKey(linkRec.Support_Ticket__c)){
                    linkSupportMap.get(linkRec.Support_Ticket__c).add(linkRec.Support_Ticket1__c);
                }
                if(linkChildSupportMap.containsKey(linkRec.Support_Ticket1__c)){
                    linkChildSupportMap.get(linkRec.Support_Ticket1__c).add(linkRec.Support_Ticket__c);
                }
            }
        }
        if(!linkSupportMap.isEmpty()){
            for(Linked_To__c linkSupportRec : newLinkedToList){
                Set<String> conSet = linkSupportMap.get(linkSupportRec.Support_Ticket__c);
                Set<String> supportParentSet = linkChildSupportMap.get(linkSupportRec.Support_Ticket__c);
                if((!conSet.isEmpty() && conSet.contains(linkSupportRec.Support_Ticket1__c)) ||( !supportParentSet.isEmpty() && supportParentSet.contains(linkSupportRec.Support_Ticket1__c)) ){
                    linkSupportRec.Support_Ticket1__c.addError(Label.Duplicate_Support_Ticket_Msg);
                }
            }
        }
    }
}