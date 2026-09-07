({
    /*    doInit : function(component, event, helper) {
        helper.getPicklistValues(component);
    },
    highlightError : function(component, event, helper) {
        
        if(component.get("v.required") == true && (component.get("v.value")=='' || component.get("v.value")==null)){
            $A.util.addClass(component.find("picklist"),"boxError");
            component.find("picklist").set("v.errors",["Please provide a value"]);
            component.set("v.validity",{'valid':false});
        }else{
            $A.util.removeClass(component.find("picklist"),"boxError");
            component.find("picklist").set("v.errors",[]);
            component.set("v.validity",{'valid':true});
        }
    }*/
    
    doInit : function(component, event, helper) {
        if(component.get("v.alreadyHasValues")==true){
	        var value = component.get("v.value");
            var options = component.get("v.options");
            /*
            options = options.concat(returnedPicklistValues.map(function(v) {
                return {
                    'label' : v.label,
                    'value' : v.value,
                    'class' : 'optionClass',
                    'selected' : v.value==value?true:false
                };
            }));   */             
            component.set('v.options', options);
        }else{
            helper.getPicklistValues(component);
        }
    },
    doNothing : function(component, event, helper) {
        
    },
    doUpdateOptions : function(component, event, helper) {
        var options = component.get('v.alreadyHasValues')?component.get("v.options"):component.get("v.allOptions");
        options = options ||[];
        for(var i=0;i<options.length;i++){
            if(component.get("v.value")==options[i].value){
                options[i].selected = true;
            }else{
                options[i].selected = false;
            }
        }
        if(component.get('v.alreadyHasValues') == false){
            component.set('v.allOptions',options);
            const hiddenValues = component.get('v.hiddenValues') || [];
            options = options.filter(val=> !hiddenValues.includes(val.value));
        }
        component.set("v.options",options);
    },
    checkBoxSelected : function(component, event, helper) {
        
        var checkBoxVals = component.get("v.checkBoxValues");  
        if(checkBoxVals)
            component.set("v.value", checkBoxVals.join(';'));
        var inputCmp = component.find('checboxGrp');
        component.find("checboxGrp-Error").set("v.message",null);
        if(inputCmp.checkValidity()==false && component.get("v.required")==true){
            component.set("v.customWarningMsg","Complete one of these fields");
        } 
    },
    doCheckValidity : function(component, event, helper) {
	    var isValid =true;
        var type = component.get("v.type");
        var inputCmp;
        if(type == 'Checkbox'){   
            var inputCmp = component.find('checboxGrp');
            if($A.util.isEmpty(component.get('v.customWarningMsg'))){
                if(inputCmp.checkValidity()==false && component.get("v.isValueSelected")==false){
                   component.find("checboxGrp-Error").set("v.message","Please select at least one checkbox");
               }else{
                   component.find("checboxGrp-Error").set("v.message",null);
               }   
            }
            component.set("v.validity", {'valid':inputCmp.checkValidity()});
		isValid =inputCmp.checkValidity();
        }
        else {
            var inputCmp =  component.find('picklist');
            inputCmp.showHelpMessageIfInvalid();
            if(component.get("v.needFocus")==true){
	            inputCmp.focus();
            }
            component.set("v.validity", inputCmp.get('v.validity'));
		return inputCmp.checkValidity();
        }
	    return isValid;
    }
})