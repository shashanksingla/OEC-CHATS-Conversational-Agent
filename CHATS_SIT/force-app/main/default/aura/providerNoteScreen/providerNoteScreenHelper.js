({
    getInitData : function(cmp){
        cmp.set("v.showSpinner", true);
        var action = cmp.get("c.getUserAssignedCounties");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue().objectData.Owner_County__c){
                    cmp.set("v.primaryCounty", response.getReturnValue().objectData.Owner_County__c);
                    cmp.set("v.county", response.getReturnValue().objectData.Owner_County__c);
                }
                if(response.getReturnValue().objectData.Common_County__c){
                    cmp.set("v.commonCounties", response.getReturnValue().objectData.Common_County__c);
                }
                if(response.getReturnValue().objectData.isAdminProfile){
                    cmp.set("v.isAdminProfile", response.getReturnValue().objectData.isAdminProfile);
                }
            }
            else{
                cmp.set("v.recordError", response.getReturnValue().message);
            }
        });
        $A.enqueueAction(action);
    },
    handleSubmit: function(cmp, event, helper) {
        cmp.set("v.showSpinner", true);
        if(cmp.get("v.SObjectName")=='T_CHATS_PROVR_STATUS__c'){
            event.preventDefault();       // stop the form from submitting
            if(!cmp.get("v.isAdminProfile")){
                var fields = event.getParam('fields');
                var isAuthorized = false;
                var commonCounties = cmp.get("v.commonCounties") || [];
                
                // Check if the selected county matches primary county or any common county
                if(fields.County__c == cmp.get("v.primaryCounty")){
                    isAuthorized = true;
                } else {
                    // Check if the selected county is in the common counties list
                    for(var i = 0; i < commonCounties.length; i++){
                        if(fields.County__c == commonCounties[i]){
                            isAuthorized = true;
                            break;
                        }
                    }
                }
                
                if(isAuthorized){
                    cmp.find('myRecordForm').submit(fields);
                }else{
                    cmp.find('messages').setError("You cannot create a note for the county not assigned to you.");
                    cmp.set("v.showSpinner", false);
                }
            }else{
                cmp.find('myRecordForm').submit(fields);
            }
        }
    },
    handleSuccess: function(cmp, event, helper) {
        cmp.set("v.showSpinner", false);
        $A.get('e.force:refreshView').fire();
        helper.redirectToRecord(cmp.get("v.recordId"));
        helper.fireToast('dismissible', 'success', 'Success', 'Record Saved Successfully');
    }
})