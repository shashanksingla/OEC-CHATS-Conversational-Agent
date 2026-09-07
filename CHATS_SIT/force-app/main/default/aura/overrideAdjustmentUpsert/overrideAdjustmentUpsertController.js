({
    doInit : function(component,event,helper) {
        if(component.get("v.objectName")==component.get("v.sObjectName")){
            component.set("v.parentId", component.get("v.recordId"));
        }
        helper.getInitData(component);
    },
    doFinish : function(component, event, helper) {
        debugger;
        var dynamicFormGenerators = component.find("dynamicFormGenerator");
        var isValid = true;
        dynamicFormGenerators.forEach(function(dynamicFormGenerator){
            var resultFromChild = dynamicFormGenerator.validateAndSetData();
            isValid = isValid && resultFromChild;
        });
        if(isValid==true){
            helper.callServerAndHandleError(component,"c.checkCountyWithUserCounty", 
                                            function(response){
                                                if(response.objectData.countyMatched==true){
                                                    helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                                                                    function(response){
                                                                                        helper.redirectToRecord(response.objectData.upsertedRecords[0].Id);
                                                                                        helper.fireToast('dismissible', 'success', '', 'Record has been successfully saved.');
                                                                                    }, {'lstSObject':[component.get("v.adjustment")],"isFinalStep":true}, false, null);
                                                }else{
                                                    //component.find("countyDifferentThanUserCounty").openModal();
                                                    component.set("v.pageMessages",'The adjustment that you are trying to create is with '+response.objectData.countyName+' county. This does not match your assigned county(ies).');
                                                    component.set("v.messageType","error");
                                                }
                                            }, {'countyId':component.get("v.adjustment.CDE_COUNTY__c")}, false, null);
        }else{
            component.set("v.pageMessages",[$A.get("$Label.c.ERRORS_ON_THIS_PAGE")]);
            component.set("v.messageType","error");
        }
    },
    doHideCountyDifferentThanUserCounty : function(component, event, helper){
        component.find("countyDifferentThanUserCounty").hideConfirmModal();
        helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                        function(response){
                                           
                                            helper.redirectToRecord(response.objectData.upsertedRecords[0].Id);
                                            helper.fireToast('dismissible', 'success', '', 'Record has been successfully saved.');
                                        }, {'lstSObject':[component.get("v.adjustment")],"isFinalStep":true}, false, null);
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
    }
})