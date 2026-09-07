({
    // To prepopulate the seleted value pill if value attribute is filled
    doInitHelper : function(component) {
        let mustValues = component.get('v.mustValues') || []; 
        let hiddenValues = component.get('v.hiddenValues') || [];
        var values = component.get('v.value') || mustValues.join(';');
        if(!$A.util.isEmpty(values)){
            var count = 0;
            var options = component.get('v.options');
            options = options.filter(val=> !hiddenValues.includes(val.value));
            var singleSelectedLabel = "";
            if(!component.get("v.doLabelMatch")){
                var valueList = [...new Set([...values.split(";"), ...mustValues])];
                valueList = valueList.filter(function(e){
                    return e
                }); 
                options.forEach(function(element, index) {
                    if(valueList.includes(element.value) || mustValues.includes(element.value)) {
                        element.selected = true;
                        count++;
                        singleSelectedLabel = element.label;
                    }
                    if(mustValues.includes(element.value)) {
                        element.required = true;
                    }
                });
                if(mustValues.length>0){
                    component.set('v.value',valueList.join(';'));
                }
            } else {
                var valueList = JSON.parse(JSON.stringify(mustValues));
                var valueString = "";
                options.forEach(function(element, index) {
                    if(values.includes(element.label) || mustValues.includes(element.value)) {
                        element.selected = true;
                        count++;
                        singleSelectedLabel = element.label;
                        valueList.push(element.value);
                    }
                    if(mustValues.includes(element.value)) {
                        element.required = true;
                    }
                });
                valueList.forEach(function(element, index) {
                    if($A.util.isEmpty(element)){
                        valueList.splice(valueList.indexOf(element), 1); // Removing blank value
                    }
                    if(valueString.includes(";;")){
                        valueString = valueString.replace(";;", ";");
                    }
                    valueString += element + ";";
                });
                values = valueString;
                component.set('v.value', values);
            }
            if(count == 0){
                component.set('v.searchString', '');
            } else if(count == 1) {
                component.set('v.searchString', singleSelectedLabel);
            } else {
                component.set('v.searchString', count + ' options selected');
            }
            component.set('v.valueList', valueList);
            component.set('v.options', options);
        }
    },
    
    // Getting picklist options from object and field schema
    getPicklistValues : function(component, event, helper) {
        var action = component.get('c.getPicklistValues');
        let hiddenValues = component.get('v.hiddenValues') || [];
        let mustValues = component.get('v.mustValues')||[]; 
        action.setParams({
            'obj' : component.get('v.object'),
            'fld' : component.get('v.field')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.isValid() && state == 'SUCCESS') {
                var returnedPicklistValues = response.getReturnValue();
                var options = [];
                if(component.get('v.showNone')){
                    options.push({
                        'label' : '--None--',
                        'value' : null
                    });
                }
                returnedPicklistValues.forEach(function(element, index) {
                    element.required = mustValues.includes(element.value);
                    if(!hiddenValues.includes(element.value))
	                    options.push(element);
                });
                component.set('v.options', options);
                helper.doInitHelper(component);
            }
        });
        $A.enqueueAction(action);
    },
    
    // When a keyword is entered in search box
    filterOptionsHelper : function(component) {
        component.set("v.message", '');
        var searchText = component.get('v.searchString');
        var options = component.get("v.options");
        var minChar = component.get('v.minChar');
        if(searchText.length >= minChar) {
            var flag = true;
            options.forEach(function(element, index) {
                if(element.label.toLowerCase().trim().includes(searchText.toLowerCase().trim())) {
                    element.isVisible = true;
                    flag = false;
                } else {
                    element.isVisible = false;
                }
            });
            component.set("v.options",options);
            if(flag) {
                component.set("v.message", "No results found for '" + searchText + "'");
            }
        }
        $A.util.addClass(component.find('resultsDiv'), 'slds-is-open');
    },
    
    // Updating selected value when an option is clicked upon
    selectItemHelper : function(component, event) {
        var options = component.get('v.options');
        var values = component.get('v.valueList') || [];
        var valueString = "";
        var singleSelectedLabel = "";
        var count = 0;
        options.forEach(function(element, index) {
            if(element.value === event.currentTarget.id) {
                if(values.includes(element.value)) {
                    values.splice(values.indexOf(element.value), 1); // Removing unselected value
                } else {
                    values.push(element.value); // Adding selected value
                }
                element.selected = element.selected ? false : true;
            }
            if(element.selected) {
                count++;
                singleSelectedLabel = element.label;
            }
        });
        values.forEach(function(element, index) {
            if($A.util.isEmpty(element)){
                values.splice(values.indexOf(element), 1); // Removing blank value
            }
            if(valueString.includes(";;")){
                valueString = valueString.replace(";;", ";");
            }
            valueString += element + ";";
        });
        component.set('v.valueList', values);
        component.set('v.value', valueString);
        component.set('v.options', options);
        if(count == 0){
            component.set('v.searchString', '');
        } else if(count == 1) {
            component.set('v.searchString', singleSelectedLabel);
        } else {
            component.set('v.searchString', count + ' options selected');
        }
        event.preventDefault();
    },
    
    // To remove the selected item when 'X' on a pill is clicked
    removePillHelper : function(component, event) {
        var value = event.getSource().get('v.name');
        var count = 0;
        var singleSelectedLabel = "";
        var options = component.get("v.options");
        var values = component.get('v.valueList') || [];
        var valueString = "";
        options.forEach(function(element, index) {
            if(element.value === value) {
                element.selected = false;
                values.splice(values.indexOf(element.value), 1);
            }
            if(element.selected) {
                count++;
                singleSelectedLabel = element.label;
            }
        });
        if(count == 0){
            component.set('v.searchString', '');
        } else if(count == 1) {
            component.set('v.searchString', singleSelectedLabel);
        } else {
            component.set('v.searchString', count + ' options selected');
        }
        values.forEach(function(element, index) {
            if($A.util.isEmpty(element)){
                values.splice(values.indexOf(element), 1); // Removing blank value
            }
            if(valueString.includes(";;")){
                valueString = valueString.replace(";;", ";");
            }
            valueString += element + ";";
        });
        component.set('v.valueList', values);
        component.set('v.value', valueString);
        component.set("v.options", options);
    },
    
    // Clears all selected values
    clearSelection : function(component) {
        var options = component.get("v.options");
        var values = [];
        options.forEach(function(element, index) {
            element.selected = false;
        });
        component.set('v.searchString', '');
        component.set('v.valueList', values);
        component.set('v.value', '');
        component.set("v.options", options);
    },
    
    // To close the dropdown if clicked outside the dropdown
    blurEventHelper : function(component, event, helper) {
        var selectedValue = component.get('v.value');
        var previousLabel;
        var count = 0;
        var singleSelectedLabel;
        var options = component.get("v.options");
        options.forEach(function(element, index) {
            if(element.value === selectedValue) {
                previousLabel = element.label;
            }
            if(element.selected) {
                count++;
                singleSelectedLabel = element.label;
            }
        });
        if(count == 0) {
            component.set('v.searchString', '');
        } else if(count == 1) {
            component.set('v.searchString', singleSelectedLabel);
        } else {
            component.set('v.searchString', count + ' options selected');
        }
        $A.util.removeClass(component.find('resultsDiv'), 'slds-is-open');
    },
    
    // Show error if field is required and value is empty
    checkValidity : function(component) {
        var required = component.get("v.required");
        var values = component.get("v.valueList");
        var inputCmp = component.find("inputMultiSelectCombobox");
        if(required && $A.util.isEmpty(values)) {
            inputCmp.setCustomValidity("Please select at least one option.");
            inputCmp.reportValidity();
            component.set("v.validity", {'valid':false});
        } else {
            inputCmp.setCustomValidity("");
            inputCmp.reportValidity();
            component.set("v.validity", {'valid':true});
        }
    }
})