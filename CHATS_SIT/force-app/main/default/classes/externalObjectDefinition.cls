public class externalObjectDefinition {
    
   @AuraEnabled public List<fieldDefinition> fldDefList{get;set;}
        public class fieldDefinition {
            @AuraEnabled public String fieldAPIName  {get;set;}
            @AuraEnabled public String objectName  {get;set;}
            @AuraEnabled public String dataType  {get;set;}   
            @AuraEnabled public String fieldLabel  {get;set;}
            @AuraEnabled public String fieldValue  {get;set;}
            @AuraEnabled public String childRecordId  {get;set;}
            @AuraEnabled public String parentRecordId  {get;set;}
            @AuraEnabled public Date fieldValueDate  {get;set;}
            @AuraEnabled public DateTime fieldValueDateTime  {get;set;}
        } 
}