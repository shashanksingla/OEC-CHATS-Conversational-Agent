({
	doInit : function(component, event, helper) {
        helper.getLstCHATSMatchedIndividualsPerPage(component,1);
	},
    doNext : function(component, event, helper) {
        debugger;
        var pageNo = component.get("v.pageNo");
        pageNo++;
        component.set("v.pageNo",pageNo);
        helper.getLstCHATSMatchedIndividualsPerPage(component, pageNo);
	},
    doPrev : function(component, event, helper) {
        var pageNo = component.get("v.pageNo");
        pageNo--;
        component.set("v.pageNo",pageNo);
        helper.getLstCHATSMatchedIndividualsPerPage(component, pageNo);
	}
})