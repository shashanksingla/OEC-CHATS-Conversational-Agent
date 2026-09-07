/********************************************************************************************
* NAME         : APXCreateCountyRatesController
* DESCRIPTION  : This aura enabled controller provides the business logic for "createCountyRates" lightining wizard.
* @AUTHOR SHUBHAM JAIN
* @DATE 09/25/2017
*
*
* MODIFICATION LOG:
* DEVELOPER                         DATE                               DESCRIPTION
* ----------------------------------------------------------------------------                 
********************************************************************************************/
public with sharing class APXCreateCountyRatesController {
    Final static String CARE_UNIT = '3';
    
    /********************************************************************************************
METHOD NAME    : getCountyRateWithCountyRateAmounts
DESCRIPTION    : fetches T_COUNTY_RATE__c header information based on recordId, along with related county rate amount records based on providerType.
RETURN TYPE    : T_COUNTY_RATE__c
PARAMETER      : String recordId,String providerType
********************************************************************************************/
    @AuraEnabled
    public static LightningServerResponse getCountyRateWithCountyRateAmounts(String recordId,String providerType){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        
        List<T_COUNTY_RATE__c> countyRateWithCountyRateAmounts = [SELECT DTE_BEGIN_EFFV_RATE__c, 
                                                                  RATE_TYPE__c, CDE_STATUS__c, 
                                                                  CDE_RATE_PLAN_TEMPLT__c,IND_RATE_PLAN_TEMPLT__c, 
                                                                  IDN_COUNTY__c, IDN_COUNTY__r.Name,
                                                                  RT_Q8_1__c,
                                                                  RT_Q8_1P__c,
                                                                  RT_Q8_2__c,
                                                                  RT_Q8_2P__c,
                                                                  RT_Q8_3__c,
                                                                  RT_Q8_3P__c,
                                                                  RT_Q8_4__c,
                                                                  RT_Q8_4P__c,
                                                                  RT_Q8_5__c,
                                                                  RT_Q8_5P__c,
                                                                  RT_Q8_6__c,
                                                                  RT_Q8_6P__c,
                                                                  RT_Q8_7__c,
                                                                  RT_Q8_7P__c,
                                                                  RT_Q8_8__c,
                                                                  RT_Q8_8P__c,
                                                                  (SELECT Id, CDE_AGE_GROUP__c, NBR_AMOUNT__c, CDE_UNIT__c, 
                                                                   CDE_RATE_TEMPLT__c, CDE_PROVR_TYPE__c, CDE_RATE_TYPE__c, 
                                                                   CDE_TIER__c FROM County_Rate__r WHERE CDE_PROVR_TYPE__c =:providerType )
                                                                  FROM T_COUNTY_RATE__c WHERE id = :recordId];
        if(!countyRateWithCountyRateAmounts.isEmpty()){
            isSuccessful = true;
            objectData.put('countyRateWithCountyRateAmounts',countyRateWithCountyRateAmounts.get(0));
        }else{
            isSuccessful = false;
            message = Label.No_County_Rate_record_found_for_the_provided_record_Id;           
        }
        List<AgeGroupWrapper> lstTierGroupValuetoLabel = CHATSUtility.getPicklistValuesToLabelList(T_COUNTY_RATE_AMT__c.CDE_AGE_GROUP__c.getDescribe());        
        if(lstTierGroupValuetoLabel!= null)
        {
            objectData.put('lstTierGroupValuetoLabel',JSON.serialize(lstTierGroupValuetoLabel));
        }
        Map<String, String> mapRateTypeValuetoLabel = CHATSUtility.getPicklistValuesToLabelMap(T_COUNTY_RATE_AMT__c.CDE_RATE_TYPE__c.getDescribe());
        if(mapRateTypeValuetoLabel!= null)
        {
            objectData.put('mapRateTypeValuetoLabel',JSON.serialize(mapRateTypeValuetoLabel));
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    
    /********************************************************************************************
METHOD NAME    : saveLstCountyRateAmount
DESCRIPTION    : upserts the list of T_COUNTY_RATE_AMT__c and fetches the list of county rate amount records based on recordId & providerType.
RETURN TYPE    : Map<String,Object>
PARAMETER      : List<T_COUNTY_RATE_AMT__c> lstCountyRateAmount, String recordId, String providerType
********************************************************************************************/
    @auraEnabled
    public static Map<String,Object> saveLstCountyRateAmount(List<T_COUNTY_RATE_AMT__c> lstCountyRateAmount,String recordId,String providerType){
        
        Map<Id,T_COUNTY_RATE_AMT__c> mapCountyRateAmountId = new Map<Id,T_COUNTY_RATE_AMT__c>([SELECT Id, NBR_AMOUNT__c FROM T_COUNTY_RATE_AMT__c WHERE IDN_COUNTY_RATE__c =:recordId]);
        
        List<T_COUNTY_RATE_AMT__c> lstCountyRateAmountToBeInserted = new List<T_COUNTY_RATE_AMT__c>();
        List<T_COUNTY_RATE_AMT__c> lstCountyRateAmountToBeUpdated = new List<T_COUNTY_RATE_AMT__c>();
        Map<String,Object> objectData = new Map<String,Object>();
        
        for(T_COUNTY_RATE_AMT__c countyRateAmount:lstCountyRateAmount){
            if(!mapCountyRateAmountId.containsKey(countyRateAmount.Id)){
                if(countyRateAmount.CDE_UNIT__c==CARE_UNIT){
                    lstCountyRateAmountToBeInserted.add(countyRateAmount);
                }
            }else if(mapCountyRateAmountId.get(countyRateAmount.Id).NBR_AMOUNT__c!=countyRateAmount.NBR_AMOUNT__c){
                if(countyRateAmount.CDE_UNIT__c==CARE_UNIT){
                    lstCountyRateAmountToBeUpdated.add(countyRateAmount);
                }
            }
        }
        
        List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
        List<CRUDPermissionException> lstCrudPermissionException = new List<CRUDPermissionException>();
        
        if(!lstCountyRateAmountToBeInserted.isEmpty()){
            List<DMLResult> lstDMLResult = GenericDMLHandler.insertRecords(lstCountyRateAmountToBeInserted, false, null);
            lstSaveResult.addAll(GenericDMLHandler.getSaveResultsFromDMLResults(lstDMLResult));
            lstCrudPermissionException.addAll(GenericDMLHandler.getCRUDPermissionExceptionsFromDMLResults(lstDMLResult));
        }
        
        if(!lstCountyRateAmountToBeUpdated.isEmpty()){
            List<DMLResult> lstDMLResult = GenericDMLHandler.updateRecords(lstCountyRateAmountToBeUpdated, false, null);
            lstSaveResult.addAll(GenericDMLHandler.getSaveResultsFromDMLResults(lstDMLResult));
            lstCrudPermissionException.addAll(GenericDMLHandler.getCRUDPermissionExceptionsFromDMLResults(lstDMLResult));
        }
        
        Set<String> lstErrors = new Set<String>();
        if(!lstCrudPermissionException.isEmpty()){
            for(CRUDPermissionException crudPermissionException:lstCrudPermissionException){
                lstErrors.add(JSON.serialize(new List<Object>{new Map<String,String>{'message'=>crudPermissionException.getMessage()}}));
            }
        }else{
            for(Database.SaveResult saveResult:lstSaveResult){
                if(!saveResult.getErrors().isEmpty()){
                    lstErrors.add(JSON.serialize(saveResult.getErrors()));
                }
            }
        }
        
        if(!lstErrors.isEmpty()){
            objectData.put('isSuccessful', false);
            objectData.put('lstErrors', lstErrors);
        }else{
            objectData.put('isSuccessful', true);
            if(String.isNotEmpty(providerType)){
                objectData.put('lstExistingCountyRateAmount', [SELECT Id, CDE_AGE_GROUP__c, NBR_AMOUNT__c, CDE_UNIT__c, CDE_RATE_TEMPLT__c, CDE_PROVR_TYPE__c, CDE_RATE_TYPE__c, CDE_TIER__c FROM T_COUNTY_RATE_AMT__c WHERE CDE_PROVR_TYPE__c =:providerType AND IDN_COUNTY_RATE__c=:recordId ]);
            }
        }
        return objectData;
    }
    
}