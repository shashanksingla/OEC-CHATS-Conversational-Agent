({
	doInit : function(component, event, helper) {
        var pType = component.get('v.picklistType');
        if(pType == "GlobalPicklist"){
            helper.getGlobalPicklistValues(component,event,helper);
        }else if(pType == "TableFetchPicklist") {
            helper.getTablePicklistValues(component,event,helper);
        }
    },
    onchangeEvent : function(component, event, helper){
        var compEvent = component.getEvent("eventOnchange");
        compEvent.setParams({ "context" : true });
        compEvent.fire();
    },
    highlightError : function(component, event, helper){
        component.set("v.validity",{'valid':true});
    }
})