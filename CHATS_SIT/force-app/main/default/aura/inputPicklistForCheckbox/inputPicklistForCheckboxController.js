({
    doInit : function(component, event, helper) {
        
        if(component.get("v.value")==null && component.get("v.makeNoAsDefault")){
            component.set("v.selectedValue","no");
        }else{
            if(component.get("v.value")==true){
                component.set("v.selectedValue","yes");
            }else{
                component.set("v.selectedValue","no");
            }
        }
    },
    doHandleValueChange : function(component, event, helper) {
        if(component.get("v.selectedValue")=="yes"){
            component.set("v.value",true);
        }else{
            component.set("v.value",false);
        }
        var val=component.get("v.value");
        
    },
    highlightError : function(component, event, helper) {
        
            var inputCmp =  component.find('picklist');
            inputCmp.showHelpMessageIfInvalid();
            component.set("v.validity", inputCmp.get('v.validity'));
	}
})