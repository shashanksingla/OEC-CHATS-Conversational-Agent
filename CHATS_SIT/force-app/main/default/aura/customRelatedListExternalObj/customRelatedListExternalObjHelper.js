/**
 * Created by gautrivedi on 6/28/18.
 * Modified by ckuester on 8/6/18
 * 	-added alternative error message functionality
 */
({
    retrieveExtObjData: function(component, event, helper){
        var action2 = component.get("c.fetchRelatedObjectdata");
        var pickListTypeFields;
        if(!$A.util.isEmpty(component.get("v.pickListTypeFields")))
            pickListTypeFields = component.get("v.pickListTypeFields").split(';');
        var componentAttributesTypes = component.get("v.componentAttributesTypes");
        var parentObjIdentifier = component.get("v.parentObjIdentifier");
        var orderByField = component.get("v.orderByField");
        var recordsLimit = component.get("v.recordsLimit");
        var sortAscDsc = component.get("v.sortAscDsc");
        var childApiName = component.get("v.childApiName");
        action2.setParams({"recordId": component.get("v.recordId"),'FieldsApiNames':componentAttributesTypes,'pickListTypeFields':pickListTypeFields,'childApiName':childApiName,'parentObjIdentifier':parentObjIdentifier, 'orderByField':orderByField, 'recordsLimit':recordsLimit, 'sortAscDsc':sortAscDsc});
        action2.setCallback(this, function(response) {
            var spinner = component.find("mySpinner");
            $A.util.toggleClass(spinner, "slds-hide");
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(!$A.util.isEmpty(res)){
                    component.set("v.listRecordsToDisplay", res);
                    component.set("v.recCount", res.length);
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
                console.log(response);
                this.showErrorToast(errors[0].message, state+': '+component.get('v.relatedListHeader'), 'error');
            }
        });
        $A.enqueueAction(action2);
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
    }
})