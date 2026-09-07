({
    toastMessage: function(state, msg) {
        var showToast = $A.get("e.force:showToast");
        showToast.setParams({
            'duration': '10000',
            'title': state,
            'type': state.toLowerCase(),
            'message': msg
        });
        showToast.fire();
        return;
    },
    
    navigateToApplnScreen : function (component, event, helper) {
        var navigationSObject = $A.get("e.force:navigateToSObject");
        navigationSObject.setParams({
            "recordId": component.get("v.recordId")
        });
        navigationSObject.fire();
    },
    
    callReferralPdfService : function (component, event, helper) {
        var recId = component.get("v.recordId");
        var action = component.get("c.getReferralPdf");
        var navigationCheck = component.get('v.navigationCheck');
        action.setParams({ recordId : recId});
        action.setCallback(this, function(response) {            
            var state = response.getState();
            if(state == 'SUCCESS'){
                debugger;
                var res = response.getReturnValue();
                if(res.isSuccessful == true){
                    if((res.objectData != null) && (res.objectData != undefined)){
                        var resJSON = JSON.parse(res.objectData.responseJSON);
                        var fileName = resJSON.fileName;
                         var pdfWin= window.open("/apex/viewReferralPdfPage?fileName="+fileName, "", "height=650,width=840");
                        if(navigationCheck == false){
                        	helper.navigateToApplnScreen(component, event, helper);
                        }
                        component.set("v.toggleSpinner",false);
                    }
                } else if(res.isSuccessful == false){
                	if(navigationCheck == false){
                		helper.navigateToApplnScreen(component, event, helper);
                	}
                    helper.toastMessage('Error', 'Error in retrieving file : ' + res.errorMessage);
                    component.set("v.toggleSpinner",false);
                }
            } else if (state == 'ERROR'){
            	if(navigationCheck == false){
            		helper.navigateToApplnScreen(component, event, helper);
            	}
                helper.toastMessage('Error', 'Error in retrieving file : ' + res.errorMessage);
                component.set("v.toggleSpinner",false);
            }
        });
        $A.enqueueAction(action);    
    }
    
})