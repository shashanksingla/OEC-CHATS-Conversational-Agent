({
	doInit : function(component, event, helper) {
        
       
        var value = component.get("v.value");
        S
        var listOfIneligReasons = component.get("v.listOfRecords");
        if(listOfIneligReasons && listOfIneligReasons.length>0 && (value!=null || value!=undefined)) {
            for(var i=0;i<listOfIneligReasons.length;i++) {
                if(value.indexOf(listOfIneligReasons[i].CDE_REASON__c)>=0) {
                    listOfIneligReasons[i].selected = true;
                } else{
                    listOfIneligReasons[i].selected = false;
                }
            }
        }
        
       // helper.getPicklistValues(component);
    },
    doUpdateOptions : function(component, event, helper) {
 		var options = component.get("v.options");
        for(var i=0;i<options.length;i++){
            if(component.get("v.value")==options[i].value){
                options[i].selected = true;
            }else{
                options[i].selected = false;
            }
        }
        component.set("v.options",options);
    },
    checkBoxSelected : function(component, event, helper) {
        
        var checkBoxVals = component.get("v.checkBoxValues");  
        if(checkBoxVals)
            component.set("v.value", checkBoxVals.join(';'));
    },
    doCheckValidity : function(component, event, helper) {
        var type = component.get("v.type");
        var inputCmp;
        if(type == 'Checkbox'){   
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