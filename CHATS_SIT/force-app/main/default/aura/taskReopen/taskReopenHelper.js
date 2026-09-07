({
    doTransfer : function(component,event,helper) {
        debugger; 
        var valueSelected=event.getParam("value");
        console.log("task2: "+component.get("v.value"));
        helper.callServerAndHandleError(component,"c.reOpenMarkCompletedTask", 
                                        function(response){
                                            debugger;
                                            if(response.isSuccessful==true){
                                                var toastType ='success';
                                                var toastTitle='Success';
                                                var successMessage = 'Task Status updated Successfully'; 
                                                helper.fireToast('dismissible', toastType, toastTitle, successMessage ) ;
                                                this.navigateRecord(component,event); 
                                            }
                                            else{
                                                helper.fireToast('dismissible', 'error', 'Error', response.message) ;
                                            }
                                            
                                        }, {'taskId':component.get("v.recordId"),
                                            'status':component.get("v.value")}, false, null);
    },
    navigateToRecord :  function(component, event, helper) {
        var recordId = event.currentTarget.dataset.item;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recordId
        });
        navEvt.fire();
    },
    hideConfirmModal: function(component){
        $A.util.removeClass(component.find('modalOverlay'),'slds-backdrop--open');
        $A.util.removeClass(component.find('confirmMsgOverlay'), 'slds-fade-in-open');        
    },
    navigateRecord : function (component, event) {
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
      "recordId": component.get("v.recordId"),
      "slideDevName": "related"
    });
    navEvt.fire();
}
})