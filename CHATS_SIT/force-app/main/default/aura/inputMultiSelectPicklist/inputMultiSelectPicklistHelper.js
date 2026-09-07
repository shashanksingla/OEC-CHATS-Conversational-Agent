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
                if(!value){
                    if($A.util.isEmpty(value)) {
                        value = returnedPicklistValues.find(function(v) {
                            return v.isDefaultValue;
                        });
                        
                        value = value ? value.value : null;
                    }
                    component.set('v.value', value);
                }
                
                var options = [];
                
                if(component.get('v.showNone')) {
                    options.push({
                        'label' : '--None--',
                        'value' : null,
                        'class' : 'optionClass'
                    });
                }
                if(component.get("v.doLabelMatch")==true){
                    options = options.concat(returnedPicklistValues.map(function(v) {
                        return {
                            'label' : v.label,
                            'value' : v.value,
                            'selected' : value!=null && value.includes(v.label)?true:false,
                            'class' : 'optionClass'
                        };
                    }));                
                }else{
                    options = options.concat(returnedPicklistValues.map(function(v) {
                        var option = {
                            'label' : v.label,
                            'value' : v.value,
                            'class' : 'optionClass',
                            'selected' : false								
                        };
                        if(value && value!=null){	
                            var valueArr = value.split(";");
                            if(valueArr.indexOf(v.value) > -1){
                                option.selected = true;
                            }
                        }
                        return option;
                    }));
                }
                component.set("v.options", options);
            } else {
                if(component.get("v.doLabelMatch")==true){
                    var value = component.get("v.value");
                    var options = component.get("v.options");
                    var newOptions = [];
                    newOptions = newOptions.concat(options.map(function(v) {
                        return {
                            'label' : v.label,
                            'value' : v.value,
                            'selected' : value!=null && value.includes(v.label)?true:false,
                            'class' : 'optionClass'
                        };
                    }));                
                    component.set("v.options",newOptions);
                }
                
            }
            component.set("v.spinner", false);
            var self= this;
            //note, we get options and set options_
            //options_ is the private version and we use this from now on.
            //this is to allow us to sort the options array before rendering
            var options = component.get("v.options");
            /*
            options.sort(function compare(a, b)
                         {
                             if (a.value == 'All')
                             {
                                 return -1;
                             }
                             else if (a.value < b.value)
                             {
                                 return -1;
                             }
                             if (a.value > b.value)
                             {
                                 return 1;
                             }
                             return 0;
                         });
            */
            component.set("v.options_", options);
            var values = self.getSelectedValues(component);
            self.setInfoText(component, values);
            
            var value=component.get("v.value");
            if (value!=null){
                
                /*var options= component.get("v.options_");
                value.split(";").forEach(function(val){
                    options.forEach(function(element){
                        if (element.value == val){
                            element.selected = true;
                        }else{
                            element.selected = false;
                        }
                    });
                });
                component.set("v.options_", options);*/
                var values = self.getSelectedValues(component);
                var labels = self.getSelectedLabels(component);
                self.setInfoText(component, labels);
                self.despatchSelectChangeEvent(component, values);
            }
        });
        $A.enqueueAction(action);
        
    },
    /********************************************************************************************
	 METHOD NAME    : handleMouseOutButton
	 DESCRIPTION    : if dropdown selection changes will trigger the event with selected labels
	 RETURN TYPE    : component reference
	 PARAMETER      : 1. component: Lightning Component reference
	 				  2. labels: Selected Labels
	 ********************************************************************************************
	 */
    setInfoText: function(component, labels)
    {
        if (labels.length == 0)
        {
            component.set("v.infoText", "Select an option...");
        }
        if (labels.length == 1)
        {
            component.set("v.infoText", labels[0]);
        }
        else if (labels.length > 1)
        {
            component.set("v.infoText", labels.length + " options selected");
        }
    },
    
    /********************************************************************************************
	 METHOD NAME    : getSelectedValues
	 DESCRIPTION    : if dropdown selection changes will trigger the event with selected values
	 RETURN TYPE    : component reference
	 PARAMETER      : 1. component: Lightning Component reference
	 ********************************************************************************************
	 */
    getSelectedValues: function(component)
    {
        var options = component.get("v.options_");
        var values = [];
        options.forEach(function(element)
                        {
                            if (element.selected)
                            {
                                values.push(element.value);
                            }
                        });
        return values;
    },
    
    /********************************************************************************************
	 METHOD NAME    : getSelectedLabels
	 DESCRIPTION    : if dropdown selection changes will trigger the event with selected labels
	 RETURN TYPE    : component reference
	 PARAMETER      : 1. component: Lightning Component reference
	 ********************************************************************************************
	 */
    getSelectedLabels: function(component)
    {
        var options = component.get("v.options_");
        var labels = [];
        options.forEach(function(element)
                        {
                            if (element.selected)
                            {
                                labels.push(element.label);
                            }
                        });
        return labels;
    },
    
    /********************************************************************************************
	 METHOD NAME    : despatchSelectChangeEvent
	 DESCRIPTION    : if dropdown selection changes will trigger the event with selected values
	 RETURN TYPE    : component reference
	 PARAMETER      : 1. component: Lightning Component reference
	 				  2. values: Selected Values
	 ********************************************************************************************
	 */
    despatchSelectChangeEvent: function(component, values)
    {
        var compEvent = component.getEvent("selectChange");
        compEvent.setParams(
            {
                "values": values
            });
        compEvent.fire();
    },
    checkValidity: function(component){
        if(component.get("v.required")==true && (component.get("v.value")=='' || component.get("v.value")==null)){
            component.set("v.validity",{'valid':false});
            component.find("inputMultiSelectPIcklistError").set("v.message","Please select at least one option.");
        }else{
            component.set("v.validity",{'valid':true});
            component.find("inputMultiSelectPIcklistError").set("v.message","");
        }
    }
})