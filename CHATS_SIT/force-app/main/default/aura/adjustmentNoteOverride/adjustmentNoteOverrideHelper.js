({
    doSetHelpText : function(component, event, helper) {
        var adjRec = component.get("v.adjRec");
        if(adjRec!= null && adjRec!= undefined && adjRec.CDE_TYPE_ADJMT__c=='1'){
            component.set("v.helpText", $A.get("$Label.c.adjtNoteHelpTextClaim"));
        }else if (adjRec!= null && adjRec!= undefined && adjRec.CDE_TYPE_ADJMT__c=='2'){
            component.set("v.helpText", $A.get("$Label.c.adjtNoteHelpTextRecovery"));
        }
    },
    doFinish : function(component, event, helper) {
        var inputComponents = component.find('input-field');
        var areAllFieldsValid = true;
        if(inputComponents){
            if(inputComponents.length>0){
                areAllFieldsValid = component.find('input-field').reduce(function (validSoFar, inputComponents) {
                    inputComponents.showHelpMessageIfInvalid();
                    return validSoFar && inputComponents.get('v.validity').valid;
                }, true);
            }else{
                if(component.find('input-field')){
	                component.find('input-field').showHelpMessageIfInvalid();
	                areAllFieldsValid =component.find('input-field').get('v.validity').valid;
                }
            }
        }
        debugger;
        if(areAllFieldsValid){
        helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                        function(response){
                                            component.set("v.adjNoteRec", helper.merge(component.get("v.adjNoteRec"),response.objectData.upsertedRecords[0]));
                                            if(component.get("v.fromAdjustmentFlow")){
                                                helper.fireToast("dismissible","success","Success!","Adjustment Note Created Successfully");
                                            	helper.closeModal(component, event, helper);    
                                            }
                                            else{
                                                helper.redirectToRecord(component.get("v.adjNoteRec").Id);
                                                }
                                        }, {'lstSObject':[component.get("v.adjNoteRec")],
                                            "isFinalStep":true
                                           }, false, null);
        }
    },
    doCancel : function(component, event, helper) {
        if(component.get("v.fromAdjustmentFlow")){
            helper.closeModal(component, event, helper);
        }else{
          window.history.back();
        }  
    },
    closeModal : function(component, event, helper){
        component.find("modalOverlay").notifyClose();
        var appEvent = $A.get("e.c:closeModal");
        appEvent.fire(); 
    }
})