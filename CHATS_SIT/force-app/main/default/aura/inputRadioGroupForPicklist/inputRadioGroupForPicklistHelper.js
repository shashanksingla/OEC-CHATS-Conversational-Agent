({
    getPicklistValues : function(component) {
        var action = component.get('c.getPicklistValues');
        action.setParams({
            'obj' : component.get('v.object'),
            'fld' : component.get('v.field')
        });
        component.set("v.spinner", true);
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var returnedPicklistValues = response.getReturnValue();
                var value = component.get('v.value');
               
                /*if($A.util.isEmpty(value)) {
                    value = returnedPicklistValues.find(function(v) {
                        return v.isDefaultValue;
                    });
                    value = value ? value.value : null;
                }
                if(value!=null){
	                component.set('v.value', value);
                }*/
                var options = [];
                options = options.concat(returnedPicklistValues.map(function(v) {
                    return {
                        'label' : v.label,
                        'value' : v.value,
                    };
                }));                
                component.set('v.options', options);
            } else {
                
            }
            var radioGroup = component.find("radioGroup");
            component.set("v.spinner", false);
            $A.util.removeClass(radioGroup, 'slds-hidden');
            $A.util.removeClass(component.find('temp-box'), 'border');
            if(component.get("v.value")!=null){
	            radioGroup.set("v.value",component.get("v.value"));
            }
        });
        $A.enqueueAction(action);
    },
    checkValidity : function(component) {
        
        var radioGroup = component.find("radioGroup");
        if(radioGroup.checkValidity()){
            component.set("v.validity",{'valid':true});
            component.find("radioGroupError").set("v.message", null);
        }else{
            component.set("v.validity",{'valid':false});
            component.find("radioGroupError").set("v.message", "Please select at least one option");
        }
    }
})