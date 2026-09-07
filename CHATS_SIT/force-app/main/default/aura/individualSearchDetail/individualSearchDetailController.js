({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        
        helper.callServerAndHandleError(component,"c.getCaseRelatedToIndividual", 
                                        function(response){
                                            
                                            if(response.isSuccessful==true){
                                                component.set("v.lstCaseDetailWrapper", response.objectData.lstCaseDetailWrapper);
                                                component.set("v.fullName", response.objectData.fullName);
                                            }
                                        }, {'individualId':recordId}, false, null);
        
    },
    openRecordDetail : function(component, event, helper) {
        var recordId = event.currentTarget.dataset.item;
        
        helper.redirectToRecord(recordId);
    },
    redirectBack: function (component, event, helper){
            var url = window.location.href; 
            var value = url.substr(0,url.lastIndexOf('/') + 1);
            window.history.back();
            return false;

    }
})