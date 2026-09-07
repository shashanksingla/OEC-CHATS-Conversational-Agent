({
    getPicklistValues : function(component) {
        
        var val = component.get('v.value');
        
        var obj = component.get('v.object');
        var fld = component.get('v.field');
        
        var action = component.get('c.getPicklistValues');
        action.setParams({
            'obj' : component.get('v.object'),
            'fld' : component.get('v.field')
        });
        component.set("v.spinner", true);
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.get("v.type")=='Checkbox')
            if (component.isValid() && state == 'SUCCESS') {
                var returnedPicklistValues = response.getReturnValue();
                
                var value = component.get('v.value');
                if($A.util.isEmpty(value)) {
                    value = returnedPicklistValues.find(function(v) {
                        return v.isDefaultValue;
                    });
                    value = value ? value.value : null;
                }
                component.set('v.value', value);
                component.set('v.checkBoxValues', [value]);
                
                var options = [];
                
                if(!component.get('v.required') || component.get('v.showNone')) {
                    options.push({
                        'label' : '--None--',
                        'value' : null,
                        'class' : 'optionClass'
                    });
                }
                
                options = options.concat(returnedPicklistValues.map(function(v) {
                    return {
                        'label' : v.label,
                        'value' : v.value,
                        'class' : 'optionClass'
                    };
                }));                
                component.set('v.options', options);
            } else {
               
            }
            component.set("v.spinner", false);
            $A.util.removeClass(component.find("picklist"), 'slds-hidden');
            $A.util.removeClass(component.find('temp-box'), 'border');
        });
        $A.enqueueAction(action);
    }
})