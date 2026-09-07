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
        debugger;
        var dynamicFormGenerators = component.find("dynamicFormGenerator");
        var isValid = true;
        dynamicFormGenerators.forEach(function(dynamicFormGenerator){
           
            var resultFromChild = dynamicFormGenerator.validateAndSetData();
            isValid = isValid && resultFromChild;
        });
        if(isValid==true){
            var provideridd=component.get("v.providerFiscalAgreement.ID_SERVICE__c");
            var pfa = component.get("v.providerFiscalAgreement"); 
            if(pfa.Id==null || pfa.Id == '' || pfa.Id == undefined){
                component.set("v.isUpdate", false);
            }
            else if(pfa.CDE_TYPE_STATUS__c !='DFT'){
                component.set("v.isUpdate", true);
            }
            helper.callServerAndHandleError(component,"c.newFiscalAgreement", 
                                            function(response){
                                               
                                                helper.callServerAndHandleError(component,"c.checkCountyWithOwnerCounty", 
                                                                                function(response){
                                                                                    var countyMismatchMessage="";
                                                                                    var ownerChanged = false;
                                                                                    
                                                                                    if(component.get("v.ownerId") != component.get("v.providerFiscalAgreement.OwnerId")){
                                                                                        ownerChanged = true;
                                                                                    }
                                                                                    if(response.objectData.countyMatched == false && response.objectData.ownerCountyMatched == false){
                                                                                        countyMismatchMessage = 'The fiscal agreement that you are trying to create is with '+response.objectData.countyName+' county. This does not match your assigned county(ies)';
                                                                                        if(ownerChanged == true){
                                                                                            countyMismatchMessage += " and county(ies) of new owner.";
                                                                                        }else{
                                                                                            countyMismatchMessage += ".";
                                                                                        }
                                                                                        component.set("v.pageMessages",countyMismatchMessage);
                                                                                        component.set("v.messageType","error");
                                                                                    }else if(response.objectData.countyMatched == false){
                                                                                        countyMismatchMessage = 'The fiscal agreement that you are trying to create is with '+response.objectData.countyName+' county. This does not match your assigned county(ies).';
                                                                                        component.set("v.pageMessages",countyMismatchMessage);
                                                                                        component.set("v.messageType","error");
                                                                                    }else if(response.objectData.ownerCountyMatched == false && ownerChanged == true){
                                                                                        countyMismatchMessage = 'The fiscal agreement that you are trying to create is with '+response.objectData.countyName+' county. This does not match the county(ies) of new owner.';
                                                                                        component.set("v.pageMessages",countyMismatchMessage);
                                                                                        component.set("v.messageType","error");
                                                                                    }else{
                                                                                        helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                                                                                                        function(response){
                                                                                                                            helper.redirectToRecord(response.objectData.upsertedRecords[0].Id);
                                                                                                                            helper.fireToast('dismissible', 'success', '', 'Record has been successfully saved.');
                                                                                                                        }, {'lstSObject':[component.get("v.providerFiscalAgreement")],"isFinalStep":true}, false, null);
                                                                                    }
                                                                                }, {'countyId':component.get("v.providerFiscalAgreement.CDE_COUNTY__c"), 'ownerId':component.get("v.providerFiscalAgreement.OwnerId")}, false, null);
                                                
                                            }, {"providerId":provideridd,
                                                "isUpdate":component.get("v.isUpdate")}, false, null);
        }else{
            component.set("v.pageMessages",[$A.get("$Label.c.ERRORS_ON_THIS_PAGE")]);
            component.set("v.messageType","error");
        }
    },
    doHidecountyMismatch: function(component, event, helper){
        component.find("countyMismatch").hideConfirmModal();
        helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                        function(response){
                                            
                                            helper.redirectToRecord(response.objectData.upsertedRecords[0].Id);
                                            helper.fireToast('dismissible', 'success', '', 'Record has been successfully saved.');
                                        }, {'lstSObject':[component.get("v.providerFiscalAgreement")],"isFinalStep":true}, false, null);
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