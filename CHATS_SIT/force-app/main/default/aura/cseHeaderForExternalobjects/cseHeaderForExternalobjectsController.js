({
	doInit : function(component, event, helper) {
        // Create the action
        if(!$A.util.isEmpty(component.get("v.recordId"))){
            var action = component.get("c.getCaseId");
            action.setParams({  recordId : component.get("v.recordId"),sobjectName : component.get("v.sObjectName")});
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var nameString;
                    component.set("v.case", response.getReturnValue().objectData['caseRecord'][0]);
                    component.set("v.childCareProgram", response.getReturnValue().objectData['childCareProgram']);
                    component.set("v.isChildProgram",true);
                    
                    if(response.getReturnValue().objectData['caseRecord'][0].CaseIndividuals__r && 
                       response.getReturnValue().objectData['caseRecord'][0].CaseIndividuals__r[0].IDN_CLIENT__r)
                    {  
                        nameString = response.getReturnValue().objectData['caseRecord'][0].CaseIndividuals__r[0].IDN_CLIENT__r.NAM_LAST__c
                        +', '+response.getReturnValue().objectData['caseRecord'][0].CaseIndividuals__r[0].IDN_CLIENT__r.NAM_FIRST__c;
                    }
                    component.set("v.primaryCaretaker", nameString);
                }
                else {
                  
                }
            });
            // Send action off to be executed
            $A.enqueueAction(action);
        }
    }
})