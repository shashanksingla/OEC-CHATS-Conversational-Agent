({
    doInit : function(component, event, helper) {
        component.set('v.placeholderInitialText', component.get("v.placeholder"));
        $A.util.toggleClass(component.find('resultsDiv'), 'slds-is-open');
        if(!component.get("v.alreadyHasValues")){
            helper.getPicklistValues(component, event, helper);
        } else {
            helper.doInitHelper(component);
        }
    },
    
    // Show error if field is required and value is empty
    highlightError : function(component, event, helper) {
        helper.checkValidity(component);
    },
    
    // Reset the field
    resetOptions : function(component, event, helper) {
        helper.clearSelection(component);
    },
    
    // When a keyword is entered in search box
    filterOptions : function(component, event, helper) {
        var searchString = component.get('v.searchString');
        if(searchString) {
            var evt = window.event || event;
            if(evt) {
                // Skipping Shift, Ctrl, Alt key as input trigger for search
                if(!~[16, 17, 18].indexOf(evt.keyCode)) {
                    if(!searchString.endsWith(" options selected"))
                        helper.filterOptionsHelper(component);
                }
            } else {
                if(!searchString.endsWith(" options selected"))
                    helper.filterOptionsHelper(component);
            }
        } else {
            $A.util.removeClass(component.find('resultsDiv'), 'slds-is-open');
        }
    },
    
    // When an item is selected
    selectItem : function(component, event, helper) {
        if(!$A.util.isEmpty(event.currentTarget.id)) {
            helper.selectItemHelper(component, event);
        } else {
            helper.clearSelection(component);
            helper.checkValidity(component);
        }
    },
    
    // Show dropdown when field is clicked on
    showOptions : function(component, event, helper) {
        var disabled = component.get("v.disabled");
        if(!disabled){
            component.set('v.placeholder', component.get("v.placeholderHelpText"));
            component.set("v.message", '');
            component.set('v.searchString', '');
            var options = component.get("v.options");
            options.forEach(function(element,index) {
                element.isVisible = true;
            });
            component.set("v.options", options);
            if(!$A.util.isEmpty(component.get('v.options'))) {
                $A.util.addClass(component.find('resultsDiv'), 'slds-is-open');
            } 
        }
    },
    
    // To remove the selected item when 'X' on a pill is clicked
    removePill : function(component, event, helper) {
        component.set('v.placeholder', component.get("v.placeholderInitialText"));
        helper.removePillHelper(component, event);
        helper.checkValidity(component);
    },
    
    // To close the dropdown if clicked outside the dropdown
    blurEvent : function(component, event, helper) {
        component.set('v.placeholder', component.get("v.placeholderInitialText"));
        helper.blurEventHelper(component, event);
        helper.checkValidity(component);
    }
})