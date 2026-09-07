({
    doInit : function(component, event, helper) {
        helper.handleBeginDateUpdate(component);
        var isCreate = component.get("v.isCreate");
        if(!isCreate) {
            var authRecClone = JSON.parse(JSON.stringify(component.get("v.authRecClone")));
            var authRec = JSON.parse(JSON.stringify(component.get("v.authRec")));
            var authRecId = component.get("v.authRec").Id;
            component.set("v.authRecId",authRecId);
            if(!$A.util.isEmpty(authRec.IDN_SLOT_CONTRACT__c)){
                component.set("v.mandatory", true);
            }
            else{
                component.set("v.mandatory", false);
            }
            if(!$A.util.isEmpty(authRecClone.Id)){
                authRec.IDN_SLOT_CONTRACT__c = authRecClone.IDN_SLOT_CONTRACT__c;
                authRec.DTE_BEGIN_SLOT__c = authRecClone.DTE_BEGIN_SLOT__c;
            }
            component.set("v.authRecClone", authRec);
            
            helper.getRateTypeOptionsVal(component, event, helper); 
            helper.validateIndicatorInEditFlow(component, event, helper);
            helper.setTransFeeRestriction(component, event, helper); // Added by Rishav for CCCAP-2618
            helper.getSCAssociations(component, event, helper);
            helper.populateSlotFields(component, event, helper);
        }
    },    
    doSchedule:function(component, event, helper) {
        /*
        if(component.get("v.validatedChild") && component.get("v.isFirstRecurrenceEntered")) {
            component.set("v.scheduleRecurrObj",{'sobjectType':'Auth_Schedule_Recurrence__c','Recur_Type__c':'','RecurDay__c':'','DTE_Begin_Date__c':'','DTE_End_Date__c':''});
            component.set("v.enterRecurrence",true);
        } else {
            var appEvent = $A.get("e.c:RecurrenceEvent");
            appEvent.setParams({"cmpValidated" : false});
            appEvent.fire(); 
        }
        */
        if(component.get("v.isReadOnly")){
            component.set("v.enterRecurrence",true);
        }else{
            var appEvent = $A.get("e.c:RecurrenceEvent");
        appEvent.setParams({"cmpValidated" : false});
        appEvent.fire();
        }
        
    },
    
    scheduleRecurrence:function(component, event, helper) {
        var params = event.getParam("arguments");
        if(params) {
            debugger;
            var cmpValidated = params.cmpValidated;
            var isEnterRecurrence = params.isEnterRecurrence;
            var isAuthFirstTime = params.isAuthFirstTime;
            var isAuthUpdated = params.isAuthUpdated;
            component.set("v.validatedChild",cmpValidated);
            component.set("v.isFirstRecurrenceEntered",isEnterRecurrence);
            component.set("v.isAuthFlowFirstTime",isAuthFirstTime);
            component.set("v.isAuthUpdatedInCreateFlow",isAuthUpdated);
        }
        var authRec =component.get("v.authRec");
        var beginDate =authRec.DTE_BEGIN_EFFV_AUTH__c;
        var endDate =authRec.DTE_END_EFFV_AUTH__c;
        var providerId = component.get("v.providerIdVal");
        var childId =authRec.IDN_CLIENT__c;
        var authRecId = authRec.Id;
        component.set("v.authRecId",authRecId);
        if(cmpValidated) {
            /*
            if((!isAuthFirstTime)&& isAuthUpdated){
                component.set("v.scheduleRecurr",[]);
            }
            */
            component.set("v.authBeginDate",beginDate);
            component.set("v.scheduleRecurrObj",{'sobjectType':'Auth_Schedule_Recurrence__c','Recur_Type__c':'','RecurDay__c':'','DTE_Begin_Date__c':'','DTE_End_Date__c':''});
            component.set("v.enterRecurrence",true);  
        }
    },
    
    handleFieldLevelValidation : function(component, event, helper) { 
        helper.handleFieldLevelValidation(component);
    },
    
    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
        //helper.validateAuthSlotBeginDate(component, event, helper);
    },
    
    getUpdatedProviderId : function(component, event, helper) {
        helper.handleBeginDateUpdate(component);
    },
    
    populateProviderId : function(component, event, helper) {
        var authRec = component.get('v.authRec');
        var providerFiscalAgreementRec= component.get('v.providerRec');
        if(providerRec!=null) {
            authRec.IDN_PROVR__c= providerRec.ID_SERVICE__c;
            component.set("v.authRec", authRec);
        }
    },
    populateSCAssId : function(component, event, helper) {
        helper.populateSlotFields(component, event, helper);
    },
    
    populateRateTypes : function(component, event, helper) {
        helper.getRateTypeOptionsVal(component);
    },
    
    validateProviderId : function(component, event, helper) {
        var providerId = component.get("v.providerIdVal");
        if($A.util.isEmpty(providerId)) {
            component.set("v.rateTypeOptions",[]);
        } else {
            helper.validateProviderIdVal(component, event, helper);
            helper.getSCAssociations(component, event, helper);
        }
    },
    
    getRateTypes :function(component, event, helper) {
        component.set("v.isModifiedAfterChange",false);
        var authRec =component.get("v.authRec");
        var beginDate =authRec.DTE_BEGIN_EFFV_AUTH__c;
        var providerId = component.get("v.providerIdVal");
        var childId =authRec.IDN_CLIENT__c;
        
        if($A.util.isEmpty(beginDate)) {
            component.set("v.rateTypeOptions",[]);
        } else if($A.util.isEmpty(childId)){
            component.set("v.rateTypeOptions",[]);
        } else if(providerId != '' && providerId != undefined && beginDate !='' && beginDate != undefined) {
            var isValidProvider = component.get("v.isInvalidProvider");
            helper.validateProviderBasedOnBeginDt(component, event, helper);
            if(isValidProvider) {
                // helper.validateProviderIdVal(component, event, helper);
            } else {
                // helper.getRateTypeOptionsVal(component, event, helper);
            }
        }
        
        var oldValue = event.getParam("oldValue");
        var newValue = event.getParam("value");
        
        if(!$A.util.isEmpty(beginDate)){
            helper.validateIndicatorBasedOnBeginDt(component, event, helper);
          /*  if(component.get("v.isCreate") && !$A.util.isEmpty(oldValue) && !$A.util.isEmpty(newValue) && typeof oldValue == 'object' && !$A.util.isEmpty(oldValue.DTE_BEGIN_EFFV_AUTH__c) && !$A.util.isEmpty(newValue.DTE_BEGIN_EFFV_AUTH__c) && oldValue.DTE_BEGIN_EFFV_AUTH__c != newValue.DTE_BEGIN_EFFV_AUTH__c){
                var currentBeginDate = newValue.DTE_BEGIN_EFFV_AUTH__c;
                var formattedBeginDate;
                if (currentBeginDate.indexOf('T') > -1) {
                var beginDateTemp = currentBeginDate.split("T");
                if(!$A.util.isEmpty(beginDateTemp)){
                    formattedBeginDate =beginDateTemp[0];
                }
                }else{
                    formattedBeginDate=currentBeginDate;
                }
                if(oldValue.DTE_BEGIN_EFFV_AUTH__c !=formattedBeginDate){
                    if(!$A.util.isEmpty(component.get("v.scheduleRecurr"))){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Warning!",
                            "type": 'warning',
                            "message": "Authorization Begin date has been changed, please review the existing recurrence patterns."
                        });
                        toastEvent.fire();
                    }  
                }
                
            }
            
            else  if(component.get("v.isCreate") && !$A.util.isEmpty(oldValue) && !$A.util.isEmpty(newValue) && typeof oldValue == 'string'  && oldValue != newValue){
                if(!$A.util.isEmpty(component.get("v.scheduleRecurr"))){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Warning!",
                        "type": 'warning',
                        "message": "Authorization Begin date has been changed, please review the existing recurrence patterns."
                    });
                    toastEvent.fire();
                }
            }*/
            /*
            if(component.get("v.isCreate")){
                helper.determineEligibility(component, event, helper);
            } 
            */
            helper.checkChildDisability(component, event, helper);
            helper.getSCAssociations(component, event, helper);
            /*
            if(component.get("v.isCreate") && !$A.util.isEmpty(oldValue) && !$A.util.isEmpty(newValue) && !$A.util.isEmpty(oldValue.DTE_BEGIN_EFFV_AUTH__c) && !$A.util.isEmpty(newValue.DTE_BEGIN_EFFV_AUTH__c) && oldValue.DTE_BEGIN_EFFV_AUTH__c != newValue.DTE_BEGIN_EFFV_AUTH__c){
                helper.setChildStateOptionsHlp(component, event, helper);
            }else if(component.get("v.isCreate") && !$A.util.isEmpty(oldValue) && !$A.util.isEmpty(newValue) && $A.util.isEmpty(oldValue.DTE_BEGIN_EFFV_AUTH__c) &&  !$A.util.isEmpty(newValue.DTE_BEGIN_EFFV_AUTH__c) ){
                helper.setChildStateOptionsHlp(component, event, helper);
            }else if(component.get("v.isCreate") && $A.util.isEmpty(oldValue) && !$A.util.isEmpty(newValue) ){
                helper.setChildStateOptionsHlp(component, event, helper);
            }else if(component.get("v.isCreate") && !$A.util.isEmpty(oldValue) && !$A.util.isEmpty(newValue) && oldValue != newValue && $A.util.isEmpty(oldValue.DTE_BEGIN_EFFV_AUTH__c) ){
                helper.setChildStateOptionsHlp(component, event, helper);
            }
            */
        }
    },
    
    getRateTypesBasedOnChild :function(component, event, helper) {
        component.set("v.isModifiedAfterChange",false);
        var authRec =component.get("v.authRec");
        var beginDate =authRec.DTE_BEGIN_EFFV_AUTH__c;
        var providerId = component.get("v.providerIdVal");
        var childId =authRec.IDN_CLIENT__c;
        
        if($A.util.isEmpty(beginDate)) {
            component.set("v.rateTypeOptions",[]);
        } else if($A.util.isEmpty(childId)) {
            component.set("v.rateTypeOptions",[]);
        } else if(providerId != '' && providerId != undefined && beginDate !='' && beginDate != undefined) {
            helper.getRateTypeOptionsVal(component, event, helper);
        }
        /*
        if(component.get("v.isCreate")){
            helper.determineEligibility(component, event, helper);
        }
        */
        helper.checkChildDisability(component, event, helper);
     },
    
    checkChildDisabilityCtr : function(component, event, helper){
        helper.checkChildDisability(component, event, helper);
        /*
        if(component.get("v.isCreate")){
            helper.determineEligibility(component, event, helper);
        }
        */
    },
    chkRelativeStatus : function(component, event, helper){
        var authRec = component.get("v.authRec");
        var relativeStat = authRec.CDE_REL_PROVR__c;
        if(relativeStat != '2' && relativeStat != '4'){
            component.set("v.authRec.CDE_PRO_REL_CHLD__c","");
            component.set("v.authRec.CDE_PROV_DIFF_RESI__c","");
        }
    },
    getProviderRelationship : function(component, event, helper){
        var authRec = component.get("v.authRec");
        var sibling = authRec.CDE_PRO_REL_CHLD__c;
        if(!sibling){
            component.set("v.authRec.CDE_PROV_DIFF_RESI__c","");
        }
    },
})