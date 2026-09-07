({
	onCaseSelectionRadioOption : function(component, event, helper) {
        var evt = $A.get("e.c:peakAppUpdateParentComponentAttribute");
        evt.setParams({'attributeName':'selectedCaseID'});
        evt.setParams({'attributeValue':null});
        evt.fire();
	},
	doInit : function(component, event, helper) {
        helper.getLstCaseIndividualPerPage(component,1);
	},
    doNext : function(component, event, helper) {
        debugger;
        var pageNo = component.get("v.pageNo");
        pageNo++;
        component.set("v.pageNo",pageNo);
        helper.getLstCaseIndividualPerPage(component, pageNo);
	},
    doPrev : function(component, event, helper) {
        var pageNo = component.get("v.pageNo");
        pageNo--;
        component.set("v.pageNo",pageNo);
        helper.getLstCaseIndividualPerPage(component, pageNo);
	}
})