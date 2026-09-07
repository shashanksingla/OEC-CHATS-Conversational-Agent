({
    doInit : function(component,event,helper) {
        if(component.get("v.objectName")==component.get("v.sObjectName")){
            component.set("v.parentId", component.get("v.recordId"));
        }
        var fetchUserdataAction = component.get("c.fetchUserdata");
        fetchUserdataAction.setCallback(this, function(response){
            var lsr = response.getReturnValue();
            if(lsr.isSuccessful){
                component.set("v.userData",lsr.objectData);
            }
            helper.getInitData(component);
        });        
        $A.enqueueAction(fetchUserdataAction);
    },
    doFinish : function(component, event, helper) {
        var dynamicFormGenerators = component.find("dynamicFormGenerator");
        var isValid = true;
        dynamicFormGenerators.forEach(function(dynamicFormGenerator){
            var resultFromChild = dynamicFormGenerator.validateAndSetData();
            isValid = isValid && resultFromChild;
        });
        // Validate the Indiv Age
        if(isValid==true){
            var caseIndividual = component.get("v.caseIndividual");
            console.log('caseIndividual--'+JSON.stringify(caseIndividual));
            if(!$A.util.isEmpty(caseIndividual) && caseIndividual.Individual_Status__c=='PC'){
                caseIndividual.IND_CRTKR__c = true; // CCCAP-13633
                helper.validateIndivAgeHlp(component, event, helper); 
                
            }else{
                if(isValid==true){
                    helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                                    function(response){
                                                        helper.redirectToRecord(response.objectData.upsertedRecords[0].Id);
                                                        helper.fireToast('dismissible', 'success', '', 'Record has been successfully saved.');
                                                    }, {'lstSObject':[component.get("v.caseIndividual")],"isFinalStep":true}, false, null);
                    
                }else{
                    component.set("v.pageMessages",[$A.get("$Label.c.ERRORS_ON_THIS_PAGE")]);
                    component.set("v.messageType","error");
                }
            }
        }else{
            component.set("v.pageMessages",[$A.get("$Label.c.ERRORS_ON_THIS_PAGE")]);
            component.set("v.messageType","error");
        }
        // End
        
    },
    doHideCountyDifferentThanUserCounty : function(component, event, helper){
        component.find("countyDifferentThanUserCounty").hideConfirmModal();
        helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                        function(response){
                                            helper.redirectToRecord(response.objectData.upsertedRecords[0].Id);
                                            helper.fireToast('dismissible', 'success', '', 'Record has been successfully saved.');
                                        }, {'lstSObject':[component.get("v.caseIndividual")],"isFinalStep":true}, false, null);
    },
    doHandleFieldValidationErrors : function(component, event, helper){
        var fieldValidationErrors = component.get("v.fieldValidationErrors");
        var newErrorComponentIds = [];
        var errorComponentIds = component.get("v.errorComponentIds");
        var errorMessageComps = component.find("errorMessageComp");
        if(!$A.util.isEmpty(fieldValidationErrors) && fieldValidationErrors.length>0){
            for(var i=0;i<fieldValidationErrors.length;i++){
                for(var j=0;j<errorMessageComps.length;j++){
                    if(errorMessageComps[j].get("v.objectToFieldValue")==fieldValidationErrors[i].sObjectName+"-"+fieldValidationErrors[i].fieldName){
                        errorMessageComps[j].set("v.errorMessage",fieldValidationErrors[i].errorMessage);
                        newErrorComponentIds.push(fieldValidationErrors[i].sObjectName+"-"+fieldValidationErrors[i].fieldName);
                    }
                }
            }
        }
        for(var i=0;i<errorComponentIds.length;i++){
            if(newErrorComponentIds.indexOf(errorComponentIds[i]) < 0){
                errorMessageComps.forEach(function(errorMessageComp){
                    if(errorMessageComp.get('v.objectToFieldValue')==errorComponentIds[i]){
                        errorMessageComp.set("v.errorMessage",null);
                    }
                });
            }
        } 
        component.set("v.errorComponentIds",newErrorComponentIds);
    },
    doCancel : function(component, event, helper){
        window.history.back();
    },
    processWithCaseIndivSave : function(component, event, helper){
        component.find("alreadyPrimaryCareTk").hideConfirmModal();
        if(component.get("v.inValidAge")){
            component.find("inValidIndivAge").openModal();
        }
        else{
            helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                            function(response){
                                                helper.redirectToRecord(response.objectData.upsertedRecords[0].Id);
                                                helper.fireToast('dismissible', 'success', '', 'Record has been successfully saved.');
                                            }, {'lstSObject':[component.get("v.caseIndividual")],"isFinalStep":true}, false, null);
        }
        
    },
    processWithCaseIndivSaveFinal : function(component, event, helper){
        component.find("inValidIndivAge").hideConfirmModal();
        
        helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                        function(response){
                                            helper.redirectToRecord(response.objectData.upsertedRecords[0].Id);
                                            helper.fireToast('dismissible', 'success', '', 'Record has been successfully saved.');
                                        }, {'lstSObject':[component.get("v.caseIndividual")],"isFinalStep":true}, false, null);
    }
    
})