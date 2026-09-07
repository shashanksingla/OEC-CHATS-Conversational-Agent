/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           01/02/2018                                                          
*  @description    class for Individual Care level update                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 01-Feb-2018                                                            
*  * Author: Diya Chaudhary
*  * Description: CHAT-2306, Fetch individual care level records  to update
*********************************************************************************************/
public with sharing class IndividualCareLvlApexCtrl {
    @AuraEnabled
    public static List<indivCareLevelWrapper> getIndividualCareLvls(String IndivId)
    {
        List<indivCareLevelWrapper> invidWrapList = new List<indivCareLevelWrapper>();
        T_SBSD_INDIV__c obj = [Select Id,IDN_EXTNL__c from T_SBSD_INDIV__c where id=:IndivId];
        Map<String, batchsit_t_sbsd_indiv_care_level__x> carlevelMap = new  Map<String, batchsit_t_sbsd_indiv_care_level__x>();
        List<batchsit_t_sbsd_indiv_care_level__x> lstIndivCare = new  List<batchsit_t_sbsd_indiv_care_level__x> ();
       List<batchsit_t_sbsd_indiv_care_level__x> listIndivCareData = new List<batchsit_t_sbsd_indiv_care_level__x>();
        if(obj != null){
            String batchId =obj.IDN_EXTNL__c;
            system.debug('obj.IDN_EXTNL__c----'+obj.IDN_EXTNL__c);
            if(Test.isRunningTest()){
                
                listIndivCareData.add(new batchsit_t_sbsd_indiv_care_level__x(idn_sbsd_indiv_care_level__c = 123456));
            }
            else {
                listIndivCareData = [Select id,idn_client__r.IDN_EXTNL__c, idn_sbsd_indiv_care_level__c,cde_level_care__c,idn_client__c,idn_client__r.Name,
                                                                 idn_client__r.IDN_STATE__c, dte_begin_effv__c,
                                                                 dte_end_effv__c from batchsit_t_sbsd_indiv_care_level__x where idn_client__r.IDN_EXTNL__c=:batchId];
                
            }
            
            for(batchsit_t_sbsd_indiv_care_level__x crLvl : listIndivCareData){
                if(!(carlevelMap.containsKey(String.valueOf(crLvl.idn_sbsd_indiv_care_level__c)))){
                    carlevelMap.put(String.valueOf(crLvl.idn_sbsd_indiv_care_level__c), crLvl);
                    lstIndivCare.add(crLvl);
                    indivCareLevelWrapper invidWrap = new indivCareLevelWrapper();
                    invidWrap.indCareLvlObj =crLvl;
                    externalObjectDefinition.fieldDefinition fldDefValue1 = DynamicExternalDetailPageController.getPickListRecordDef('cde_level_care__c','R00710__c','batchsit_t_sbsd_indiv_care_level__x',String.valueOf(crLvl.cde_level_care__c),'Field_Utility__c');
                    if(fldDefValue1 != null){
                        invidWrap.careLvel= fldDefValue1.fieldValue;
                    }
                    invidWrapList.add(invidWrap);
                }
            }
        }
        return invidWrapList;
    } 
    @AuraEnabled
    public static indivCareLevelWrapper validateIndCareLst(String IndivId,List<batchsit_t_sbsd_indiv_care_level__x> individualCareLst){
        List<batchsit_t_sbsd_indiv_care_level__x> lstIndivCare = new  List<batchsit_t_sbsd_indiv_care_level__x> ();
        batchsit_t_sbsd_indiv_care_level__x lstIndivCareSA = new  batchsit_t_sbsd_indiv_care_level__x();
        List<batchsit_t_sbsd_indiv_care_level__x> lstIndivCareOldSA = new  List<batchsit_t_sbsd_indiv_care_level__x>();
        batchsit_t_sbsd_indiv_care_level__x lstIndivCareSAM = new  batchsit_t_sbsd_indiv_care_level__x();
        indivCareLevelWrapper invidWrap = new indivCareLevelWrapper();
        List<Object> encmbrObject;
        invidWrap.indivId =IndivId;
        List<T_AUTH__c> authObj = [SELECT Id, IDN_CLIENT__c,DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c from T_AUTH__c where IDN_CLIENT__c =:IndivId];
        List<batchsit_t_auth_encmbr__x> encmbrAuthList = new List<batchsit_t_auth_encmbr__x>();
        Boolean isError = false;
        String message = '';
        String SA ='8';
        Date startDateSAM;
        Date startDateSA;
        if(IndivId != null){
            
            if(Test.isRunningTest()){
                
                lstIndivCareOldSA.add(new batchsit_t_sbsd_indiv_care_level__x(idn_sbsd_indiv_care_level__c = 123456));
            }else{
            lstIndivCareOldSA =[Select id,idn_client__r.IDN_EXTNL__c, idn_sbsd_indiv_care_level__c,cde_level_care__c,idn_client__c,idn_client__r.Name,
                                idn_client__r.IDN_STATE__c, dte_begin_effv__c,lastmodifiedbyid__c,lastmodifieddate__c,
                                dte_end_effv__c from batchsit_t_sbsd_indiv_care_level__x where idn_client__r.id=:IndivId and cde_level_care__c =:SA] ;
            }
        }
            
       
        for(batchsit_t_sbsd_indiv_care_level__x btch : individualCareLst){
            if(btch.cde_level_care__c == '8'){
                btch.lastmodifiedbyid__c = UserInfo.getUserId();
                btch.lastmodifieddate__c = System.now();
                startDateSA = btch.dte_begin_effv__c;
                lstIndivCareSA = btch;
            }
            if(btch.cde_level_care__c == '7'){
                btch.lastmodifiedbyid__c = UserInfo.getUserId();
                btch.lastmodifieddate__c = System.now();
                lstIndivCareSAM = btch;
                startDateSAM = btch.dte_begin_effv__c;
            }
        }
        
        if(lstIndivCareSA != null && lstIndivCareSAM != null ){
            if(lstIndivCareOldSA.size()>0){
                if(lstIndivCareOldSA[0].dte_begin_effv__c != lstIndivCareSA.dte_begin_effv__c ){
                    lstIndivCareSAM.dte_end_effv__c = lstIndivCareSA.dte_begin_effv__c.addDays(-1);
                    system.debug('lstIndivCareSAM.dte_end_effv__c---'+lstIndivCareSAM.dte_end_effv__c);
                }    
            }
            System.debug('lstIndivCareSA.dte_begin_effv__c **'+lstIndivCareSA.dte_begin_effv__c+'lstIndivCareSAM.dte_begin_effv__c**'+lstIndivCareSAM.dte_begin_effv__c);
            if(lstIndivCareSA.dte_begin_effv__c < lstIndivCareSAM.dte_begin_effv__c){
                isError = true;
                message = 'School Age begin effective date should be greater than 36-SAM.';
            } 
        }
        
        invidWrap.isError =isError;
        invidWrap.message =message;
        system.debug('isError--'+isError);
        system.debug('message--'+message);
        system.debug('individualCareLst----'+individualCareLst);
        if(!isError){
            Id userId= UserInfo.getUserId();
            String nowDate = String.valueOf(system.now());
            
            for(batchsit_t_sbsd_indiv_care_level__x btch : individualCareLst){
                if(btch.cde_level_care__c == '7'){
                    if(btch.Id ==lstIndivCareSAM.Id ){
                        btch=lstIndivCareSAM;
                        system.debug('btch----'+btch);
                    }
                    
                    
                }
            }
            if( (!isError) && (IndivId != null) && (startDateSAM != null) && (startDateSA != null)){
                String jsonStr = '{"idn_Client":"'+IndivId +'","start_Date_36M":"'+startDateSAM+'","start_Date_SA":"'+startDateSA +'"}';
                encumbranceUpdate(jsonStr,IndivId);
            }
            invidWrap.indCareLvl =individualCareLst;
        }
        return invidWrap;
    }
    public static List<Object> encumbranceUpdate(String dataBody,Id IndivId){
        system.debug('dataBody----'+dataBody);
        List<Object> lst_JsonParse = new List<Object>();
        String method = 'POST';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Integer timeOutVal = Integer.valueOf(System.Label.AuthWebServiceTimeOut);
        request.setTimeout(timeOutVal);
        request.setEndpoint(System.Label.EncumbranceUpdate);
        //request.setEndpoint('http://chatstranswsdevapp.herokuapp.com/AuthEncumbr/UpdateRecord');
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody(dataBody);
       /* HttpResponse response = http.send(request);
        System.debug('**************'+response.getBody());
        if (response.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            } else {
                System.debug(response.getBody());
            }
*/
        // request.setBody('[{"cde_Status_Encmbr":"8","idn_Auth":"a1fg0000001kMgQAAU","idn_Encmbr_Auth":"33","lastmodifieddate":"2012-12-12 10:10:10","lastmodifiedbyid":"Salesforce"}]');  
        try{
            HttpResponse response = http.send(request);
            
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
                 ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'IndividualCareLvlApexCtrl','Method__c'=>'encumbranceUpdate','Record_ID__c'=>IndivId});          
            } else {
                System.debug(response.getBody());
            }  
           } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'IndividualCareLvlApexCtrl','Method__c'=>'encumbranceUpdate','Record_ID__c'=>IndivId});             
        }  
       
        return lst_JsonParse;
    }
    public static List<Object> fetchAuthEncumbrance(String authIdsRes){
        List<Object> lst_JsonParse = new List<Object>();
        String method = 'GET';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Integer timeOutVal = Integer.valueOf(System.Label.AuthWebServiceTimeOut);
        request.setTimeout(timeOutVal);
        request.setEndpoint(System.Label.IndividualCareLevelFetch);
        //request.setEndpoint('http://chatstranswsdevapp.herokuapp.com/AuthEncumbr/FetchRecords');
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        //String jsonStr = '{"authId":"'+authId +'"}';
        system.debug('authIdsRes--'+authIdsRes);
        //request.setBody('{"authId":"a1fg0000001kMgQAAU"}');
        request.setBody(authIdsRes);
            try {
            HttpResponse response = http.send(request);
            
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
                ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'IndividualCareLvlApexCtrl','Method__c'=>'fetchAuthEncumbrance'});          
     
            } else {
                lst_JsonParse = (List<Object>) JSON.deserializeUntyped(response.getBody());
                system.debug('----res---'+response.getBody());
                for(Object obj : lst_JsonParse)
                {
                    Map<String,Object> mp_StrObj = (Map<string,Object>)obj;
                    system.debug(mp_StrObj.get('cde_Status_Encmbr'));
                    
                }
            }
            
            } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'IndividualCareLvlApexCtrl','Method__c'=>'fetchAuthEncumbrance'});             
           }  
        
        return lst_JsonParse;
    }
    public static void authEncumbranceUpdate(String dataBody){
        String method = 'POST';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(System.Label.IndividualCareLevelUpdate);
        Integer timeOutVal = Integer.valueOf(System.Label.AuthWebServiceTimeOut);
        request.setTimeout(timeOutVal);
        //request.setEndpoint('http://chatstranswsdevapp.herokuapp.com/AuthEncumbr/UpdateRecord');
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody(dataBody);
        // request.setBody('[{"cde_Status_Encmbr":"8","idn_Auth":"a1fg0000001kMgQAAU","idn_Encmbr_Auth":"33","lastmodifieddate":"2012-12-12 10:10:10","lastmodifiedbyid":"Salesforce"}]');  
        
            try{
            HttpResponse response = http.send(request);
            
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
                ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'IndividualCareLvlApexCtrl','Method__c'=>'authEncumbranceUpdate'});          
                  
            } else {
                System.debug('----RESPONSE----'+response.getBody());
                List<Object> lst_JsonParse = (List<Object>) JSON.deserializeUntyped(response.getBody());
                for(Object obj : lst_JsonParse)
                {
                    Map<String,Object> mp_StrObj = (Map<string,Object>)obj;
                    system.debug('Level care---'+(String)mp_StrObj.get('cde_Level_Care'));
                    system.debug('unit care---'+(String)mp_StrObj.get('cde_Type_Unit_Care'));
                    
                    
                }
            }
            
            } catch(Exception ex) {
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'IndividualCareLvlApexCtrl','Method__c'=>'authEncumbranceUpdate'});             
           }  
        
    }
    @auraEnabled
    public static LightningServerResponse insertATSRecord(String individualId){
        String message;
        Map<String,Object> objectData = new Map<String,Object>();
        String authId;
        List<batchsit_t_pos_trans_queue_ats__x> lstATSRecords = new List<batchsit_t_pos_trans_queue_ats__x>();        
        for(T_Auth__c authRec :[Select Id, Name, IDN_CLIENT__c from T_AUTH__c where IDN_CLIENT__c=:individualId]){
            authId = authRec.Name ;
            batchsit_t_pos_trans_queue_ats__x atsRecord = new batchsit_t_pos_trans_queue_ats__x();
            atsRecord.CDE_STATUS_TRANS__c= '1';
            atsRecord.CDE_TYPE_TRANS__c ='6';
            if(authId!=null){
                atsRecord.IDN_AUTH__c = authId;
            }
            atsRecord.DTE_CHANGE_LAST__c = system.today();
            lstATSRecords.add(atsRecord);
            batchsit_t_pos_trans_queue_ats__x atsRecord2 = new batchsit_t_pos_trans_queue_ats__x();
            atsRecord2.CDE_STATUS_TRANS__c= '1';
            atsRecord2.CDE_TYPE_TRANS__c ='7';
            if(authId!=null){
                atsRecord2.IDN_AUTH__c = authId;
            }
            atsRecord2.DTE_CHANGE_LAST__c = system.today();
            lstATSRecords.add(atsRecord2);
        }
        
        if(!lstATSRecords.isEmpty()){
            ATSHandler.insertATSRecord(true, lstATSRecords);
        }
        
        return new LightningServerResponse(true, message, objectData);
    }
    public class indivCareLevelWrapper{
        @AuraEnabled public Boolean isError;
        @AuraEnabled public List<batchsit_t_sbsd_indiv_care_level__x> indCareLvl;
        @AuraEnabled public Id indivId;
        @AuraEnabled public String message;
        @AuraEnabled public String careLvel;
        @AuraEnabled public batchsit_t_sbsd_indiv_care_level__x indCareLvlObj;
        public indivCareLevelWrapper(Boolean isError,List<batchsit_t_sbsd_indiv_care_level__x> indCareLvl,String message, Id indivId){
            this.isError = isError;
            this.indCareLvl = indCareLvl;
            this.message = message;
            this.indivId = indivId;
        }
        public indivCareLevelWrapper(){
        /** 
		* Creates instance of {@indivCareLevelWrapper}. Used for calling the default constructor explicitly
		*/     
        }
    }
}