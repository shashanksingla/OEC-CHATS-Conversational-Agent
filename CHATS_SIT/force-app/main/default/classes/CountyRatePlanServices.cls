/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/07/2017                                                          
*  @description    Handler class for County Rate Plan Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 9-Sept-2017                                                             
*  * Author: Shubham Khandelwal                                                      
*  * Description: Initial version                                                
*                                                                                 
*  * Version: 2.0                                                                             
*  * Date: 08-Dec-2017                                                             
*  * Author: Azharuddin Mohammad
*  * Description: CHAT-1051, Populate Effv End Date of previous record with new record begindate - 1 
*  *
*  * Version: 3.0                                                                             
*  * Date: 13-Feb-2017                                                             
*  * Author: Azharuddin Mohammad
*  * Description: CHAT-2865, user should not be able to create multiple template with same name.
*  * if a template exists with same name and Template Indicator as checked, then user should not be able to create new county Rate plan for that county
*  
*  * Version: 4.0                                                                             
*  * Date: 05-30-2018                                                             
*  * Author: Gaurav Trivedi
*  * Description: Ristrict multiple county plans of Draft type for one county. Added as a part of CHATS-4910 bug fix
*
*  * Version: 5.0                                                                             
*  * Date: 06-18-2018                                                             
*  * Author: Shubham Jain
*  * Description: Removed SOQL query from for loop.
*********************************************************************************************/
public with sharing class CountyRatePlanServices {
    
    public static final String DRAFT = 'PEN';
    public static final String NONE = '5';
    public static final String APPROVED = 'APV';
    public static final String NEED_REVISION = 'NRV';
    public static final String SUBMITTED = 'SUB';
    public static final String INPROGRESS= 'In Progress';
    public static final String NORMAL= 'Normal';
    public static boolean templateRecordUpdate= false;
    public static final String CARE_UNIT = '3';
    
    
    
    /**
* @description Validate county rate plan status before deletion
* @author Shubham Khandelwal
* @date 09/07/2017
* @param List<T_COUNTY_RATE__c> trigger.old county plan list
* @return void
*/
    
    public static void validateBeforeDelete(List<T_COUNTY_RATE__c> oldCountyRatePlans){
        for(T_COUNTY_RATE__c aCountyRatePlan:oldCountyRatePlans){
            if(aCountyRatePlan.CDE_STATUS__c != DRAFT && aCountyRatePlan.County_Rate_Plan__c ==null){
                aCountyRatePlan.addError(Label.County_Rate_Plan_Delete_ErrorMessage);
            }
        }
    } 
    
    /**
* @description filter county rate plan template records.
* @author Shubham Jain
* @date 09/29/2017
* @param List<T_County_Rate__c> newCountyRatePlans
* @return List<T_County_Rate__c>
*/
    public static List<T_County_Rate__c> filterCountyRatePlanTemplateRecords(List<T_County_Rate__c> newCountyRatePlans){
        List<T_County_Rate__c> filteredCountyRatePlanTemplateRecords = new List<T_County_Rate__c>();
        for(T_County_Rate__c newCountyRate : newCountyRatePlans){            
            if(newCountyRate.IND_RATE_PLAN_TEMPLT__c || newCountyRate.CDE_RATE_PLAN_TEMPLT__c=='5' ){
                filteredCountyRatePlanTemplateRecords.add(newCountyRate);
            }
        }
        return filteredCountyRatePlanTemplateRecords;
    }
    
    /**
* @description: creates county rate amount records
* @author Shubham Jain
* @date 09/29/2017
* @param List<T_County_Rate__c> newCountyRatePlans, Map<Id,T_County_Rate__c> newCountyRateMap
* @return void
*/
    public static void createCountyRateAmountRecords(List<T_County_Rate__c> newCountyRatePlans, Map<Id,T_County_Rate__c> newCountyRateMap, Map<Id,T_County_Rate__c> oldCountyRateMap){
        List<String> lstProviderTypes = getPicklistValues(T_COUNTY_RATE_AMT__c.CDE_PROVR_TYPE__c.getDescribe());        
        Map<String,List<String>> mapProviderTypeTierValues = new Map<String,List<String>>{
            'CEN'=>new List<String>{'2','3','4','5','6'},
                'HOM'=>new List<String>{'2','3','4','5','6'},
                    'EXE'=>new List<String>{'1'}                
        };
            List<String> listOfTemplate=new List<String>();
        Set<String> setRateTypeToBeCloned = new Set<String>();
        Set<String> setRateTypeToBeDeleted = new Set<String>();
        List<Id> lstRateAmountToBeDeleted = new List<Id>();
        Set<String> setNewRateType = new Set<String>();
        Set<String> setOldRateType = new Set<String>();        
        for(T_COUNTY_RATE__c newCountyRate : newCountyRatePlans){
            if(newCountyRate.County_Rate_Plan__c == null){
                if(!String.isEmpty(newCountyRate.RATE_TYPE__c)){
                    setNewRateType = new Set<String>(newCountyRate.RATE_TYPE__c.split(';')) ;
                }
                if(!String.isEmpty(oldCountyRateMap.get(newCountyRate.Id).RATE_TYPE__c)){
                    setOldRateType = new Set<String>(oldCountyRateMap.get(newCountyRate.Id).RATE_TYPE__c.split(';')) ;
                }
                for(String newRateType : setNewRateType){
                    if(!setOldRateType.contains(newRateType)){
                        setRateTypeToBeCloned.add(newRateType); 
                    }
                }
                for(String oldRateType : setOldRateType){
                    if(!setNewRateType.contains(oldRateType)){
                        setRateTypeToBeDeleted.add(oldRateType); 
                    }
                }
            } 
        }        
        List<String> lstAgeGroup = getPicklistValues(T_COUNTY_RATE_AMT__c.CDE_AGE_GROUP__c.getDescribe());        
        //List<String> lstRateTypes = getPicklistValues(T_COUNTY_RATE_AMT__c.CDE_RATE_TYPE__c.getDescribe());  
        List<String> lstRateTypes = new List<String>(setRateTypeToBeCloned);
        List<T_COUNTY_RATE_AMT__c> lstCountyRateAmount = new List<T_COUNTY_RATE_AMT__c>();
        List<Id> countyRatePlanIdsToBeDeleted = new List<Id>();
        for(T_County_Rate__c countyRatePlan : newCountyRatePlans){
            if(countyRatePlan.County_Rate_Plan__c == null){
                Set<String> selectedRateTypes = new Set<String>();
                for(String rateType:lstRateTypes){
                    for(String providerType:lstProviderTypes){
                        if(mapProviderTypeTierValues.containsKey(providerType)){
                            for(String tierValue:mapProviderTypeTierValues.get(providerType)){
                                for(String ageGroup:lstAgeGroup){
                                    T_COUNTY_RATE_AMT__c countyRateAmount = new T_COUNTY_RATE_AMT__c();
                                    lstCountyRateAmount.add(new T_COUNTY_RATE_AMT__c(CDE_AGE_GROUP__c = ageGroup,CDE_PROVR_TYPE__c = providerType,CDE_RATE_TEMPLT__c = countyRatePlan.CDE_RATE_PLAN_TEMPLT__c,CDE_RATE_TYPE__c = rateType,CDE_TIER__c = tierValue,CDE_UNIT__c = CARE_UNIT,IDN_COUNTY_RATE__c = countyRatePlan.Id,NBR_AMOUNT__c = 0
                                                                                    ));
                                }
                            }
                        }
                    }
                }                
                if(!setRateTypeToBeDeleted.isEmpty()){
                    countyRatePlanIdsToBeDeleted.add(countyRatePlan.Id);
                }
            }
        }
        
        if(!countyRatePlanIdsToBeDeleted.isEmpty()){
            for(T_COUNTY_RATE_AMT__c countyRateAmount :[Select id from T_COUNTY_RATE_AMT__c where IDN_COUNTY_RATE__c IN:countyRatePlanIdsToBeDeleted and CDE_RATE_TYPE__c not in :setNewRateType]){
                lstRateAmountToBeDeleted.add(countyRateAmount.Id);
            }
        }
        
        if(!lstRateAmountToBeDeleted.isEmpty()){
            GenericWithoutSharingDMLOperations.setRecordsIdsToBeDeleted(lstRateAmountToBeDeleted);
            GenericWithoutSharingDMLOperations.deleteRecords( new Map<String,Object>{'Class__c'=>'CountyRatePlanServices','Method__c'=>'createCountyRateAmountRecords'});
        }
        
        if(!lstCountyRateAmount.isEmpty()){
            List<Database.SaveResult> lstSaveResult =GenericDMLHandler.getSaveResultsFromDMLResults(GenericDMLHandler.insertRecords(lstCountyRateAmount,false, new Map<String,Object>{'Class__c'=>'CountyRatePlanServices','Method__c'=>'createCountyRateAmountRecords'}));
            for(Integer i = 0;i<lstSaveResult.size();i++){
                if(!lstSaveResult.get(i).getErrors().isEmpty()){
                    Database.Error error=lstSaveResult.get(i).getErrors().get(0);String failedDML = error.getMessage();Id countyRatePlanId = lstCountyRateAmount.get(i).IDN_COUNTY_RATE__c;
                    newCountyRateMap.get(countyRatePlanId).addError(Label.County_Rate_Insert_Error+' : '+failedDML);
                }
            }
        }
        
    }
    
    public static List<String> getPicklistValues(Schema.DescribeFieldResult fieldResult){
        List<String> lstPicklistValues = new List<String>();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            lstPicklistValues.add(f.getValue());
        }       
        return lstPicklistValues;
    }    
    
    
    public static List<T_County_Rate__c> filterCountyRatePlans(List<T_County_Rate__c> newCountyRatePlans){
        List<T_County_Rate__c> filteredCountyRatePlans = new List<T_County_Rate__c>();
        for(T_County_Rate__c newCountyRate : newCountyRatePlans){            
            if(!newCountyRate.IND_RATE_PLAN_TEMPLT__c && String.isNotEmpty(newCountyRate.CDE_RATE_PLAN_TEMPLT__c) && newCountyRate.CDE_RATE_PLAN_TEMPLT__c!= NONE && newCountyRate.County_Rate_Plan__c==null){
                filteredCountyRatePlans.add(newCountyRate);
            }
            
        }
        return filteredCountyRatePlans;
    }
    
    public static void cloneRateTemplateRecord(List<T_County_Rate__c> newCountyRatePlans,Map<Id,T_County_Rate__c> newCountyRateMap, Map<Id,T_County_Rate__c>oldCountyRateMap){
        if(newCountyRatePlans != null){
            List<String> listOfTemplate=new List<String>();
            Set<String> setRateTypeToBeCloned = new Set<String>();
            Set<String> setRateTypeToBeDeleted = new Set<String>();
            List<Id> lstRateAmountToBeDeleted = new List<Id>();
            Set<String> setNewRateType= new Set<String>();
            Set<String> setOldRateType = new Set<String>();
            Set<Id> setOfCounty = new Set<Id>();
            for(T_County_Rate__c countyRate:newCountyRatePlans ){
                if(countyRate.County_Rate_Plan__c == null){
                    listOfTemplate.add(countyRate.CDE_RATE_PLAN_TEMPLT__c);
                    setOfCounty.add(countyRate.IDN_COUNTY__c);
                    if(!String.isEmpty(countyRate.RATE_TYPE__c)){
                        setNewRateType = new Set<String>(countyRate.RATE_TYPE__c.split(';')) ;
                    }
                    if(!String.isEmpty(oldCountyRateMap.get(countyRate.Id).RATE_TYPE__c)){
                        setOldRateType = new Set<String>(oldCountyRateMap.get(countyRate.Id).RATE_TYPE__c.split(';')) ;
                    }
                    for(String newRateType : setNewRateType){
                        if(!setOldRateType.contains(newRateType)){
                            setRateTypeToBeCloned.add(newRateType); 
                        }
                    }
                    for(String oldRateType : setOldRateType){
                        if(!setNewRateType.contains(oldRateType)){
                            setRateTypeToBeDeleted.add(oldRateType); 
                        }
                    }
                }
            }
            
            Map<String, T_County_Rate__c> templateNameToTemplateCountyPlan = new Map<String, T_County_Rate__c>();
            List<Id> newCountyRateIdsToBeDeleted = new List<Id>();
            for(T_County_Rate__c aCRP: [Select Id, CDE_RATE_PLAN_TEMPLT__c,IDN_COUNTY__c,
                                        (select CDE_RATE_TYPE__c,IDN_COUNTY_RATE__c,
                                         NBR_AMOUNT__c,CDE_UNIT__c,CDE_TIER__c,CDE_RATE_TEMPLT__c,CDE_AGE_GROUP__c,
                                         CDE_PROVR_TYPE__c from County_Rate__r where CDE_UNIT__c=:CARE_UNIT and CDE_RATE_TYPE__c in :setRateTypeToBeCloned )
                                        from T_County_Rate__c
                                        where IND_RATE_PLAN_TEMPLT__c=true and CDE_RATE_PLAN_TEMPLT__c IN :listOfTemplate 
                                        AND CDE_STATUS__c=:APPROVED AND IDN_COUNTY__c IN :setOfCounty ]){
                                            templateNameToTemplateCountyPlan.put(aCRP.IDN_COUNTY__c+aCRP.CDE_RATE_PLAN_TEMPLT__c, aCRP);
                                        }
            List<T_COUNTY_RATE_AMT__c> countyRateAmountsToBeInserted = new List<T_COUNTY_RATE_AMT__c>();
            for(T_County_Rate__c newCountyRate : newCountyRatePlans){
                
                if(newCountyRate.County_Rate_Plan__c==null && templateNameToTemplateCountyPlan.containsKey(newCountyRate.IDN_COUNTY__c+newCountyRate.CDE_RATE_PLAN_TEMPLT__c)){
                    for(T_COUNTY_RATE_AMT__c countyRateAmtToBeCloned: templateNameToTemplateCountyPlan.get(newCountyRate.IDN_COUNTY__c+newCountyRate.CDE_RATE_PLAN_TEMPLT__c).County_Rate__r ){
                        T_COUNTY_RATE_AMT__c cloneCountyRateAmt = countyRateAmtToBeCloned.clone(false, false);   
                        cloneCountyRateAmt.IDN_COUNTY_RATE__c = newCountyRate.Id;
                        countyRateAmountsToBeInserted.add(cloneCountyRateAmt);
                    }
                }
                if(!setRateTypeToBeDeleted.isEmpty()){
                    newCountyRateIdsToBeDeleted.add(newCountyRate.Id);
                }
            }
            if(!newCountyRateIdsToBeDeleted.isEmpty()){
                for(T_COUNTY_RATE_AMT__c countyRateAmount :[Select id from T_COUNTY_RATE_AMT__c where IDN_COUNTY_RATE__c IN :newCountyRateIdsToBeDeleted and CDE_RATE_TYPE__c not in :setNewRateType]){
                    lstRateAmountToBeDeleted.add(countyRateAmount.Id);
                }
            }
            if(!lstRateAmountToBeDeleted.isEmpty()){
                GenericWithoutSharingDMLOperations.setRecordsIdsToBeDeleted(lstRateAmountToBeDeleted);
                GenericWithoutSharingDMLOperations.deleteRecords(new Map<String,Object>{'Class__c'=>'CountyRatePlanServices','Method__c'=>'cloneRateTemplateRecord'});
            }
            List<Database.SaveResult> insertResult = null;
            Database.Error error = null;
            if( !countyRateAmountsToBeInserted.isEmpty() ){
                insertResult = GenericDMLHandler.getSaveResultsFromDMLResults(GenericDMLHandler.insertRecords(countyRateAmountsToBeInserted,false, new Map<String,Object>{'Class__c'=>'CountyRatePlanServices','Method__c'=>'cloneRateTemplateRecord'}));
                for(Integer i = 0;i<insertResult.size();i++){
                    if(!insertResult.get(i).getErrors().isEmpty()){
                        error=insertResult.get(i).getErrors().get(0);String failedDML = error.getMessage();Id countyRatePlanId = countyRateAmountsToBeInserted.get(i).IDN_COUNTY_RATE__c;
                        newCountyRateMap.get(countyRatePlanId).addError(Label.County_Rate_Insert_Error+' : '+failedDML);
                    }
                }
            }
            
        }
    }
    
    
    public static void createTaskForApprovalProcessHandler(List<T_COUNTY_RATE__c> lstNewCountyRatePlans,Map<Id,T_COUNTY_RATE__c> mapOldCountyRatePlans){
        Map<Id,T_COUNTY_RATE__c> mapFilteredRejectedCountyRatePlans = new Map<Id,T_COUNTY_RATE__c>();
        for(T_COUNTY_RATE__c aCountyRatePlan : lstNewCountyRatePlans){
            if(aCountyRatePlan.CDE_STATUS__c != mapOldCountyRatePlans.get(aCountyRatePlan.Id).CDE_STATUS__c && aCountyRatePlan.CDE_STATUS__c == NEED_REVISION && aCountyRatePlan.County_Rate_Plan__c==null){
                mapFilteredRejectedCountyRatePlans.put(aCountyRatePlan.id,aCountyRatePlan);
            }
        }
        
        List<Task> lstCreatedTask = CountyApprovalProcessService.createTaskForRejectedCountyRatePlan(mapFilteredRejectedCountyRatePlans);
        
        if(lstCreatedTask.size()>0){
            List<Database.SaveResult> inserTasktList = GenericDMLHandler.getSaveResultsFromDMLResults(GenericDMLHandler.insertRecords(lstCreatedTask, false, new Map<String,Object>{'Class__c'=>'CountyRatePlanServices','Method__c'=>'createTaskForApprovalProcessHandler'})); 
            for(Integer i=0; i < inserTasktList.size() ; i++){
                if(!inserTasktList.get(i).isSuccess()){
                    List<Database.Error> lstError = inserTasktList.get(i).getErrors();
                    String failedDML;
                    for(Database.Error error : lstError){
                        failedDML = failedDML + '\n' + error.getMessage();
                    }
                    Task failedTask = lstCreatedTask.get(i);T_COUNTY_RATE__c countyRatePlan = mapFilteredRejectedCountyRatePlans.get(failedTask.WhatId);
                    countyRatePlan.addError('Unable to create task for this County Rate Plan Request : ' +failedDML);
                }
            }
        }
    }
    
    /**
* @description: CHAT-1051, Populate Effv End Date of previous record with new record begindate - 1
* @author Azharuddin Mohammad
* @date 08-Dec-2017
* @param List<T_COUNTY_RATE__c> newCountyRatePlanList
* @return void
*/ 
    public static void effvEndDate(List<T_COUNTY_RATE__c> newCountyRatePlanList,Map<Id,T_COUNTY_RATE__c> oldCountyRateMap){
        Set<Id> countyRatePlanIds = new Set<Id>();
        Map<Id, T_COUNTY_RATE__c> newCountyRatePlanRecords = new Map<Id, T_COUNTY_RATE__c>();
        Map<Id, T_COUNTY_RATE__c> oldCountyRatePlanRecords = new Map<Id, T_COUNTY_RATE__c>();
        for(T_COUNTY_RATE__c eachCountyRatePlan: newCountyRatePlanList){
            //added for CCCAP-13170
            if(!test.isRunningTest() && eachCountyRatePlan.CDE_STATUS__c!=oldCountyRateMap.get(eachCountyRatePlan.Id).CDE_STATUS__c && 
               (eachCountyRatePlan.CDE_STATUS__c == 'APV' ||  eachCountyRatePlan.CDE_STATUS__c =='NRV') 
               && eachCountyRatePlan.IDN_COUNTY__c != NULL && eachCountyRatePlan.Is_being_approved_by_Flow__c == false){
                   eachCountyRatePlan.addError('Please use the Approve or Reject County Rate Plan button to take the approval action.');
                   continue;
               }
            if(eachCountyRatePlan.CDE_STATUS__c!=oldCountyRateMap.get(eachCountyRatePlan.Id).CDE_STATUS__c && eachCountyRatePlan.CDE_STATUS__c == 'APV' && eachCountyRatePlan.IDN_COUNTY__c != NULL && eachCountyRatePlan.DTE_BEGIN_EFFV_RATE__c !=NULL && !eachCountyRatePlan.IND_RATE_PLAN_TEMPLT__c && eachCountyRatePlan.County_Rate_Plan__c==null){
                newCountyRatePlanRecords.put(eachCountyRatePlan.IDN_COUNTY__c , eachCountyRatePlan);
            }
            if(eachCountyRatePlan.Id !=NULL){
                countyRatePlanIds.add(eachCountyRatePlan.Id);
            }
        }
        
        for(T_COUNTY_RATE__c oldCountyRatePlanRec: [select Id, IDN_COUNTY__c, DTE_END_EFFV_RATE__c FROM T_COUNTY_RATE__c WHERE IDN_COUNTY__c IN:newCountyRatePlanRecords.keySet() AND CDE_STATUS__c = 'APV' AND Id NOT IN:countyRatePlanIds AND DTE_END_EFFV_RATE__c = NULL AND IND_RATE_PLAN_TEMPLT__c=false and County_Rate_Plan__c=null ]){
            if(newCountyRatePlanRecords.get(oldCountyRatePlanRec.IDN_COUNTY__c) != NULL){
                oldCountyRatePlanRec.DTE_END_EFFV_RATE__c = newCountyRatePlanRecords.get(oldCountyRatePlanRec.IDN_COUNTY__c).DTE_BEGIN_EFFV_RATE__c - 1;
                oldCountyRatePlanRecords.put(oldCountyRatePlanRec.Id, oldCountyRatePlanRec);
            }
        }
        if(oldCountyRatePlanRecords != NULL){
            GenericDMLHandler.updateRecords(oldCountyRatePlanRecords.values(), new Map<String,Object>{'Class__c'=>'CountyRatePlanServices','Method__c'=>'effvEndDate'});
        }
    }
    
    /**
* @description: if a template exists with same name and Template Indicator as checked, then user should not be able to create new county Rate plan for that county
* @author Azharuddin Mohammad
* @date 13-Feb-2017
* @param List<T_COUNTY_RATE__c> newCountyRatePlanList
* @return void
*/     
    public static void validateCountyRatePlanTemplate(List<T_COUNTY_RATE__c> newCountyRatePlanList) {
        map<Id, T_COUNTY_RATE__c> countyTemplateMap = new map<Id, T_COUNTY_RATE__c>();
        List<T_COUNTY_RATE__c> newCheckedtemplatesList = new list<T_COUNTY_RATE__c>();
        set<string> newRatePlanTemplates = new set<string>();
        Map<string, T_COUNTY_RATE__c > prvRatePlanTemplates = new Map<string, T_COUNTY_RATE__c>();
        if(!newCountyRatePlanList.isEmpty()){
            for(T_COUNTY_RATE__c eachCountyRatePlan: newCountyRatePlanList){
                if(eachCountyRatePlan.IND_RATE_PLAN_TEMPLT__c && eachCountyRatePlan.CDE_RATE_PLAN_TEMPLT__c !=null && eachCountyRatePlan.County_Rate_Plan__c==null ) {
                    newRatePlanTemplates.add(eachCountyRatePlan.CDE_RATE_PLAN_TEMPLT__c);
                    newCheckedtemplatesList.add(eachCountyRatePlan);
                }
            }    
        }
        if(!newRatePlanTemplates.isEmpty()){
            for(T_COUNTY_RATE__c eachPrvTemplateCheck : [select Id, CDE_RATE_PLAN_TEMPLT__c, IND_RATE_PLAN_TEMPLT__c, IDN_COUNTY__c FROM T_COUNTY_RATE__c WHERE CDE_RATE_PLAN_TEMPLT__c IN:newRatePlanTemplates AND IND_RATE_PLAN_TEMPLT__c =:true ]){
                if(eachPrvTemplateCheck.CDE_RATE_PLAN_TEMPLT__c != null) {
                    prvRatePlanTemplates.put(eachPrvTemplateCheck.CDE_RATE_PLAN_TEMPLT__c, eachPrvTemplateCheck);
                }
            }
        }
        if(prvRatePlanTemplates != null) {
            for(T_COUNTY_RATE__c eachSatisfiedTemplates : newCheckedtemplatesList) {
                if((eachSatisfiedTemplates !=null) && (prvRatePlanTemplates.keySet().contains(eachSatisfiedTemplates.CDE_RATE_PLAN_TEMPLT__c))
                   && prvRatePlanTemplates.get(eachSatisfiedTemplates.CDE_RATE_PLAN_TEMPLT__c).Id!=eachSatisfiedTemplates.Id  
                   && prvRatePlanTemplates.get(eachSatisfiedTemplates.CDE_RATE_PLAN_TEMPLT__c).IDN_COUNTY__c == eachSatisfiedTemplates.IDN_COUNTY__c){
                       T_COUNTY_RATE__c errorTemplate = new T_COUNTY_RATE__c();
                       errorTemplate = eachSatisfiedTemplates;
                       errorTemplate.addError('Template already exists for County');
                   }
            }
        }
    }
    
    public static void validateEffectiveBeginEndDateOfExistingCountyRatePlans(List<T_COUNTY_RATE__c> newCountyRatePlanList, Map<Id, T_COUNTY_RATE__c> oldMap){
        Set<Id> countyIdSet = new Set<Id>();
        Set<Id> newCountyRatePlanIdForEdit = new Set<Id>();
        Map<Id, List<T_COUNTY_RATE__c>> countyIdToExistingCountyRatePlansMap = new Map<Id, List<T_COUNTY_RATE__c>>();
        
        if(!newCountyRatePlanList.isEmpty()){
            for(T_COUNTY_RATE__c eachCountyRatePlan: newCountyRatePlanList){
                if(eachCountyRatePlan.IDN_COUNTY__c != null && eachCountyRatePlan.County_Rate_Plan__c==null){
                    if(oldMap ==  null){
                        countyIdSet.add(eachCountyRatePlan.IDN_COUNTY__c);
                    }
                    else if(oldMap !=  null && oldMap.containskey(eachCountyRatePlan.Id) && eachCountyRatePlan.DTE_BEGIN_EFFV_RATE__c != oldMap.get(eachCountyRatePlan.Id).DTE_BEGIN_EFFV_RATE__c){
                        countyIdSet.add(eachCountyRatePlan.IDN_COUNTY__c);
                        newCountyRatePlanIdForEdit.add(eachCountyRatePlan.Id);
                    }
                }
            }
        }
        
        if(!countyIdSet.isEmpty()){
            List<T_COUNTY_RATE__c> existingCountyRatePlans = [SELECT Id, Name, DTE_BEGIN_EFFV_RATE__c, DTE_END_EFFV_RATE__c, IDN_COUNTY__c, IND_RATE_PLAN_TEMPLT__c FROM T_COUNTY_RATE__c WHERE IDN_COUNTY__c in :countyIdSet AND IND_RATE_PLAN_TEMPLT__c=false];
            if(!existingCountyRatePlans.isEmpty()){
                for(T_COUNTY_RATE__c eachCountyRatePlan : existingCountyRatePlans){
                    if(!newCountyRatePlanIdForEdit.contains(eachCountyRatePlan.Id)){
                        if(countyIdToExistingCountyRatePlansMap.containsKey(eachCountyRatePlan.IDN_COUNTY__c)){
                            List<T_COUNTY_RATE__c> tempCountyRatePlanList = countyIdToExistingCountyRatePlansMap.get(eachCountyRatePlan.IDN_COUNTY__c);
                            tempCountyRatePlanList.add(eachCountyRatePlan);
                            countyIdToExistingCountyRatePlansMap.put(eachCountyRatePlan.IDN_COUNTY__c, tempCountyRatePlanList);
                        }
                        else{
                            countyIdToExistingCountyRatePlansMap.put(eachCountyRatePlan.IDN_COUNTY__c, new List<T_COUNTY_RATE__c>{eachCountyRatePlan});
                        }
                    }
                }
            }
        }
        if(!countyIdToExistingCountyRatePlansMap.isEmpty()){
            for(T_COUNTY_RATE__c newCountyRatePlan : newCountyRatePlanList){
                if(newCountyRatePlan.County_Rate_Plan__c==null && newCountyRatePlan.IDN_COUNTY__c != null && countyIdToExistingCountyRatePlansMap.containsKey(newCountyRatePlan.IDN_COUNTY__c)){
                    for(T_COUNTY_RATE__c existingCountyRatePlan : countyIdToExistingCountyRatePlansMap.get(newCountyRatePlan.IDN_COUNTY__c)){
                        if(!newCountyRatePlan.IND_RATE_PLAN_TEMPLT__c && existingCountyRatePlan.DTE_END_EFFV_RATE__c != null && (newCountyRatePlan.DTE_BEGIN_EFFV_RATE__c <= existingCountyRatePlan.DTE_BEGIN_EFFV_RATE__c || newCountyRatePlan.DTE_BEGIN_EFFV_RATE__c <= existingCountyRatePlan.DTE_END_EFFV_RATE__c)){
                            newCountyRatePlan.addError('New County Rate Plan can not be created prior to existing County Rate Plan.');
                        }
                        else if(!newCountyRatePlan.IND_RATE_PLAN_TEMPLT__c && existingCountyRatePlan.DTE_END_EFFV_RATE__c == null && newCountyRatePlan.DTE_BEGIN_EFFV_RATE__c <= existingCountyRatePlan.DTE_BEGIN_EFFV_RATE__c){
                            newCountyRatePlan.addError('New County Rate Plan can not be created prior to existing County Rate Plan.');
                        }
                    }
                }
            }
        }
    }
    /**    
* @description Insert Record in ATS Object
* @author Vineet Srivastava
* @date 4/12/2018   
* @param List<T_COUNTY_RATE__c> trigger.new Fiscal Agreements list,
* @return void
*/  
    public static void insertATSRecord(List<T_COUNTY_RATE__c> newCountyRatePlanList) {
        List<batchsit_t_pos_trans_queue_ats__x> lstATSRecords = new List<batchsit_t_pos_trans_queue_ats__x>();
        Set<Id> countyIdSet = new Set<Id>();
        Map<Id, Decimal> countyIdtoCodeMap = new Map<Id,Decimal>();
        for(T_COUNTY_RATE__c countyRatePlan:newCountyRatePlanList) {
            if(countyRatePlan.County_Rate_Plan__c ==null &&  countyRatePlan.CDE_STATUS__c=='APV'){
                countyIdSet.add(countyRatePlan.IDN_COUNTY__c);
            }
        }
        for(T_COUNTY__c countyRec: [Select Id, CDE_COUNTY__c from T_COUNTY__c where Id in :countyIdSet]){
            countyIdtoCodeMap.put(countyRec.Id, countyRec.CDE_COUNTY__c);
        }
        for(T_COUNTY_RATE__c countyRatePlan:newCountyRatePlanList) {
            if(countyRatePlan.County_Rate_Plan__c ==null && countyRatePlan.CDE_STATUS__c=='APV'){
                batchsit_t_pos_trans_queue_ats__x atsRecord = new batchsit_t_pos_trans_queue_ats__x();
                atsRecord.CDE_STATUS_TRANS__c= '1';
                atsRecord.CDE_TYPE_TRANS__c ='8';
                atsRecord.IDN_PLAN_CNTY__c = countyRatePlan.Name; 
                atsRecord.drop_in_days_at_the_authorization_level__c = countyRatePlan.PAYMENT_Q14_3__c; // Updated as per CHATS-5738- VS- 07/13/2018
                if(countyIdtoCodeMap.containsKey(countyRatePlan.IDN_COUNTY__c)){
                    //atsRecord.IDN_PLAN_CNTY__c = String.valueOf(countyIdtoCodeMap.get(countyRatePlan.IDN_COUNTY__c));
                    atsRecord.CDE_COUNTY__c = String.valueOf(countyIdtoCodeMap.get(countyRatePlan.IDN_COUNTY__c)); // Updated by RP as per CHATS-5697
                }
                atsRecord.DTE_CHANGE_LAST__c = system.today();
                lstATSRecords.add(atsRecord);
            }
        }
        ATSHandler.insertATSRecord(true, lstATSRecords);
    }
    /**    
* @description Submit the Rate Plan for Approval
* @author Vineet Srivastava
* @date 5/10/2018   
* @param Id Record Id for County Rate Plan,
* @return LightningServerResponse
*/  
    public static LightningServerResponse submitForApproval(String recordId){
        System.savePoint sp = Database.setSavePoint();
        Boolean isSuccess;
        String message;
        List<T_COUNTY_RATE_NOTES__c> CountyRatePlanNotes=[Select Id,Name,IDN_COUNTY_RATE__c,IDN_COUNTY_RATE__r.Id from T_COUNTY_RATE_NOTES__c where IDN_COUNTY_RATE__r.Id=:recordId];    
        if(CountyRatePlanNotes.size()>0){
            try{
                Map<String, Schema.SObjectField> fieldsMap = T_COUNTY_RATE__c.sObjectType.getDescribe().fields.getMap();
                String query = 'SELECT ';
                query += String.join(fieldsMap.keySet(), ', ');
                query += ' FROM T_COUNTY_RATE__c WHERE Id = :recordId';                
                T_COUNTY_RATE__c countyRatePlan = Database.query(query);                
                
                if(countyRatePlan.Flow_Completed__c){
                    // added submission insertion logic for CCCAP-13170
                    T_COUNTY_RATE__c submissionCRP =CountyRatePlanApprovalAction.SubmissionInstance(countyRatePlan,Date.Today());
                    submissionCRP.DTE_BEGIN_EFFV_RATE__c = null;
                    Insert submissionCRP;
                    //CCCAP-13170 changes end
                    Approval.ProcessSubmitRequest req1 =new Approval.ProcessSubmitRequest();
                    req1.setComments('Submitting request for approval.');
                    req1.setObjectId(recordId);
                    req1.setSubmitterId(UserInfo.getUserId());
                    req1.setProcessDefinitionNameOrId('County_Rate_Plan_Approval_Process');
                    req1.setSkipEntryCriteria(true);
                    // Submit the approval request for the account
                    Approval.ProcessResult result = Approval.process(req1);
                    // Verify the result
                    System.assert(result.isSuccess());
                    isSuccess=true;
                    message= Label.SubmitForApprovalSuccess;
                }
                else{
                    isSuccess=false;
                    message= Label.ComleteFlowForAproval;
                }
            }
            catch(DMLException e){
                database.rollback(sp);
                isSuccess=false;
                message=String.valueOf(e.getDmlMessage(0));
                ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'CountyRatePlanServices','Method__c'=>'submitForApproval'});
            }
        }else{
            isSuccess=false;
            message=System.Label.CountyRatePlanNoteErrorMsg;
        }
        
        return new LightningServerResponse(isSuccess, message, null);
    }
    /**
* @description Ristrict multiple county plans of Draft type for one county. Added as a part of CHATS-4910 bug fix
* @author Gaurav Trivedi
* @date 05-30-2018
* @param List<T_COUNTY_RATE__c> trigger.new county plan list
* @return void
*/
    public static void ristrictMultipleDraft(List<T_COUNTY_RATE__c> newCountyList){
        Boolean throwError = false;
        Set<Id> countyIdSet = new Set<Id>();
        for(T_COUNTY_RATE__c countyRate : newCountyList){
            countyIdSet.add(countyRate.IDN_COUNTY__c);
        }
        if(!countyIdSet.isEmpty()){
            List<AggregateResult> draftCountyRate = [SELECT Count(Id), IDN_COUNTY__c FROM T_COUNTY_RATE__c WHERE IDN_COUNTY__c <> null AND IDN_COUNTY__c IN : countyIdSet AND CDE_STATUS__c = : DRAFT AND IND_RATE_PLAN_TEMPLT__c=false AND County_Rate_Plan__c = NULL  GROUP BY IDN_COUNTY__c];
            if(!draftCountyRate.isEmpty()){
                for(AggregateResult draftCounty: draftCountyRate){
                    if((Integer.valueOf(draftCounty.get('expr0')) > 1 && trigger.isUpdate) || trigger.isInsert){
                        throwError = true;
                    }
                    
                }
                if(throwError){
                    for(T_COUNTY_RATE__c countyRate : newCountyList){
                        if(!countyRate.IND_RATE_PLAN_TEMPLT__c){
                            countyRate.addError('You can not add multiple draft version of County Rate Plan');
                        }
                    }
                }
            }
        }
    }
    
    /* @description Assign County Rate Plan submitted task to County Plan Approver and Template Admin role uers. Added as a part of CHATS-5387 bug fix
* @author Bharadwaj Gaddam
* @date 06-25-2018
* @param List<T_COUNTY_RATE__c> trigger.new county plan list and Map<Id,T_COUNTY_RATE__c> Trigger.oldMap old Map
* @return void
*/   
    
    public static void createTasksforRolesAfterSubmission(List<T_COUNTY_RATE__c> countyPlanNewList,Map<Id,T_COUNTY_RATE__c> countyPlanOldMap) {
        Set<Id> countyRatePlanIdSet = new Set<Id>();
        List<Task> tasklist = new List<Task>();
        Date duedate=System.Today().addDays(5);
        for(T_COUNTY_RATE__c countyPlanEach:countyPlanNewList) {
            if( countyPlanEach.County_Rate_Plan__c==null && countyPlanEach.CDE_STATUS__c != countyPlanOldMap.get(countyPlanEach.Id).CDE_STATUS__c && countyPlanEach.CDE_STATUS__c == SUBMITTED) {
                countyRatePlanIdSet.add(countyPlanEach.Id);            
            }
        }
        if(countyRatePlanIdSet.size()>0) {
            for(User userEach:[Select Id from User where UserRole.Name IN(:Label.County_Plan_Approver,:Label.Template_Administrator)]) {
                for(Id countyPlanId:countyRatePlanIdSet) {
                    tasklist.add(new Task(OwnerId=userEach.Id,WhatId=countyPlanId,Subject=Label.Approve_County_Rate_Plan,
                                          Description=Label.County_has_submitted_a_County_Rate_Plan_for_Approval,ActivityDate=duedate,
                                          Status=INPROGRESS,Priority=NORMAL));
                }
            }        
        }
        
        if(tasklist.size()>0) {
            //Database.DMLOptions dm = new Database.DMLOptions();
            //dm.EmailHeader.triggerUserEmail=true;
            //dm.optAllOrNone = false;
            //GenericDMLHandler.insertRecordsWithEmailTrigger(tasklist,dm,new Map<String,Object>{'Class__c'=>'CountyRatePlanServices','Method__c'=>'createTasksforRolesAfterSubmission'});
            GenericDMLHandler.insertRecords(tasklist,false,new Map<String,Object>{'Class__c'=>'CountyRatePlanServices','Method__c'=>'createTasksforRolesAfterSubmission'});     
        }
        
    }
    public static void updateTemplateRecord(List<T_COUNTY_RATE__c> countyRatePlanNewList,Map<Id,T_COUNTY_RATE__c> countyRatePlanOldMap) {
        List<T_COUNTY_RATE__c> lstApprovedCountyRatePlans = new List<T_COUNTY_RATE__c>();
        Set<Id> setApprovedCountyRatePlanIds = new Set<Id>();
        Set<String> setCounty = new Set<String>();
        for(T_COUNTY_RATE__c countyRatePlan : countyRatePlanNewList){
            if(countyRatePlan.County_Rate_Plan__c==null && (countyRatePlan.CDE_STATUS__c == APPROVED)
               && countyRatePlan.CDE_STATUS__c != countyRatePlanOldMap.get(countyRatePlan.Id).CDE_STATUS__c){
                lstApprovedCountyRatePlans.add(countyRatePlan);
                setCounty.add(countyRatePlan.IDN_COUNTY__c );
                setApprovedCountyRatePlanIds.add(countyRatePlan.Id);
            }
        }
        if(!lstApprovedcountyRatePlans.isEmpty()){
            Map<String,T_COUNTY_RATE__c> mapCountyRatePlanTemplates = new Map<String,T_COUNTY_RATE__c>();
            List<T_COUNTY_RATE_AMT__c> lstCountyRatesToInsert = new List<T_COUNTY_RATE_AMT__c>();
            Set<Id> setExistingTemplateRecordIds = new Set<Id>();
            List<Id> lstCountyRateIdsToBeDeleted = new List<Id>();
            for(T_COUNTY_RATE__c countyRatePlan : [Select Id,IDN_COUNTY__c,IND_RATE_PLAN_TEMPLT__c,DTE_BEGIN_EFFV_RATE__c,DTE_END_EFFV_RATE__c,PAYMENT_Q13_1__c FROM T_COUNTY_RATE__c WHERE IDN_COUNTY__c in:setCounty AND IND_RATE_PLAN_TEMPLT__c = true and County_Rate_Plan__c=NULL] ){
                mapCountyRatePlanTemplates.put(countyRatePlan.IDN_COUNTY__c,countyRatePlan);
                setExistingTemplateRecordIds.add(countyRatePlan.Id);
            }
            T_COUNTY_RATE__c crpTemplate;
            List<T_COUNTY_RATE__c> lstTemplatetoUpdate = new List<T_COUNTY_RATE__c>();
            List<T_COUNTY_RATE__c> lstTemplatetoInsert = new List<T_COUNTY_RATE__c>();
            Set<String> removedHolidaySet = new Set<String>();
            Set<String> addedHolidaySet = new Set<String>();
            list<String> tempHolidays;
            list<String> crpHolidays;
            T_COUNTY_RATE__c approvedCRP;
            for(T_COUNTY_RATE__c countyRatePlan : lstApprovedCountyRatePlans){
                T_COUNTY_RATE__c countyRatePlanClone = countyRatePlan.clone();
                if(mapCountyRatePlanTemplates.containsKey(countyRatePlan.IDN_COUNTY__c)){
                    crpTemplate = mapCountyRatePlanTemplates.get(countyRatePlan.IDN_COUNTY__c);
                    countyRatePlanClone.Id = crpTemplate.Id;
                    countyRatePlanClone.IND_RATE_PLAN_TEMPLT__c = crpTemplate.IND_RATE_PLAN_TEMPLT__c;
                    countyRatePlanClone.DTE_BEGIN_EFFV_RATE__c = crpTemplate.DTE_BEGIN_EFFV_RATE__c;
                    countyRatePlanClone.DTE_END_EFFV_RATE__c = crpTemplate.DTE_END_EFFV_RATE__c;
                    countyRatePlanClone.CDE_STATUS__c = APPROVED;
                    countyRatePlanClone.Is_Conditionally_Approved__c = false;
                    lstTemplatetoUpdate.add(countyRatePlanClone);
                    
                    if(crpTemplate.PAYMENT_Q13_1__c != countyRatePlan.PAYMENT_Q13_1__c){
                        if(String.isNotBlank(crpTemplate.PAYMENT_Q13_1__c) && String.isNotBlank(countyRatePlan.PAYMENT_Q13_1__c)){
                            tempHolidays = crpTemplate.PAYMENT_Q13_1__c.split(';');
                            crpHolidays = countyRatePlan.PAYMENT_Q13_1__c.split(';'); 
                            for(String s : tempHolidays){
                                if(!crpHolidays.contains(s)){
                                    removedHolidaySet.add(s);
                                }
                            }
                            for(String s : crpHolidays){
                                if(!tempHolidays.contains(s)){
                                    addedHolidaySet.add(s);
                                }
                            }
                        } else if(String.isNotBlank(crpTemplate.PAYMENT_Q13_1__c) && String.isBlank(countyRatePlan.PAYMENT_Q13_1__c)){
                            //tempHolidays = crpTemplate.PAYMENT_Q13_1__c.split(';');
                            removedHolidaySet.addAll(crpTemplate.PAYMENT_Q13_1__c.split(';'));
                        } else if(String.isBlank(crpTemplate.PAYMENT_Q13_1__c) && String.isNotBlank(countyRatePlan.PAYMENT_Q13_1__c)){
                            //crpHolidays = countyRatePlan.PAYMENT_Q13_1__c.split(';');
                            addedHolidaySet.addAll(countyRatePlan.PAYMENT_Q13_1__c.split(';'));
                        }
                        approvedCRP = countyRatePlan;
                    }
                }
                else{
                    countyRatePlanClone.IND_RATE_PLAN_TEMPLT__c = true;
                    countyRatePlanClone.DTE_BEGIN_EFFV_RATE__c = null;
                    countyRatePlanClone.DTE_END_EFFV_RATE__c = null;
                    countyRatePlanClone.CDE_STATUS__c = APPROVED;
                    countyRatePlanClone.Is_Conditionally_Approved__c = false;
                    lstTemplatetoInsert.add(countyRatePlanClone);
                }                
            }
            if(!lstTemplatetoUpdate.isEmpty()){
                templateRecordUpdate = true; 
                try{
                    // SS: Added additional paramter of fieldNames for Checkmarx CCCAP-8861
                    GenericDMLHandler.updateRecords(lstTemplatetoUpdate,new Map<String,Object>{'Class__c'=>'CountyRatePlanServices','Method__c'=>'updateTemplateRecord'},new List<String>{'IND_RATE_PLAN_TEMPLT__c','DTE_BEGIN_EFFV_RATE__c','DTE_END_EFFV_RATE__c'});
                }
                catch(Exception e){
                    for(T_COUNTY_RATE__c countyRatePlan : lstApprovedCountyRatePlans){
                        countyRatePlan.addError('Template Records can be modified/checked by Template Administrators only');
                    }
                } 
            }
            if(!lstTemplatetoInsert.isEmpty()){
                Integer i = 0;
                // SS: Added additional paramter of fieldNames for Checkmarx CCCAP-8861
                for(DMLResult result : GenericDMLHandler.insertRecords(lstTemplatetoInsert,false,new Map<String,Object>{'Method__c'=>'updateTemplateRecord','Class__c'=>'CountyRatePlanServices'},new List<String>{'IND_RATE_PLAN_TEMPLT__c','DTE_BEGIN_EFFV_RATE__c','DTE_END_EFFV_RATE__c'})){
                    if(result.saveResult.isSuccess()){
                        //lstTemplatetoInsert[i].Id = result.saveResult.getId(); //SS: commented for Checkmarx CCCAP-8861
                        mapCountyRatePlanTemplates.put(lstTemplatetoInsert[i].IDN_COUNTY__c,lstTemplatetoInsert[i]);
                        i++;
                    }
                }
            }
            
            system.debug('removedHolidaySet: '+removedHolidaySet);
            if(removedHolidaySet.size() > 0){
                String day = System.now().format('EEEE');                   
                Integer daysToAdd = day == 'Saturday' ? 13 : (day == 'Sunday' ? 12 : 14);
                Date crpBeginDt = approvedCRP.DTE_BEGIN_EFFV_RATE__c;
                List<T_YEAR_HOL__c> holidayList = [SELECT DTE_HOL__c, DTE_OBSERVED_HOL__c, toLabel(CDE_HOL__c) FROM T_YEAR_HOL__c 
                                     				WHERE CDE_HOL__c IN :removedHolidaySet AND (DTE_HOL__c > TODAY or DTE_HOL__c = LAST_N_DAYS:9)
                                                      //AND DTE_HOL__c > :crpBeginDt 
							ORDER by DTE_HOL__c ASC];
                Map<Id, T_PROVR_FISCAL_AGREMENT__c> faMap = new map<Id, T_PROVR_FISCAL_AGREMENT__c>([SELECT Id, Name, OwnerId, CDE_COUNTY__c, CDE_COUNTY__r.Name, ID_SERVICE__c, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c
                                                      		 FROM T_PROVR_FISCAL_AGREMENT__c WHERE CDE_COUNTY__c = :approvedCRP.IDN_COUNTY__c
                                                              AND (Record_Type_Name__c = 'Open' OR Record_Type_Name__c = 'Finalized')
                                                              AND DTE_END_AGRMT__c >= :crpBeginDt]);
                List<Task> taskToInsert = new List<Task>();
                Date holDt;
                Map<Id, Map<String, list<String>>> faDateMapForTask = new Map<Id, Map<String, list<String>>>();
                for(T_PROVR_FISCAL_AGREMENT__c fa : faMap.values()){
                    for(T_YEAR_HOL__c hol : holidayList){
                        holDt = hol.DTE_OBSERVED_HOL__c != null ? hol.DTE_OBSERVED_HOL__c : hol.DTE_HOL__c;
                        if(holDt >= fa.DTE_BEGIN_AGRMT__c && holDt <= fa.DTE_END_AGRMT__c){
                            if(!faDateMapForTask.containsKey(fa.Id)){
                                faDateMapForTask.put(fa.Id, new Map<String, list<String>>());
                            }
                            Map<String, list<String>> holMap = faDateMapForTask.get(fa.Id);
                            if(!holMap.containsKey(hol.CDE_HOL__c)){
                                holMap.put(hol.CDE_HOL__c, new list<String>());
                            }
                            holMap.get(hol.CDE_HOL__c).add(holDt.month()+'/'+holDt.day()+'/'+holDt.year());
                            faDateMapForTask.put(fa.Id, holMap);
                        }
                    }
                }
                String orgDomainUrl = URL.getOrgDomainUrl().toExternalForm();
                String crpEffectiveDt = crpBeginDt.month()+'/'+crpBeginDt.day()+'/'+crpBeginDt.year();
                for(Id faId : faDateMapForTask.keySet()){
                    T_PROVR_FISCAL_AGREMENT__c fa = faMap.get(faId);
					Map<String, list<String>> holMap = faDateMapForTask.get(faId);
                    List<String> holidayParts = new List<String>();
                    for(String holName : holMap.keySet()){
                        holidayParts.add(holName + ' ' + String.join(holMap.get(holName), ','));
                    }
                    String holidayStr = String.join(holidayParts, ', ');
                    
                    Task tsk = new Task();
                    tsk.OwnerId = fa.OwnerId;
                    tsk.WhatId = fa.Id;
                    tsk.Subject = 'T221 - Holiday has been removed from CRP';
                    tsk.Status = 'Open';  
                    tsk.ActivityDate = Date.today().addDays(daysToAdd);
                    tsk.Description = holidayStr
                        + ' is no longer an observed holiday and has been removed from the '+fa.CDE_COUNTY__r.Name
                        + ' CRP effective ' + crpEffectiveDt
                        + ' .Please take action to add Provider Closure records as necessary. Fiscal Agreement ID: '+ fa.Name
                        +'('+ orgDomainUrl +'/lightning/r/T_PROVR_FISCAL_AGREMENT__c/'+fa.Id+'/view)';
                    taskToInsert.add(tsk);
                }
                if(!taskToInsert.isEmpty()){
                    //Database.DMLOptions dm = new Database.DMLOptions();
                    //dm.EmailHeader.triggerUserEmail = true;
                    //dm.optAllOrNone = false;
                    //GenericDMLHandler.insertRecordsWithEmailTrigger(taskToInsert,dm,new Map<String,Object>{'Method__c'=>'appoveCountyRatePlan','Class__c'=>'CountyRatePlanServices'});
                    GenericDMLHandler.insertRecords(taskToInsert,false,new Map<String,Object>{'Method__c'=>'appoveCountyRatePlan','Class__c'=>'CountyRatePlanServices'});
                }
            }
            if(addedHolidaySet.size() > 0){
                Date crpBeginDt = approvedCRP.DTE_BEGIN_EFFV_RATE__c;
                Date holDt;
                set<Date> holidayDates = new set<Date>();
                for(T_YEAR_HOL__c hol : [SELECT DTE_HOL__c, DTE_OBSERVED_HOL__c, toLabel(CDE_HOL__c) FROM T_YEAR_HOL__c 
                                     	  WHERE CDE_HOL__c IN :addedHolidaySet AND (DTE_HOL__c > TODAY or DTE_HOL__c = LAST_N_DAYS:9)
                                            //AND DTE_HOL__c > :crpBeginDt
					                              ]){
                    //holDt = hol.DTE_OBSERVED_HOL__c != null ? hol.DTE_OBSERVED_HOL__c : hol.DTE_HOL__c;
                    //holidayDates.add(holDt);
			                                          if(hol.DTE_OBSERVED_HOL__c != null){
                                                    holidayDates.add(hol.DTE_OBSERVED_HOL__c);
                                                }
                                                if(hol.DTE_HOL__c != null){
                                                    holidayDates.add(hol.DTE_HOL__c);
                                                }
                }
                
                List<T_PROVR_CLOSURE__c> provList = [SELECT Id, Name, DTE_BEGIN_CLOSURE__c, CDE_COUNTY__c, IDN_PROVIDER__c,TXT_COMMENTS__c,IND_ACTIVE__c  
                                               	 	  FROM T_PROVR_CLOSURE__c 
                                                 	  WHERE DTE_BEGIN_CLOSURE__c IN :holidayDates AND IND_ACTIVE__c = true
                                                     	AND CDE_COUNTY__c =:approvedCRP.IDN_COUNTY__c];
                Set<date> encumDateSet = new Set<date>();
                set<id> provClosureSet = new set<id>();
                for(T_PROVR_CLOSURE__c pc : provList){
                    pc.IND_ACTIVE__c = false;
                    encumDateSet.add(pc.DTE_BEGIN_CLOSURE__c);
                    provClosureSet.add(pc.Id);
                }
                if(!provList.isEmpty()){
                    // SS: Added additional paramter of fieldNames for Checkmarx CCCAP-8861
                    GenericDMLHandler.updateRecords(provList, new Map<String,Object>{'Class__c'=>'CountyRatePlanServices','Method__c'=>'updateTemplateRecord'}, new List<String>{'IND_ACTIVE__c'});
                    // update provList;
                }
                updateEncumInactiv(encumDateSet,provClosureSet,approvedCRP.IDN_COUNTY__c);
            }
            
            for (T_COUNTY_RATE_AMT__c countyRate : [Select Id, CDE_AGE_GROUP__c, NBR_AMOUNT__c, CDE_UNIT__c, IDN_COUNTY_RATE__c, IDN_COUNTY_RATE__r.IDN_COUNTY__c, CDE_RATE_TEMPLT__c, IND_RATE_TEMPLT__c, CDE_PROVR_TYPE__c, CDE_RATE_TYPE__c, CDE_TIER__c from T_COUNTY_RATE_AMT__c where IDN_COUNTY_RATE__c in :setApprovedCountyRatePlanIds and CDE_UNIT__c=:CARE_UNIT]){
                if(mapCountyRatePlanTemplates.containsKey(countyRate.IDN_COUNTY_RATE__r.IDN_COUNTY__c)){
                    T_COUNTY_RATE_AMT__c countyRateClone = new T_COUNTY_RATE_AMT__c();
                    countyRateClone.CDE_AGE_GROUP__c = countyRate.CDE_AGE_GROUP__c;
                    countyRateClone.NBR_AMOUNT__c = countyRate.NBR_AMOUNT__c;
                    countyRateClone.CDE_UNIT__c = countyRate.CDE_UNIT__c;
                    countyRateClone.IDN_COUNTY_RATE__c = mapCountyRatePlanTemplates.get(countyRate.IDN_COUNTY_RATE__r.IDN_COUNTY__c).Id;
                    countyRateClone.CDE_RATE_TEMPLT__c = countyRate.CDE_RATE_TEMPLT__c;
                    countyRateClone.IND_RATE_TEMPLT__c = countyRate.IND_RATE_TEMPLT__c;
                    countyRateClone.CDE_PROVR_TYPE__c = countyRate.CDE_PROVR_TYPE__c;
                    countyRateClone.CDE_RATE_TYPE__c = countyRate.CDE_RATE_TYPE__c;
                    countyRateClone.CDE_TIER__c = countyRate.CDE_TIER__c;
                    lstCountyRatesToInsert.add(countyRateClone);
                }
            }
            for(T_COUNTY_RATE_AMT__c countyRate :[Select Id from T_COUNTY_RATE_AMT__c where IDN_COUNTY_RATE__c in:setExistingTemplateRecordIds  ]){
                lstCountyRateIdsToBeDeleted.add(countyRate.Id); 
            }
            if(!lstCountyRateIdsToBeDeleted.isEmpty()){
                GenericWithoutSharingDMLOperations.setRecordsIdsToBeDeleted(lstCountyRateIdsToBeDeleted);
                GenericWithoutSharingDMLOperations.deleteRecords( new Map<String,Object>{'Class__c'=>'CountyRatePlanServices','Method__c'=>'updateTemplateRecord'});
            }
            if(!lstCountyRatesToInsert.isEmpty()){
                // SS: Added additional paramter of fieldNames for Checkmarx CCCAP-8861
                GenericDMLHandler.insertRecords(lstCountyRatesToInsert,new Map<String,Object>{'Class__c'=>'CountyRatePlanServices','Method__c'=>'updateTemplateRecord'},new List<String>{'CDE_AGE_GROUP__c','NBR_AMOUNT__c','CDE_UNIT__c','IDN_COUNTY_RATE__c','CDE_RATE_TEMPLT__c','IND_RATE_TEMPLT__c','CDE_PROVR_TYPE__c','CDE_RATE_TYPE__c','CDE_TIER__c'}); 
            }
        }
    }
    
    @future(callout = true)
    public static void updateEncumInactiv(set<date> encumSet,set<id> provClosureSet,id countyId){
        List<T_AUTH__c> authList = new list<T_AUTH__c>();
        set<Id> authIdSet = new set<Id>();
        Map<id,T_AUTH__c> authMap = new map<id,T_AUTH__c>();
        Map<id,Map<date,T_AUTH_ENCUMBR__c>> response = new Map<id,Map<date,T_AUTH_ENCUMBR__c>>();
        Map<String,string> resultMap = new Map<String,string>();
        string anyAuthId;
        set<id> provIdSet = new set<id>();
        for(T_PROVR_CLOSURE__c prov : [SELECT Id, Name, DTE_BEGIN_CLOSURE__c, CDE_COUNTY__c, IDN_PROVIDER__c,TXT_COMMENTS__c,IND_ACTIVE__c  
                                       FROM T_PROVR_CLOSURE__c Where Id IN :provClosureSet]){
                                           provIdSet.add(prov.IDN_PROVIDER__c);                               
                                       }
        for(T_AUTH__c indiAuth : [SELECT Id, Name, Authorization_Status__c, IDN_PROVR__c, Number_of_Drop_in_Days__c, IDN_CASE__r.Name, IDN_PROVR__r.Name, CDE_COUNTY__r.CDE_COUNTY__c, isFinishedFlow__c
                                  FROM T_AUTH__c WHERE Authorization_Status__c = '2' AND IDN_PROVR__c IN : provIdSet AND CDE_COUNTY__c =:countyId]){
                                      authMap.put(indiAuth.id, indiAuth);
                                      anyAuthId = indiAuth.id; 
                                  }        
        
        if(!authMap.isEmpty()){
            List<batchsit_t_auth_encmbr__x> listOfEncum = new List<batchsit_t_auth_encmbr__x>();
            if(Test.isRunningTest()){
                batchsit_t_auth_encmbr__x statBtch = new batchsit_t_auth_encmbr__x(idn_auth__c =anyAuthId,dte_care__c =system.today().addMonths(4),cnt_Hour_Care__c =4,cde_status_encmbr__c='2',ind_0_36_months__c='N');
                listOfEncum.add(statBtch);
            }else{
                listOfEncum = [select id,dte_care__c,cnt_Hour_Care__c,cde_status_encmbr__c,cde_type_unit_care__c,idn_Auth__c,idn_encmbr_auth__c, ind_0_36_months__c 
                               from batchsit_t_auth_encmbr__x where idn_Auth__c in :authMap.keyset() and dte_care__c in :encumSet];
            }
            
            List<T_AUTH_ENCUMBR__c> encumList = [select id, IDN_AUTH__c,dte_care__c,cnt_hour_care__c,cde_status_encmbr__c, ind_0_36_months__c 
                                                 from T_AUTH_ENCUMBR__c where IDN_AUTH__c in : authMap.keySet()];
            if(encumList.size()>0){
                for(T_AUTH_ENCUMBR__c indiEncum : encumList){
                    if(response.containsKey(indiEncum.IDN_AUTH__c)){
                        Map<date,T_AUTH_ENCUMBR__c> orgMap = response.get(indiEncum.IDN_AUTH__c);
                        orgMap.put(indiEncum.dte_care__c, indiEncum);
                        response.put(indiEncum.IDN_AUTH__c,orgMap);
                    }
                    else{
                        response.put(indiEncum.IDN_AUTH__c,new Map<date,T_AUTH_ENCUMBR__c>{indiEncum.dte_care__c=>indiEncum});
                    }
                }
            }
            
            if(listOfEncum.size()>0){                         
                List<ProviderCalendarApxCtrl.encumbranceWrap> encumtoupdate = new List<ProviderCalendarApxCtrl.encumbranceWrap>();
                for(batchsit_t_auth_encmbr__x indiEncum : listOfEncum){                    
                    ProviderCalendarApxCtrl.encumbranceWrap indiWrap=new ProviderCalendarApxCtrl.encumbranceWrap();
                    string originalStatus,originalHour;
                    Map<date,T_AUTH_ENCUMBR__c> dtVsAuth = new Map<date,T_AUTH_ENCUMBR__c>();
                    dtVsAuth=response.get(indiEncum.idn_Auth__c);
                    if(dtVsAuth != null && !dtVsAuth.isEmpty() && dtVsAuth.containsKey(indiEncum.dte_care__c)){
                        originalStatus = dtVsAuth.get(indiEncum.dte_care__c).cde_status_encmbr__c;
                        originalHour = String.valueOf(dtVsAuth.get(indiEncum.dte_care__c).cnt_hour_care__c);
                        indiWrap.cde_Status_Encmbr = originalStatus==null? '2' : originalStatus;
                        indiWrap.cnt_Hour_Care = originalHour == null? '0' : originalHour;
                        indiWrap.lastmodifieddate = String.valueOf(system.now().format('yyyy-MM-dd HH:mm:ss')) ;
                        indiWrap.lastmodifiedbyid = Userinfo.getUserId();
                        indiWrap.idn_Encmbr_Auth = string.valueof(indiEncum.idn_encmbr_auth__c);
                        encumtoupdate.add(indiWrap);   
                        
                        if(!authIdSet.contains(indiEncum.idn_Auth__c)){
                            authList.add(authMap.get(indiEncum.idn_Auth__c));
                            authIdSet.add(indiEncum.idn_Auth__c);
                        }
                    }
                }
                
                system.debug('serialize '+JSON.serialize(encumtoupdate));
                if(!Test.isRunningTest()){
                    resultMap = HerokuService.authEncumbranceUpdate(JSON.serialize(encumtoupdate));
                }
                system.debug('resultMap '+resultMap);
            } 
            if(!authList.isEmpty()){
                AuthorizationStatusController.insertATSRecords(authList);
                ProviderCalendarApxCtrl.triggerCR213Corr(authList);
            }
        }        
    }
    @AuraEnabled
    public static LightningServerResponse checkIfNewChanges(String recordId, Boolean isNewComponent){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = false;
        T_COUNTY_RATE__c countyRatePlanRec = [SELECT Id, DTE_BEGIN_EFFV_RATE__c FROM T_COUNTY_RATE__c WHERE Id=:recordId LIMIT 1];
        if(countyRatePlanRec != null){
            Boolean isbeginAfter = CompareCP_CRP_lwc.IsDateAfter_15June2025(countyRatePlanRec.DTE_BEGIN_EFFV_RATE__c);
            objectData.put('showButton',(isNewComponent && isbeginAfter) || (!isNewComponent && !isbeginAfter));
            isSuccessful = true;
        }
        return new LightningServerResponse(isSuccessful,'Done',objectData);
    }
}