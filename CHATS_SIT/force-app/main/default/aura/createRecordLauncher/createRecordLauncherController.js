({
	handleModalButtonClick : function(component, event, helper) {
        var windowHash = window.location.hash;
        var windowHref = window.location.href;
		var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": component.get("v.objectAPIName"),
            "defaultFieldValues": {
                'IDN_EMPLMT_INDIV__c': component.get("v.recordId")
            },
            "navigationLocation": "LOOKUP",
            "panelOnDestroyCallback": function(event){
                window.location.hash = windowHash;
                $A.get('e.force:refreshView').fire();
            }
        });
        createRecordEvent.fire();
	}
})