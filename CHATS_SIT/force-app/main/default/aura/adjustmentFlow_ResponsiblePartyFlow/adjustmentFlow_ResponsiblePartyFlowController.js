({
     doInit : function(component, event, helper) {
         var responsiblePartyObj = component.get("v.responsiblePartyObj");
    },
	fireEvent :function(component, event, helper) {
        helper.fireEventHlp(component, event, helper);
    },
    handleValidateCurrentPage : function(component, event, helper) {
        var resultFromThisPage = helper.validateCurrentPage(component);
        debugger;
        console.log('resultFromThisPage---'+resultFromThisPage);
        return resultFromThisPage;
    },
})