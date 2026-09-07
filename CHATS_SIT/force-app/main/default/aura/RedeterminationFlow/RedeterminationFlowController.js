({
    doHandleCaseChange : function(component, event, helper) {
        try{
            component.set("v.caseCopy",JSON.parse(JSON.stringify(component.get("v.caseRec"))));
        }catch(ex){
            
        }
    },
    doSave : function(component, event, helper) {        
        if(helper.checkValidData(component,event,helper)){
            helper.updateRec(component,event,helper);
            helper.redirectToRecord(component.get("v.recordId"));
        }
    },
    doFinish : function(component, event, helper) {
        
        if(helper.checkValidData(component,event,helper)){
            helper.updateRec(component,event,helper);
            var caseRec = component.get("v.caseRec");
            helper.callServerAndHandleError(component,"c.updateCase", 
                                            function(response){
                                                helper.redirectToRecord(component.get("v.recordId"));
                                            }, {'caseRecs':[caseRec]}, false, null);
        }
        
    }
})