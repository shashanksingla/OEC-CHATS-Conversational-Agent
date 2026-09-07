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
                    if(fieldDefinition.fieldAPIName=='CDE_STATUS_ADJMT__c'){
                        fieldDefinition.fieldUtilityPicklistFieldName = 'Restricted_Adjustment_Status__c';
                    }else if(fieldDefinition.fieldAPIName=='CDE_TYPE_ADJMT__c'){
                        fieldDefinition.fieldUtilityPicklistFieldName = 'Restricted_Adjustment_Type__c';
                    }
                    
                    if(!$A.util.isEmpty(fieldDefinition.referenecedObjectName) && component.get("v.sObjectName")==fieldDefinition.referenecedObjectName){
                        
                        var adjustment = component.get("v.adjustment");
                        adjustment[fieldDefinition.fieldAPIName] = component.get("v.recordId");
                        //component.set("v.adjustment",adjustment);
                    }
                }
                component.set("v.fieldDefinition",fieldDefinitions);
                this.includeRequiredFieldInFieldDefinition(component);
                
               
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
                            
                            component.set("v.adjustment", response.getReturnValue());
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
    }
})