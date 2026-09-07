({
	doInit : function(component, event, helper) {
        debugger;
        var recId = component.get("v.recordId");        
        var closeSupportTicket = component.get('c.onCloseButtonClick');
        closeSupportTicket.setParams({ recordId: recId });
        
        closeSupportTicket.setCallback(this, function(res) {
            debugger;
                if (res.getState() === 'SUCCESS') {
                 window.parent.location = '/' + recId;
                } else {
                 window.parent.location = '/' + recId;
                }
            });
            $A.enqueueAction(closeSupportTicket);
	}
})