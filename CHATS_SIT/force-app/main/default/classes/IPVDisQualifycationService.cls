/************************************************************
*  Author:         Deloitte Consulting LLP.
*  Date:           06/16/2021
*  Description:    Handler class for IPVDisQualifycationApxTrigger.apxt
*  Test class:     IPVDisQualifycationApxTrigger_Test
*
*  Modification Log:
*  * Version: 1.0
*  * Date: 14-July-2021
*  * Author: Diya Chaudhary
*  * Description: Initial version
*
*  * Version: 1.1
*  * Date: 03/03/2023
*  * Author: Rishav Maji
*  * Description: API Upgrade, Code cleanup, CheckMarx fix
************************************************************/
public class IPVDisQualifycationService {
    public static final String CR110RsnCode = 'CR0023';
    public static void triggerCR110(List<IPV_Information__c> disQualListNewList,List<IPV_Information__c> disQualListOldList,Boolean triggerContext)    {
        Set<Id> indivIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        Set<Decimal> countyCodeSet = new Set<Decimal>();
        Map<String, String> caseIndivMap = new Map<String, String> ();
        Set<Id> disQualIds = new Set<Id>();
        Map<string,string> keyParams = new Map<string, string>();
        Map<Id, IPV_Information__c> disQualOldMap = new Map<Id, IPV_Information__c> ();
        Map<Id, IPV_Information__c> disQualNewMap = new Map<Id, IPV_Information__c> ();
        Map<String, T_DOC_RQ__c> oldDOCRQMap = new Map<String, T_DOC_RQ__c> ();
        Map<String,String> caseIndivSortedMap = new Map<String,String>();
        Map<String,String> ipvCountyMap = new Map<String,String>();
        Map<String,String> indivCaseMap = new Map<String,String>();
        Map<String,Date> caseIndivDateMap = new Map<String,Date>();
        integer countyCode;
        List<T_DOC_RQ__c> corrReq = new List<T_DOC_RQ__c>();
        List<T_DOC_RQ__c> updAlreadyExistingFACorrespondence = new List<T_DOC_RQ__c>();
        List<T_DOC_RQ__c> existingAuthCorrespondence = new List<T_DOC_RQ__c>();
        for(IPV_Information__c eachDisQual : disQualListNewList){
            disQualIds.add(eachDisQual.Id);
        }
        system.debug('disQualListOldList--'+disQualListOldList);
        if(disQualListOldList!=null){
            for(IPV_Information__c eachDisQual : disQualListOldList){
                disQualOldMap.put(eachDisQual.Id,eachDisQual);
                indivIds.add(eachDisQual.Individual_ID__c);
              //  countyCodeSet.add(Decimal.valueOf(eachDisQual.County__c));
                ipvCountyMap.put(eachDisQual.Individual_ID__c, eachDisQual.County__c);
            }  
        }
        for(T_DOC_RQ__c obj :[select id,IPV_Information__c,IDN_CLIENT__c,CDE_CORSPD_STATUS__c from T_DOC_RQ__c where IPV_Information__c =:disQualIds and DTE_REQ__c =: system.today() and CDE_CORSPD_STATUS__c='Requested' And NME_CORSPD__c='CR110']){
            oldDOCRQMap.put(obj.IPV_Information__c, obj); 
            existingAuthCorrespondence.add(obj);
        } 
        Map<Id,List<T_SBSD_CASE__c>> indivOpenCases= new Map<Id,List<T_SBSD_CASE__c>>() ;
        List<T_SBSD_CASE_INDIV__c> caseIndivList =[SELECT IDN_CLIENT__r.NAM_FIRST__c,IDN_CASE__c,DTE_BEGIN_EFFV__c,IDN_CLIENT__c,IDN_CASE__r.CDE_COUNTY__r.CDE_COUNTY__c,
                                                   IDN_CLIENT__r.NAM_LAST__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CLIENT__c IN:indivIds AND
                                                   DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY) and IDN_CASE__r.CDE_COUNTY__c IN:ipvCountyMap.values() order by DTE_BEGIN_EFFV__c DESC ];
        for(T_SBSD_CASE_INDIV__c caseIndiv :caseIndivList){
            caseIds.add(caseIndiv.IDN_CASE__c);
           
        }
        system.debug('caseIds--'+caseIds);
        if(caseIds!= null && caseIds.size()>0){
            for(T_SBSD_CASE__c cseRec :[SELECT Id,Name,CDE_COUNTY__R.NAME,OWNER.NAME,(SELECT IDN_CASE__r.Name, IDN_CLIENT__r.NAM_FIRST__c,IDN_CASE__c,DTE_BEGIN_EFFV__c,IDN_CLIENT__c,IDN_CASE__r.CDE_COUNTY__r.CDE_COUNTY__c,
                                             IDN_CLIENT__r.NAM_LAST__c FROM CaseIndividuals__r WHERE IDN_CLIENT__c IN:indivIds AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY)),                                 
                                             (SELECT CDE_STATUS_CASE__c,toLabel(CDE_MODE_CASE__c), DTE_BEGIN_EFFV__c FROM T_SBSD_CASE10__r where DTE_END_EFFV__c = null Order by DTE_BEGIN_EFFV__c,createddate Desc NULLS FIRST Limit 1)
                                        FROM T_SBSD_CASE__c where CDE_COUNTY__c in:ipvCountyMap.values() and id IN:caseIds ]){
                                            system.debug('cseRec--'+cseRec);
                                            if(cseRec.T_SBSD_CASE10__r != null && cseRec.T_SBSD_CASE10__r.size()>0 && (new List<String>{'OPN','CLS'}.contains((string)cseRec.T_SBSD_CASE10__r[0].CDE_STATUS_CASE__c))){
                                                 system.debug('cseRec.T_SBSD_CASE10__r--'+cseRec.T_SBSD_CASE10__r);
                                                if(cseRec.CaseIndividuals__r != null && cseRec.CaseIndividuals__r.size()>0){
                                                     
                                                    for(T_SBSD_CASE_INDIV__c caseIndiv:cseRec.CaseIndividuals__r){
                                                        system.debug('caseIndiv--'+caseIndiv);
                                                        if(caseIndivDateMap.containsKey(caseIndiv.IDN_CLIENT__c)){
                                                            Date beginDate = caseIndivDateMap.get(caseIndiv.IDN_CLIENT__c);
                                                            if(beginDate<caseIndiv.DTE_BEGIN_EFFV__c){
                                                                caseIndivDateMap.put(caseIndiv.IDN_CLIENT__c, caseIndiv.DTE_BEGIN_EFFV__c);
                                                                if(ipvCountyMap.get(caseIndiv.IDN_CLIENT__c) == caseIndiv.IDN_CASE__r.CDE_COUNTY__c){
                                                                    caseIndivMap.put(caseIndiv.IDN_CLIENT__c,caseIndiv.IDN_CASE__r.Name);
                                                                }
                                                                
                                                            }
                                                        }else{
                                                            caseIndivDateMap.put(caseIndiv.IDN_CLIENT__c, caseIndiv.DTE_BEGIN_EFFV__c); 
                                                            if(ipvCountyMap.get(caseIndiv.IDN_CLIENT__c) == caseIndiv.IDN_CASE__r.CDE_COUNTY__c){
                                                                caseIndivMap.put(caseIndiv.IDN_CLIENT__c,caseIndiv.IDN_CASE__r.Name);
                                                            }
                                                        } 
                                                    }
                                                    
                                                    
                                                }   
                                            }
                                        }
        }
        system.debug('caseIndivMap--'+caseIndivMap);
        
        for(IPV_Information__c disQual :[Select id,Number_of_occurrences__c,Disqualification_Begin_Date__c,
                                         Disqualification_End_Date__c,Disqualification_determination_Date__c,Name,Disqualification_Result__c,
                                         Individual_ID__c,Individual_ID__r.Name,County__c,County__r.CDE_COUNTY__c from IPV_Information__c where id IN:disQualIds]){
                                             disQualNewMap.put(disQual.id,disQual);
                                             
                                         }
        for(IPV_Information__c disQual:disQualListNewList){
            
            if(triggerContext){
                if((disQual.disqualification_created__c ==true) && (disQual.Disqualification_determination_Date__c!= NULL) && ((disQual.Number_of_occurrences__c != disQualOldMap.get(disQual.Id).Number_of_occurrences__c) ||
                   (disQual.Disqualification_Begin_Date__c != disQualOldMap.get(disQual.Id).Disqualification_Begin_Date__c)||
                   (disQual.Disqualification_End_Date__c != disQualOldMap.get(disQual.Id).Disqualification_End_Date__c) ||
                   (disQual.Disqualification_determination_Date__c != disQualOldMap.get(disQual.Id).Disqualification_determination_Date__c))){
                        IPV_Information__c ipvRec = disQualNewMap.get(disQual.Id);

                       String clientId= ipvRec.Individual_ID__r.Name;
                       if(disQual.County__c != null){
                           countyCode = integer.valueOf(ipvRec.County__r.CDE_COUNTY__c);
                       }
                       if(caseIndivMap.containsKey(ipvRec.Individual_ID__c)){
                           keyParams.put('caseId', caseIndivMap.get(ipvRec.Individual_ID__c));
                       }
                       keyParams.put('clientId', clientId);
                       if(disQual.Number_of_occurrences__c != null){
                          keyParams.put('numOfOccurrences', String.valueOf(disQual.Number_of_occurrences__c)); 
                       }
                       if(disQual.Disqualification_Begin_Date__c != null){
                            keyParams.put('DQBeginDate', String.valueOf(disQual.Disqualification_Begin_Date__c));
                       }
                       if(disQual.Disqualification_End_Date__c != null){
                           keyParams.put('DQEndDate', String.valueOf(disQual.Disqualification_End_Date__c));
                       }
                       if(disQual.Disqualification_determination_Date__c != null){
                           keyParams.put('DQHearingDate', String.valueOf(disQual.Disqualification_determination_Date__c));
                       }
                       keyParams.put('IPVRecordId', String.valueOf(ipvRec.Id));
                       if(caseIndivMap.containsKey(ipvRec.Individual_ID__c)){
                            if(!oldDOCRQMap.containsKey(ipvRec.Id)){
                                CorspdTrigger.createCorspdRequest(CR110RsnCode,NULL,NULL,countyCode,keyParams);
                            }else{
                                T_DOC_RQ__C updAuthCorrRec = oldDOCRQMap.get(ipvRec.Id);
                                updAuthCorrRec.Disqualification_Begin_Date__c =disQual.Disqualification_Begin_Date__c;
                                updAuthCorrRec.Disqualification_End_Date__c =disQual.Disqualification_End_Date__c;
                                updAuthCorrRec.Disqualification_Hearing_Date__c =disQual.Disqualification_determination_Date__c;
                                updAuthCorrRec.Number_of_Occurrences__c =Decimal.valueOf(disQual.Number_of_occurrences__c);
                                updAlreadyExistingFACorrespondence.add(updAuthCorrRec);  
                            }  
                        }
                   }
            }else{
                if(disQual.disqualification_created__c ==true){
                     IPV_Information__c ipvRec = disQualNewMap.get(disQual.Id);

                       String clientId= ipvRec.Individual_ID__r.Name;
                    if(disQual.County__c != null){
                        countyCode = integer.valueOf(ipvRec.County__r.CDE_COUNTY__c);
                    }
                    if(caseIndivMap.containsKey(ipvRec.Individual_ID__c)){
                           keyParams.put('caseId', caseIndivMap.get(ipvRec.Individual_ID__c));
                       }
                    keyParams.put('IPVRecordId', String.valueOf(ipvRec.Id));
                    keyParams.put('clientId', clientId);
                    keyParams.put('numOfOccurrences', String.valueOf(disQual.Number_of_occurrences__c));
                    keyParams.put('DQBeginDate', String.valueOf(disQual.Disqualification_Begin_Date__c));
                    keyParams.put('DQEndDate', String.valueOf(disQual.Disqualification_End_Date__c));
                    keyParams.put('DQHearingDate', String.valueOf(disQual.Disqualification_determination_Date__c));
                    if(caseIndivMap.containsKey(ipvRec.Individual_ID__c) && (disQual.Disqualification_determination_Date__c != NULL)){
                        if(!oldDOCRQMap.containsKey(ipvRec.Id)){
                            CorspdTrigger.createCorspdRequest(CR110RsnCode,NULL,NULL,countyCode,keyParams);
                        }else{
                            T_DOC_RQ__C updAuthCorrRec = oldDOCRQMap.get(ipvRec.Id);
                            updAuthCorrRec.Disqualification_Begin_Date__c =disQual.Disqualification_Begin_Date__c;
                            updAuthCorrRec.Disqualification_End_Date__c =disQual.Disqualification_End_Date__c;
                            updAuthCorrRec.Disqualification_Hearing_Date__c =disQual.Disqualification_determination_Date__c;
                            updAuthCorrRec.Number_of_Occurrences__c =Decimal.valueOf(disQual.Number_of_occurrences__c);
                            updAlreadyExistingFACorrespondence.add(updAuthCorrRec);  
                        }
                    }
                }
                
            }
            
        }
        if(updAlreadyExistingFACorrespondence!=null && updAlreadyExistingFACorrespondence.size()>0 && !Test.isRunningTest()){
            GenericDMLHandler.updateRecords(updAlreadyExistingFACorrespondence, null);
        }
        
    }
}