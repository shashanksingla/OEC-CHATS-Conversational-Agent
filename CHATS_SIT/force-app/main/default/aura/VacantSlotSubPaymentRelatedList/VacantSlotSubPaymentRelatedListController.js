({
	doInit : function(component, event, helper) {
		if(!component.get("v.isNavigateToCmp")){
            component.set('v.showMore',(window.location.href.split("?")[0]).endsWith('view'));
        }
        helper.getSubPmtRecords(component);
	},
	navigateToChilComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:VacantSlotSubPaymentRelatedList",
            componentAttributes: {
                recCount : component.get("v.recCount"),
                subPmtRecLst : component.get("v.subPmtRecLst"),
                childApiName : component.get("v.childApiName"),
                recordId: component.get("v.recordId"),
                isNavigateToCmp:true,
                showMore:false
            }
        });
        if(component.get("v.showMore"))
            evt.fire();
        else
            window.history.back();
    }
})