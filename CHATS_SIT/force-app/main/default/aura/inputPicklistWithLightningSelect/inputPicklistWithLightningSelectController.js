({
    doInit : function(component, event, helper) {
        var value = component.get("v.value");
        
        helper.getPicklistValues(component);
    },
    doNothing : function(component, event, helper) {
        
    },
    checkBoxSelected : function(component, event, helper) {
        
        var checkBoxVals = component.get("v.checkBoxValues");  
        if(checkBoxVals)
            component.set("v.value", checkBoxVals.join(';'));
    },
    doCheckValidity : function(component, event, helper) {
        var type = component.get("v.type");
        var inputCmp;
        if(type == 'Checkbox')
        {   
            var inputCmp = component.find('checboxGrp');
            component.set("v.validity", inputCmp.checkValidity());
        }
        else {
            var inputCmp =  component.find('picklist');
            inputCmp.showHelpMessageIfInvalid();
            component.set("v.validity", inputCmp.get('v.validity'));
        }
    }
})