({
	getInitData : function(component) {
        component.set("v.showSpinner", true);
        var getFielDefinitionAction = component.get("c.getFieldDefinition");
        getFielDefinitionAction.setParams({
            lstObjectToField : component.get("v.fieldNames")
        });
        getFielDefinitionAction.setCallback(this, function(response){
             if(response.getState()=='SUCCESS') {
                var fieldDefinitions = response.getReturnValue();
                var sectionInformation = component.get("v.sectionInformation"); 
                var sectionBreakerPoint = 0;
                for(var i=0;i<fieldDefinitions.length;i++){
                    var fieldDefinition = fieldDefinitions[i];
                    if(!$A.util.isEmpty(sectionInformation[fieldDefinition.fieldAPIName])){
                        fieldDefinition.preSectionName = sectionInformation[fieldDefinition.fieldAPIName];
                        if(i!=0 && sectionBreakerPoint%2==0){
                            fieldDefinition.sectionBreakerPoint = true;
                            sectionBreakerPoint = 0;
                        }else{
                            sectionBreakerPoint++;
                        }
                    }
                    if(!$A.util.isEmpty(fieldDefinition.referenecedObjectName) && component.get("v.sObjectName")==fieldDefinition.referenecedObjectName){
                        var caseIndividual = component.get("v.caseIndividual");
                        caseIndividual[fieldDefinition.fieldAPIName] = component.get("v.recordId");
                    }
                }
                component.set("v.fieldDefinition",fieldDefinitions);
                this.includeRequiredFieldInFieldDefinition(component);
                this.includeReadOnlyInFieldDefinition(component);
                               if(response.getReturnValue()) {
                    var receivedMap = response.getReturnValue();
                    var dataString = JSON.stringify(receivedMap);
                    if(!$A.util.isEmpty(component.get("v.parentId"))){
                        var getDataOnLoad = component.get("c.getDataOnLoadInCHATS");
                        getDataOnLoad.setParams({
                            fieldList: dataString,
                            sObjectId: component.get("v.parentId")
                        });
                        getDataOnLoad.setCallback(this, function(response){
                            component.set("v.showSpinner", false);
                            component.set("v.caseIndividual", response.getReturnValue());
                            if(!$A.util.isEmpty(response.getReturnValue().OwnerId)){
                                component.set("v.ownerId", response.getReturnValue().OwnerId);
                            }
                            this.includeReadOnlyInFieldDefinition(component);
                            component.set("v.initDataLoaded",true);
                        });
                        $A.enqueueAction(getDataOnLoad);
                    } else{
                        var userId = $A.get("$SObjectType.CurrentUser.Id");
                        component.set("v.caseIndividual.OwnerId",userId);
                        component.set("v.showSpinner", false);
                        component.set("v.initDataLoaded",true);
                    }
                }                  
            }
            else if(response.getState()=='ERROR') {
            }
        });
        $A.enqueueAction(getFielDefinitionAction);
        
    },
    callServerAndHandleError : function(cmp, method, callback, params, cacheable, successMessage) {
        cmp.set("v.pageMessages",[]);
        cmp.set("v.fieldValidationErrors",[]);
        cmp.set("v.messageType",null);
        this.callServer(cmp, method, function(response){
            // pass returned value to callback function
            if(response.isSuccessful==true){
                callback.call(this,response);
                if(successMessage && successMessage!=null){
                    cmp.set("v.pageMessages",[successMessage]);
                    cmp.set("v.messageType","success");
                }
            }else{
                var pageMessages = [response.errorMessage];
                var lstAPXFieldValidationError = response.lstAPXFieldValidationError;
                if(lstAPXFieldValidationError){
                    var lstOnlyAPXFieldValidationError = [];
                    for(var i=0;i<lstAPXFieldValidationError.length;i++){
                        if(lstAPXFieldValidationError[i].isTopOfPageError==true){
                            pageMessages.push(lstAPXFieldValidationError[i].errorMessage);
                        }else{
                            lstOnlyAPXFieldValidationError.push(lstAPXFieldValidationError[i]);
                        }
                    }
                    cmp.set("v.fieldValidationErrors",lstOnlyAPXFieldValidationError);
                }
                cmp.set("v.pageMessages",pageMessages);
                cmp.set("v.messageType","error");
            }
        }, params, cacheable);
    },
    includeRequiredFieldInFieldDefinition : function(component) {
        var requiredFields = component.get("v.requiredFields");
        var fieldDefinitions = component.get("v.fieldDefinition");
        var requiredFieldsList = requiredFields;
        fieldDefinitions.forEach(function(fieldDefinition){
            var indexOfCurrValue = requiredFieldsList.indexOf(fieldDefinition.objectName+'.'+fieldDefinition.fieldAPIName);
            if(indexOfCurrValue>=0) {
                fieldDefinition['required']=true;
            }else{
                fieldDefinition['required']=false;
            }
        });
        component.set("v.fieldDefinition",fieldDefinitions);
    },
    includeReadOnlyInFieldDefinition : function(component) {
        var readOnlyFields = ['T_SBSD_CASE_INDIV__c.Name'];
        var userData = component.get("v.userData");
        var parentId = component.get("v.parentId");
       
        var caseIndividual = component.get("v.caseIndividual");
        if(!$A.util.isEmpty(caseIndividual) && caseIndividual.DTE_END_EFFV__c != null){
            readOnlyFields.push('T_SBSD_CASE_INDIV__c.DTE_END_EFFV__c'); 
            readOnlyFields.push('T_SBSD_CASE_INDIV__c.Individual_Status__c'); 
            readOnlyFields.push('T_SBSD_CASE_INDIV__c.IDN_CASE__c'); 
            readOnlyFields.push('T_SBSD_CASE_INDIV__c.IDN_CLIENT__c'); 
            readOnlyFields.push('T_SBSD_CASE_INDIV__c.DTE_BEGIN_EFFV__c'); 
            component.set("v.isUpdatable",false);
        }
        /* if($A.util.isEmpty(userData) || (userData.userProfileName!='CHATS System Administrator' ||
           userData.userProfileName!='CHATS System Administrator'|| 
           userData.userProfileName!='CHATS System Administrator' || 
           userData.userProfileName!='CHATS System Administrator')){
	    	readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.CDE_TYPE_STATUS__c');  
        } */
        var fieldDefinitions = component.get("v.fieldDefinition");
        fieldDefinitions.forEach(function(fieldDefinition){
            var indexOfCurrValue = readOnlyFields.indexOf(fieldDefinition.objectName+'.'+fieldDefinition.fieldAPIName);
            if(indexOfCurrValue>=0) {
                fieldDefinition['readOnly']=true;
            }else{
                fieldDefinition['readOnly']=false;
            }
        });
        component.set("v.fieldDefinition",fieldDefinitions);
    },
    validateIndivAgeHlp : function(component , event, helper){
        var isValid = true;
        var getFielDefinitionAction = component.get("c.validateIndivAge");
        getFielDefinitionAction.setParams({
            'caseIndivList':[component.get("v.caseIndividual")]
        });
        getFielDefinitionAction.setCallback(this, function(response){
            if(response.getState()=='SUCCESS') {
                var res = response.getReturnValue();
                 if(res.objectData.IndivAgeLessThan21){
                    component.set("v.inValidAge",res.objectData.IndivAgeLessThan21);
                    }
                 if(res.objectData.primaryCareTakerExist){
                    var alreadyPrimaryCareTaker = "You have selected to change the Primary Caretaker on this case. Select Yes if you are sure you would like to continue.";
                    component.set("v.alreadyPrimaryCareTaker",alreadyPrimaryCareTaker);
                     isValid = false;
                     if(res.objectData.IndivAgeLessThan21){
                    component.set("v.inValidAge",res.objectData.IndivAgeLessThan21);
                    }
                    component.find("alreadyPrimaryCareTk").openModal();
                     return isValid;
                    
                 }else if(res.objectData.IndivAgeLessThan21){
                     isValid = false;
                     component.find("inValidIndivAge").openModal();
                     return isValid;
                     
                 }
                else{
                    isValid = true;
                    this.callServerIfValid(component, event, helper);
                }
            }
            else if(response.getState()=='ERROR') {
                return false;
            }
        });
        $A.enqueueAction(getFielDefinitionAction);
        
    },
    callServerIfValid: function(component, event, helper){
        helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                                    function(response){
                                                        helper.redirectToRecord(response.objectData.upsertedRecords[0].Id);
                                                        helper.fireToast('dismissible', 'success', '', 'Record has been successfully saved.');
                                                    }, {'lstSObject':[component.get("v.caseIndividual")],"isFinalStep":true}, false, null);
    },
})