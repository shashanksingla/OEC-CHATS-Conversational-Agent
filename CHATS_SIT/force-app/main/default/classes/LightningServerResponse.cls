public class LightningServerResponse {
    @AuraEnabled public RequestStatus status {get; set;}
    @AuraEnabled public Boolean isSuccessful {get; private set;}
    @AuraEnabled public String successMessage { get; private set;}
    @AuraEnabled public String errorMessage { get; private set;}
    @AuraEnabled public String messageType { get; set;}
    @AuraEnabled public map<String, Object> objectData { get; private set; }
    @AuraEnabled public List<APXFieldValidationError> lstAPXFieldValidationError { get; private set; }
    public LightningServerResponse(Boolean isSuccessful, String message ,map<String, Object> objectData) {
        this.isSuccessful = isSuccessful;
        if(isSuccessful){
            this.successMessage = message;
        }
        else {
            this.errorMessage = message;
        }
        this.objectData = objectData;
    }
    
    
    public LightningServerResponse(Boolean isSuccessful, String message ,map<String, Object> objectData, List<APXFieldValidationError> lstAPXFieldValidationError) {
        this.isSuccessful = isSuccessful;
        if(isSuccessful){
            this.successMessage = message;
        }
        else{
            this.errorMessage = message;
        }
        this.objectData = objectData;
        this.lstAPXFieldValidationError = lstAPXFieldValidationError;
    }
}