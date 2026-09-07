({
	doChangeCurrentPageValid : function(component, event, helper) {
       
        var pageMessages = component.get("v.pageMessages");
        if(component.get("v.isCurrentPageValid")==false && pageMessages.length==0){
            component.set("v.pageMessages",['There are errors on this page. Please correct them to proceed.']);
            component.set("v.messageType",'error');
        }else{
            component.set("v.pageMessages",[]);
            component.set("v.messageType",null);
        }
	}
})