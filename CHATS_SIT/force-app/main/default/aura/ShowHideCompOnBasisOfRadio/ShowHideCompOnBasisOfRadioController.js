({
    doInit : function(component, event, helper) {

    },
    updateRadioButtons : function(component, event, helper) {
        helper.updateRadioButtons(component, event);
    },
    optionSelected : function(component, event, helper) {
        helper.showHideTextArea(component, event);
        component.set("v.showError",false);
    },
    highlightError : function(component, event, helper) {
        
       
        if(component.get("v.required")==true && (component.get("v.val")==null || component.get("v.val")=='')){
            component.set("v.showError",true);
            component.set("v.validity",{'valid':false});
        }else{
            component.set("v.showError",false);
            component.set("v.validity",{'valid':true});
        }
	}
})