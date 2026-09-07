({
    closeModel  : function(component, event, helper) {
        component.set("v.isOpen", false);
        component.set("v.childAttr",false);
    },
    
    onchange  : function (component, event, helper) {
        if(event.getSource().getLocalId() == 'corspdName'){ //added for CCCAP-11596
            helper.clearAllFields(component); 
        }
        helper.disabledfield(component, event);
    },
    
    myAction : function(component, event, helper) {
        var newparam = component.get("v.param");
        let manual = (component.get("v.manualchecklist") || {});
        if((newparam.NME_CORSPD__c == 'CR107') && ((manual.DTE_DEADLINE__c == '' || manual.DTE_DEADLINE__c == undefined) || (newparam.CR107_Checklist__c == '' || newparam.CR107_Checklist__c == undefined))) {
            if(newparam.CR107_OTHER_TEXT__c != null && (manual.DTE_DEADLINE__c == '' || manual.DTE_DEADLINE__c == undefined) ){
                helper.toastMessage('Error','Please provide all the Mandatory Information.');
            } else if(newparam.CR107_OTHER_TEXT__c != null) {
                helper.updateItem(component, event, helper);
            } else {
                helper.toastMessage('Error','Please provide all the Mandatory Information.');
            }
        } else if((newparam.NME_CORSPD__c == 'CR702') && ((manual.DTE_DEADLINE__c == '' || manual.DTE_DEADLINE__c == undefined) || (newparam.CR702_Checklist__c == '' || newparam.CR702_Checklist__c == undefined))) {
            if(newparam.CR702_TEXT__c != null && (manual.DTE_DEADLINE__c == '' || manual.DTE_DEADLINE__c == undefined) ) {
                helper.toastMessage('Error','Please provide all the Mandatory Information.');
            } else if(newparam.CR702_TEXT__c != null) {
                helper.updateItem(component, event, helper);
            } else {
                helper.toastMessage('Error','Please provide all the Mandatory Information.');
            }
        } else if((newparam.NME_CORSPD__c == 'CR114')) {          
            
            if( $A.util.isEmpty(newparam.IDN_CLIENT__c) || $A.util.isEmpty(newparam.IDN_CASE__c)) {
                
                helper.toastMessage('Error','Please provide all the Mandatory Information.');
            } else {
                helper.updateItem(component, event, helper);
            }
        } else if((newparam.NME_CORSPD__c == 'CR108')) {
            if ( newparam.IDN_CASE__c != null ) {
                helper.updateItem(component, event, helper);
            } else {
                helper.toastMessage('Error','Please provide all the Mandatory Information.');
            }
        } else if(newparam.NME_CORSPD__c == 'CR207') {
            if (newparam.IDN_ADJMT__c != null) {
                if(newparam.IDN_PROVR__c == null && newparam.IDN_CASE__c == null) {
                    helper.toastMessage('Error','Please provide valid Case ID/Provider ID and associated Adjustment ID.');
                } else {
                    // Added below check by Rishav for CCCAP-4245
                    if(newparam.IDN_CASE__c != null && newparam.IDN_CLIENT__c == null) {
                        helper.toastMessage('Error','Please provide all the Mandatory Information.');
                    } else {
                        helper.updateItem(component, event, helper);
                    }
                }  
            } else {
                helper.toastMessage('Error','Please provide valid Case ID/Provider ID and associated Adjustment ID.');
            }
        } else if((newparam.NME_CORSPD__c == 'CR212')) {
            if ( newparam.IDN_CASE__c != null && newparam.CR212_Checklist__c) {
                helper.updateItem(component, event, helper);
            } else {
                helper.toastMessage('Error','Please provide all the Mandatory Information.');
            }
        } else if(newparam.NME_CORSPD__c == 'CR110') { // Added this else if section by Rishav for CCCAP-2213
            var isFormValid = true;
            if (!newparam.IDN_CASE__c || !newparam.IDN_CLIENT__c 
                || !newparam.Disqualification_Begin_Date__c || !newparam.Contact_Phone_Number__c 
                || !newparam.Disqualification_Hearing_Date__c || !newparam.Number_of_Occurrences__c)
                isFormValid = false;
            if(!newparam.Disqualification_End_Date__c && component.get("v.DQEndDateRequired"))
                isFormValid = false;
            if(isFormValid){
                helper.updateItem(component, event, helper);
            } else {
                helper.toastMessage('Error','Please enter all the Mandatory Information');
            }
        } else if((newparam.NME_CORSPD__c != "choose one") && ((newparam.IDN_CASE__c != null) || (newparam.IDN_PROVR__c != null) && (newparam.CDE_COUNTY__c != null) && (newparam.CDE_COUNTY__c != ' '))) {
            helper.updateItem(component, event, helper);
        } else {
            helper.toastMessage('Error','Please provide all the Mandatory Information.');
        }
    },
    
    hideProvider : function(component,event,helper) {
        console.log('hideProvider');
        var newparam = component.get("v.param");
        if(newparam.IDN_CASE__c != null) {
            component.set('v.cidbooleanCase', false);
            component.set('v.cr207ProviderReq', false);
            component.set('v.cr207CaseReq', true);
            component.set('v.pidbooleanProvider', true);    
        } else {
            component.set('v.cr207CaseReq', false);
            component.set('v.cr207ProviderReq', false);
            component.set('v.cidbooleanCase', false);
            component.set('v.pidbooleanProvider', false);     
        }  
    },
    
    hideCase : function(component,event,helper) {
        console.log('hideCase');
        var newparam = component.get("v.param");
        if(newparam.IDN_PROVR__c != null ) {
            component.set('v.cr207CaseReq', false);
            component.set('v.cidbooleanCase', true);
            component.set('v.pidbooleanProvider', false);
            component.set('v.cr207ProviderReq', true);
        } else {
            component.set('v.cr207CaseReq', false);
            component.set('v.cr207ProviderReq', false);
            component.set('v.cidbooleanCase', false);
            component.set('v.pidbooleanProvider', false);   
        }
    },
    
    // Added by Rishav for CCCAP-2769
    validateAndUpdateDates : function(component, event, helper) {
        if(component.get("v.param.Disqualification_Begin_Date__c")){
            helper.validateDQBeginDate(component, event, helper);
        }
        helper.updateDQEndDate(component, event, helper);
    }
    
})