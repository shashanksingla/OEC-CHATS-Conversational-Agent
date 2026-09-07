({
    doInit : function(component, event, helper) {
        component.set("v.newCaseCopayRec.amt_copay_case_ft_qlty__c",Math.floor(component.get("v.newCaseCopayRec").amt_copay_case_ft__c * 0.8));
        component.set("v.newCaseCopayRec.amt_copay_case_pt_qlty__c",Math.floor(component.get("v.newCaseCopayRec").amt_copay_case_pt__c * 0.8));
        component.set("v.newCaseCopayRec.amt_copay_case_ft__c", Math.floor(component.get("v.newCaseCopayRec").amt_copay_case_ft__c));
        component.set("v.newCaseCopayRec.amt_copay_case_pt__c", Math.floor(component.get("v.newCaseCopayRec").amt_copay_case_pt__c));
       
    },
    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    },
    handleFieldLevelValidation : function(component, event, helper) {
        helper.handleFieldLevelValidation(component);
    },
    validateField : function(component, event, helper) {
        helper.checkFieldValidity(component,event.getSource().get("v.label"),event.getSource().get("v.value"));
    },
    getActiveAuth :  function(component, event, helper) {
        var oldDate = event.getParam("oldValue");
        var newDate = event.getParam("value");
        if(!$A.util.isEmpty(newDate) && newDate != oldDate){
            component.set("v.showSpinner", true); 
            helper.getActiveAuthHlp(component, event, helper,newDate);
            helper.getCaseParentFeeHlp(component, event, helper,newDate);
            helper.getRecommendedCopayUnit(component, event, helper,newDate);
        }
        else if($A.util.isEmpty(newDate) ){
            component.set("v.newCaseCopayRec.ind_qlty__c",'');
        }
    },
    validateOverrideReason : function(cmp, event, helper) {
        var caseCopayRec = cmp.get("v.caseCopayRec");
        var isFirstCaseCopayRec = cmp.get("v.isFirstCaseCopayRec");
        var newCaseCopayRec = cmp.get("v.newCaseCopayRec");
        var parentFee = newCaseCopayRec.amt_copay_case_assesd__c;
        var overrideReason = newCaseCopayRec.cde_reason_ovrd__c;
        if(!$A.util.isEmpty(caseCopayRec.amt_copay_case_assesd__c) && (!isFirstCaseCopayRec)){
            if(!$A.util.isEmpty(parentFee) && parentFee != caseCopayRec.amt_copay_case_assesd__c) {
                if($A.util.isEmpty(overrideReason)) {
                    cmp.set("v.isOverrideReasonRequired",true);
                   // cmp.find("batchsit_t_sbsd_case_copay__x-CDE_REASON_OVRD__c").set("v.message","Please enter a value");
                }
                else {
                    cmp.find("batchsit_t_sbsd_case_copay__x-CDE_REASON_OVRD__c").set("v.message",null);
                }
            }   else{
                cmp.set("v.isOverrideReasonRequired",false);
            }
        }
    },
})