/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/14/2017                                                          
*  @description    APEX CLASS for Rate Schedule Flow                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 14-Dec-2017                                                             
*  * Author: Vineet Srivastava, Gaurav Dharra                                                     
*  * Description: Initial version 
*  
*  * Version: 1.1                                                                            
*  * Date: 06-08-2018                                                             
*  * Author: Gaurav Trivedi
*  * Description: Added error handeling for updateCaseParentFeeRecords as a part of CHATS-5173 bug fix                                                    
*********************************************************************************************/

public with sharing class RateScheduleFlowApxCtrl {
    /**
* @description get Provider, Fiscal Agreement, RAT Fees Information
* @author Vineet Srivasatava
* @date 12/14/2017   
* @param prvdrFiscalAgreementId
* @return LightningServerResponse
*/

    public static final String CR707RsnCode = 'CR0016'; 
	
    @AuraEnabled
    public static LightningServerResponse getInitData(String prvdrFiscalAgreementId, String effectiveBeginDateInput){
    Map<String, Object> objectData = new map<String, Object>();
	Map<String, Object> mapRateDescription = new map<String, Object>();    
        Boolean isSuccessful;
        String message;
        system.debug('EffectiveBeginDate--->'+effectiveBeginDateInput);
        List<T_PROVR_FISCAL_AGREMENT__c> prvdrFiscalAgreements = [SELECT Id, ID_SERVICE__c, CDE_COUNTY__c, CDE_TYPE_FACILITY__c, CDE_COUNTY__r.Name, DTE_BEGIN_AGRMT__c, (SELECT Id, DTE_BEGIN_EFFV__c FROM Rate_Schedules__r ORDER BY CreatedDate DESC NULLS FIRST) FROM T_PROVR_FISCAL_AGREMENT__c WHERE Id =:prvdrFiscalAgreementId];
        //objectData.put('prvdrFiscalAgreement',prvdrFiscalAgreements.isEmpty()?null:prvdrFiscalAgreements.get(0)); 
        List<T_CHATS_PROVR_STATUS__c> provider = [SELECT Id, TXT_CHATS_RATING__c FROM T_CHATS_PROVR_STATUS__c 
                                                  WHERE Id =: prvdrFiscalAgreements.get(0).ID_SERVICE__c];
        objectData.put('CDE_TYPE_FACILITY__c',prvdrFiscalAgreements.get(0).CDE_TYPE_FACILITY__c);
        if(provider.size()>0){
            objectData.put('providerQualityRating',provider.get(0).TXT_CHATS_RATING__c);
        }
        List<String> rateTypeOptions = new List<String>();
        String countyName = '';
        Boolean countyMatched = true;
        Date effectiveBeginDate;
        T_COUNTY_RATE__c countyRate = new T_COUNTY_RATE__c();
        if(!prvdrFiscalAgreements.isEmpty()){
            countyMatched = CHATSUtility.checkCountyWithUserCounty(prvdrFiscalAgreements[0].CDE_COUNTY__c);
            
            System.debug('prvdrFiscalAgreements:'+prvdrFiscalAgreements);
            if(effectiveBeginDateInput!=null && effectiveBeginDateInput!=''){
            List<T_COUNTY_RATE__c> effectiveCountyRatePlan = [SELECT RATE_TYPE__c, PAYMENT_Q9_1__c, PAYMENT_Q10_1__c, PAYMENT_Q11_1__c, PAYMENT_Q17__c 
                                                              FROM T_COUNTY_RATE__c 
                                                              WHERE IDN_COUNTY__c = :prvdrFiscalAgreements.get(0).CDE_COUNTY__c
                                                              AND DTE_BEGIN_EFFV_RATE__c<=:Date.valueOf(effectiveBeginDateInput) 
                                                              AND (DTE_END_EFFV_RATE__c>=:Date.valueOf(effectiveBeginDateInput) OR DTE_END_EFFV_RATE__c=null)
                                                              AND CDE_STATUS__c = 'APV'
                                                              AND IND_RATE_PLAN_TEMPLT__c = false];
            System.debug('effectiveCountyRatePlan:'+effectiveCountyRatePlan);
            if(effectiveCountyRatePlan.size() > 0){
                countyRate = effectiveCountyRatePlan.get(0);
            }
            if(!effectiveCountyRatePlan.isEmpty() && String.isNotEmpty(effectiveCountyRatePlan.get(0).RATE_TYPE__c)){
                //Added as part of HF_CHATS_20_09_2018
                List<String> lstRateTypeOptions=effectiveCountyRatePlan.get(0).RATE_TYPE__c.split(';');
                List<String> lstRestrictedTypeOptions = Label.Inactive_Rate_Type.split(';');
                for(integer i=0;i<lstRateTypeOptions.size();i++){
                    if(!lstRestrictedTypeOptions.contains(lstRateTypeOptions.get(i))){
                      rateTypeOptions.add(lstRateTypeOptions.get(i));  
                    }   
                }
            }
            }    
            if(String.isNotEmpty(prvdrFiscalAgreements.get(0).CDE_COUNTY__c)){
                countyName = prvdrFiscalAgreements.get(0).CDE_COUNTY__r.Name;
            }
            if(prvdrFiscalAgreements.get(0).Rate_Schedules__r.isEmpty()){
                effectiveBeginDate = prvdrFiscalAgreements.get(0).DTE_BEGIN_AGRMT__c;
            }
            if(!prvdrFiscalAgreements.get(0).Rate_Schedules__r.isEmpty()){
                
                /*List<T_FISCAL_RATE__c> lstExistingFiscalRateAmount = [SELECT CDE_AGE_GROUP__c, CDE_CARE_UNIT__c, AMT_FA__c,
                                                                      IDN_FISCAL_SCH__c, AMT_PROVR__c, CDE_RATE_TYPE__c FROM T_FISCAL_RATE__c 
                                                                      WHERE IDN_FISCAL_SCH__c =:prvdrFiscalAgreements.get(0).Rate_Schedules__r.get(0).Id ];*/
                List<batchsit_t_fiscal_rate__x> lstExistingFiscalRateAmount = getLstFiscalRateAmount(prvdrFiscalAgreements.get(0).Rate_Schedules__r.get(0).Id);
                objectData.put('lstExistingFiscalRateAmount', lstExistingFiscalRateAmount);
            }
        }
        List<T_FISCAL_RAT_FEES__c> associatedRATFees = getAssocRATFees(prvdrFiscalAgreementId);
        
        List<T_FISCAL_SCH__c> latestRateSchedule = [Select Id, DTE_BEGIN_EFFV__c, DTE_END_EFFV__c, IDN_AGRMT_FISCAL__c, CDE_RATE_TYPE__c From T_FISCAL_SCH__c Where IDN_AGRMT_FISCAL__r.CDE_COUNTY__c=:prvdrFiscalAgreements.get(0).CDE_COUNTY__c AND IDN_AGRMT_FISCAL__r.ID_SERVICE__c=:prvdrFiscalAgreements.get(0).ID_SERVICE__c ORDER BY DTE_END_EFFV__c  DESC NULLS FIRST LIMIT 1];
        objectData.put('latestRateSchedule', latestRateSchedule);
        
        objectData.put('rateTypeOptions', rateTypeOptions);        
        objectData.put('countyName', countyName);   
        objectData.put('countyMatched', countyMatched); 
        objectData.put('effectiveBeginDate', effectiveBeginDate);    
        objectData.put('effectiveCountyRatePlan', countyRate);
        
        
        if(associatedRATFees.size()>0) {
            objectData.put('ratFeesRec', associatedRATFees.get(0));
        }
        
        List<AgeGroupWrapper> lstTierGroupValuetoLabel = CHATSUtility.getPicklistValuesToLabelList(T_COUNTY_RATE_AMT__c.CDE_AGE_GROUP__c.getDescribe());        
        if(lstTierGroupValuetoLabel!= null)
        {
            objectData.put('lstTierGroupValuetoLabel',JSON.serialize(lstTierGroupValuetoLabel));
        }
        Map<String, String> mapRateTypeValuetoLabel = CHATSUtility.getPicklistValuesToLabelMap(T_COUNTY_RATE_AMT__c.CDE_RATE_TYPE__c.getDescribe());
        if(mapRateTypeValuetoLabel!= null)
        {
            objectData.put('mapRateTypeValuetoLabel',JSON.serialize(mapRateTypeValuetoLabel));
        }
	for(Rate_Type_Description__mdt rateDescription :[Select id, MasterLabel, Rate_Type_Code__c, Description__c from Rate_Type_Description__mdt ]){
            mapRateDescription.put(rateDescription.Rate_Type_Code__c,rateDescription);
        }
        if(mapRateDescription != null){
           objectData.put('mapRateDescription',mapRateDescription); 
        }    
        isSuccessful = true;
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @auraEnabled
    public static LightningServerResponse getCeilingAmount(String countyRatePlanId, String providerType, String tierValue){
        system.debug('providerType--->'+providerType);
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<T_COUNTY_RATE_AMT__c> lstCountyRateAmt = getCountyRateAmountAssocToCountyRatePlan(countyRatePlanId, providerType, tierValue);
        if (lstCountyRateAmt.size()>0){
            isSuccessful = true;
            objectData.put('lstCountyRateAmt' , lstCountyRateAmt);
        }
        else{
            isSuccessful = false;
            message = Label.No_County_Rate_Amount_Data_Found;
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @auraEnabled
    public static LightningServerResponse getCeilingAmountForExe(String countyRatePlanId, String providerType, String tierValue, List<String> selectedRateLst){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<T_COUNTY_RATE_AMT__c> lstCountyRateAmt = getCountyRateAmountAssocToCountyRatePlanForExe(countyRatePlanId, providerType, tierValue, selectedRateLst);
        if (lstCountyRateAmt.size()>0){
            isSuccessful = true;
            objectData.put('lstCountyRateAmt' , lstCountyRateAmt);
        }
        else{
            isSuccessful = false;
            message = Label.No_County_Rate_Amount_Data_Found;
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    /**
* @description get RAT Fees Information associated to a Rate Schedule
* @author Gaurav Dharra
* @date 12/14/2017   
* @param String fiscal Agreement Id
* @return List<T_FISCAL_RAT_FEES__c>
*/   
    @AuraEnabled
    public static List<T_FISCAL_RAT_FEES__c> getAssocRATFees(Id fiscalAgreementId) {
        List<T_FISCAL_RAT_FEES__c> assocRATFeesRec = new List<T_FISCAL_RAT_FEES__c>();
        //Removed unused variable on 5/14/2018 BG  
        List<T_FISCAL_SCH__c> latestRateSchedulerRec = getRateSchedulerAssocToFiscalAggrement(fiscalAgreementId);
        if(latestRateSchedulerRec.size()>0) {
            assocRATFeesRec.addAll(getRATFeesAssocToRateScheduler(latestRateSchedulerRec.get(0).Id));
        }
        return assocRATFeesRec;
    }
    /**
* @description get Rate Scheduler Information associated to a Fiscal Agreement
* @author Gaurav Dharra
* @date 12/14/2017   
* @param String fiscal Agreement Id
* @return List<T_FISCAL_SCH__c>
*/   
    public static List<T_FISCAL_SCH__c> getRateSchedulerAssocToFiscalAggrement(Id fiscalAgreementId) {
        return [SELECT Id from T_FISCAL_SCH__c where IDN_AGRMT_FISCAL__c =: fiscalAgreementId ORDER By DTE_END_EFFV__c DESC];
    }
    /**
* @description get RAT Fees associated to a Rate Scheduler
* @author Gaurav Dharra
* @date 12/14/2017   
* @param String fiscal Agreement Id
* @return List<T_FISCAL_RAT_FEES__c>
*/   
    public static List<T_FISCAL_RAT_FEES__c> getRATFeesAssocToRateScheduler(Id rateScheduleId) {
        // Added 3 TXT MONTH fields by Rishav for CCCAP-2616
        return [SELECT AMT_TRANS_FA__c, CDE_TRANS_FREQ__c, AMT_ACT_FA__c, CDE_ACT_FREQ__c, AMT_REG_FA__c, CDE_REG_FREQ__c, AMT_TRANS_PROVR__c, AMT_ACT_PROVR__c, AMT_REG_PROVR__c,TXT_ACT_MONTH__c,TXT_REG_MONTH__c,TXT_TRANS_MONTH__c
                FROM T_FISCAL_RAT_FEES__c 
                WHERE IDN_FISCAL_SCH__c =: rateScheduleId 
                ORDER By CreatedDate DESC];
    }
    public static List<T_COUNTY_RATE_AMT__c> getCountyRateAmountAssocToCountyRatePlan(Id countyRatePlanId, String facilityType, String tierValue ) {
        system.debug('Rate Plan Id----> '+countyRatePlanId);
        system.debug('facility Type---->'+ facilityType);
        return [SELECT CDE_AGE_GROUP__c, NBR_AMOUNT__c, CDE_UNIT__c, IDN_COUNTY_RATE__c, CDE_RATE_TYPE__c, CDE_TIER__c
                FROM T_COUNTY_RATE_AMT__c 
                WHERE IDN_COUNTY_RATE__c =: countyRatePlanId and CDE_PROVR_TYPE__c=: facilityType and CDE_TIER__c =:facilityType!='EXE'?tierValue : '1'
                ORDER By CreatedDate DESC];
    }
    
    public static List<T_COUNTY_RATE_AMT__c> getCountyRateAmountAssocToCountyRatePlanForExe(Id countyRatePlanId, String facilityType, String tierValue, List<String> selectedRateLst ) {
        List<T_COUNTY_RATE_AMT__c> countyRateAmtList = [SELECT CDE_AGE_GROUP__c, NBR_AMOUNT__c, CDE_UNIT__c, IDN_COUNTY_RATE__c, CDE_RATE_TYPE__c, CDE_TIER__c
                                                        FROM T_COUNTY_RATE_AMT__c 
                                                        WHERE IDN_COUNTY_RATE__c =: countyRatePlanId and CDE_PROVR_TYPE__c=: facilityType and CDE_RATE_TYPE__c IN :selectedRateLst  and CDE_TIER__c =:facilityType!='EXE'?tierValue : '1'
                                                        ORDER By CreatedDate DESC];
        return countyRateAmtList;
    }
    
    @AuraEnabled
    public static LightningServerResponse getInitDataView(String rateScheduleId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        Map<String, Object> mapRateDescription = new map<String, Object>();
        
        /*List<T_FISCAL_RATE__c> lstExistingFiscalRateAmount = [SELECT Id,CDE_AGE_GROUP__c, CDE_CARE_UNIT__c, AMT_FA__c,
                                                              IDN_FISCAL_SCH__c, AMT_PROVR__c, CDE_RATE_TYPE__c
                                                              FROM T_FISCAL_RATE__c 
                                                              WHERE IDN_FISCAL_SCH__c =:rateScheduleId ];*/
        
        T_FISCAL_SCH__c fiscalSchedule = [SELECT IDN_AGRMT_FISCAL__r.CDE_COUNTY__c,
                                          IDN_AGRMT_FISCAL__r.CDE_COUNTY__r.name,  
                                          DTE_BEGIN_EFFV__c, IDN_AGRMT_FISCAL__c,
                                          IDN_AGRMT_FISCAL__r.ID_SERVICE__c,
                                          CDE_RATE_TYPE__c,
                                          TXT_CHATS_RATING__c
                                          FROM T_FISCAL_SCH__c 
                                          WHERE Id =:rateScheduleId ];
        List<batchsit_t_fiscal_rate__x> lstExistingFiscalRateAmount = getLstFiscalRateAmount(rateScheduleId);                                  
        List<String> selectedRateTypeOptions = new List<String>();
        if(fiscalSchedule.CDE_RATE_TYPE__c!=null){
            selectedRateTypeOptions = fiscalSchedule.CDE_RATE_TYPE__c.split(';');
        }
	for(Rate_Type_Description__mdt rateDescription :[Select id, MasterLabel, Rate_Type_Code__c, Description__c from Rate_Type_Description__mdt ]){
            mapRateDescription.put(rateDescription.Rate_Type_Code__c,rateDescription);
        }
        if(mapRateDescription != null){
           objectData.put('mapRateDescription',mapRateDescription); 
        }    
        if (lstExistingFiscalRateAmount.size()>0){
            objectData.put('lstExistingFiscalRateAmount', lstExistingFiscalRateAmount);
            isSuccessful= true;
           // Id providerId= fiscalSchedule.IDN_AGRMT_FISCAL__r.ID_SERVICE__c;   
            //Id countyId = fiscalSchedule.IDN_AGRMT_FISCAL__r.CDE_COUNTY__c;    
            String countyName = fiscalSchedule.IDN_AGRMT_FISCAL__r.CDE_COUNTY__r.name;
            Date effectiveBeginDate = fiscalSchedule.DTE_BEGIN_EFFV__c;
            
            
            objectData.put('providerQualityRating',fiscalSchedule.TXT_CHATS_RATING__c);
            objectData.put('rateTypeOptions', selectedRateTypeOptions);
            objectData.put('selectedRateTypeOptions', selectedRateTypeOptions);
            objectData.put('countyName', countyName);    
            objectData.put('effectiveBeginDate', effectiveBeginDate);    
            List<AgeGroupWrapper> lstTierGroupValuetoLabel = CHATSUtility.getPicklistValuesToLabelList(T_COUNTY_RATE_AMT__c.CDE_AGE_GROUP__c.getDescribe());        
            if(lstTierGroupValuetoLabel!= null)
            {
                objectData.put('lstTierGroupValuetoLabel',JSON.serialize(lstTierGroupValuetoLabel));
            }
            Map<String, String> mapRateTypeValuetoLabel = CHATSUtility.getPicklistValuesToLabelMap(T_COUNTY_RATE_AMT__c.CDE_RATE_TYPE__c.getDescribe());
            if(mapRateTypeValuetoLabel!= null)
            {
                objectData.put('mapRateTypeValuetoLabel',JSON.serialize(mapRateTypeValuetoLabel));
            }
            
            List<T_FISCAL_RAT_FEES__c> associatedRATFees = getRATFeesAssocToRateScheduler(rateScheduleId);
            
            if(associatedRATFees.size()>0) {
                objectData.put('ratFeesRec', associatedRATFees.get(0));
            }
        }else
        {
            isSuccessful= false;
            message= Label.No_Data_Found;  
        }
        
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @AuraEnabled
    public static LightningServerResponse finishRateSchedule(String providerId, T_FISCAL_SCH__c rateSchedule){
        
    	List<T_FISCAL_SCH__c> rateScheduleList = new List<T_FISCAL_SCH__c>();
        rateScheduleList.add(rateSchedule);
        LightningServerResponse lsr = updateCaseParentFeeRecords(providerId);
        RateScheduleServices.insertATSRecord(rateScheduleList);
        return lsr;
    }
    public static LightningServerResponse updateCaseParentFeeRecords(String providerId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        try{
            WebserviceResponse wsr = HerokuService.updateCaseParentFee(providerId);
            isSuccessful = wsr.isSuccess;
            message = wsr.statusCode+Label.SEPARATOR_COMMA+wsr.message;
        }catch(Exception e) {
            message  = Label.HEROKU_ERROR+e.getMessage();
            isSuccessful = false;
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'RateScheduleFlowApxCtrl','Method__c'=>'updateCaseParentFeeRecords'});
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    public static List<batchsit_t_fiscal_rate__x> getLstFiscalRateAmount(Id rateScheduleId){
        List<Id>lstRateScheduleId = new List<Id>();
        lstRateScheduleId.add(rateScheduleId);
        List<batchsit_t_fiscal_rate__x> lstExistingFiscalRateAmount = new List<batchsit_t_fiscal_rate__x>(); 
        List<FiscalRateWrapper> lstFiscalRateWrapper = HerokuService.fiscalRatefetch(lstRateScheduleId);
        for(FiscalRateWrapper fiscalWrap : lstFiscalRateWrapper){
            batchsit_t_fiscal_rate__x fiscalRate = new batchsit_t_fiscal_rate__x();
            fiscalRate.cde_age_group__c =  fiscalWrap.ageGroup;
            fiscalRate.cde_care_unit__c = fiscalWrap.careUnit;
            fiscalRate.amt_fa__c = fiscalWrap.fiscalRateAmount;
            fiscalRate.idn_fiscal_sch__c = fiscalWrap.idnFiscalSchedule;
            fiscalRate.amt_provr__c = fiscalWrap.providerRateAmount;
            fiscalRate.cde_rate_type__c = fiscalWrap.rateType;
            lstExistingFiscalRateAmount.add(fiscalRate);
        }
        return lstExistingFiscalRateAmount;
    }
    @auraEnabled
    public static LightningServerResponse insertFiscalRateRecords(List<batchsit_t_fiscal_rate__x>lstFiscalRateAmount){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        WebserviceResponse wsr = HerokuService.createFiscalRateRecords(lstFiscalRateAmount);
        isSuccessful = wsr.isSuccess;
        if(isSuccessful == true && !(wsr.message == 'Retry')){
            objectData.put('upsertedRecords',wsr.lstSObject);
            message= 'Success';    
        }else{
            if(wsr.message == 'Retry'){
                objectData.put('Retry',true);
                message = 'Retry';
                isSuccessful = true;
            }else{
                message = wsr.message;  
            }  
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @auraEnabled
    public static LightningServerResponse triggerCorspdCR707(Id rateScheduleId){
    	String message;
        set<Id> rateSchedules = new set<Id>();
        Map<string,string> keyParams = new Map<string, string>();
        integer countyCode;

        try{
        map<Id, T_FISCAL_SCH__c> ratFeesFiscalAgrmntMap = new map<Id, T_FISCAL_SCH__c>([select Id, IDN_AGRMT_FISCAL__c, IDN_AGRMT_FISCAL__r.Name, IDN_AGRMT_FISCAL__r.CDE_COUNTY__r.CDE_COUNTY__c, IDN_AGRMT_FISCAL__r.ID_SERVICE__r.Name FROM T_FISCAL_SCH__c WHERE Id =:rateScheduleId]);
        
        for(Id eachRateSchedule: ratFeesFiscalAgrmntMap.keySet()){
            if(ratFeesFiscalAgrmntMap.get(eachRateSchedule).IDN_AGRMT_FISCAL__r.CDE_COUNTY__c != NULL){
                decimal cntyCode = ratFeesFiscalAgrmntMap.get(eachRateSchedule).IDN_AGRMT_FISCAL__r.CDE_COUNTY__r.CDE_COUNTY__c;
                countyCode = integer.valueOf(cntyCode);
            }
            if(ratFeesFiscalAgrmntMap.get(eachRateSchedule).IDN_AGRMT_FISCAL__c != NULL){
                keyParams.put('faId', ratFeesFiscalAgrmntMap.get(eachRateSchedule).IDN_AGRMT_FISCAL__c);
            }
            if(ratFeesFiscalAgrmntMap.get(eachRateSchedule).IDN_AGRMT_FISCAL__r.ID_SERVICE__c != NULL){
                keyParams.put('providerId', ratFeesFiscalAgrmntMap.get(eachRateSchedule).IDN_AGRMT_FISCAL__r.ID_SERVICE__r.Name);
            }
            CorspdTrigger.createCorspdRequest(CR707RsnCode,NULL,NULL,countyCode,keyParams);
        }
        return new LightningServerResponse(true,message,null); 
        }
        catch(Exception e) {
            return new LightningServerResponse(false,message,null);
        }

    }
}