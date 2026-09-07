({
    doInit : function(component, event, helper) {
        var sOb = component.get("v.sOb");
        var fieldAPIName = component.get("v.fieldAPIName");
        if(!$A.util.isEmpty("v.sOb") && !$A.util.isEmpty("v.fieldAPIName")){
            component.set("v.fieldValue",sOb[fieldAPIName]);    
        }
        component.set("v.initLoaded", true);
    },
    doValidateAndSetData : function(component, event, helper) {
        
        if(component.get("v.readOnly")==true){
            return true;            
        }else{
            var sOb = component.get("v.sOb");
            var fieldAPIName = component.get("v.fieldAPIName");
            var fieldValue = component.get("v.fieldValue");
            if(!$A.util.isEmpty("v.sOb") && !$A.util.isEmpty("v.fieldAPIName")){
                sOb[fieldAPIName] = fieldValue;
                component.set("v.sOb",sOb);    
            }
            var validity = {};
            validity.valid = true;
            component.find('field').showHelpMessageIfInvalid();
            validity = component.find('field').get('v.validity').valid;
            
           
            return validity;
        }
    }
})