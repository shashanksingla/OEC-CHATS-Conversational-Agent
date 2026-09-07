({
    doInit : function(component, event, helper) {
        if(component.get("v.sObjectName")=='T_SBSD_CASE__c'){
            component.set("v.caseId",component.get("v.recordId"));
        }else{
            component.set("v.fields",[component.get("v.relationshipToCase")]);                
        }
    },
    doSetCaseId : function(component, event, helper) {
        
        var childRecord = component.get('v.childRecord');
        var relationshipToCase = component.get("v.relationshipToCase");
        
        if(childRecord!=null && !$A.util.isEmpty(childRecord[relationshipToCase])){
            var caseId = childRecord[relationshipToCase];
            component.set("v.caseId",caseId);
        }
    },
    doGetCaseData : function(component, event, helper) {
        // Create the action
        if(!$A.util.isEmpty(component.get("v.caseId"))){
            var action = component.get("c.getInitData");
            action.setParams({  caseId : component.get("v.caseId")});
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS" && !$A.util.isEmpty(response.getReturnValue().objectData)) {
                    var nameString;
                    component.set("v.case", response.getReturnValue().objectData['caseRecord'][0]);
                    component.set("v.childCareProgram", response.getReturnValue().objectData['childCareProgram']);
                    component.set("v.closeDate", response.getReturnValue().objectData['scheduledCloseDate']);
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
    },
    handleClick :  function(component, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.caseId")
        });
        navEvt.fire();
    }
})