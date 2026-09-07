({
	doGetCaseData : function(component, event) {
        // Create the action
        if(!$A.util.isEmpty(component.get("v.recordId"))){
            var action = component.get("c.getInitData");
            action.setParams({  caseId : component.get("v.recordId")});
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var nameString;
                    component.set("v.childCareProgram", response.getReturnValue().objectData['childCareProgram']);
                    component.set("v.homeAddress", response.getReturnValue().objectData['homeAddressRecord']);
                    component.set("v.mailingAddress", response.getReturnValue().objectData['mailingAddressRecord']);
                    component.set("v.indivEmailRecforPrimary", response.getReturnValue().objectData['individualEmailRecordforPrimary']);
                    component.set("v.SecondaryCareInf", response.getReturnValue().objectData['SecondaryCaretakerEmails']);
                    component.set("v.SecondaryCareDat", response.getReturnValue().objectData['SecondaryCaretakerDates']);
                }
                else {
                    console.log("Failed with state: " + state);
                }
            });
            $A.enqueueAction(action);
        }
    },
    navigateToRecord :  function(component, event, helper) {
        var recordId = event.currentTarget.dataset.item;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recordId
        });
        navEvt.fire();
    }
})