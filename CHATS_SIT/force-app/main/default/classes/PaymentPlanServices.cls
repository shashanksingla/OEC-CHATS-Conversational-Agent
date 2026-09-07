/*********************************************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           22/11/2017
*  @description    Handler class for Payment Plan Trigger

*  Modification Log:
*  * Version: 1.0
*  * Date: 22-Nov-2017
*  * Author: Bharadwaj Gaddam
*  * Description: Initial version 
*
*  * Version: 2.0
*  * Date: 14-May-2018
*  * Author: Shubham K
*  * Description: Updating line 52 to check null before DML Operation
*
*  * Version: 3.0
*  * Date: 10/19/2020
*  * Author: Diya Chaudhary
*  * Description: Adding validation for the logged user county vs active payment plan county on provider.
*********************************************************************************************/
public with sharing class PaymentPlanServices {
/*
Description: Deactivate Previous Plan
Author Bharadwaj Gaddam
Date 22/11/2017 
*/
    public static void deactivatePreviousPlan(List<T_PMT_PLAN__c> newPaymentPlansList) {
        Set<Id> paymentplanIds= new Set<Id>();
        Set<Id> providerIds= new Set<Id>();
        Map<Id, T_PMT_PLAN__c> updatedPreviousPlans = new Map<Id, T_PMT_PLAN__c>();
        
        for(T_PMT_PLAN__c eachplan:newPaymentPlansList) {
            if(eachplan.IDN_PROVR__c!=null && eachplan.Id!=null && eachplan.IND_ACTIVE__c) {
                providerIds.add(eachplan.IDN_PROVR__c);
                paymentplanIds.add(eachplan.Id);
            }
        }
        try {
            for(T_PMT_PLAN__c updatePlan: [Select Id, IND_ACTIVE__c,IDN_PROVR__c from T_PMT_PLAN__c where IDN_PROVR__c IN:providerIds and Id Not IN:paymentplanIds and IND_ACTIVE__c!=false]) {
                updatePlan.IND_ACTIVE__c=false;
                updatedPreviousPlans.put(updatePlan.Id,updatePlan);
            }
            if(!updatedPreviousPlans.isEmpty() && updatedPreviousPlans != NULL) {
                update updatedPreviousPlans.values();
            }
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'PaymentPlanServices','Method__c'=>'deactivatePreviousPlan'});
            System.debug('The following exception has occurred from Method deactivatePreviousPlan Line 52 in Apex class PaymentPlanServices: ' + ex.getMessage()); // IronDome Report fix.        
        } 
    }
    
    // Added by Rishav for CCCAP-5785
    // When an active Repayment Plan is inserted, that provider's other active plans for same county gets deactivated.
    public static void deactivatePreviousPlanPerCounty(List<T_PMT_PLAN__c> newPaymentPlansList) {
        List<String> providerIdList = new List<String>();
        List<T_PMT_PLAN__c> activeRepayPlanList = new List<T_PMT_PLAN__c>();
        for(T_PMT_PLAN__c pp : newPaymentPlansList){
            if(pp.IDN_PROVR__c != null && pp.IND_ACTIVE__c){
                providerIdList.add(pp.IDN_PROVR__c);
                activeRepayPlanList.add(pp);
            }
        }
        Try {
            Map<String, Set<String>> provRepayPlanMap = new Map<String, Set<String>>();
            Map<String, String> repayPlanCountyMap = new Map<String, String>();
            for(T_PMT_PLAN__c pp : [SELECT Id, IDN_PROVR__c, CDE_COUNTY__c FROM T_PMT_PLAN__c WHERE IDN_PROVR__c IN: providerIdList AND IND_ACTIVE__c = true]){
                repayPlanCountyMap.put(pp.Id, pp.CDE_COUNTY__c);
                if(provRepayPlanMap.containsKey(pp.IDN_PROVR__c)){
                    Set<String> repayPlanSet = provRepayPlanMap.get(pp.IDN_PROVR__c);
                    if(!repayPlanSet.contains(pp.Id)){
                        repayPlanSet.add(pp.Id);
                    }
                    provRepayPlanMap.put(pp.IDN_PROVR__c, repayPlanSet);
                } else {
                    Set<String> repayPlanSet = new Set<String>{pp.Id};
                        provRepayPlanMap.put(pp.IDN_PROVR__c, repayPlanSet);
                }
            }
            
            List<T_PMT_PLAN__c> planToDeactivate = new List<T_PMT_PLAN__c>();
            for(T_PMT_PLAN__c pp : activeRepayPlanList){
                for(String oldRepayPlanId : provRepayPlanMap.get(pp.IDN_PROVR__c)){
                    if(pp.CDE_COUNTY__c == repayPlanCountyMap.get(oldRepayPlanId) && pp.Id != oldRepayPlanId){
                        T_PMT_PLAN__c plan = new T_PMT_PLAN__c(Id = oldRepayPlanId, IND_ACTIVE__c = false);
                        planToDeactivate.add(plan);
                    }
                }
            }
            if(!planToDeactivate.isEmpty()){
                Database.update(planToDeactivate);
            }
        } catch(Exception ex) {
            System.debug('[PaymentPlanServices.deactivatePreviousPlanPerCounty]--Exception-->' + ex.getMessage());
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'PaymentPlanServices','Method__c'=>'deactivatePreviousPlanPerCounty'});
        } 
    }
    
    // CCCAP-2011 CCCAP-2386
    public static Boolean paymentPlanCountyCheck(String providerId){ 
        Boolean isCountyMatch =false;
        Set<Id> paymentplanIds= new Set<Id>();
        Set<Id> providerIds= new Set<Id>();
        Map<Id, Id> userOfPmtPlan = new Map<Id, Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> oldUserIds = new Set<Id>();
        Map<Id, Id> previousUserOfPmtPlan = new Map<Id, Id>();
        Set<Id> oldUserUpdateIds = new Set<Id>();
        Map<Id, Id> previousUserUpdateOfPmtPlan = new Map<Id, Id>();
        Map<Id, T_PMT_PLAN__c> updatedPreviousPlans = new Map<Id, T_PMT_PLAN__c>();
        Map<id,Set<String>> newUserCountyMap= new Map<id,Set<String>>();
        Map<id,Set<String>> oldUserCountyMap= new Map<id,Set<String>>();
        /* Commenting since using custom permission CCCAP-14993
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;*/
        
        if(providerId!=null ) {
            providerIds.add(providerId);
            userOfPmtPlan.put(providerId,UserInfo.getUserId());
            userIds.add(UserInfo.getUserId());
        }
        if(userIds.size()>0){
            newUserCountyMap = getCountyInfo(userIds);
        }
        try{
            for(T_PMT_PLAN__c updatePlan: [Select Id, IND_ACTIVE__c,IDN_PROVR__c,CreatedById from T_PMT_PLAN__c where IDN_PROVR__c IN:providerIds and IND_ACTIVE__c!=false]) {
                updatedPreviousPlans.put(updatePlan.IDN_PROVR__c,updatePlan);
                previousUserOfPmtPlan.put(updatePlan.IDN_PROVR__c,updatePlan.CreatedById);
                oldUserIds.add(updatePlan.CreatedById);
            }
            if(oldUserIds.size()>0){
                oldUserCountyMap = getCountyInfo(oldUserIds);
            }else{
                isCountyMatch=true;
            }
            //Replacing with Custom Permission CCCAP-14993
            if((FeatureManagement.checkPermission('System_Administrator') || FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')) && !test.isRunningTest()){
                isCountyMatch =true;
            }else{
                if(userOfPmtPlan.containsKey(providerId)){
                    Set<String> counties = newUserCountyMap.get(userOfPmtPlan.get(providerId)); 
                    if(previousUserOfPmtPlan.containsKey(providerId)){
                        Set<String> previousCounties = oldUserCountyMap.get(previousUserOfPmtPlan.get(providerId)); 
                        for(String cty:counties){
                            if(previousCounties.contains(cty) && cty!=null){
                                isCountyMatch=true;
                                break;
                            }
                        }
                        if(!isCountyMatch){
                            return isCountyMatch;
                        }
                    }
                }
            }
            return isCountyMatch;
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'PaymentPlanServices','Method__c'=>'deactivatePreviousPlan'});
            System.debug('The following exception has occurred from Method deactivatePreviousPlan Line 52 in Apex class PaymentPlanServices: ' + ex.getMessage()); // IronDome Report fix.        
        }
        return isCountyMatch;
    }
    
    public static Map<id,Set<String>> getCountyInfo(Set<Id> userIds){
        Map<id,Set<String>> userCountyMap= new Map<id,Set<String>>();
        for(User usr:[SELECT Owner_County__c,Common_County__c FROM User WHERE Id IN :userIds]){
            if(userCountyMap.containsKey(usr.Id)){
                Set<String> countySet =userCountyMap.get(usr.Id);
                countySet.add(usr.Owner_County__c);
                if(usr.Common_County__c != null){
                    countySet.addAll(usr.Common_County__c.split(';'));
                }
                userCountyMap.put(usr.Id,countySet );
            }else{
                Set<String> countySet = new Set<String>();
                countySet.add(usr.Owner_County__c);
                if(usr.Common_County__c != null){
                    countySet.addAll(usr.Common_County__c.split(';'));
                }
                userCountyMap.put(usr.Id,countySet );
            }
        }
        return userCountyMap;
    }
    
    public static void countyCheck(List<T_PMT_PLAN__c> newPaymentPlansList,Boolean isUpdate){ 
        Set<Id> paymentplanIds= new Set<Id>();
        Set<Id> providerIds= new Set<Id>();
        Map<Id, Id> userOfPmtPlan = new Map<Id, Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> oldUserIds = new Set<Id>();
        Map<Id, Id> previousUserOfPmtPlan = new Map<Id, Id>();
        Set<Id> oldUserUpdateIds = new Set<Id>();
        Map<Id, Id> previousUserUpdateOfPmtPlan = new Map<Id, Id>();
        Map<Id, T_PMT_PLAN__c> updatedPreviousPlans = new Map<Id, T_PMT_PLAN__c>();
        Map<id,Set<String>> newUserCountyMap= new Map<id,Set<String>>();
        Map<id,Set<String>> oldUserCountyMap= new Map<id,Set<String>>();
        /*Commenting since using custom permission CCCAP-14993
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;*/
        for(T_PMT_PLAN__c eachplan:newPaymentPlansList) {
            system.debug('eachplan--'+eachplan);
            if(eachplan.IDN_PROVR__c!=null ) {
                providerIds.add(eachplan.IDN_PROVR__c);
                if(eachplan.Id != null){
                    paymentplanIds.add(eachplan.Id);
                }
                userOfPmtPlan.put(eachplan.IDN_PROVR__c,UserInfo.getUserId());
                userIds.add(UserInfo.getUserId());
                if(isUpdate){
                    previousUserUpdateOfPmtPlan.put(eachplan.IDN_PROVR__c,eachplan.CreatedById);
                    oldUserUpdateIds.add(eachplan.CreatedById);
                }
            }
        }
        if(userIds.size()>0){
            newUserCountyMap = getCountyInfo(userIds);
        }
        try{
            for(T_PMT_PLAN__c updatePlan: [Select Id, IND_ACTIVE__c,IDN_PROVR__c,CreatedById from T_PMT_PLAN__c where IDN_PROVR__c IN:providerIds and Id Not IN:paymentplanIds and IND_ACTIVE__c!=false]) {
                system.debug('updatePlan--'+updatePlan);
                updatedPreviousPlans.put(updatePlan.IDN_PROVR__c,updatePlan);
                previousUserOfPmtPlan.put(updatePlan.IDN_PROVR__c,updatePlan.CreatedById);
                oldUserIds.add(updatePlan.CreatedById);
            }
            if(oldUserIds.size()>0){
                oldUserCountyMap = getCountyInfo(oldUserIds);
            }else{
                if(isUpdate && oldUserUpdateIds.size()>0){
                    oldUserCountyMap = getCountyInfo(oldUserUpdateIds);  
                }
            }
            system.debug('oldUserCountyMap--'+oldUserCountyMap);
            system.debug('newUserCountyMap--'+newUserCountyMap);
            system.debug('oldUserIds--'+oldUserIds);
            system.debug('userIds--'+userIds);
            //Replacing with Custom Permission CCCAP-14993
            if((!FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team'))|| Test.isRunningTest()){
                for(T_PMT_PLAN__c eachplan:newPaymentPlansList) {
                    if(userOfPmtPlan.containsKey(eachplan.IDN_PROVR__c)){
                        Set<String> counties = newUserCountyMap.get(userOfPmtPlan.get(eachplan.IDN_PROVR__c)); 
                        if(previousUserOfPmtPlan.containsKey(eachplan.IDN_PROVR__c)){
                            system.debug('new user id'+userOfPmtPlan.containsKey(eachplan.IDN_PROVR__c));
                            system.debug('previousUserOfPmtPlan user id'+previousUserOfPmtPlan.containsKey(eachplan.IDN_PROVR__c));
                            Set<String> previousCounties = oldUserCountyMap.get(previousUserOfPmtPlan.get(eachplan.IDN_PROVR__c)); 
                            system.debug('counties--'+counties);
                            system.debug('previousCounties--'+previousCounties);
                            Boolean isCountyMatch =false;
                            for(String cty:counties){
                                if(previousCounties.contains(cty) && cty!=null){
                                    isCountyMatch=true;
                                    break;
                                }
                            }
                            system.debug('isCountyMatch--'+isCountyMatch);
                            if(!isCountyMatch){
                                eachplan.addError(System.Label.PaymentPlanCountyCheck);
                            }
                        } else if(isUpdate) {
                            if(previousUserUpdateOfPmtPlan.containsKey(eachplan.IDN_PROVR__c)){
                                system.debug('new user id'+userOfPmtPlan.containsKey(eachplan.IDN_PROVR__c));
                                system.debug('previousUserOfPmtPlan user id'+previousUserUpdateOfPmtPlan.containsKey(eachplan.IDN_PROVR__c));
                                Set<String> previousCounties = oldUserCountyMap.get(previousUserUpdateOfPmtPlan.get(eachplan.IDN_PROVR__c));
                                system.debug('counties--'+counties);
                                system.debug('previousCounties--'+previousCounties);
                                Boolean isCountyMatch =false;
                                for(String cty:counties){
                                    if(previousCounties.contains(cty) && cty!=null){
                                        isCountyMatch=true;
                                        break;
                                    }
                                }
                                system.debug('isCountyMatch--'+isCountyMatch);
                                if(!isCountyMatch){
                                    eachplan.addError(System.Label.PaymentPlanCountyCheck);
                                }
                            }
                            
                        }
                    }
                }
            } 
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'PaymentPlanServices','Method__c'=>'deactivatePreviousPlan'});
            System.debug('The following exception has occurred from Method deactivatePreviousPlan Line 52 in Apex class PaymentPlanServices: ' + ex.getMessage()); // IronDome Report fix.        
        } 
    }
    //END

    //CCCAP-2322
    public static void activePaymentPlanCheck(List<T_PMT_PLAN__c> newPaymentPlansList){ 
        Set<Id> paymentplanIds= new Set<Id>();
        Set<Id> providerIds= new Set<Id>();
        Map<Id, T_PMT_PLAN__c> updatedPreviousPlans = new Map<Id, T_PMT_PLAN__c>();
        
        for(T_PMT_PLAN__c eachplan:newPaymentPlansList) {
            if(eachplan.IDN_PROVR__c!=null && eachplan.Id!=null && eachplan.IND_ACTIVE__c) {
                providerIds.add(eachplan.IDN_PROVR__c);
                paymentplanIds.add(eachplan.Id);
            }
        }
        try {
            for(T_PMT_PLAN__c updatePlan: [Select Id, IND_ACTIVE__c,IDN_PROVR__c from T_PMT_PLAN__c where IDN_PROVR__c IN:providerIds and Id Not IN:paymentplanIds and IND_ACTIVE__c!=false]) {
                updatedPreviousPlans.put(updatePlan.IDN_PROVR__c,updatePlan);
            }
            for(T_PMT_PLAN__c eachplan:newPaymentPlansList) {
                if(eachplan.IDN_PROVR__c!=null && eachplan.Id!=null && eachplan.IND_ACTIVE__c) {
                    IF(updatedPreviousPlans.containsKey(eachplan.IDN_PROVR__c)){
                        eachplan.addError(System.Label.PaymentPlanActiveCheck);
                    }
                }
            }
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'PaymentPlanServices','Method__c'=>'deactivatePreviousPlan'});
            System.debug('The following exception has occurred from Method deactivatePreviousPlan Line 52 in Apex class PaymentPlanServices: ' + ex.getMessage()); // IronDome Report fix.        
        } 
    }
    //END
    
    // Added by Rishav for CCCAP-5785
    // When a Repayment Plan is activated, checks if there are already a active plan for same provider and same county.
    public static void activePaymentPlanPerCountyCheck(List<T_PMT_PLAN__c> newPaymentPlansList) {
        List<String> providerIdList = new List<String>();
        List<T_PMT_PLAN__c> activeRepayPlanList = new List<T_PMT_PLAN__c>();
        for(T_PMT_PLAN__c pp : newPaymentPlansList){
            if(pp.IDN_PROVR__c != null && pp.IND_ACTIVE__c){
                providerIdList.add(pp.IDN_PROVR__c);
                activeRepayPlanList.add(pp);
            }
        }
        Try {
            Map<String, Set<String>> provCountyMap = new Map<String, Set<String>>();
            for(T_PMT_PLAN__c pp : [SELECT Id, IDN_PROVR__c, CDE_COUNTY__c FROM T_PMT_PLAN__c WHERE IDN_PROVR__c IN: providerIdList AND IND_ACTIVE__c = true]){
                if(provCountyMap.containsKey(pp.IDN_PROVR__c)){
                    Set<String> repayPlanCountySet = provCountyMap.get(pp.IDN_PROVR__c);
                    if(!repayPlanCountySet.contains(pp.CDE_COUNTY__c)){
                        repayPlanCountySet.add(pp.CDE_COUNTY__c);
                    }
                    provCountyMap.put(pp.IDN_PROVR__c, repayPlanCountySet);
                } else {
                    Set<String> repayPlanCountySet = new Set<String>{pp.CDE_COUNTY__c};
                    provCountyMap.put(pp.IDN_PROVR__c, repayPlanCountySet);
                }
            }
            
            for(T_PMT_PLAN__c pp : activeRepayPlanList){
                Set<String> oldRepayPlanCountySet = provCountyMap.get(pp.IDN_PROVR__c);
                if(oldRepayPlanCountySet.contains(pp.CDE_COUNTY__c)){
                    pp.addError(System.Label.PaymentPlanActiveCheck);
                }
            }
        } catch(Exception ex) {
            System.debug('[PaymentPlanServices.activePaymentPlanPerCountyCheck]--Exception-->' + ex.getMessage());
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'PaymentPlanServices','Method__c'=>'activePaymentPlanPerCountyCheck'});
        }
    }
}