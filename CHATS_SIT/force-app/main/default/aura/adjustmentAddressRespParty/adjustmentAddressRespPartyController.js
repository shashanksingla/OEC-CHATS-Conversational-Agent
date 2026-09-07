({
	doInit : function(component, event, helper) {
		debugger;
        console.log('resp addrs init'+JSON.stringify(component.get("v.address")));
        debugger;
	},
    fireEvent :function(component, event, helper) {
       // helper.fireEventHlp(component, event, helper);
    },
    handleValidateCurrentPage : function(component, event, helper) {
        debugger;
        return helper.validateCurrentPage(component);
    },
    divideZipCode : function(component, event, helper) {
         helper.divideZipCodeHelper(component, event, helper);
    },
})