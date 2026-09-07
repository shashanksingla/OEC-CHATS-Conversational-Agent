({
    doInit :  function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.checkIfAppHasPrimaryCaretaker", 
                                        function(response){
                                            if(!$A.util.isEmpty(response.objectData)){
	                                            component.set("v.hasPrimaryCaretaker",response.objectData.hasPrimaryCaretaker);
                                            }
                                            component.set("v.initLoaded",true);
                                            var countyError = 'The application process queue belongs to '+response.objectData.countyName+' county. This does not match your assigned county(ies).';
                                            component.set("v.countyMsg",countyError);
                                        }, {'appProcessQueueId':component.get("v.recordId")}, false, null);
    },
    showConfirmModal : function(component, event, helper) {
        helper.showConfirmModal(component);
    },
    hideConfirmModal: function(component, evt, helper){
        helper.hideConfirmModal(component);
    }
})