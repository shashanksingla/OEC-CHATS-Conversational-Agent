public class FieldInformationWrapper {

    public class fieldDefinition {
     	@AuraEnabled public String fieldAPIName  {get;set;}
        @AuraEnabled public String objectName  {get;set;}
        @AuraEnabled public String dataType  {get;set;}   
        @AuraEnabled public String fieldLabel  {get;set;}
        @AuraEnabled public String referenecedObjectName  {get;set;}
    }
    
    public class referenceFieldDefinition {
     	@AuraEnabled public String referenecedObjectName  {get;set;}
        @AuraEnabled public String referenecedObjectLabel  {get;set;}
    }
    
    public class picklistFieldDefinition {
     	@AuraEnabled public String picklistLabel  {get;set;}
        @AuraEnabled public String picklistValue  {get;set;}
    }
}