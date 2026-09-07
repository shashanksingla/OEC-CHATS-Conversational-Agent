({
	doInit : function(component, event, helper) {
		var tabNames = component.get("v.tabNames");
        var tabMetadata = [];
        for(var i=0;i<tabNames.length;i++){
            tabMetadata.push({'tabNumber':i+1,'tabName':tabNames[i]});
        }
        component.set("v.tabMetadata",tabMetadata);
	}
})