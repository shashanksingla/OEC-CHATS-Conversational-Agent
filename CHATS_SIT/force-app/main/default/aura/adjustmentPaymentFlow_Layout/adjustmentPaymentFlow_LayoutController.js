({
    doInit : function(component, event, helper) {
        if(component.get("v.parentObjectAPI") == 'T_SBSD_CASE__c'){
            component.set('v.adjPaymentObj.IDN_CASE__c', component.get("v.parentObjectId"));
            component.set('v.caseLookupLabel', component.get("v.parentObjectName"));
        }
        if(component.get("v.parentObjectAPI") == 'T_CHATS_PROVR_STATUS__c'){
            component.set('v.adjPaymentObj.IDN_PROVR__c', component.get("v.parentObjectId"));
            component.set('v.providerLookupLabel', component.get("v.parentObjectName"));
        }
        if(component.get("v.parentObjectAPI") == 'T_PAYMT__c'){
            component.set('v.adjPaymentObj.IDN_PMT__c', component.get("v.parentObjectId"));
            component.set('v.paymentLookupLabel', component.get("v.parentObjectName"));
        }
    },

    handleFieldLevelValidation : function(component, event, helper) {
        helper.handleFieldLevelValidation(component);
    }
})