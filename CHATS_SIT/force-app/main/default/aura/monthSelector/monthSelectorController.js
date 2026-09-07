({
    doInit: function(component, event, helper) {
		helper.setGridStyle(component, event, helper);
    },
    
    // Called when 'preSelectedMonths' attribute is having data
    preSelectMonths: function(component, event, helper) {
        helper.preSelectMonthsHelper(component, event, helper);
    },
    
    // Called when checkbox is clicked, it stores the selected months in output attributes
    handleChange: function(component, event, helper) {
        helper.addRemoveSelectedMonths(component, event, helper);
	}
})