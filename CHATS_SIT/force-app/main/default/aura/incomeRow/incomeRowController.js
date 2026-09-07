({
    doInit : function(component, event, helper) {
        helper.setEmpNumberOptions(component); // Added for CCCAP-3236 by Rishav
    },
    
    validateRow : function(component, event, helper) {
        var validRow = component.find('input-field').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            inputCmp.focus();
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
        return validRow;
    },
    
    roundOffHours : function(component,event,helper){
        helper.roundOffHours(component,event,helper);
    }
})