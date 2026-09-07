({
	
	callDoInitHelper:function(cmp, event, helper){
        if(cmp.get("v.showCreateNewLinkComponent")==false){
            $A.util.toggleClass(cmp.find("mySpinner"), "slds-hide");
            var urlStr = window.location.origin + window.location.pathname;
            cmp.set('v.showMore', urlStr.endsWith('view'));
            this.retrieveExtObjData(cmp, event, helper);     
        }
    },
	
    retrieveExtObjData: function(component, event, helper){
        var action2 = component.get("c.fetchRelatedObjectdata");
        action2.setParams({"recordId": component.get("v.recordId") });
        action2.setCallback(this, function(response) {
            var spinner = component.find("mySpinner");
            $A.util.toggleClass(spinner, "slds-hide");
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(!$A.util.isEmpty(res)){
                    component.set("v.listRecordsToDisplay", res.objectData.fetchedLinkedRecords);
                    component.set("v.recCount", res.objectData.fetchedLinkedRecords.length);
                }
            }else if(response.getState() === "INCOMPLETE"){
                component.set("v.listRecordsToDisplay", []);
                component.set("v.recCount", 0);
                var error = 'Server could not be reached due to a network issue.';
                this.showErrorToast(error, 'SECTION NOTICE: '+component.get('v.relatedListHeader'), 'warning');
            }else {
                component.set("v.listRecordsToDisplay", []);
                component.set("v.recCount", 0);
                //case: state was "ERROR"
                var errors = response.getError();
                this.showErrorToast(errors[0].message, state+': '+component.get('v.relatedListHeader'), 'error');
            }
        });
        $A.enqueueAction(action2);
    },
    
    navigateToChilComponentHelper:function(component, event, helper){
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:supportTicketLinkedRelatedList",
            componentAttributes: {
                sortAscDsc : component.get("v.sortAscDsc"),
                orderByField : component.get("v.orderByField"),
                recCount : component.get("v.recCount"),
                listRecordsToDisplay : component.get("v.listRecordsToDisplay"),
                relatedListHeader : component.get("v.relatedListHeader"),
                parentObjIdentifier : component.get("v.parentObjIdentifier"),
                childApiName : component.get("v.childApiName"),
                recordId: component.get("v.recordId")
            }
        });
        if(component.get("v.showMore"))
            evt.fire();
        else
            window.history.back();
    },
    
    showErrorToast: function(message, state, type){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : state,
            message: message,
            duration:' 3000',
            key: 'info_alt',
            type: type,
            mode: 'pester'
        });
        toastEvent.fire();
    },
    sortBy: function(component, id) {
        var sortAsc = component.get("v.sortAsc"),
            field = id,
            sortField = id,
            records = component.get("v.listRecordsToDisplay"),
            dummyRecordArray = [],
            sortedRecord = [];
        // dummyRecord will possess all 'PAYLOAD' Object from all records
        for (var i = 0; i < records.length; i++) {
            dummyRecordArray[i] = records[i];
            // Another additional attribute 'parentIndex' is added to keep track of actual index of the object
            dummyRecordArray[i].parentIndex = i;
        }
        sortAsc = sortField != field || !sortAsc;
        // dummyRecord Array is Sorted
        dummyRecordArray.sort(function(a, b) {
            var t1 = a[field] == b[field],
                t2 = (!a[field] && b[field]) || (a[field] < b[field]);
            return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
        });
        
        
        for (var i = 0; i < records.length; i++) {
            sortedRecord.push(records[dummyRecordArray[i].parentIndex]);
        }
        component.set("v.sortAsc", sortAsc);
        component.set("v.listRecordsToDisplay", sortedRecord);
    },
    
    navigateToDetailHelper: function(component, event, helper){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": event.currentTarget.id,
            "slideDevName": "related"
        });
        navEvt.fire(); 
    },
    
    supportTicketLinkHelper: function(component, event, helper){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": event.currentTarget.id,
            "slideDevName": "detail"
        });
        
        navEvt.fire();
    },
    
    supportTicketLink1Helper: function(component, event, helper){
        helper.supportTicketLink1Helper(component, event, helper);
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": event.currentTarget.id,
            "slideDevName": "detail"
        });
        
        navEvt.fire();
    },
    
    createRecordHelper: function(component, event, helper){
        /*var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": "Linked_To__c",
            "defaultFieldValues": {
                'Support_Ticket__c' : component.get("v.recordId")
            }
        });
        createRecordEvent.fire();*/
    	component.set("v.showCreateNewLinkComponent",true);
    },
    
    handleDeleteRecordHelper: function(component, event, helper){
        component.find("recordHandler").deleteRecord($A.getCallback(function(deleteResult) { 
            if (deleteResult.state === "SUCCESS" || deleteResult.state === "DRAFT") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "duration":' 10000', 
                    "title": "Success!",
                    "type":"success",
                    "message": "Your record has been successfully deleted."
                });
                toastEvent.fire();
                window.location.reload()
            } 
        }));
    }
    
})