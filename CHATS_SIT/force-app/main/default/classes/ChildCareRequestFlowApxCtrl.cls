/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/20/2017                                                          
*  @description    ChildCareRequestFlowApxCtrl
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 20-Nov-2017                                                             
*  * Author: Shubham Jain                                                      
*  * Description: Initial version                                                 
*  * JIRA Ticket: CHAT-1189
*  * v1.1 - Vai - March 7 2018 - Added condition to the SOQL in getInitData to fix bug 2810                                                                          
*********************************************************************************************/
public with sharing class ChildCareRequestFlowApxCtrl {
    public static final Date EMPTY_DATE = null; 
    @AuraEnabled
    public static LightningServerResponse getInitData(String caseId){
        Boolean isSuccessful;
        Boolean isReadOnly = false;
        String profileName = [Select Name from Profile where Id =: UserInfo.getProfileId() Limit 1].Name;
        String message;
        Date nullDate;
        Map<String, Object> objectData = new map<String, Object>();
        isSuccessful = true;
	
	List<T_INDIV_REL__c> prmCrTkr_Relationships = new list<T_INDIV_REL__c>();
        List<T_SBSD_CASE_INDIV__c> caseIndividuals1 = new List<T_SBSD_CASE_INDIV__c>();
        Map<String,T_INDIV_REL__c> child_validRelation_prmcrtkr = new Map<String,T_INDIV_REL__c>();
        List<String> TEEN_PARENT_RELATIONSHIPS = new List<String>{'M','F','H','W','CLH','CLW','LIC','SO'};
	
        List<T_SBSD_CASE_INDIV__c> caseIndividuals = [SELECT Id, IDN_CLIENT__c, 
                                                      IDN_CLIENT__r.NAM_LAST__c,
                                                      IDN_CLIENT__r.NAM_FIRST__c, 
                                                      IDN_CLIENT__r.IDN_STATE__c, 
                                                      IDN_CLIENT__r.Age__c,DTE_BEGIN_EFFV__c,
                                                      (SELECT Id, DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,OVERRIDDEN_DTE_BEGIN_EFFV__c,cde_reason_ovrd__c,txt_cmt_ovrd__c FROM Child_Care_Requests__r ORDER BY DTE_BEGIN_EFFV__c DESC, OVERRIDDEN_DTE_BEGIN_EFFV__c DESC)
                                                      FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c = :caseId AND IDN_CLIENT__r.Age__c<: Integer.valueOf(System.Label.Teen_Parent_Age_Limit)  
                                                      //AND IDN_CLIENT__r.Has_Allowed_Relationship__c = false
                                                      AND IND_CRTKR__c = false AND (DTE_END_EFFV__c=:nullDate OR DTE_END_EFFV__c >= Today) WITH SECURITY_ENFORCED];
        
        List<T_SBSD_CASE_INDIV__c> primCaretaker_CaseIndiv = [SELECT Id, IDN_CLIENT__c 
                                                              FROM T_SBSD_CASE_INDIV__c 
                                                              WHERE IDN_CASE__c = :caseId  
                                                              AND IND_CRTKR__c = true 
                                                              AND (DTE_END_EFFV__c=:nullDate OR DTE_END_EFFV__c >= Today) WITH SECURITY_ENFORCED limit 1];
        
        if(!primCaretaker_CaseIndiv.isEmpty()){
            prmCrTkr_Relationships = [	Select Id, IDN_CLIENT__c, IDN_CLIENT_RELTD__c, DTE_BEGIN_EFFV__c, DTE_END_EFFV__c, CDE_TYPE_REL_INDIV__c
                                                      		FROM T_INDIV_REL__c
                                                      		WHERE IDN_CLIENT__c = :primCaretaker_CaseIndiv[0].IDN_CLIENT__c
                                                           	AND DTE_BEGIN_EFFV__c <= Today
                                                          	AND (DTE_END_EFFV__c=:nullDate OR DTE_END_EFFV__c >= Today)
                                     				AND CDE_TYPE_REL_INDIV__c NOT IN:TEEN_PARENT_RELATIONSHIPS];    
            if(!prmCrTkr_Relationships.isEmpty()){
            	for(T_INDIV_REL__c eachRelation: prmCrTkr_Relationships){
                	child_validRelation_prmcrtkr.put(eachRelation.IDN_CLIENT_RELTD__c, eachRelation);
            	}
            }
        }
        
        if(child_validRelation_prmcrtkr != null){
            for(T_SBSD_CASE_INDIV__c eachchildCaseIndivRec : caseIndividuals){
                if(child_validRelation_prmcrtkr.containsKey(eachchildCaseIndivRec.IDN_CLIENT__c)){
                    caseIndividuals1.add(eachchildCaseIndivRec);
                }        
            }
        } 
        objectData.put('caseIndividuals',caseIndividuals1);
        //CCCAP-14993 Replacing using custom permission
        if(FeatureManagement.checkPermission('Read_Only_User') || FeatureManagement.checkPermission('Provider_Worker') || FeatureManagement.checkPermission('Provider_Worker_Supervisor') || FeatureManagement.checkPermission('Business_Office_Supervisor') || FeatureManagement.checkPermission('Business_Office_Worker') || FeatureManagement.checkPermission('Fiscal_Worker') || FeatureManagement.checkPermission('Fiscal_Worker_Supervisor')) {
            isReadOnly = true;
        }
        objectData.put('isReadOnly', isReadOnly);
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse submitData(String caseIndividualIdToCCRJSON){
        Map<String,Object> caseIndividualIdToCCR = (Map<String,Object>)JSON.deserializeUntyped(caseIndividualIdToCCRJSON);
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'ChildCareRequestFlowApxCtrl','Method__c'=>'submitData'};
        try{
            List<T_INDIV_CAT_RQ__c> childCareRequestsToBeInserted = new List<T_INDIV_CAT_RQ__c>();
            List<T_INDIV_CAT_RQ__c> childCareRequestsToBeUpdated = new List<T_INDIV_CAT_RQ__c>();
            for(T_SBSD_CASE_INDIV__c caseIndividual:[SELECT Id, (
                SELECT Id, DTE_END_EFFV__c,OVERRIDDEN_DTE_BEGIN_EFFV__c FROM Child_Care_Requests__r ORDER BY DTE_END_EFFV__c DESC LIMIT 1
            ) FROM T_SBSD_CASE_INDIV__c WHERE Id IN :caseIndividualIdToCCR.keySet() WITH SECURITY_ENFORCED]){
                Object ob = caseIndividualIdToCCR.get(caseIndividual.Id);
                Map<String,Object> mapCaseIndividualIdToCCR = (Map<String,Object>)ob;
                if(mapCaseIndividualIdToCCR.get('ccChecboxChanged') == true || mapCaseIndividualIdToCCR.get('beginDateOverriden') == true){
                    T_INDIV_CAT_RQ__c ccReqRecord = new T_INDIV_CAT_RQ__c();
                    if(!caseIndividual.Child_Care_Requests__r.isEmpty()){
                        ccReqRecord = caseIndividual.Child_Care_Requests__r.get(0);
                    }
                    // cc checkbox changed from UI
                    if(mapCaseIndividualIdToCCR.get('ccChecboxChanged') == true){
                        // cc checkbox unchecked and existing CC Request exist, end dating it.
                        if(!(Boolean)mapCaseIndividualIdToCCR.get('ccRequest') && !caseIndividual.Child_Care_Requests__r.isEmpty()){
                            ccReqRecord.DTE_END_EFFV__c = System.today();
                        }// cc checkbox checked
                        else if((Boolean)mapCaseIndividualIdToCCR.get('ccRequest')){
                            //existing CC Request exist of same today's end date.
                            if(!caseIndividual.Child_Care_Requests__r.isEmpty() && ccReqRecord.DTE_END_EFFV__c  == System.today()){
                                ccReqRecord.DTE_END_EFFV__c =  EMPTY_DATE;
                            }else{
                                ccReqRecord = new T_INDIV_CAT_RQ__c(CDE_CAT_PROG__c = 'CC',
                                                                    DTE_BEGIN_EFFV__c = Date.Today(),
                                                                    IDN_CASE_INDIV__c = caseIndividual.Id
                                                                   );
                            }
                        }
                    }
                    if(mapCaseIndividualIdToCCR.get('beginDateOverriden') == true){
                        ccReqRecord.cde_reason_ovrd__c = (String)mapCaseIndividualIdToCCR.get('cde_reason_ovrd__c');
                        ccReqRecord.txt_cmt_ovrd__c = (String)mapCaseIndividualIdToCCR.get('txt_cmt_ovrd__c');
                        ccReqRecord.OVERRIDDEN_DTE_BEGIN_EFFV__c = Date.valueOf((String)mapCaseIndividualIdToCCR.get('beginDate'));
                    }
                    // check if CC Request Record is existing or New
                    if(ccReqRecord.Id!=null){
                        childCareRequestsToBeUpdated.add(ccReqRecord);
                    }else{
                        childCareRequestsToBeInserted.add(ccReqRecord);
                    }
                }
            }
            List<SObject> childCareRequestsToBeUpserted = new List<SObject>();
            if(!childCareRequestsToBeUpdated.isEmpty()){
                GenericDMLHandler.updateRecords(childCareRequestsToBeUpdated, methodInfo, new List<String>{'cde_reason_ovrd__c', 'txt_cmt_ovrd__c', 'OVERRIDDEN_DTE_BEGIN_EFFV__c', 'DTE_END_EFFV__c'});                   
                childCareRequestsToBeUpserted.addAll(childCareRequestsToBeUpdated);
            }
            if(!childCareRequestsToBeInserted.isEmpty()){
                GenericDMLHandler.insertRecords(childCareRequestsToBeInserted, methodInfo, new List<String>{'cde_reason_ovrd__c', 'txt_cmt_ovrd__c', 'OVERRIDDEN_DTE_BEGIN_EFFV__c', 'DTE_END_EFFV__c'});                            
                childCareRequestsToBeUpserted.addAll(childCareRequestsToBeInserted);
            }
			objectData.put('childCareRequestsToBeUpserted',childCareRequestsToBeUpserted);            
            isSuccessful = true;
        }catch(Exception ex){
            isSuccessful = false;
            message = ex.getLineNumber()+System.LABEL.SEPARATOR_SEMI_COLUMN+ex.getMessage();
            ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }    
    
    
     @AuraEnabled
    public static LightningServerResponse afterSubmitData(List<T_INDIV_CAT_RQ__c> childCareRequestsToBeUpserted){
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'ChildCareRequestFlowApxCtrl','Method__c'=>'afterSubmitData'};
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        try{
            if(!childCareRequestsToBeUpserted.isEmpty()){
                IndividulCareLevelServices.doMethod(childCareRequestsToBeUpserted);
            }
            isSuccessful = true;
        }catch(Exception ex){
            isSuccessful = false;
            message = ex.getLineNumber()+System.LABEL.SEPARATOR_SEMI_COLUMN+ex.getMessage();
            ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }    
}