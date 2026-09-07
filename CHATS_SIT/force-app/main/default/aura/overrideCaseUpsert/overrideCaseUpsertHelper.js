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
                    if(fieldDefinition.fieldAPIName=='CNT_CC_NEED_CHILD__c' || fieldDefinition.fieldAPIName=='CNT_SIZE_FAMILY__c' || fieldDefinition.fieldAPIName=='AMT_INCOME__c'){
                        fieldDefinition.usePlainValue = true;
                    }else{
                        fieldDefinition.usePlainValue = false;
                    }
                    if(!$A.util.isEmpty(sectionInformation[fieldDefinition.fieldAPIName])){
                        fieldDefinition.preSectionName = sectionInformation[fieldDefinition.fieldAPIName];
                        if(sectionBreakerPoint%2==0){
                            fieldDefinition.sectionBreakerPoint = true;
                            sectionBreakerPoint = 0;
                        }else{
                            sectionBreakerPoint++;
                        }
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
                            
                            component.set("v.caseRec", response.getReturnValue());
                            if(!$A.util.isEmpty(response.getReturnValue().OwnerId)){
                                component.set("v.ownerId", response.getReturnValue().OwnerId);
                            }
                            component.set("v.initDataLoaded",true);
                        });
                        $A.enqueueAction(getDataOnLoad);
                    } else{
                       
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
    //This method defines required fields if included in the requiredFields attribute of the component
    //Input parameter(s): component
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
        
        var readOnlyFields = component.get("v.readOnlyFields");
        
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
    }
})