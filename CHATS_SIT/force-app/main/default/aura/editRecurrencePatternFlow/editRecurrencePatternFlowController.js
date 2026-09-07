({
    doInit : function(component, event, helper) {
        var action2 = component.get("c.getSelectedScheduleRecurrence");
        action2.setParams({"recordId": component.get("v.recordId")});
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res=response.getReturnValue();
                var employmentPayStabObj = component.get("v.authSchRecurrObj");
                console.log("res.---"+JSON.stringify(res));
                console.log('recordId---'+component.get("v.recordId"));
                if(res.objectData.authSchRecurrObj){
                    component.set("v.authSchRecurrObj",res.objectData.authSchRecurrObj);
                }
                
                
                component.set("v.oneTimeDateLoadValidatity",false);
                component.set("v.oneTimeDateLoadValidatity",true);
                component.set("v.sObjectName", res.objectData.getSobjectName);
                component.set("v.initDataLoaded",true);
            } else {
                console.log('Problem getting authorization, response state: ' + state);
            }
        });
        $A.enqueueAction(action2);
    },
    doFinish : function(component, event, helper) {
        var childCmp = component.find("authSchRecurrObj");
        childCmp.callValidateCurrentPage();
        console.log(component.get("v.isCurrentPageValid"));
        debugger;
         console.log('----isValid---'+component.get("v.isValid"));
        if(component.get("v.isValid")==true){
            component.set("v.showSpinner", true); 
            console.log('----authSchRecurrObj---'+JSON.stringify(component.get("v.authSchRecurrObj")));
            debugger;
            helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                            function(response){
                                                debugger;
                                                if(response){
                                                    var toastEvent = $A.get("e.force:showToast");
                                                    toastEvent.setParams({
                                                        "title": "Success!",
                                                        "type":"success",
                                                        "message": 'Authorization Recurrence has been updated successfully.'
                                                    });
                                                    toastEvent.fire();
                                                    component.set("v.showEditModal",false);
                                                }
                                            },
                                            {"lstSObject": [component.get("v.authSchRecurrObj")],"isFinalStep":true}, false, null);
            
        }else{
            component.set("v.showSpinner", false); 
        }
    },
    doCancel : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get("v.recordId"))){
           // helper.redirectToRecord(component.get("v.recordId"));
           component.set("v.showEditModal",false);
        }else{
            window.history.back();
        }
        
    },
     closeModel : function(component, event, helper) {
        // Set isModalOpen attribute to false  
      //  component.set("v.isModalOpen", false);
      //  $A.get("e.force:closeQuickAction").fire();
     component.set("v.showEditModal",false);
    },
})