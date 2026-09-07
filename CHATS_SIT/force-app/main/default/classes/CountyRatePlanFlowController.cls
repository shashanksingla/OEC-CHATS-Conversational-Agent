/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           
*  @description    CountyRatePlanFlowController                            
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 
*  * Author: Vineet 
*  * Description: Initial version                                                 
*  
*    Version: 2.0                                                                             
*  * Date: 5/12/2018
*  * Author: Ranjan Poojary
*  * Description: Update the code in Catch Block as part IronDome report fix                                                 
*********************************************************************************************/
public with sharing class CountyRatePlanFlowController {
    
    @auraEnabled
    public static LightningServerResponse getCountyRatePlanRecord(String countyRatePlanId) {
        T_COUNTY_RATE__c countyRatePlan = new T_COUNTY_RATE__c();
        try{
            countyRatePlan = [Select IND_RATE_PLAN_TEMPLT__c, Name,
                              IDN_COUNTY__c,
                              CDE_STATUS__c,
                              DTE_BEGIN_EFFV_RATE__c,
                              CDE_RATE_PLAN_TEMPLT__c,
                              PAYMENT_Q1__c,
                              PAYMENT_Q1_1__c,
                              PAYMENT_Q1_OTHER__c,
                              PAYMENT_Q2__c,
                              PAYMENT_Q3__c,
                              PAYMENT_Q4__c,
                              PAYMENT_Q5__c,
                              PAYMENT_Q5_1__c,
                              PAYMENT_Q5_OTHER__c,
                              PAYMENT_Q6__c,
                              PAYMENT_Q7__c,
                              PAYMENT_Q8__c,
                              PAYMENT_Q9__c,
                              PAYMENT_Q9_1__c,
                              PAYMENT_Q10__c,
                              PAYMENT_Q10_1__c,
                              PAYMENT_Q11__c,
                              PAYMENT_Q11_1__c,
                              PAYMENT_Q11_2__c,
                              PAYMENT_Q11_3__c,
                              PAYMENT_Q12__c,
                              PAYMENT_Q12_1__c,
                              PAYMENT_Q12_2__c,
                              PAYMENT_Q12_2_OTHER__c,
                              PAYMENT_Q13_a__c,
                              PAYMENT_Q13_b__c,
                              PAYMENT_Q13_c__c,
                              PAYMENT_Q13_d__c,
                              PAYMENT_Q13_e__c,
                              PAYMENT_Q13_1__c,
                              PAYMENT_Q13_2__c,
                              PAYMENT_Q13_OTHER__c,
                              PAYMENT_Q14__c,
                              PAYMENT_Q14_1__c,
                              PAYMENT_Q14_2__c,
                              PAYMENT_Q14_3__c,
                              PAYMENT_Q14_4__c,
                              PAYMENT_Q14_5__c,
                              PAYMENT_Q15__c,
                              PAYMENT_Q16__c,
                              PAYMENT_Q17__c,
                              PAYMENT_Q17_1__c,
                              PAYMENT_Q17_2__c,
                              PAYMENT_Q17_3__c,
                              PAYMENT_Q17_4__c,
                              PAYMENT_Q17_OTHER__c,
                              ROO_Q1__c,
                              ROO_Q1_1_1__c,
                              ROO_Q1_1_1a__c,
                              ROO_Q1_1_2__c,
                              ROO_Q1_1_2a__c,
                              ROO_Q1_1_3__c,
                              ROO_Q1_1_3a__c,
                              ROO_Q1_1_4__c,
                              ROO_Q1_1_4a__c,
                              ROO_Q1_1_5__c,
                              ROO_Q1_1_5a__c,
                              ROO_Q1_1_6__c,
                              ROO_Q1_1_6a__c,
                              ROO_Q1_1_7__c,
                              ROO_Q1_1_7a__c,
                              ROO_Q1_1_8__c,
                              ROO_Q1_1_8a__c,
                              ROO_Q1_1_9__c,
                              ROO_Q1_1_9a__c,
                              ROO_Q1_2__c,
                              ROO_Q1_3__c,
                              ROO_Q1_4__c,
                              ROO_Q1_5__c,
                              ROO_Q1_6__c,
                              ROO_Q1_7__c,
                              ROO_Q1_8__c,
                              ROO_Q1_9__c,
                              ROO_Q1_10__c,
                              CFS_Q1__c,
                              CFS_Q1_1__c,
                              CFS_Q1_2__c,
                               CFS_Q1_3__c,
                               CFS_Q1_4__c,
                              CFS_Q2__c,
                              CFS_Q2_OTHER__c,
                              CFS_Q2_1__c,
                              CFS_Q3__c,
                              CFS_Q3_1__c,
                              CFS_Q4__c,
                              CFS_Q5__c,
                              CFS_Q6__c,
                              CFS_Q6_1__c,
                              CFS_Q7__c,
                              CFS_Q8__c,
                              CFS_Q8_1__c,
                              CFS_Q8_2__c,
                              QEP_Q1__c,
                              QEP_Q1_new__c,
                              QEP_Q2__c,
                              RATE_TYPE__c,
                              PAYMENT_Q18__c,
                              PAYMENT_Q18_1__c,
                              PAYMENT_Q18_2__c,
                              PAYMENT_Q18_3__c,
                              PAYMENT_Q18_OTHER__c,
                              RT_Q1__c,
                              RT_Q2__c,
                              RT_Q2_a__c,
                              RT_Q2_b__c,
                              RT_Q2_3__c,
                              RT_Q2_c__c,
                              RT_Q2_d__c,
                              RT_Q2_e__c,
                              RT_Q2_f__c,
                              RT_Q2_g__c,
                              PAYMENT_Q15_1__c,
                              RT_Q8_1__c,
                              RT_Q8_1P__c,
                              RT_Q8_2__c,
                              RT_Q8_2P__c,
                              RT_Q8_3__c,
                              RT_Q8_3P__c,
                              RT_Q8_4__c,
                              RT_Q8_4P__c,
                              RT_Q8_5__c,
                              RT_Q8_5P__c,
                              RT_Q8_6__c,
                              RT_Q8_6P__c,
                              RT_Q8_7__c,
                              RT_Q8_7P__c,
                              RT_Q8_8__c,
                              RT_Q8_8P__c,
                              RT_Q1_1__c,
                              PAYMENT_Q17_1_1__c,
                              PAYMENT_Q17_3_1__c,
                              PAYMENT_Q14_4_1__c,
                              PAYMENT_Q14_4_2__c,
                              PAYMENT_Q14_4_3__c,
                              PAYMENT_Q14_4_4__c
                              from T_COUNTY_RATE__c where ID =:countyRatePlanId];
        }
        catch(Exception ex)
        {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'CountyRatePlanFlowController','Method__c'=>'getCountyRatePlanRecord'});
            return new LightningServerResponse(false, ex.getMessage(), null);
            
        }
        
        return new LightningServerResponse(true, 'Success', new Map<String, Object>{'countyRatePlanRecord'=>countyRatePlan});
    }
    
    
    
    @auraEnabled
    public static LightningServerResponse getCountyRatePlanRecordForTemplate(String templateName,String countyId) {
        //T_COUNTY_RATE__c countyRatePlan = new T_COUNTY_RATE__c();
        List<T_COUNTY_RATE__c> countyRatePlanlst = new List<T_COUNTY_RATE__c>();
        if(templateName != '5') {
            try{
                countyRatePlanlst= [Select CDE_RATE_PLAN_TEMPLT__c,
                                    PAYMENT_Q1__c,
                                    PAYMENT_Q1_1__c,
                                    PAYMENT_Q1_OTHER__c,
                                    PAYMENT_Q2__c,
                                    PAYMENT_Q3__c,
                                    PAYMENT_Q4__c,
                                    PAYMENT_Q5__c,
                                    PAYMENT_Q5_1__c,
                                    PAYMENT_Q5_OTHER__c,
                                    PAYMENT_Q6__c,
                                    PAYMENT_Q7__c,
                                    PAYMENT_Q8__c,
                                    PAYMENT_Q9__c,
                                    PAYMENT_Q9_1__c,
                                    PAYMENT_Q10__c,
                                    PAYMENT_Q10_1__c,
                                    PAYMENT_Q11__c,
                                    PAYMENT_Q11_1__c,
                                    PAYMENT_Q11_2__c,
                                    PAYMENT_Q11_3__c,
                                    PAYMENT_Q12__c,
                                    PAYMENT_Q12_1__c,
                                    PAYMENT_Q12_2__c,
                                    PAYMENT_Q12_2_OTHER__c,
                                    PAYMENT_Q13_a__c,
                                    PAYMENT_Q13_b__c,
                                    PAYMENT_Q13_c__c,
                                    PAYMENT_Q13_d__c,
                                    PAYMENT_Q13_e__c,
                                    PAYMENT_Q13_1__c,
                                    PAYMENT_Q13_2__c,
                                    PAYMENT_Q13_OTHER__c,
                                    PAYMENT_Q14__c,
                                    PAYMENT_Q14_1__c,
                                    PAYMENT_Q14_2__c,
                                    PAYMENT_Q14_3__c,
                                    PAYMENT_Q14_4__c,
                                    PAYMENT_Q14_5__c,
                                    PAYMENT_Q15__c,
                                    PAYMENT_Q16__c,
                                    PAYMENT_Q17__c,
                                    PAYMENT_Q17_1__c,
                                    PAYMENT_Q17_2__c,
                                    PAYMENT_Q17_3__c,
                                    PAYMENT_Q17_4__c,
                                    PAYMENT_Q17_OTHER__c,
                                    ROO_Q1__c,
                                    ROO_Q1_1_1__c,
                                    ROO_Q1_1_1a__c,
                                    ROO_Q1_1_2__c,
                                    ROO_Q1_1_2a__c,
                                    ROO_Q1_1_3__c,
                                    ROO_Q1_1_3a__c,
                                    ROO_Q1_1_4__c,
                                    ROO_Q1_1_4a__c,
                                    ROO_Q1_1_5__c,
                                    ROO_Q1_1_5a__c,
                                    ROO_Q1_1_6__c,
                                    ROO_Q1_1_6a__c,
                                    ROO_Q1_1_7__c,
                                    ROO_Q1_1_7a__c,
                                    ROO_Q1_1_8__c,
                                    ROO_Q1_1_8a__c,
                                    ROO_Q1_1_9__c,
                                    ROO_Q1_1_9a__c,
                                    ROO_Q1_2__c,
                                    ROO_Q1_3__c,
                                    ROO_Q1_4__c,
                                    ROO_Q1_5__c,
                                    ROO_Q1_6__c,
                                    ROO_Q1_7__c,
                                    ROO_Q1_8__c,
                                    ROO_Q1_9__c,
                                    ROO_Q1_10__c,
                                    CFS_Q1__c,
                                    CFS_Q1_1__c,
                                    CFS_Q1_2__c,
                                    CFS_Q1_3__c,
                                    CFS_Q1_4__c,
                                    CFS_Q2__c,
                                    CFS_Q2_OTHER__c,
                                    CFS_Q2_1__c,
                                    CFS_Q3__c,
                                    CFS_Q3_1__c,
                                    CFS_Q4__c,
                                    CFS_Q5__c,
                                    CFS_Q6__c,
                                    CFS_Q6_1__c,
                                    CFS_Q7__c,
                                    CFS_Q8__c,
                                    CFS_Q8_1__c,
                                    CFS_Q8_2__c,
                                    QEP_Q1__c,
                                    QEP_Q1_new__c,
                                    QEP_Q2__c,
                                    RATE_TYPE__c,
                                    PAYMENT_Q18__c,
                                    PAYMENT_Q18_1__c,
                                    PAYMENT_Q18_2__c,
                                    PAYMENT_Q18_3__c,
                                    PAYMENT_Q18_OTHER__c,
                                    RT_Q1__c,
                                    RT_Q2__c,
                                    RT_Q2_a__c,
                                    RT_Q2_b__c,
                                    RT_Q2_3__c,
                                    RT_Q2_c__c,
                                    RT_Q2_d__c,
                                    RT_Q2_e__c,
                                    RT_Q2_f__c,
                                    RT_Q2_g__c,
                                    PAYMENT_Q15_1__c,
                                    RT_Q8_1__c,
                                    RT_Q8_1P__c,
                                    RT_Q8_2__c,
                                    RT_Q8_2P__c,
                                    RT_Q8_3__c,
                                    RT_Q8_3P__c,
                                    RT_Q8_4__c,
                                    RT_Q8_4P__c,
                                    RT_Q8_5__c,
                                    RT_Q8_5P__c,
                                    RT_Q8_6__c,
                                    RT_Q8_6P__c,
                                    RT_Q8_7__c,
                                    RT_Q8_7P__c,
                                    RT_Q8_8__c,
                                    RT_Q8_8P__c,
                                    RT_Q1_1__c,
                                    PAYMENT_Q17_1_1__c,
                                    PAYMENT_Q17_3_1__c,
                                    PAYMENT_Q14_4_1__c,
                                    PAYMENT_Q14_4_2__c,
                                    PAYMENT_Q14_4_3__c,
                                    PAYMENT_Q14_4_4__c
                                    from T_COUNTY_RATE__c where  CDE_RATE_PLAN_TEMPLT__c=:templateName and IND_RATE_PLAN_TEMPLT__c = true and IDN_COUNTY__c=:countyId  ORDER BY LastModifiedDate DESC NULLS FIRST LIMIT 1 ];
            }
            catch(Exception ex)
            {
                ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'CountyRatePlanFlowController','Method__c'=>'getCountyRatePlanRecordForTemplate'});
                return new LightningServerResponse(false, ex.getMessage(), null);
            }
        }
        if(countyRatePlanlst.size()>0){
            return new LightningServerResponse(true, 'Success', new Map<String, Object>{'countyRatePlanRecord'=>countyRatePlanlst[0]});  
        }else{
            return new LightningServerResponse(false, 'Success', new Map<String, Object>{'countyRatePlanRecord'=>new T_COUNTY_RATE__c()}); 
        }
        // return new LightningServerResponse(true, 'Success', new Map<String, Object>{'countyPlanRecord'=>countyRatePlan});
    }
    
    //CHAT-2131
    @auraEnabled
    public static T_COUNTY_RATE__c getCountyValidatedForNewRatePlan(String countyID){
        T_COUNTY_RATE__c countyRatePlan = new T_COUNTY_RATE__c();
        try{
            List<T_COUNTY_RATE__c> lstCountyRatePlan = [select Id FROM T_COUNTY_RATE__c WHERE IDN_COUNTY__c =:countyId AND CDE_STATUS__c != 'APV' LIMIT 1];    
            if (!lstCountyRatePlan.isEmpty()){
                countyRatePlan = lstCountyRatePlan.get(0);
            }
        }
        catch(Exception ex){
            //return new LightningServerResponse(false, ex.getMessage(), null);  // IronDome Report fix.
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'CountyRatePlanFlowController','Method__c'=>'getCountyValidatedForNewRatePlan'});
        }
        return countyRatePlan;
    }
    
    @AuraEnabled
    public static map<String, Object> ownerCountyValidation(String recordId, Boolean isCounty){
        map<String, Object> responseMap = new map<String, Object>();
        Boolean countyMatched = true;
        String countyName = '';
        Id countyId;
        if(!String.isBlank(recordId)){
            if(isCounty){
                countyId = recordId;
                T_COUNTY__c county = [SELECT Id, Name FROM T_COUNTY__c WHERE Id = :recordId];
                countyName = county.Name;
            }
            else{
                T_COUNTY_RATE__c countyRatePlan = [SELECT Id, IDN_COUNTY__c, IDN_COUNTY__r.Name,DTE_BEGIN_EFFV_RATE__c FROM T_COUNTY_RATE__c WHERE Id = :recordId];
                countyId = countyRatePlan.IDN_COUNTY__c;
                countyName = countyRatePlan.IDN_COUNTY__r.Name;
                Boolean feedbacksExist = [select id from CP_CRP_Feedback__c where County__c =:countyId AND feedback_type__c IN ('CRP','CRP_Rate')]?.size()>0;
                responseMap.put('isFeedbackVisible',feedbacksExist && CompareCP_CRP_lwc.IsDateAfter_15June2025(countyRatePlan.DTE_BEGIN_EFFV_RATE__c));
            }
            countyMatched = CHATSUtility.checkCountyWithUserCounty(countyId);
        }
        responseMap.put('countyMatched', countyMatched);
        responseMap.put('countyName', countyName);
        responseMap.put('countyId', countyId);
        return responseMap;
    }
}