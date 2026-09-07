({
    doInit : function(component, event, helper) {
        console.log(component.get("v.alreadyHasValues"));
        if(component.get("v.alreadyHasValues")==false){
        helper.getPicklistValues(component);
        }else{
            var values = helper.getSelectedLabels(component);
            helper.setInfoText(component, values);
        }
    },
    
    /********************************************************************************************
	 METHOD NAME    : handleClick
	 DESCRIPTION    : Option the dropdown upon clicking on input text
	 RETURN TYPE    : component reference
	 PARAMETER      : 1. component: Lightning Component reference
	 				  2. event: event that trigger the method call
	                  3. helper: helper js instance
	 ********************************************************************************************
	 */
    handleClick: function(component, event, helper)
    {
        var mainDiv = component.find('main-div');
        var vl = component.get("v.opened");
        
        if(vl)
            $A.util.addClass(mainDiv, 'slds-is-open');
        else
            $A.util.removeClass(mainDiv, 'slds-is-open');
        
        component.set("v.opened", !vl);
    },
    
    /********************************************************************************************
	 METHOD NAME    : handleSelection
	 DESCRIPTION    : Select and trigger event when option selected or deselected
	 RETURN TYPE    : component reference
	 PARAMETER      : 1. component: Lightning Component reference
	 				  2. event: event that trigger the method call
	                  3. helper: helper js instance
	 ********************************************************************************************
	 */
    handleSelection: function(component, event, helper)
    {
        var item = event.currentTarget;
        if (item && item.dataset)
        {
            var value = item.dataset.value;
            var selected = item.dataset.selected;
            
            var options = component.get("v.options_");
            
            //shift key ADDS to the list (unless clicking on a previously selected item)
            //also, shift key does not close the dropdown (uses mouse out to do that)
            if (event.shiftKey)
            {
                options.forEach(function(element)
                                {
                                    if (element.value == value)
                                    {
                                        element.selected = selected == "true" ? false : true;
                                    }
                                });
            }
            else
            {
                options.forEach(function(element)
                                {
                                    if (element.value == value)
                                    {
                                        element.selected = selected == "true" ? false : true;
                                    }
                                    else
                                    {
                                        element.selected = false;
                                    }
                                });
                var mainDiv = component.find('main-div');
                $A.util.removeClass(mainDiv, 'slds-is-open');
            }
            component.set("v.options_", options);
            setTimeout(function()
                       {
                           var values = helper.getSelectedValues(component);
                           var labels = helper.getSelectedLabels(component);
                           helper.setInfoText(component, labels);
                           helper.despatchSelectChangeEvent(component, values);
                           helper.checkValidity(component);
                       }, 1000);
        }
        
    },
    
    /********************************************************************************************
	 METHOD NAME    : handleMouseLeave
	 DESCRIPTION    : Hide the dropdown when mouse leave
	 RETURN TYPE    : component reference
	 PARAMETER      : 1. component: Lightning Component reference
	 				  2. event: event that trigger the method call
	                  3. helper: helper js instance
	 ********************************************************************************************
	 */
    handleMouseLeave: function(component, event, helper)
    {
        component.set("v.dropdownOver",false);
    },
    
    /********************************************************************************************
	 METHOD NAME    : handleMouseEnter
	 DESCRIPTION    : Hover the dropdown upon moving the mouse over
	 RETURN TYPE    : component reference
	 PARAMETER      : 1. component: Lightning Component reference
	 				  2. event: event that trigger the method call
	                  3. helper: helper js instance
	 ********************************************************************************************
	 */
    handleMouseEnter: function(component, event, helper)
    {
        component.set("v.dropdownOver",true);
    },
    
    /********************************************************************************************
	 METHOD NAME    : handleMouseOutButton
	 DESCRIPTION    : if dropdown over, user has hovered over the dropdown, so don't close
	 RETURN TYPE    : component reference
	 PARAMETER      : 1. component: Lightning Component reference
	 				  2. event: event that trigger the method call
	                  3. helper: helper js instance
	 ********************************************************************************************
	 */
    handleMouseOutButton: function(component, event, helper)
    {
        window.setTimeout(
            $A.getCallback(function() {
                if (component.isValid()) {
                    //if dropdown over, user has hovered over the dropdown, so don't close.
                    if (component.get("v.dropdownOver")) {
                        return;
                    }
                    var mainDiv = component.find('main-div');
                    $A.util.removeClass(mainDiv, 'slds-is-open');
                }
            }), 1000
        );
    },
    highlightError : function(component, event, helper) {
		helper.checkValidity(component);
    },
    updateValue : function(component, event, helper) {
        var options = helper.getSelectedValues(component);
        var value= '';
        for(var i=0;i<options.length;i++)
        {
            value+=options[i]+";";
        }
        component.set("v.value", value);
       
    }
})