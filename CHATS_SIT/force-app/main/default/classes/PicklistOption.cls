public class PicklistOption {
    
    @AuraEnabled
    public String label {get; private set;}
    
    @AuraEnabled
    public String value {get; private set;}
    
    public PicklistOption(String label, String value){
        this.label = label;
        this.value = value;
    } 
}