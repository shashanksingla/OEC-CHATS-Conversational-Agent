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
            if (component.isValid() && state == 'SUCCESS') {
                var returnedPicklistValues = response.getReturnValue();
                var value = component.get('v.value');
                if($A.util.isEmpty(value)) {
                    value = returnedPicklistValues.find(function(v) {
                        return v.isDefaultValue;
                    });
                    value = value ? value.value : null;
                    component.set('v.value', value);
                }else{
                    component.set('v.checkBoxValues', [value]);
                }
                
                if(component.get("v.type")=='Checkbox' && value!=null && value!='') {
                    
                    try{
                        component.set('v.checkBoxValues', value.split(';'));
                    }catch(ex){
                       
                        component.set('v.checkBoxValues', [value]);
                    }
                }
                
                var options = [];

                if(component.get('v.showSelect')) {
                    options.push({
                        'label' : '--Select--',
                        'value' : null,
                        'class' : 'optionClass',
                        'selected' : value==null?true:false
                    });
                }
                
                else if((!component.get('v.required') || component.get('v.showNone')) && component.get('v.type')!='Checkbox') {
                    options.push({
                        'label' : '--None--',
                        'value' : null,
                        'class' : 'optionClass',
                        'selected' : value==null?true:false
                    });
                }
                if(component.get("v.matchWithLabel")==true){
                    for(var i=0;i<returnedPicklistValues.length;i++){
                        if(returnedPicklistValues[i].label==value){
                            value = returnedPicklistValues[i].value;
                        }
                    }
                    component.set("v.value",value);
                }
                if(component.get("v.type")=='ReadOnly'){
                    for(var i=0;i<returnedPicklistValues.length;i++){
                        if(returnedPicklistValues[i].value==value){
                            component.set("v.valueLabel",returnedPicklistValues[i].label);
                            break;
                        }
                    }
                }
                
                
                options = options.concat(returnedPicklistValues.map(function(v) {
                    return {
                        'label' : v.label,
                        'value' : v.value,
                        'class' : 'optionClass',
                        'selected' : v.value==value?true:false
                    };
                }));
                const hiddenValues = component.get('v.hiddenValues') || [];
                component.set('v.allOptions',options);
        		options = options.filter(val=> !hiddenValues.includes(val.value));
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