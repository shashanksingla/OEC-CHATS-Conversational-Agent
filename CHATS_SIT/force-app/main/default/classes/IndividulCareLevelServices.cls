public with sharing class IndividulCareLevelServices {
    
    public static void doMethod(List<T_INDIV_CAT_RQ__c> childCareRequest){
        Map<ID,T_INDIV_CAT_RQ__c> mapInvIdChildCare = new Map<ID,T_INDIV_CAT_RQ__c>();
        Map<ID,integer> mapInvIdCareLevelLength = new Map<ID,integer>();
        Map<ID,ID> mapCaseInvIdIndvId = new Map<ID,ID>();
        Map<ID,ID> mapInvIdCaseIndvId = new Map<ID,ID>();
        Id loggedUserId = UserInfo.getUserId();
        DateTime nowDate = System.now();
        // iterate over this list and collect Individual Id
        try{
            for(T_INDIV_CAT_RQ__c objChildCare:childCareRequest){
                mapInvIdChildCare.put(objChildCare.IDN_CASE_INDIV__c, objChildCare);
            }
            List<T_SBSD_CASE_INDIV__c> listCaseIndv =[select id,IDN_CLIENT__c from T_SBSD_CASE_INDIV__c where id in: mapInvIdChildCare.keySet()];
            for (T_SBSD_CASE_INDIV__c objCaseIndiv:listCaseIndv){
                mapCaseInvIdIndvId.put(objCaseIndiv.Id, objCaseIndiv.IDN_CLIENT__c);
                mapInvIdCaseIndvId.put(objCaseIndiv.IDN_CLIENT__c, objCaseIndiv.Id);
            }
            
            List<T_SBSD_INDIV__c> lstIndv = [select id,DTE_DOB__c,CDE_ATTENDING_SCHOOL1__c,CDE_ATTENDING_SCHOOL_BEGINDATE__c,IDN_EXTNL__c,(select id from batchsit_t_sbsd_indiv_care_level__r) from T_SBSD_INDIV__c where id in: mapInvIdCaseIndvId.keySet()];
            map<id,T_SBSD_INDIV__c>  mapIdIndv= new map<id,T_SBSD_INDIV__c>();
            for(T_SBSD_INDIV__c objIndv:lstIndv){
                mapIdIndv.put(objIndv.id, objIndv);
                if(objIndv.batchsit_t_sbsd_indiv_care_level__r != null){
                    mapInvIdCareLevelLength.put(objIndv.id, objIndv.batchsit_t_sbsd_indiv_care_level__r.size());
                    
                }
                else{
                    mapInvIdCareLevelLength.put(objIndv.id, 0);
                }
                
            }
            list<SObject> listCareLevel = new List<SObject>();
            String bodyText = '[';
            String body='';
            for(T_INDIV_CAT_RQ__c objChildCare:childCareRequest){
                system.debug('mapCaseInvIdIndvId.get(objChildCare.IDN_CASE_INDIV__c)--'+mapCaseInvIdIndvId.get(objChildCare.IDN_CASE_INDIV__c));
                if(mapInvIdCareLevelLength.get(mapCaseInvIdIndvId.get(objChildCare.IDN_CASE_INDIV__c)) ==0){
                    body +=  getBodyForCreateCareLevelWS(objChildCare,mapCaseInvIdIndvId,mapIdIndv);
                }
            }
            if(String.isNotBlank(body) && body.length() >1){
                body = body.substring(0, body.length()-1);
                bodyText ='[' + body +']';
                if(!Test.isRunningTest()) {
                    HerokuService.createCareLevelRecords(bodyText);
                }
            }
        } catch (Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'IndividulCareLevelServices','Method__c'=>'doMethod'}); 
        }      
    }
    
    public static String getBodyForCreateCareLevelWS(T_INDIV_CAT_RQ__c objChildCare, Map<ID,ID> mapCaseInvIdIndvId,map<id,T_SBSD_INDIV__c>  mapIdIndv  ){
        Id loggedUserId = UserInfo.getUserId();
        DateTime nowDate = System.now();
        Integer beginDateInt =0;
        Integer endDateInt =6;
        String bodyText='';
        Id individualId = mapCaseInvIdIndvId.get(objChildCare.IDN_CASE_INDIV__c);
        T_SBSD_INDIV__c individualRecord = mapIdIndv.get(individualId);
        Integer Age = Date.Today().year() - individualRecord.DTE_DOB__c.year();
        Integer months = Date.Today().Month() - individualRecord.DTE_DOB__c.Month();
        if (months < 0 || (months == 0 && Date.Today().Day() < individualRecord.DTE_DOB__c.Day())) {
            Age--;
        }
        Date SABeginDate = getSABeginDate(individualRecord,Age);
        for(Integer i=1;i<=8;i++){
            bodyText+='{';
            bodyText+='"cde_level_care":"'+i+'",';
            bodyText+='"createdbyid":"'+UserInfo.getUserId()+'",';
            bodyText+='"nbr_seq_hist":"1",';
            bodyText+='"lastmodifiedbyid":"'+UserInfo.getUserId()+'",';
            bodyText+='"idn_client":"'+individualRecord.IDN_EXTNL__c+'",';
            if(i == 1){
                bodyText+='"dte_begin_effv":"'+individualRecord.DTE_DOB__c+'",';
                bodyText+='"dte_end_effv":"'+(individualRecord.DTE_DOB__c.addmonths(6)).adddays(-1)+'"';
            }
            else if(i==7){
                bodyText+='"dte_begin_effv":"'+individualRecord.DTE_DOB__c.addmonths(36)+'",';
                bodyText+='"dte_end_effv":"'+SABeginDate.adddays(-1)+'"';
            }else if(i==8){
                bodyText+='"dte_begin_effv":"'+SABeginDate+'"';
            }
            else{
                bodyText+='"dte_begin_effv":"'+individualRecord.DTE_DOB__c.addmonths(beginDateInt)+'",';
                bodyText+='"dte_end_effv":"'+(individualRecord.DTE_DOB__c.addmonths(endDateInt)).adddays(-1)+'"';
            }
            bodyText+='},';
            beginDateInt = beginDateInt+6;
            endDateInt = endDateInt+6;
        }
        return bodyText;
    }
    public static date getSABeginDate(T_SBSD_INDIV__c individualRecord,Integer Age){
        Date SABeginDate = individualRecord.DTE_DOB__c.addmonths(60);
        if(Age<18 && Age >=5){
            if((individualRecord.CDE_ATTENDING_SCHOOL1__c == 'N'|| individualRecord.CDE_ATTENDING_SCHOOL1__c == 'Unknown')
               && individualRecord.CDE_ATTENDING_SCHOOL_BEGINDATE__c!=null){
                   SABeginDate = individualRecord.CDE_ATTENDING_SCHOOL_BEGINDATE__c;
               }
        }else if(Age<5){
            if((individualRecord.CDE_ATTENDING_SCHOOL1__c == 'N' ||  individualRecord.CDE_ATTENDING_SCHOOL1__c == 'Y')
               &&  individualRecord.CDE_ATTENDING_SCHOOL_BEGINDATE__c!=null){
                   SABeginDate = individualRecord.CDE_ATTENDING_SCHOOL_BEGINDATE__c;
               }
        }
        return SABeginDate;
    }
}