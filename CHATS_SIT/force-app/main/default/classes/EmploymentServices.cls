/*********************************************************************************************
*  @author         Deloitte Consulting                                             
*  @date           03/10/2021                                                          
*  @description    Handler class for Employment Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 10-March-2021                                                             
*  * Author: Barkha Jain                                                     
*  * Description: Initial version                                                 
*********************************************************************************************/
public with sharing class EmploymentServices {
    
    public static void validateEmploymentCounty(List<T_SBSD_INDIV_EMPLMT__c> newList, Map<Id, T_SBSD_INDIV_EMPLMT__c> oldMap){
        set<Id> caseIdSet = new set<Id>();
        for(T_SBSD_INDIV_EMPLMT__c emp : newList){
            if(emp.IDN_CASE__c != null && (oldMap == null || oldMap.get(emp.Id).IDN_CASE__c != emp.IDN_CASE__c 
                                           || oldMap.get(emp.Id).IDN_CLIENT__c != emp.IDN_CLIENT__c)){
                caseIdSet.add(emp.IDN_CASE__c);
                if(oldMap != null && oldMap.get(emp.Id).IDN_CASE__c != emp.IDN_CASE__c){
                    caseIdSet.add(oldMap.get(emp.Id).IDN_CASE__c);
                }
            }
        }
        
        if(caseIdSet.isEmpty())
            return;
        
        Set<Id> countyIdSet = new Set<Id>();
        Map<Id, T_SBSD_CASE__c> caseMap = new Map<Id, T_SBSD_CASE__c>();
        Map<Id, set<Id>> caseClientIdMap = new Map<Id, set<Id>>();
        for(T_SBSD_CASE__c cs : [SELECT Id, Name, CDE_County__c, CDE_County__r.Name, 
                                 (SELECT IDN_CLIENT__c FROM CaseIndividuals__r) FROM T_SBSD_CASE__c WHERE ID IN :caseIdSet WITH SECURITY_ENFORCED]){
            caseMap.put(cs.Id, cs);
            countyIdSet.add(cs.CDE_County__c);
            caseClientIdMap.put(cs.Id, new Set<Id>());
            for(T_SBSD_CASE_INDIV__c indiv : cs.CaseIndividuals__r){
                caseClientIdMap.get(cs.Id).add(indiv.IDN_CLIENT__c);
            }                        
        }
        Map<Id, Boolean> countyMatchedMap = CHATSUtility.checkCountyWithUserCountyBulk(countyIdSet);
        
        T_SBSD_CASE__c oldCase;
        T_SBSD_CASE__c newCase;
        for(T_SBSD_INDIV_EMPLMT__c emp : newList){
            if(emp.IDN_CASE__c != null){
                newCase = caseMap.get(emp.IDN_CASE__c);
                if(oldMap != null && oldMap.get(emp.Id).IDN_CASE__c != emp.IDN_CASE__c && oldMap.get(emp.Id).IDN_CASE__c != null){                    
                    oldCase = caseMap.get(oldMap.get(emp.Id).IDN_CASE__c);
                    if(newCase.CDE_County__c != oldCase.CDE_County__c)                       
                        emp.addError('The Employment record belongs to '+newCase.CDE_County__r.Name+' county and cannot be associated to new county.');                
                } else if(oldMap == null && countyMatchedMap.containsKey(newCase.CDE_County__c) && emp.Is_CBMS_Data__c == false){
                    Boolean countyMatched = countyMatchedMap.get(newCase.CDE_County__c);
                    if(!countyMatched){
                        emp.addError('The case '+newCase.Name+' belongs to '+newCase.CDE_County__r.Name+' county. This does not match your assigned county(ies).');  
                    }
                }
                if(oldMap == null || oldMap.get(emp.Id).IDN_CASE__c != emp.IDN_CASE__c || oldMap.get(emp.Id).IDN_CLIENT__c != emp.IDN_CLIENT__c){
                    if(!caseClientIdMap.get(emp.IDN_CASE__c).contains(emp.IDN_CLIENT__c)){
                        emp.addError('The Individual is not associated with Case ID entered. Please verify the Case ID.');  
                    }
                }
            }
        }
    }

}