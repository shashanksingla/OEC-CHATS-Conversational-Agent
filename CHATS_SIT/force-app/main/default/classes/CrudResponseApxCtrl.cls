public class CrudResponseApxCtrl {
    
    public static final String TOP_OF_PAGE_ERROR = 'TOP_OF_PAGE_ERROR';
    private static final String TOP_OF_PAGE_ERRORCODE_PATTERN =  '(.*)(:)(.*)';
    //Required fields are missing: [Phone Number]
    
    /**
* Generates a list of List<APXFieldValidationError> and a list of SaveResulsts
* @param List<SObject> containing the records to package in the CrudResponse
* @param List<DataBase.SaveResult> containing the response from the database transaction
* @return List<APXFieldValidationError> which contains the records and validation errors
**/
    public static List<APXFieldValidationError> getCrudResponseFromSaveResults(List<SObject> sObjects, List<Database.SaveResult> saveResults) {
        List<APXFieldValidationError> validationErrorList = new List<APXFieldValidationError>();
        System.debug('sObjects-->'+sObjects);
        System.debug('saveResults-->'+saveResults);
        for(Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult saveResult = saveResults[i];
            if(saveResult != null){
            List<Database.Error> saveResultErrors = saveResult.getErrors();
            for(Integer j = 0; j < saveResultErrors.size(); j++) {
                Database.Error saveResultError = saveResultErrors[j];
                String errorFieldName = TOP_OF_PAGE_ERROR; 
                Boolean isTopOfPageError = true;
                // validation rules causes problems when displayed at top of page   
                System.debug(saveResultError);
                if(Pattern.matches(TOP_OF_PAGE_ERRORCODE_PATTERN, saveResultError.getMessage()) || saveResultError.getFields().isEmpty()){
                    validationErrorList.add(new APXFieldValidationError(sObjects[i].getSObjectType().getDescribe().getName(),
                                                                        null,
                                                                        saveResultError.getMessage(),
                                                                        sObjects[i].id,
                                                                        true,String.valueOf(i)
                                                                       ));
                }else{
                    validationErrorList.add(new APXFieldValidationError(sObjects[i].getSObjectType().getDescribe().getName(),
                                                                        saveResultError.getFields()[0],
                                                                        saveResultError.getMessage(),
                                                                        sObjects[i].id,
                                                                        false,String.valueOf(i)
                                                                       ));
                }
            }
            }
        }
        return validationErrorList;
    }
    
    
}