/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/25/2017                                                          
*  @description    Handler class for waitlist Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 25-Nov-2017                                                             
*  * Author: Azharuddin Mohammad                                                      
*  * Description: Initial version                                                 
*  * CHAT-1157: Whenever a T_SBSD_CASE_WTLST record is created or updated (related to the case), 
*  *           populate waitlist Status field in T_SBSD_CASE__c with value of T_SBSD_CASE_WTLST.CDE_STATUS_WTLST 
*  *           where today is on or between T_SBSD_CASE_WTLST.DTE_BEGIN_EFFV_WTLST and 
*  *           T_SBSD_CASE_WTLST.DTE_END_EFFV_WTLST
*  * Version: 2.0                                                                             
*  * Date: 05-Dec-2017                                                             
*  * Author: Azharuddin Mohammad 
*  * CHAT-675 : Event Based Trigger 
*********************************************************************************************/
public with sharing class waitlistServices {
    
    public static void caseWaitlistStatusUpdate(List<T_SBSD_CASE_WTLST__c> newCaseWaitlist){
        Map<Id,T_SBSD_CASE_WTLST__c> waitlistMap = new Map<Id,T_SBSD_CASE_WTLST__c>();
        Map<Id,T_SBSD_CASE__c> caseMap = new Map<Id,T_SBSD_CASE__c>();
        List<string> cases = new List<string>();
        for(T_SBSD_CASE_WTLST__c eachWaitlist: newCaseWaitlist){
            if((eachWaitlist.CDE_STATUS_WTLST__c !=NULL) && (eachWaitlist.DTE_BEGIN_EFFV_WTLST__c <= date.today()) && (eachWaitlist.DTE_END_EFFV_WTLST__c == NULL || eachWaitlist.DTE_END_EFFV_WTLST__c > date.today())){
                waitlistMap.put(eachWaitlist.IDN_CASE__c, eachWaitlist);
                cases.add(eachWaitlist.IDN_CASE__c);                
            }
        }
        if(cases != NULL){
            for(T_SBSD_CASE__c caseRecord : [select Id, Name, CDE_STATUS_WTLST__c FROM T_SBSD_CASE__c WHERE Id IN:waitlistMap.keySet()]){
                if(waitlistMap.get(caseRecord.Id) != NULL){
                    T_SBSD_CASE_WTLST__c waitlistRecord = waitlistMap.get(caseRecord.Id);
                    caseMap.put(caseRecord.Id, new T_SBSD_CASE__c(Id=waitlistRecord.IDN_CASE__c, CDE_STATUS_WTLST__c = waitlistRecord.CDE_STATUS_WTLST__c));
                }
            }
        }
        system.debug('caseMap:@@@@'+caseMap);
        if(!caseMap.isEmpty()){
            update caseMap.values();
        }
        
    }
    
    public static void validateCounty(List<T_SBSD_CASE_WTLST__c> newCaseWaitlist, Map<Id, T_SBSD_CASE_WTLST__c> oldMap){
        User user = [SELECT Owner_County__c, Common_County__c
                       FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
         //CCCAP-14993              
        if(!FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')){
            set<Id> cases = new set<Id>();
            for(T_SBSD_CASE_WTLST__c wtlst : newCaseWaitlist){
                if(wtlst.CDE_STATUS_WTLST__c == 'REM' && (oldMap == null || oldMap.get(wtlst.id).CDE_STATUS_WTLST__c != wtlst.CDE_STATUS_WTLST__c)){
                    cases.add(wtlst.IDN_CASE__c);                
                }
            }
            if(!cases.isEmpty()){
                Map<Id, T_SBSD_CASE__c> caseMap = new Map<Id, T_SBSD_CASE__c>([SELECT Id, CDE_COUNTY__c, CDE_COUNTY__r.Name, CDE_COUNTY__r.CDE_COUNTY__c
                                                                               FROM T_SBSD_CASE__c Where Id IN: cases]); 
                for(T_SBSD_CASE_WTLST__c wtlst : newCaseWaitlist){
                    if(wtlst.CDE_STATUS_WTLST__c == 'REM' && (oldMap == null || oldMap.get(wtlst.id).CDE_STATUS_WTLST__c != wtlst.CDE_STATUS_WTLST__c)){
                        cases.add(wtlst.IDN_CASE__c);                
                    }
                }
                for(T_SBSD_CASE_WTLST__c wtlst : newCaseWaitlist){
                    if(wtlst.CDE_STATUS_WTLST__c == 'REM' && (oldMap == null || oldMap.get(wtlst.id).CDE_STATUS_WTLST__c != wtlst.CDE_STATUS_WTLST__c)){
                        T_SBSD_CASE__c cs = caseMap.get(wtlst.IDN_CASE__c); 
                        String county = cs != null ? String.valueOf(cs.CDE_COUNTY__r.CDE_COUNTY__c) : null;
                        if(user.Owner_County__c != county && (String.isNotBlank(user.Common_County__c) && !new Set<String>(user.Common_County__c.split(';')).contains(county))){
                        	wtlst.addError('The Case Waitlist record that you are trying to update belongs to '+cs.CDE_COUNTY__r.Name+' county. This does not match your assigned county(ies).');
                        }
                    }
                }
            }
        }        
    }
    
    //start of Version-2
    public static final String CR101rsnCode ='CR0002';
    public static void triggerCorspdCR101(set<Id> waitlistCaseIds){
        //Removed unused variable on 5/14/2018 BG  
        Map<string,string> keyParams = new Map<string, string>();
        integer countyCode;

        Map<Id,T_SBSD_CASE__c> caseIdCountyCodeMap = new Map<Id,T_SBSD_CASE__c>([select Id, Name, CDE_COUNTY__r.CDE_COUNTY__c FROM T_SBSD_CASE__c WHERE Id IN:waitlistCaseIds]);
        
        for(Id eachWaitlistCase : waitlistCaseIds){
            if(eachWaitlistCase != Null){
                decimal cntyCode = caseIdCountyCodeMap.get(eachWaitlistCase).CDE_COUNTY__r.CDE_COUNTY__c;
                countyCode = integer.valueOf(cntyCode);
                keyParams.put('caseId', caseIdCountyCodeMap.get(eachWaitlistCase).Name);
            }
            CorspdTrigger.createCorspdRequest(CR101rsnCode,NULL,NULL,countyCode,keyParams); 
        }
    }
    //End of Version-2
}