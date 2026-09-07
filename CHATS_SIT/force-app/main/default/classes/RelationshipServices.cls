/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           22/12/2017                                                          
*  @description    Handler class for Relationship Trigger                          
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 22-Dec-2017                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version                                                 
*  * Change Log : Updating line number
*********************************************************************************************/
public with sharing class RelationshipServices{
    
    /**
* @description updates Relationship type on Individual
* @author Bharadwaj Gaddam
* @date 22/12/2017 
* @param List<T_INDIV_REL__c> trigger.new Relationship list
* @return void
*/
    public static void updateIndividualWithHasAllowedRelationship(List<T_INDIV_REL__c> relationshipList) {
        Set<Id> individualIdSet = new Set<Id>();
        Map<Id,T_SBSD_INDIV__c> updateIndvidualMap = new Map<Id,T_SBSD_INDIV__c>();
        List<String> TEEN_PARENT_RELATIONSHIPS = new List<String>{'M','F','H','W','CLH','CLW','LIC','SO'};
            for(T_INDIV_REL__c relationEach:relationshipList) {
                if(relationEach.CDE_TYPE_REL_INDIV__c!=null && relationEach.IDN_CLIENT__c!=null && relationEach.IDN_CLIENT_RELTD__c!=null) {
                    individualIdSet.add(relationEach.IDN_CLIENT_RELTD__c);
                }
            }
        try {
            for(T_SBSD_INDIV__c individual:[select Id,Has_Allowed_Relationship__c,(SELECT Id FROM Relationship__r WHERE CDE_TYPE_REL_INDIV__c IN:TEEN_PARENT_RELATIONSHIPS and IDN_CLIENT__c!=null) from T_SBSD_INDIV__c where Id IN:individualIdSet]) {
               
                if(individual.Relationship__r.size()>0) {
                    if(!individual.Has_Allowed_Relationship__c) {
                       individual.Has_Allowed_Relationship__c=true;
                       updateIndvidualMap.put(individual.Id,individual);
                    }
                } 
                else if(individual.Has_Allowed_Relationship__c) {
                       individual.Has_Allowed_Relationship__c=false;
                       updateIndvidualMap.put(individual.Id,individual);
                }
            }
           
            if(!updateIndvidualMap.isEmpty() && updateIndvidualMap != Null ) {
                update updateIndvidualMap.values();
            }
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'RelationshipServices','Method__c'=>'updateIndividualWithHasAllowedRelationship'});
        }
    }
    
    public static void beginDatePopulation(List<T_INDIV_REL__c> relationshipList) {
        
        for(T_INDIV_REL__c relationEach : relationshipList){
            relationEach.DTE_BEGIN_EFFV__c = system.today();
        }
    }
 //added for CCCAP-972
      public static void relationshipDateOverlapping(List<T_INDIV_REL__c> newRelationship){
          Set<Id> indivIdSet = new Set<Id>();
          Set<Id> clientIdSet = new Set<Id>();
          Set<Id> relationshipRecordId = new Set<Id>();
          for(T_INDIV_REL__c relationship: newRelationship){
            indivIdSet.add(relationship.IDN_CLIENT__c);
            clientIdSet.add(relationship.IDN_CLIENT_RELTD__c);
            relationshipRecordId.add(relationship.Id);
          }        
          List<T_INDIV_REL__c> relationList=[select id,name,IDN_CLIENT_RELTD__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c from T_INDIV_REL__c where IDN_CLIENT__c in :indivIdSet and id NOT IN:relationshipRecordId];
          for(T_INDIV_REL__c relationship: newRelationship){
             for (T_INDIV_REL__c existingRelation: relationList)
             {
                 if(existingRelation.IDN_CLIENT_RELTD__c==relationship.IDN_CLIENT_RELTD__c){
                    
                 if((relationship.DTE_BEGIN_EFFV__c >= existingRelation.DTE_BEGIN_EFFV__c && relationship.DTE_BEGIN_EFFV__c <= existingRelation.DTE_END_EFFV__c) 
                    || (relationship.DTE_END_EFFV__c >= existingRelation.DTE_BEGIN_EFFV__c && relationship.DTE_END_EFFV__c <= existingRelation.DTE_END_EFFV__c) 
                    || (relationship.DTE_BEGIN_EFFV__c<= existingRelation.DTE_BEGIN_EFFV__c  && relationship.DTE_END_EFFV__c >= existingRelation.DTE_END_EFFV__c))
                 {
                    relationship.addError(Label.RelationshipDateOverlappError);
                 }
               }
             }
          } 
      }

    public static void relationshipValidation(List<T_INDIV_REL__c> relationshipList) { 
        Map<Id, List<T_SBSD_CASE_INDIV__c>> primaryIdWithCaseIndivMap  = new Map<Id, List<T_SBSD_CASE_INDIV__c>>();
        Map<Id, Set<Id>> primaryIdWithCaseMap  = new Map<Id, Set<Id>>();
        Map<Id, List<T_SBSD_CASE_INDIV__c>> clientIdWithCaseIndivMap  = new Map<Id, List<T_SBSD_CASE_INDIV__c>>();
        Map<Id, Set<Id>> clientIdWithCaseMap  = new Map<Id, Set<Id>>();
        Set<Id> indivIdSet = new Set<Id>();
        Set<Id> clientIdSet = new Set<Id>();
        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> primaryIndivSet = new Set<Id>();
        Set<Id> nonPrimaryIndivSet = new Set<Id>();
        String parentNameClientName;
        
        
        for(T_INDIV_REL__c relationEach : relationshipList){
            indivIdSet.add(relationEach.IDN_CLIENT__c);
            clientIdSet.add(relationEach.IDN_CLIENT_RELTD__c);
        }
        
        for(T_SBSD_CASE_INDIV__c caseIndivEach : [Select Id, IDN_CASE__c, IDN_CASE__r.Name, IDN_CLIENT__c, IDN_CLIENT__r.Name From T_SBSD_CASE_INDIV__c Where IDN_CLIENT__c IN :indivIdSet AND IND_CRTKR__c = true]){
            if(!primaryIdWithCaseMap.containsKey(caseIndivEach.IDN_CLIENT__c)){
                primaryIdWithCaseIndivMap.put(caseIndivEach.IDN_CLIENT__c, new List<T_SBSD_CASE_INDIV__c>());
                primaryIdWithCaseMap.put(caseIndivEach.IDN_CLIENT__c, new Set<Id>());
            }
            primaryIdWithCaseIndivMap.get(caseIndivEach.IDN_CLIENT__c).add(caseIndivEach);
            primaryIdWithCaseMap.get(caseIndivEach.IDN_CLIENT__c).add(caseIndivEach.IDN_CASE__c);
            caseIdSet.add(caseIndivEach.IDN_CASE__c);   
        }
        
        for(T_SBSD_CASE_INDIV__c caseIndivEach : [Select Id, IDN_CASE__c, IDN_CASE__r.Name, IDN_CLIENT__c, IDN_CLIENT__r.Name From T_SBSD_CASE_INDIV__c Where IDN_CLIENT__c IN :clientIdSet AND IDN_CASE__c IN :caseIdSet AND IND_CRTKR__c = false]){
            if(!clientIdWithCaseMap.containsKey(caseIndivEach.IDN_CLIENT__c)){
                clientIdWithCaseIndivMap.put(caseIndivEach.IDN_CLIENT__c, new List<T_SBSD_CASE_INDIV__c>());	
                clientIdWithCaseMap.put(caseIndivEach.IDN_CLIENT__c, new Set<Id>());
            }
            clientIdWithCaseIndivMap.get(caseIndivEach.IDN_CLIENT__c).add(caseIndivEach);
            clientIdWithCaseMap.get(caseIndivEach.IDN_CLIENT__c).add(caseIndivEach.IDN_CASE__c);  
        }
        
        Set<String> parentNameClientNameSet = new Set<String>();
        
        for(T_INDIV_REL__c relRec : [Select Id, IDN_CLIENT__r.Name, IDN_CLIENT_RELTD__r.Name From T_INDIV_REL__c Where IDN_CLIENT__c IN :indivIdSet AND IDN_CLIENT_RELTD__c IN :clientIdSet AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>Today)]){
            parentNameClientNameSet.add(relRec.IDN_CLIENT__r.Name+relRec.IDN_CLIENT_RELTD__r.Name);
        }
        Boolean isChildExist;
        
        for(T_INDIV_REL__c relationEach : relationshipList){
            if(!primaryIdWithCaseMap.containsKey(relationEach.IDN_CLIENT__c)){
                relationEach.addError('Please select Primary Caretaker Individual.');
            }else{
                if(relationEach.IDN_CLIENT__c == relationEach.IDN_CLIENT_RELTD__c){
                    relationEach.addError('The Primary Caretaker and Client ID selected may not be for the same individual.'); 
                }else{
                    parentNameClientName = primaryIdWithCaseIndivMap.get(relationEach.IDN_CLIENT__c)[0].IDN_CLIENT__r.Name;
                    
                    isChildExist = true;
                    for(Id caseId : primaryIdWithCaseMap.get(relationEach.IDN_CLIENT__c)){
                        if(!clientIdWithCaseMap.containsKey(relationEach.IDN_CLIENT_RELTD__c)){
                            relationEach.addError('Please ensure that Client ID is present on Primary Caretaker\'s Case.');
                            isChildExist = false;
                        }
                    }
                    if(isChildExist){
                        parentNameClientName += clientIdWithCaseIndivMap.get(relationEach.IDN_CLIENT_RELTD__c)[0].IDN_CLIENT__r.Name;
                        if(parentNameClientNameSet.contains(parentNameClientName)){
                            relationEach.addError('Relationship already exists.');
                        }
                    } 
                }
                
            }
        }	
    }
}