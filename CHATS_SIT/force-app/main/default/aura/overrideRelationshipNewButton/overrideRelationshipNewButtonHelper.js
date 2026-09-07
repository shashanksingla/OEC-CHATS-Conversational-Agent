({
    doInitHelper : function(component, event, helper) {
        var action2 = component.get("c.getDoInit");
        action2.setParams({"recordId": component.get("v.recordId")});
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res=response.getReturnValue();
                var relationshipObj = component.get("v.newRelationshipObj");
                if(res.objectData.getSobjectName != undefined){
                    if(res.objectData.getSobjectName == 'T_SBSD_INDIV__c'){
                        relationshipObj.IDN_CLIENT__c =component.get("v.recordId");
                        component.set("v.newRelationshipObj",relationshipObj);
                    }
                    else if(res.objectData.getSobjectName == 'T_INDIV_REL__c'){
                        if(res.objectData.relRec){
                            component.set("v.newRelationshipObj",res.objectData.relRec);
                        }
                    }
                }
                component.set("v.initDataLoaded",true);
            } else {
            }
        });
        $A.enqueueAction(action2);
    },
    doFinishHelper : function(component, event, helper) {
        var childCmp = component.find("newRelRecord");
        childCmp.callValidateCurrentPage();
        if(component.get("v.isCurrentPageValid")==true){
            component.set("v.showSpinner", true); 
            helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                            function(response){
                                                if(response){
                                                    helper.redirectToRecord(component.get("v.recordId"));
                                                }
                                            }, 
                                            {"lstSObject": [component.get("v.newRelationshipObj")],
                                                "isFinalStep":true}, false, null);
            
        }else{
            
            component.set("v.showSpinner", false); 
        }
    },
    doCancelHelper : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get("v.recordId"))){
            helper.redirectToRecord(component.get("v.recordId"));
        }else{
            window.history.back();
        }
    }    
})