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
    
    callPeakPdfService : function (component, event, helper) {
        debugger;
        var recId = component.get("v.recordId");
        var action = component.get("c.getPdfFromPeak");
        var navigationCheck = component.get('v.navigationCheck');
        action.setParams({ recordId : recId});
        action.setCallback(this, function(response) {            
            var state = response.getState();
            if(state == 'SUCCESS'){
                debugger;
                var res = response.getReturnValue();
                if(res.isSuccessful == true){
                    if((res.objectData != null) && (res.objectData != undefined)){
                        //var labelUrl = $A.get("$Label.c.correspondenceTargetPdfServlet");
                        var resJSON = JSON.parse(res.objectData.responseJSON);
                        var fileName = resJSON.fileName;
                        //var path1 = 'interfaces/peak/applicationPDF';
                        //var url = labelUrl + 'pathInAws=' + path1 + '&fileName=' + resJSON.fileName;
                        //var pdfWin = window.open(url, "", "height=650,width=840");
                        /*
                        this.callServerAndHandleError(component, "c.getFileBlob",function(resp) {
                            
                        }, {
                        	fileName: resJSON.fileName
                    	}, false, null);
                        */
                        var pdfWin= window.open("/apex/viewPeakPdfPage?fileName="+fileName, "", "height=650,width=840");
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