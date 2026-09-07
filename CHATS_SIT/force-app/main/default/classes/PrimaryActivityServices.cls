/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/7/2017                                                          
*  @description    Handler class for Primary Activity Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 7-Dec-2017                                                             
*  * Author: Bharadwaj Gaddam                                                    
*  * Description: Initial version  
*
*  * Version: 2.0                                                                             
*  * Date: 14-May-2018                                                             
*  * Author: Shubham Khandelwal                                                  
*  * Description: Updating line 220 for null check before DML Update.
*                                                                                 
*********************************************************************************************/

public with sharing class PrimaryActivityServices {
    public static final String PRIMARYACTIVITYTYPEGED=Label.PRIMARYACTIVITYTYPEGED;
    public static final String PRIMARYACTIVITYTYPEPOS=Label.PRIMARYACTIVITYTYPEPOS; 
    public static final String PRIMARYACTIVITYTYPEJS=Label.PRIMARYACTIVITYTYPEJS;   
    public static set<Id> individualIdset = new set<Id>();
    public static set<Id> caseIdset = new set<Id>();
        
/**
* @description maps ClientId and CaseId as Key and Primary Activity record as value in a Map 
* @author Bharadwaj Gaddam
* @date 12/7/2017 
* @param List<T_PRIM_ACTV__c> trigger.new PrimaryActivity list
* @return Map<Id,T_PRIM_ACTV__c>
*/    
    public static Map<string,T_PRIM_ACTV__c> primaryActivityIndividualMap(List<T_PRIM_ACTV__c> newPrimaryActivityList) {
        
        Map<string,T_PRIM_ACTV__c> primActivIndivMap= new Map<string,T_PRIM_ACTV__c>();
        for(T_PRIM_ACTV__c primActEach:newPrimaryActivityList) {
            if(primActEach.IDN_CLIENT__c !=null && primActEach.IDN_CASE__c !=null) {
                primActivIndivMap.put(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c,primActEach);    
                individualIdset.add(primActEach.IDN_CLIENT__c);       
                caseIdset.add(primActEach.IDN_CASE__c);
           }
      
        }
        return primActivIndivMap;
    }
    
 /**
* @description checks existing Primary Activity with no enddate for an individual and case and will not allow new Primary Activity
* @author Bharadwaj Gaddam
* @date 12/7/2017 
* @param Map<Id,T_PRIM_ACTV__c> => <ClientId,PrimaryActivity>
* @return void
*/      
    public static void primActBeforeInsertCheckNullEnddate(Map<string,T_PRIM_ACTV__c> newPrimaryActivityIndivMap){ 
        Date nulldate; 
        
        for(T_PRIM_ACTV__c primActEach:[Select Id,IDN_CLIENT__c,IDN_CASE__c from T_PRIM_ACTV__c where IDN_CLIENT__c IN:individualIdset and IDN_CASE__c IN:caseIdset and DTE_END_ACTV_PRIM__c=:nulldate]) {
            if(newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c)!=null && newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c).Is_CBMS_Data__c == false) {
                newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c).addError(Label.Only_have_one_effective_Primary_Activity);               
                
            }
            
        }
    
    }

   
 /**
* @description checks existing Primary Activity with type as GED or POS for an individual and case and will not allow new Primary Activity with same types
* @author Bharadwaj Gaddam
* @date 12/7/2017 
* @param Map<Id,T_PRIM_ACTV__c> => <ClientId,PrimaryActivity>
* @return void
*/      
    public static void primActBeforeInsertCheckType(Map<string,T_PRIM_ACTV__c> newPrimaryActivityIndivMap){ 
        Date nulldate;
        for(T_PRIM_ACTV__c resultEach:[Select IDN_CLIENT__c,CDE_TYPE_ACTV__c,IDN_CASE__c, DTE_BEGIN_ACTV_PRIM__c, DTE_END_ACTV_PRIM__c from T_PRIM_ACTV__c where IDN_CLIENT__c IN:individualIdset and IDN_CASE__c IN:caseIdset and (CDE_TYPE_ACTV__c=:PRIMARYACTIVITYTYPEGED OR CDE_TYPE_ACTV__c=:PRIMARYACTIVITYTYPEPOS) and DTE_BEGIN_ACTV_PRIM__c!=:nulldate and DTE_END_ACTV_PRIM__c!=:nulldate]) {
            if(newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c)!= null  && newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c).Is_CBMS_Data__c == false) {
                if(	newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c).CDE_TYPE_ACTV__c == resultEach.CDE_TYPE_ACTV__c &&
                  	((	newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c).DTE_BEGIN_ACTV_PRIM__c >= resultEach.DTE_BEGIN_ACTV_PRIM__c && 
						newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c).DTE_BEGIN_ACTV_PRIM__c <= resultEach.DTE_END_ACTV_PRIM__c) ||
		 			 (	newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c).DTE_END_ACTV_PRIM__c >= resultEach.DTE_BEGIN_ACTV_PRIM__c && 
						newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c).DTE_END_ACTV_PRIM__c <= resultEach.DTE_END_ACTV_PRIM__c) ||
		 			 (	newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c).DTE_BEGIN_ACTV_PRIM__c <= resultEach.DTE_BEGIN_ACTV_PRIM__c && 
						newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c).DTE_END_ACTV_PRIM__c >= resultEach.DTE_END_ACTV_PRIM__c) ||
		 			 (	newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c).DTE_BEGIN_ACTV_PRIM__c >= resultEach.DTE_BEGIN_ACTV_PRIM__c && 
						newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c).DTE_END_ACTV_PRIM__c <= resultEach.DTE_END_ACTV_PRIM__c) ||
                     (	newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c).DTE_BEGIN_ACTV_PRIM__c <= resultEach.DTE_BEGIN_ACTV_PRIM__c && 
						newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c).DTE_END_ACTV_PRIM__c == null)
                     
					)
                  ){
                    newPrimaryActivityIndivMap.get(resultEach.IDN_CLIENT__c+';'+resultEach.IDN_CASE__c).addError(resultEach.CDE_TYPE_ACTV__c == PRIMARYACTIVITYTYPEGED ? Label.The_Individual_already_has_an_existing_primary_activity_GED_ESL_ABE : Label.The_Individual_already_has_an_existing_primary_activity_POS); 
                   }
            }
        }
    
    }
 
 
 /**
* @description checks existing Primary Activity with type as JS and utilized weeks defined in the county plan for that year for an individual and will not allow new Primary Activity with same type
* @author Bharadwaj Gaddam
* @date 12/7/2017 
* @param Map<Id,T_PRIM_ACTV__c> => <ClientId,PrimaryActivity>
* @return void
*/   
/*    
    public static void primActBeforeInsertCheckJobsearchUtilize(Map<Id,T_PRIM_ACTV__c> newPrimaryActivityIndivMap) {
        Date nulldate; 
        set<Id> caseIdsSet= new set<Id>();
        Map<Id,Id> countyCaseMap = new Map<Id,Id>();
        Map<Id,T_COUNTY_PLAN__c> countyCountyPlanMap = new Map<Id,T_COUNTY_PLAN__c>();
        Set<Id> clientIdsSet= new Set<Id>();
        Set<Id> primActivIndivJSIdsSet = new Set<Id>();
        for(T_PRIM_ACTV__c primActivEach:newPrimaryActivityIndivMap.values()) {
            if(primActivEach.CDE_TYPE_ACTV__c==PRIMARYACTIVITYTYPEJS) {
                caseIdsSet.add(primActivEach.IDN_CASE__c);  
                primActivIndivJSIdsSet.add(primActivEach.IDN_CLIENT__c);
            }
                    
        }
        
        Map<Id,T_SBSD_CASE__c> caseCountyMap= new Map<Id,T_SBSD_CASE__c>([Select Id, CDE_COUNTY__c from T_SBSD_CASE__c where Id IN:caseIdsSet ]);
        for(T_SBSD_CASE__c caseEach:caseCountyMap.values()) {
            countyCaseMap.put(caseEach.Id,caseEach.CDE_COUNTY__c);
        }
        
        for(T_COUNTY_PLAN__c countyPlanEach:[Select Id,CDE_COUNTY__c,ELIGIBILITY_Q4__c from T_COUNTY_PLAN__c where CDE_COUNTY__c IN:countyCaseMap.values() and DTE_BEGIN_EFFEV__c <= Today and DTE_END_EFFEV__c >= Today and ELIGIBILITY_Q4__c!=null]) {
            countyCountyPlanMap.put(countyPlanEach.CDE_COUNTY__c,countyPlanEach);
        }
        
        for(T_PRIM_ACTV_CNTR__c primActCntrEach:[Select Id,IDN_PRIM_ACTV__c,IDN_PRIM_ACTV__r.IDN_CASE__c,IDN_PRIM_ACTV__r.IDN_CLIENT__c,CNT_WEEKS__c,IDN_PRIM_ACTV__r.DTE_BEGIN_ACTV_PRIM__c from T_PRIM_ACTV_CNTR__c where IDN_PRIM_ACTV__r.IDN_CLIENT__c IN:primActivIndivJSIdsSet and IDN_PRIM_ACTV__r.CDE_TYPE_ACTV__c=:PRIMARYACTIVITYTYPEJS and IDN_PRIM_ACTV__r.DTE_BEGIN_ACTV_PRIM__c!=:nulldate order by IDN_PRIM_ACTV__r.DTE_BEGIN_ACTV_PRIM__c desc]) {
            if(!clientIdsSet.contains(primActCntrEach.IDN_PRIM_ACTV__r.IDN_CLIENT__c)) {
                if(primActCntrEach.CNT_WEEKS__c!=null && countyCountyPlanMap.get(countyCaseMap.get((primActCntrEach.IDN_PRIM_ACTV__r.IDN_CASE__c)))!=null) {
                if(primActCntrEach.CNT_WEEKS__c >= countyCountyPlanMap.get(countyCaseMap.get((primActCntrEach.IDN_PRIM_ACTV__r.IDN_CASE__c))).ELIGIBILITY_Q4__c) {
                    if(newPrimaryActivityIndivMap.get(primActCntrEach.IDN_PRIM_ACTV__r.IDN_CLIENT__c)!=null){
                        if((Date.valueOf(primActCntrEach.IDN_PRIM_ACTV__r.DTE_BEGIN_ACTV_PRIM__c).addYears(1)) >= System.Today()) {
                            newPrimaryActivityIndivMap.get(primActCntrEach.IDN_PRIM_ACTV__r.IDN_CLIENT__c).addError(Label.The_Individual_has_already_reached_the_time_limit_for_Job_Search_in_the_past_yea);               
                                        
                        }
                      }
                    }
                                
                }   
            }           
                
            
        }
        
        
    }
    
    */
 
  /**
* @description checks existing Primary Activity with no enddate for an individual and case and will not allow other Primary Activity update with empty enddate
* @author Bharadwaj Gaddam
* @date 12/7/2017 
* @param Map<Id,T_PRIM_ACTV__c> => <ClientId,PrimaryActivity> , Set<Id> trigger.newMap.Keyset() of Primary Activities
* @return void
*/     
    public static void primActBeforeUpdateCheckNullEnddate(Map<string,T_PRIM_ACTV__c> newPrimaryActivityIndivMap,Set<Id> primaryIdSet){ 
        Date nulldate; 
        for(T_PRIM_ACTV__c primActEach:[Select Id,IDN_CLIENT__c,DTE_END_ACTV_PRIM__c,IDN_CASE__c from T_PRIM_ACTV__c where IDN_CLIENT__c IN:individualIdset and IDN_CASE__c IN:caseIdset and DTE_END_ACTV_PRIM__c=:nulldate and Id NOT IN:primaryIdSet]) {
            if(newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c)!=null) {
                if(newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c).DTE_END_ACTV_PRIM__c==nulldate){
                    newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c).addError(Label.Only_have_one_effective_Primary_Activity);               
                }
            }
        
        }
    
    
    }

  /**
* @description checks existing Primary Activity with begin date and end date for an individual and case and will not allow new Primary Activity with begin date falls on or between existing Primary activity begin date and end date
* @author Bharadwaj Gaddam
* @date 12/7/2017 
* @param Map<Id,T_PRIM_ACTV__c> => <ClientId,PrimaryActivity>
* @return void
*/    
    
    public static void primActBeforeInsertCheckBeginDate(Map<string,T_PRIM_ACTV__c> newPrimaryActivityIndivMap) {
        Date nulldate; 
        for(T_PRIM_ACTV__c primActEach:[Select Id,IDN_CLIENT__c,DTE_END_ACTV_PRIM__c,DTE_BEGIN_ACTV_PRIM__c,IDN_CASE__c from T_PRIM_ACTV__c where IDN_CLIENT__c IN:individualIdset and IDN_CASE__c IN:caseIdset and DTE_END_ACTV_PRIM__c!=:nulldate and DTE_BEGIN_ACTV_PRIM__c!=:nulldate]) {
            if(newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c)!=null) {
                if(newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c).DTE_BEGIN_ACTV_PRIM__c >= primActEach.DTE_BEGIN_ACTV_PRIM__c && newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c).DTE_BEGIN_ACTV_PRIM__c <= primActEach.DTE_END_ACTV_PRIM__c && newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c).Is_CBMS_Data__c == false) {
                    newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c).addError(Label.Only_have_one_effective_Primary_Activity);               
                }
            }
            
        }
     
    }

  /**
* @description checks existing Primary Activity with begin date and end date for an individual and case and will not allow update on Primary Activity with begin date falls on or between existing Primary activity begin date and end date
* @author Bharadwaj Gaddam
* @date 12/7/2017 
* @param Map<Id,T_PRIM_ACTV__c> => <ClientId,PrimaryActivity> , Set<Id> trigger.newMap.Keyset() of Primary Activities
* @return void
*/      
    public static void primActBeforeUpdateCheckBeginDate(Map<string,T_PRIM_ACTV__c> newPrimaryActivityIndivMap,Set<Id> primaryIdSet) {
        Date nulldate; 
        for(T_PRIM_ACTV__c primActEach:[Select Id,IDN_CLIENT__c,DTE_END_ACTV_PRIM__c,DTE_BEGIN_ACTV_PRIM__c,IDN_CASE__c from T_PRIM_ACTV__c where IDN_CLIENT__c IN:individualIdset and IDN_CASE__c IN:caseIdset and DTE_END_ACTV_PRIM__c!=:nulldate and DTE_BEGIN_ACTV_PRIM__c!=:nulldate and Id NOT IN:primaryIdSet]) {
            if(newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c)!=null) {
                if(newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c).DTE_BEGIN_ACTV_PRIM__c >= primActEach.DTE_BEGIN_ACTV_PRIM__c && newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c).DTE_BEGIN_ACTV_PRIM__c <= primActEach.DTE_END_ACTV_PRIM__c && newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c).Is_CBMS_Data__c == false ) {
                    newPrimaryActivityIndivMap.get(primActEach.IDN_CLIENT__c+';'+primActEach.IDN_CASE__c).addError(Label.Only_have_one_effective_Primary_Activity);               
                }
            }
            
        }
     
    }
    
/**
* @description creates Primary Activity Counter records for new Primary Activity records
* @author Bharadwaj Gaddam
* @date 1/5/2018 
* @param List<T_PRIM_ACTV__c> New Primary Activities
* @return void
*/   
    public static void createPrimaryActivityCounter(List<T_PRIM_ACTV__c> newPrimaryActivityList) {
    
    Map<Id,T_PRIM_ACTV_CNTR__c> newPrimaryActivityCounterMap = new Map<Id,T_PRIM_ACTV_CNTR__c>();
    try{
    for(T_PRIM_ACTV__c primActEach:newPrimaryActivityList) {
        if(primActEach.CDE_TYPE_ACTV__c==PRIMARYACTIVITYTYPEGED || primActEach.CDE_TYPE_ACTV__c==PRIMARYACTIVITYTYPEPOS || primActEach.CDE_TYPE_ACTV__c==PRIMARYACTIVITYTYPEJS || primActEach.CDE_TYPE_ACTV__c=='SUD') {//Added SUD as part of CCCAP-13790
        newPrimaryActivityCounterMap.put(primActEach.Id,new T_PRIM_ACTV_CNTR__c(IDN_PRIM_ACTV__c=primActEach.Id,IDN_CLIENT__c=primActEach.IDN_CLIENT__c,CNT_WEEKS__c=0));
        
        }       
    }
    
    if(!newPrimaryActivityCounterMap.isEmpty() && newPrimaryActivityCounterMap != NULL ) {
        insert newPrimaryActivityCounterMap.values();
    
    }
    }catch(Exception ex) {
        ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'PrimaryActivityServices','Method__c'=>'createPrimaryActivityCounter'});
    }
    
    }
    
}