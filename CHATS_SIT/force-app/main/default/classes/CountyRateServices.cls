/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/26/2017                                                          
*  @description    Handler class for County Rate Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 26-Sept-2017                                                             
*  * Author: Shubham Khandelwal                                                      
*  * Description: Initial version                                                 
*                                                                                 
*********************************************************************************************/

public with sharing class CountyRateServices {
    
    public static final String FT = '3'; 
    public static final String PT = '2'; 
    public static final String FTPT = '4';
    public static final String FTFT = '5';
    public static final List<String> fullTimeCopyRateTypes = Label.FullTimeCopyRateTypes.split(';') ;
    
    public static Map<String, Decimal> unitTypeToMultiplicationFactor{
        get{
            if(unitTypeToMultiplicationFactor == null){
                unitTypeToMultiplicationFactor = new Map<String, Decimal>();
                //query metadata and populate
                for(County_Rate_Unit_Amount_Calculation__mdt  rateAmtMultiplication:[Select Multiplication_Factor__c, Rate_Unit_Type__c from County_Rate_Unit_Amount_Calculation__mdt where Multiplication_Factor__c!=null and Rate_Unit_Type__c!=null ]){
                    unitTypeToMultiplicationFactor.put(rateAmtMultiplication.Rate_Unit_Type__c, rateAmtMultiplication.Multiplication_Factor__c);
                }
                
            }
            
            return unitTypeToMultiplicationFactor;
        }set;
    }
    
    public static void  updateCountyRateAmountsOnFTAmtUpdate(List<T_COUNTY_RATE_AMT__c> filteredCountyRates, Boolean isUpdate){
        
        Map<String, T_COUNTY_RATE_AMT__c> uniqueKeyToFtRateAmt = new Map<String, T_COUNTY_RATE_AMT__c>();
        Map<Id, Id> ftRateAmtToRatePlanId = new Map<Id, Id>();
        Set<Id> crpIds = new Set<Id>();
        
        for(T_COUNTY_RATE_AMT__c ftCountyRateAmt : filteredCountyRates){ 
            String key = ftCountyRateAmt.CDE_PROVR_TYPE__c + '_' +
                ftCountyRateAmt.CDE_RATE_TYPE__c + '_' + ftCountyRateAmt.CDE_AGE_GROUP__c+'_'+
                ftCountyRateAmt.CDE_TIER__c + '_' + ftCountyRateAmt.IDN_COUNTY_RATE__c;
            uniqueKeyToFtRateAmt.put(key, ftCountyRateAmt);
            ftRateAmtToRatePlanId.put(ftCountyRateAmt.Id, ftCountyRateAmt.IDN_COUNTY_RATE__c);
            crpIds.add(ftCountyRateAmt.IDN_COUNTY_RATE__c);
        }
        List<T_COUNTY_RATE_AMT__c> countyRatesToBeUpdated = new List<T_COUNTY_RATE_AMT__c>();
        for(T_COUNTY_RATE__c aCountyRate : [Select Id, (Select Id,IDN_COUNTY_RATE__c,NBR_AMOUNT__c,CDE_UNIT__c,CDE_RATE_TYPE__c,CDE_PROVR_TYPE__c,CDE_AGE_GROUP__c,CDE_TIER__c from County_Rate__r) from T_COUNTY_RATE__c where id In :crpIds]){
            for(T_COUNTY_RATE_AMT__c aCountyRateAmt : aCountyRate.County_Rate__r){
                String key = aCountyRateAmt.CDE_PROVR_TYPE__c + '_' +
                    aCountyRateAmt.CDE_RATE_TYPE__c + '_' + aCountyRateAmt.CDE_AGE_GROUP__c+'_'+
                    aCountyRateAmt.CDE_TIER__c + '_' + aCountyRateAmt.IDN_COUNTY_RATE__c;
                if(isUpdate){
                    if(uniqueKeyToFtRateAmt.containsKey(key) && aCountyRateAmt.CDE_UNIT__c != FT && aCountyRateAmt.CDE_UNIT__c != null){
                        T_COUNTY_RATE_AMT__c ftRateAmt = uniqueKeyToFtRateAmt.get(key);
                        if(fullTimeCopyRateTypes.contains(aCountyRateAmt.CDE_RATE_TYPE__c)){
                            aCountyRateAmt.NBR_AMOUNT__c = ftRateAmt.NBR_AMOUNT__c.setScale(2,System.RoundingMode.HALF_UP) ;
                        }else{
                            aCountyRateAmt.NBR_AMOUNT__c = (ftRateAmt.NBR_AMOUNT__c * unitTypeToMultiplicationFactor.get(aCountyRateAmt.CDE_UNIT__c)).setScale(2,System.RoundingMode.HALF_UP);
                        }
                        countyRatesToBeUpdated.add(aCountyRateAmt);
                    }
                }else{
                    if(uniqueKeyToFtRateAmt.containsKey(key) && aCountyRateAmt.CDE_UNIT__c == FT && aCountyRateAmt.CDE_UNIT__c != null){
                        T_COUNTY_RATE_AMT__c ftRateAmt = uniqueKeyToFtRateAmt.get(key);
                        // Creating PT,FTFT and PTFT records
                        T_COUNTY_RATE_AMT__c countRateAmtFTPT = new T_COUNTY_RATE_AMT__c();
                        if(fullTimeCopyRateTypes.contains(ftRateAmt.CDE_RATE_TYPE__c)){
                            countRateAmtFTPT.NBR_AMOUNT__c = ftRateAmt.NBR_AMOUNT__c .setScale(2,System.RoundingMode.HALF_UP); 
                        }
                        else{
                            countRateAmtFTPT.NBR_AMOUNT__c = (ftRateAmt.NBR_AMOUNT__c * unitTypeToMultiplicationFactor.get('4')).setScale(2,System.RoundingMode.HALF_UP);
                        }
                        countRateAmtFTPT.CDE_UNIT__c = '4';
                        countRateAmtFTPT.CDE_RATE_TYPE__c = ftRateAmt.CDE_RATE_TYPE__c;
                        countRateAmtFTPT.CDE_PROVR_TYPE__c =  ftRateAmt.CDE_PROVR_TYPE__c;
                        countRateAmtFTPT.CDE_TIER__c = ftRateAmt.CDE_TIER__c;
                        countRateAmtFTPT.CDE_RATE_TEMPLT__c = ftRateAmt.CDE_RATE_TEMPLT__c;
                        countRateAmtFTPT.CDE_AGE_GROUP__c =ftRateAmt.CDE_AGE_GROUP__c;
                        countRateAmtFTPT.IDN_COUNTY_RATE__c = ftRateAmt.IDN_COUNTY_RATE__c;
                        countyRatesToBeUpdated.add(countRateAmtFTPT);
                        T_COUNTY_RATE_AMT__c countRateAmtPT = new T_COUNTY_RATE_AMT__c();
                        if(fullTimeCopyRateTypes.contains(ftRateAmt.CDE_RATE_TYPE__c)){
                            countRateAmtPT.NBR_AMOUNT__c = ftRateAmt.NBR_AMOUNT__c.setScale(2,System.RoundingMode.HALF_UP); 
                        }
                        else{
                            countRateAmtPT.NBR_AMOUNT__c = (ftRateAmt.NBR_AMOUNT__c * unitTypeToMultiplicationFactor.get('2')).setScale(2,System.RoundingMode.HALF_UP);
                        }
                        countRateAmtPT.CDE_UNIT__c = '2';
                        countRateAmtPT.CDE_RATE_TYPE__c = ftRateAmt.CDE_RATE_TYPE__c;
                        countRateAmtPT.CDE_PROVR_TYPE__c =  ftRateAmt.CDE_PROVR_TYPE__c;
                        countRateAmtPT.CDE_TIER__c = ftRateAmt.CDE_TIER__c;
                        countRateAmtPT.CDE_RATE_TEMPLT__c = ftRateAmt.CDE_RATE_TEMPLT__c;
                        countRateAmtPT.CDE_AGE_GROUP__c =ftRateAmt.CDE_AGE_GROUP__c;
                        countRateAmtPT.IDN_COUNTY_RATE__c = ftRateAmt.IDN_COUNTY_RATE__c;
                        countyRatesToBeUpdated.add(countRateAmtPT);
                        T_COUNTY_RATE_AMT__c countRateAmtFTFT = new T_COUNTY_RATE_AMT__c();
                        if(fullTimeCopyRateTypes.contains(ftRateAmt.CDE_RATE_TYPE__c)){
                            countRateAmtFTFT.NBR_AMOUNT__c = ftRateAmt.NBR_AMOUNT__c.setScale(2,System.RoundingMode.HALF_UP);
                        }
                        else{
                            countRateAmtFTFT.NBR_AMOUNT__c = (ftRateAmt.NBR_AMOUNT__c * unitTypeToMultiplicationFactor.get('5')).setScale(2,System.RoundingMode.HALF_UP);
                        }
                        countRateAmtFTFT.CDE_UNIT__c = '5';
                        countRateAmtFTFT.CDE_RATE_TYPE__c = ftRateAmt.CDE_RATE_TYPE__c;
                        countRateAmtFTFT.CDE_PROVR_TYPE__c =  ftRateAmt.CDE_PROVR_TYPE__c;
                        countRateAmtFTFT.CDE_TIER__c = ftRateAmt.CDE_TIER__c;
                        countRateAmtFTFT.CDE_RATE_TEMPLT__c = ftRateAmt.CDE_RATE_TEMPLT__c;
                        countRateAmtFTFT.CDE_AGE_GROUP__c =ftRateAmt.CDE_AGE_GROUP__c;
                        countRateAmtFTFT.IDN_COUNTY_RATE__c = ftRateAmt.IDN_COUNTY_RATE__c;
                        countyRatesToBeUpdated.add(countRateAmtFTFT);
                    }
                }
            }
        }
        updateCountyRates(countyRatesToBeUpdated, uniqueKeyToFtRateAmt);
    }
    
    //[SJ 7/3/18: Split the records into lists to insert and update separately]
    public static void updateCountyRates(List<T_COUNTY_RATE_AMT__c> countyRates, Map<String, T_COUNTY_RATE_AMT__c> uniqueKeyToFtRateAmt){
        List<T_COUNTY_RATE_AMT__c> recordsToBeInserted = new List<T_COUNTY_RATE_AMT__c>();
        List<T_COUNTY_RATE_AMT__c> recordsToBeUpdated = new List<T_COUNTY_RATE_AMT__c>();
        for(T_COUNTY_RATE_AMT__c countyRate:countyRates){
            if(String.isEmpty(countyRate.id)){
                recordsToBeInserted.add(countyRate);
            }else{
                recordsToBeUpdated.add(countyRate);
            }
        }
        //Inserting records
        try{
            if(!recordsToBeInserted.isEmpty()){
                GenericDMLHandler.insertRecords(recordsToBeInserted, new Map<String,Object>{'Class__c'=>'CountyRateServices','Method__c'=>'updateCountyRates'});
            }
        }catch(Exception dEX){
            for(Integer i=0;i<dEX.getNumDML();i++){
                T_COUNTY_RATE_AMT__c countyRateAmt = recordsToBeInserted[dEX.getDmlIndex(i)];
                String key = countyRateAmt.CDE_PROVR_TYPE__c + '_' +
                    countyRateAmt.CDE_RATE_TYPE__c + '_' + countyRateAmt.CDE_AGE_GROUP__c+'_'+
                    countyRateAmt.CDE_TIER__c + '_' + countyRateAmt.IDN_COUNTY_RATE__c;            
                if(uniqueKeyToFtRateAmt.containsKey(key)){
                    uniqueKeyToFtRateAmt.get(key).addError(dEX.getDmlMessage(i));
                }
            }
        }
        //Updating records
        try{
            if(!recordsToBeUpdated.isEmpty()){
                GenericDMLHandler.updateRecords(recordsToBeUpdated, new Map<String,Object>{'Class__c'=>'CountyRateServices','Method__c'=>'updateCountyRates'});
            }
        }catch(Exception dEX){
            for(Integer i=0;i<dEX.getNumDML();i++){
                T_COUNTY_RATE_AMT__c countyRateAmt = recordsToBeUpdated[dEX.getDmlIndex(i)];
                String key = countyRateAmt.CDE_PROVR_TYPE__c + '_' +
                    countyRateAmt.CDE_RATE_TYPE__c + '_' + countyRateAmt.CDE_AGE_GROUP__c+'_'+
                    countyRateAmt.CDE_TIER__c + '_' + countyRateAmt.IDN_COUNTY_RATE__c;            
                if(uniqueKeyToFtRateAmt.containsKey(key)){
                    uniqueKeyToFtRateAmt.get(key).addError(dEX.getDmlMessage(i));
                }
            }
        }
    }
    
    public static List<T_COUNTY_RATE_AMT__c> filterFTRatesWhereAmtIdUpdated(List<T_COUNTY_RATE_AMT__c> newCountyRates, 
                                                                            Map<Id, T_COUNTY_RATE_AMT__c> oldCountyRates, Boolean isUpdate){
                                                                                List<T_COUNTY_RATE_AMT__c> filteredCountyRates = new List<T_COUNTY_RATE_AMT__c>();
                                                                                for(T_COUNTY_RATE_AMT__c aCountyRate :newCountyRates){
                                                                                    if(isUpdate){
                                                                                        if(aCountyRate.CDE_UNIT__c == FT && 
                                                                                           (aCountyRate.NBR_AMOUNT__c != oldCountyRates.get(aCountyRate.Id).NBR_AMOUNT__c)){
                                                                                               filteredCountyRates.add(aCountyRate);
                                                                                           }  
                                                                                    }else{
                                                                                        if(aCountyRate.CDE_UNIT__c == FT){
                                                                                            filteredCountyRates.add(aCountyRate);
                                                                                        }
                                                                                    }
                                                                                }
                                                                                return filteredCountyRates;
                                                                            }    
}