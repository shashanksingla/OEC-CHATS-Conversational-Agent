({
    startFlow : function(component, event, helper) {
        var flowCmp = component.find("flow");
        if(flowCmp){
            var flow = component.get("v.flowAPIName");
            flowCmp.startFlow(flow, [{ 
                name:"recordId", 
                type: "String",
                value: component.get("v.recordId")}]);
        }
    },
    handleStatusChange: function(component, event, helper) {
        var messageType='';
        var message='';
        if(event.getParam("status") === 'FINISHED'){
            var outputVariables = event.getParam("outputVariables") || [];
            outputVariables.forEach( function(outputVariable){
                if(outputVariable.name == 'OutputMessage'){
                    message = outputVariable.value;
                }
                if(outputVariable.name == 'MessageType'){
                    messageType = outputVariable.value;            
                }
            });
            var modalRef = component.get("v.modalRef");
            if(modalRef && typeof modalRef.close === "function"){
                modalRef.close();
            }
            //added for error handling for Checkmarx issues
            if(messageType != '' && messageType == 'error' && message != ''){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": message+'',
                    "type": 'error',
                    "mode":"dismissable"
                });
                toastEvent.fire();
            } else{
                $A.get('e.force:refreshView').fire();
            }
        }
    }
})