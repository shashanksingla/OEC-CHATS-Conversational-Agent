/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           8/10/2018                                                          
*  @description    Invoked by AssessEligibilityFlowApxCtrl controller to get a JSON with Record Id, Object Name and Lastmodofieddate to check synchronization                            
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 10-Aug-2018                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version  
*********************************************************************************************/
public with sharing class SyncDataJSONCreator {
    
 /**
* @description query all child records of case record and form JOSN with Record Id, Object Name and Lastmodofieddate for each record
* @author Bharadwaj Gaddam
* @date 08/10/2018   
* @param string caseID: Case record Id passed by AssessEligibilityFlowApxCtrl controller
* @return string
*/
    public static string SyncDataJSONForm(string caseID) {
        List<T_SBSD_CASE__c> caseList= new List<T_SBSD_CASE__c>();
        List<T_SBSD_CASE_INDIV__c> caseIndividualList = new List<T_SBSD_CASE_INDIV__c>();
        List<T_SBSD_INDIV__c> individualList = new List<T_SBSD_INDIV__c>();
        List<T_SBSD_INDIV_EMPLMT__c> employmentList= new List<T_SBSD_INDIV_EMPLMT__c>();
        List<T_EMPLMT_INCOME__c> employmentIncomeList= new List<T_EMPLMT_INCOME__c>();
        List<T_INDIV_VERIF__c> individuaVerifList = new List<T_INDIV_VERIF__c>();
        set<Id> individualIdSet= new set<Id>();
        Map<string,object> objectNametoRecords = new Map<string,object>();
        set<Id> countyIdSet = new set<Id>();
        List<Map<string,string>> syncDataMap= new List<Map<string,string>>();
        Set<Map<string,string>> syncDataMapWithoutDuplicates= new Set<Map<string,string>>();
        set<Id> indivRelIdSet= new set<Id>();
        
        //Query to get case record along with its child records 
        caseList=[Select Id, LastModifiedDate,CDE_COUNTY__c,(Select Id, LastModifiedDate from T_SBSD_CASE10__r where DTE_BEGIN_EFFV__C <= Today and (DTE_END_EFFV__C=null or  DTE_END_EFFV__C>=Today)),
                  (Select Id, LastModifiedDate from T_SBSD_CASE3__r where CDE_TYPE_ADR__c ='HOM'), (Select Id, LastModifiedDate from T_SBSD_CASE4__r),
                  (Select Id,LastModifiedDate,IDN_CLIENT__c from CaseIndividuals__r where DTE_BEGIN_EFFV__c<=Today and (DTE_END_EFFV__c=null or DTE_END_EFFV__c>=Today )),
                  //(Select Id, LastModifiedDate from T_AUTH__r where DTE_END_EFFV_AUTH__c=null or DTE_END_EFFV_AUTH__c>=Today),//Removed as per CHATS-6887
                  (Select Id, LastModifiedDate from CBMS_Additional_Information__r)            
                  from T_SBSD_CASE__c where Id=:caseID];    
        if(caseList.size()>0 ) { 
            objectNametoRecords.put('T_SBSD_CASE__c',caseList.get(0));
            if(caseList[0].CaseIndividuals__r.size()>0) {
                for(T_SBSD_CASE_INDIV__c caseIndivEach:caseList[0].CaseIndividuals__r) {
                    individualIdSet.add(caseIndivEach.IDN_CLIENT__c);
                }
            }
            for(T_SBSD_CASE__c caseEach:caseList) {
                if(caseEach.CDE_COUNTY__c!=null) {
                    countyIdSet.add(caseEach.CDE_COUNTY__c);
                }
            }
            if(countyIdSet.size()>0) {
                for(T_COUNTY_PLAN__C countyPlan:[select Id, LastModifiedDate from T_COUNTY_PLAN__C where CDE_COUNTY__c IN:countyIdSet and 
                                                 DTE_BEGIN_EFFEV__c <= Today and (DTE_END_EFFEV__c=null or DTE_END_EFFEV__c>=Today) ]) {
                                                     if(countyPlan.Id!=null) {
                                                         syncDataMap.add(new Map<string,string>{'Id'=>countyPlan.Id,'LastModified'=>countyPlan.LastmodifiedDate+'','ObjectName'=>'T_COUNTY_PLAN__C'});
                                                     }
                                                 }
            }
                   
            //Query to get Case Individual records along with its child records
            caseIndividualList=[Select Id, LastModifiedDate,(Select Id, LastModifiedDate,IDN_CASE_INDIV__r.IDN_CLIENT__c from Case_Individual_Role__r where CDE_ROLE_CASE__C = 'HOH' and DTE_BEGIN_EFFV__c<=Today and (DTE_END_EFFV__c=null or DTE_END_EFFV__c>=Today)),
                                (Select Id, LastModifiedDate from Child_Care_Requests__r where ((DTE_BEGIN_EFFV__c<=Today and OVERRIDDEN_DTE_BEGIN_EFFV__c=null) or OVERRIDDEN_DTE_BEGIN_EFFV__c <=Today) and (DTE_END_EFFV__c=null or DTE_END_EFFV__c>=Today))
                                from T_SBSD_CASE_INDIV__c where IDN_CASE__c=:caseID and IDN_CLIENT__c IN :individualIdSet and DTE_BEGIN_EFFV__c<=Today and (DTE_END_EFFV__c=null or DTE_END_EFFV__c>=Today)];
            if(caseIndividualList.size()>0) {
                objectNametoRecords.put('T_SBSD_CASE_INDIV__c',caseIndividualList);
                for(T_SBSD_CASE_INDIV__c caseIndiEach:caseIndividualList) {
                    if(caseIndiEach.Case_Individual_Role__r.size()>0) {
                        for(T_SBSD_CASE_INDIV_ROLE__c caseIndivRole:caseIndiEach.Case_Individual_Role__r) {
                            indivRelIdSet.add(caseIndivRole.IDN_CASE_INDIV__r.IDN_CLIENT__c);
                        }
                    }
                }
            }
            
            //Query to get Individual records along with its child records
            individualList=[Select Id, LastModifiedDate,(Select Id, LastModifiedDate from T_SBSD_INDIV24__r),
                            (Select Id, LastModifiedDate,IDN_CLIENT__c,IDN_CLIENT_RELTD__c,Name from Relationship__r where (IDN_CLIENT__c IN:indivRelIdSet and IDN_CLIENT_RELTD__c IN:individualIdSet)),
                            (Select Id, LastModifiedDate,IDN_CLIENT__c,IDN_CLIENT_RELTD__c,Name from Primary_Individual_Relationship__r where (IDN_CLIENT_RELTD__c IN:indivRelIdSet and IDN_CLIENT__c IN: individualIdSet )),
                            (Select Id, LastModifiedDate from T_SBSD_INDIV6__r),(Select Id, LastModifiedDate from T_SBSD_INDIV7__r),
                            (Select Id, LastModifiedDate from Child_Support_Deductions__r),
                            (Select Id, LastModifiedDate from T_SBSD_INDIV10__r),(Select Id, LastModifiedDate from T_SBSD_INDIV12__r),
                            (Select Id, LastModifiedDate from T_SBSD_INDIV22__r),
                            (Select Id, LastModifiedDate from T_SBSD_INDIV1__r),(Select Id, LastModifiedDate from T_SBSD_INDIV14__r)
                            from T_SBSD_INDIV__c where Id IN:individualIdSet ]; 
            if(individualList.size()>0) {
                objectNametoRecords.put('T_SBSD_INDIV__c',individualList);
            }
            
            //Iterating Primary Activity Counter records whose Primary Activity's Individual is mathich with individualIdSet and also CDE_TYPE__c should be equal to CDE_TYPE_ACTV__c on associated Primary Activity
            for(T_PRIM_ACTV_CNTR__c primActCounter:[select Id, LastModifiedDate,CDE_TYPE__c,IDN_PRIM_ACTV__r.CDE_TYPE_ACTV__c from T_PRIM_ACTV_CNTR__c where IDN_PRIM_ACTV__r.IDN_CLIENT__c IN:individualIdSet ]) {
                if(primActCounter.CDE_TYPE__c == primActCounter.IDN_PRIM_ACTV__r.CDE_TYPE_ACTV__c) {
                    syncDataMap.add(new Map<string,string>{'Id'=>primActCounter.Id,'LastModified'=>primActCounter.LastmodifiedDate+'','ObjectName'=>'T_PRIM_ACTV_CNTR__c'});
                }
            }
            
            //Query to get Employment records along with its child records
            employmentList=[Select Id, LastModifiedDate,(Select Id, LastModifiedDate from T_SBSD_INDIV_EMPLMT1__r),
                            (Select Id, LastModifiedDate from Employment_Verifications__r),(Select Id, LastModifiedDate from Employment_Information__r) 
                            from T_SBSD_INDIV_EMPLMT__c where IDN_CLIENT__c IN:individualIdSet and DTE_BEGIN_EFFV__c<=Today and (DTE_END_EFFV__c=null or DTE_END_EFFV__c>=Today)];
            if(employmentList.size()>0) {
                objectNametoRecords.put('T_SBSD_INDIV_EMPLMT__c',employmentList);
            }
            
            //Query to get Employment Income records along with its child records
            employmentIncomeList=[Select Id, LastModifiedDate,(Select Id, LastModifiedDate from Employment_Pay_Stub__r)
                                  from T_EMPLMT_INCOME__c where IDN_EMPLMT_INDIV__r.IDN_CLIENT__c IN:individualIdSet and (IDN_EMPLMT_INDIV__r.DTE_BEGIN_EFFV__c<=Today and (IDN_EMPLMT_INDIV__r.DTE_END_EFFV__c=null or IDN_EMPLMT_INDIV__r.DTE_END_EFFV__c>=Today))];
            if(employmentIncomeList.size()>0) {
                objectNametoRecords.put('T_EMPLMT_INCOME__c',employmentIncomeList);
            }
            
            //Query to get Individual Verification records whose CDE_TYPE_INFO_INDIV__C is 'CS'
            individuaVerifList=[Select Id, LastModifiedDate from T_INDIV_VERIF__c where IDN_CLIENT__r.IDN_CLIENT__c IN:individualIdSet and CDE_TYPE_INFO_INDIV__C IN ('CS') AND IDN_CLIENT__r.IDN_CASE__c=:caseID];
            if(individuaVerifList.size()>0) {
                objectNametoRecords.put('T_INDIV_VERIF__c',individuaVerifList);
            }
        }
        
        //Adding all records to syncDataMap list which holds Map<string,string>
        for(string objName:objectNametoRecords.keySet()) {
            if(objName=='T_SBSD_CASE__c') {
                T_SBSD_CASE__c caseObj=(T_SBSD_CASE__c)objectNametoRecords.get(objName);
                syncDataMap.add(new Map<string,string>{'Id'=>caseObj.Id,'LastModified'=>caseObj.LastmodifiedDate+'','ObjectName'=>'T_SBSD_CASE__c'});    
                if(caseObj.T_SBSD_CASE10__r.size()>0) {
                    for(T_SBSD_CASE_STATUS_MODE__c eachRec:caseObj.T_SBSD_CASE10__r) {
                        syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_SBSD_CASE_STATUS_MODE__c'});
                    }
                }   
                if(caseObj.T_SBSD_CASE3__r.size()>0) {
                    for(T_SBSD_CASE_ADR__c eachRec:caseObj.T_SBSD_CASE3__r) {
                        syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_SBSD_CASE_ADR__c'});
                    }
                }
                if(caseObj.T_SBSD_CASE4__r.size()>0) {
                    for(T_SBSD_CASE_ASSET__c eachRec:caseObj.T_SBSD_CASE4__r) {
                        syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_SBSD_CASE_ASSET__c'});
                    }
                }
                if(caseObj.CaseIndividuals__r.size()>0) {
                    for(T_SBSD_CASE_INDIV__c eachRec:caseObj.CaseIndividuals__r) {
                        syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_SBSD_CASE_INDIV__c'});
                    }
                }
                //if(caseObj.T_AUTH__r.size()>0) {
                    //for(T_AUTH__c eachRec:caseObj.T_AUTH__r) {
                        //syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_AUTH__c'});
                    //}
                //}
                if(caseObj.CBMS_Additional_Information__r.size()>0) {
                    for(T_CBMS_ADDNL_INFO__c eachRec:caseObj.CBMS_Additional_Information__r) {
                        syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_CBMS_ADDNL_INFO__c'});
                    }
                }
            }
            else if(objName=='T_SBSD_CASE_INDIV__c') {
                List<T_SBSD_CASE_INDIV__c> caseIndivObjList=(List<T_SBSD_CASE_INDIV__c>)objectNametoRecords.get(objName);
                for(T_SBSD_CASE_INDIV__c caseIndivObj:caseIndivObjList) {
                    if(caseIndivObj.Case_Individual_Role__r.size()>0) {
                        for(T_SBSD_CASE_INDIV_ROLE__c eachRec:caseIndivObj.Case_Individual_Role__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_SBSD_CASE_INDIV_ROLE__c'});
                        }
                    }
                    if(caseIndivObj.Child_Care_Requests__r.size()>0) {
                        for(T_INDIV_CAT_RQ__c eachRec:caseIndivObj.Child_Care_Requests__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_INDIV_CAT_RQ__c'});
                        }
                    }
                }
            }
            
            else if(objName=='T_SBSD_INDIV__c') {
                List<T_SBSD_INDIV__c> IndivObjList=(List<T_SBSD_INDIV__c>)objectNametoRecords.get(objName);    
                for(T_SBSD_INDIV__c IndivObj:IndivObjList) {
                    syncDataMap.add(new Map<string,string>{'Id'=>IndivObj.Id,'LastModified'=>IndivObj.LastmodifiedDate+'','ObjectName'=>'T_SBSD_INDIV__c'});
                    if(IndivObj.T_SBSD_INDIV24__r.size()>0) {
                        for(T_INDIV_CUST__c eachRec:IndivObj.T_SBSD_INDIV24__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_INDIV_CUST__c'});
                        }
                    }  
                    if(IndivObj.Relationship__r.size()>0) {
                        for(T_INDIV_REL__C eachRec:IndivObj.Relationship__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_INDIV_REL__C'});
                        }
                    } 
                    if(IndivObj.Primary_Individual_Relationship__r.size()>0) {
                        for(T_INDIV_REL__C eachRec:IndivObj.Primary_Individual_Relationship__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_INDIV_REL__C'});
                        }
                    } 
                    if(IndivObj.T_SBSD_INDIV6__r.size()>0) {
                        for(T_INDIV_DSBLTY__c eachRec:IndivObj.T_SBSD_INDIV6__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_INDIV_DSBLTY__c'});
                        }
                    } 
                    if(IndivObj.T_SBSD_INDIV7__r.size()>0) {
                        for(T_INDIV_EDUC__c eachRec:IndivObj.T_SBSD_INDIV7__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_INDIV_EDUC__c'});
                        }
                    } 
                    if(IndivObj.Child_Support_Deductions__r.size()>0) {
                        for(T_INDIV_DDTN__c eachRec:IndivObj.Child_Support_Deductions__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_INDIV_DDTN__c'});
                        }
                    }
                    if(IndivObj.T_SBSD_INDIV10__r.size()>0) {
                        for(T_INDIV_OTHER_INCOME__c eachRec:IndivObj.T_SBSD_INDIV10__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_INDIV_OTHER_INCOME__c'});
                        }
                    } 
                    if(IndivObj.T_SBSD_INDIV12__r.size()>0) {
                        for(T_INDIV_TRAIN__c eachRec:IndivObj.T_SBSD_INDIV12__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_INDIV_TRAIN__c'});
                        }
                    } 
                    if(IndivObj.T_SBSD_INDIV22__r.size()>0) {
                        for(T_PRIM_ACTV__c eachRec:IndivObj.T_SBSD_INDIV22__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_PRIM_ACTV__c'});
                        }
                    }
                    if(IndivObj.T_SBSD_INDIV1__r.size()>0) {
                        for(T_CHILD_SUP__c eachRec:IndivObj.T_SBSD_INDIV1__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_CHILD_SUP__c'});
                        }
                    }
                    if(IndivObj.T_SBSD_INDIV14__r.size()>0) {
                        for(T_JOB_SEARCH__c eachRec:IndivObj.T_SBSD_INDIV14__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_JOB_SEARCH__c'});
                        }
                    }
                }
            }
            
            else if(objName=='T_SBSD_INDIV_EMPLMT__c') {
                List<T_SBSD_INDIV_EMPLMT__c> empObjList=(List<T_SBSD_INDIV_EMPLMT__c>)objectNametoRecords.get(objName); 
                for(T_SBSD_INDIV_EMPLMT__c empObj:empObjList) {
                    syncDataMap.add(new Map<string,string>{'Id'=>empObj.Id,'LastModified'=>empObj.LastmodifiedDate+'','ObjectName'=>'T_SBSD_INDIV_EMPLMT__c'});
                    if(empObj.T_SBSD_INDIV_EMPLMT1__r.size()>0) {
                        for(T_EMPLMT_INCOME__c eachRec:empObj.T_SBSD_INDIV_EMPLMT1__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_EMPLMT_INCOME__c'});
                        }
                    }  
                    if(empObj.Employment_Verifications__r.size()>0) {
                        for(T_INDIV_EMPLMT_VERIF__c eachRec:empObj.Employment_Verifications__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_INDIV_EMPLMT_VERIF__c'});
                        }
                    }  
                    if(empObj.Employment_Information__r.size()>0) {
                        for(T_INDIV_EMPLMT_INFO__c eachRec:empObj.Employment_Information__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_INDIV_EMPLMT_INFO__c'});
                        }
                    }  
                }
            }
            else if(objName=='T_EMPLMT_INCOME__c') {
                List<T_EMPLMT_INCOME__c> empIncomeObjList=(List<T_EMPLMT_INCOME__c>)objectNametoRecords.get(objName); 
                for(T_EMPLMT_INCOME__c empObj:empIncomeObjList) {
                    if(empObj.Employment_Pay_Stub__r.size()>0) {
                        for(T_EMPLMT_PAY_STUB__c eachRec:empObj.Employment_Pay_Stub__r) {
                            syncDataMap.add(new Map<string,string>{'Id'=>eachRec.Id,'LastModified'=>eachRec.LastmodifiedDate+'','ObjectName'=>'T_EMPLMT_PAY_STUB__c'});
                        }
                    }
                }
            }
            else if(objName=='T_INDIV_VERIF__c') {
                List<T_INDIV_VERIF__c> indivVerifObjList=(List<T_INDIV_VERIF__c>)objectNametoRecords.get(objName); 
                for(T_INDIV_VERIF__c indivVerifObj:indivVerifObjList) {
                    syncDataMap.add(new Map<string,string>{'Id'=>indivVerifObj.Id,'LastModified'=>indivVerifObj.LastmodifiedDate+'','ObjectName'=>'T_INDIV_VERIF__c'});
                }
            }
        }
        
        syncDataMapWithoutDuplicates.addAll(syncDataMap);
        //return JSON
        return JSON.serialize(syncDataMapWithoutDuplicates);
    }
    
    
}