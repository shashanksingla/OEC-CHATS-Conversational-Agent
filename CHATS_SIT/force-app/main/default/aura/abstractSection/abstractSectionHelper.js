({
    handleFieldLevelValidation : function(component) {
        var lstAPXFieldValidationError = component.get("v.fieldValidationErrors");
        var index = component.get("v.index");
        var errorComponentIds = component.get("v.errorComponentIds");
        var newErrorComponentIds = [];
        var pageMessagesMissingAuraIds = [];
        if(!$A.util.isEmpty(lstAPXFieldValidationError)){
        for(var i=0;i<lstAPXFieldValidationError.length;i++){
            if(!index || index==lstAPXFieldValidationError[i].index){
                var errorComponent = component.find(lstAPXFieldValidationError[i].sObjectName+"-"+lstAPXFieldValidationError[i].fieldName);
                if(errorComponent){
                    errorComponent.set("v.message",lstAPXFieldValidationError[i].errorMessage);
                    newErrorComponentIds.push(lstAPXFieldValidationError[i].sObjectName+"-"+lstAPXFieldValidationError[i].fieldName);
                }else{
                    pageMessagesMissingAuraIds.push(lstAPXFieldValidationError[i].errorMessage);
                }
            }
        }
    }
        component.set("v.pageMessagesMissingAuraIds",pageMessagesMissingAuraIds);
        for(var i=0;i<errorComponentIds.length;i++){
            if(newErrorComponentIds.indexOf(errorComponentIds[i]) < 0){
                var errorComponent = component.find(errorComponentIds[i]);
               
                if(errorComponent){
                    errorComponent.set("v.message",null);
                    
                }
            }
        } 
        component.set("v.errorComponentIds",newErrorComponentIds);
    },
    validateCurrentPage : function(cmp){
        var inputComponents = cmp.find('input-field');
        var areAllFieldsValid = true;
        if(inputComponents){
            if(inputComponents.length>0){
                areAllFieldsValid = cmp.find('input-field').reduce(function (validSoFar, inputComponents) {
                    inputComponents.showHelpMessageIfInvalid();
                    return validSoFar && inputComponents.get('v.validity').valid;
                }, true);
            }else{
                if(cmp.find('input-field')){
	                cmp.find('input-field').showHelpMessageIfInvalid();
	                areAllFieldsValid =cmp.find('input-field').get('v.validity').valid;
                }
            }
        }
        var isRecordValid = this.checkCustomValidations(cmp);
        var overallResult = areAllFieldsValid && isRecordValid;
        
		cmp.set("v.isCurrentPageValid",overallResult);
        return overallResult;
    },
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        
        return true;
    },
  setFieldValueForReport : function(component) {
        debugger;
        var dataValue = component.get("v.initData");
        if(dataValue[component.get("v.associatedObjName")]) {
            if(component.get("v.fieldType")=='REFERENCE') {
                dataValue[component.get("v.associatedObjName")][0][component.get("v.fieldAPIName")] = component.get("v.lookupFieldValue");
            }else {
                dataValue[component.get("v.associatedObjName")][0][component.get("v.fieldAPIName")] = component.get("v.fieldValue");
            }
        } else {
            if(component.get("v.fieldType")=='REFERENCE') {
                dataValue[component.get("v.associatedObjName")] = [{}];
                dataValue[component.get("v.associatedObjName")][0][component.get("v.fieldAPIName")] = component.get("v.lookupFieldValue");
            }else {
                dataValue[component.get("v.associatedObjName")] = [{}];
                dataValue[component.get("v.associatedObjName")][0][component.get("v.fieldAPIName")] = component.get("v.fieldValue");
            }
        }
        
        if(component.get("v.isControllingField")) {
            component.set("v.isControllingFieldUpdated",true);
        }else{
            component.set("v.isControllingFieldUpdated",false);
        }
        component.set("v.initData", dataValue);
    },

    /*
     Author: Rishav Maji
     Description: Generic method to show toast alert messeges as green Success, yellow Warning & red Error
     I/O: type = success / warning / error, messege = custom string
   	*/ 
       showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        if(type == 'error'){
            toastEvent.setParams({
                "title": "Error!",
                "type":'error',
                "message": message
            });
        }
        if(type == 'success'){
            toastEvent.setParams({
                "title": "Success!",
                "type":'success',
                "message": message
            });
        }
        if(type == 'warning'){
            toastEvent.setParams({
                "title": "Warning!",
                "type":'warning',
                "message": message
            });
        }
        toastEvent.fire();
    }
})