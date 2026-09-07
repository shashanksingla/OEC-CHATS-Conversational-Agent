({
    doInit : function(component, event, helper) {
        component.set("v.selectedMonth","");
    },
    setFieldValue : function(component, event, helper) {
        if(component.get("v.fieldType") == 'PICKLIST'){
            component.set("v.fieldValue",component.get("v.picklistFieldValue"));
            helper.setFieldValueForReport(component);
	    var parentComponent = component.get("v.parent"); 
            parentComponent.disableField(component.get("v.fieldAPIName"), component.get("v.fieldValue"));
        }
        if(component.get("v.fieldType") == 'STRING' && component.get("v.fieldLabel") =='Zip Code'){
            var val=component.find("input-field").get('v.value');
            var inputCmp = component.find("input-field");
            if(!$A.util.isEmpty(val) && (isNaN(val) && val.length <=5)){
                inputCmp.setCustomValidity("Zip code must be a numeric value of length 5.");
            }else{
                inputCmp.set("v.validity",{'valid':true});
                inputCmp.setCustomValidity("");  
            }
            inputCmp.reportValidity();
        }
        if(component.get("v.fieldType") == 'REFERENCE'){
            component.set("v.fieldValue",component.get("v.lookupFieldValue"));
            var parentComponent = component.get("v.parent"); 
            parentComponent.disableField(component.get("v.fieldAPIName"), component.get("v.fieldValue"));
            helper.setFieldValueForReport(component);
        }
        if(component.get("v.fieldType") == 'Date'){
            component.set("v.fieldValue",component.get("v.dateValueStr"));
            helper.setFieldValueForReport(component);
        }
        if(component.get("v.fieldType") == 'MULTIPICKLIST'){
            component.set("v.fieldValue",component.get("v.multiPicklistFieldValue"));
            helper.setFieldValueForReport(component);
        }
        else{
          helper.setFieldValueForReport(component);  
        }
    },
    handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
		var validity = helper.validateCurrentPage(component);
        return validity;
    },
    checkCustomTextValidation :  function(component, event, helper) {
        if(component.get("v.fieldLabel") == 'SSN' || component.get("v.fieldLabel") == 'FEIN'){
            var parentComponent = component.get("v.parent"); 
            parentComponent.setProviderValFunc(component.get("v.fieldLabel"), component.get("v.fieldValue"));
        }
        helper.checkCustomTextValidationHlp(component);
    },
    validateMonthDate : function(component, event, helper) {
        var isValid = helper.validateMonthDateHlp(component, event, helper);
        return isValid;
    },
    validateDate : function(component, event, helper) {
        var isValid = helper.validateDateHlp(component, event, helper);
        return isValid;
    },
})