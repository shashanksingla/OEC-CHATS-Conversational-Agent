({
	doInit : function(component, event, helper) {
        var action = component.get("c.validateCounty");
        action.setParams({"recordId": component.get("v.recordId")});        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res.objectData.isValidCounty == false && component.get('v.navigationCheck') == false){
                    var recordError = 'The Peak Application that you are trying to access belongs to '+res.objectData.countyName+' county. This does not match your assigned county(ies). Would you like to countinue?';
                    component.set("v.msgOnDiffOwnerCounty", recordError);
                    var modalCall = component.find("warningModalOnDiffOwnerCounty");
                    if(modalCall){
                        modalCall.openModal();
                    }
                } else {
                    component.set("v.toggleSpinner",true);
                    var recId = component.get("v.recordId");
                    
                    var act = component.get("c.fetchPdfFileFromS3");
                    act.setParams({ recordId : recId});
                    act.setCallback(this, function(r) {
                        var state = r.getState();
                        helper.navigateToApplnScreen(component, event, helper);
                        if(state == 'SUCCESS'){
                            var result = r.getReturnValue();
                            if(result){                
                                var navigationCheck = component.get('v.navigationCheck');
                                var pdfWin= window.open("/apex/viewPeakPdfPage?fileName="+result+"&recordId="+recId, "", "height=650,width=840");
                                component.set("v.toggleSpinner",false);
                            }
                        } else if(state == 'ERROR'){
                            helper.toastMessage('Error', 'Error in retrieving filename');
                            component.set("v.toggleSpinner",false);
                        }
                    });    
                    $A.enqueueAction(act);
                }
            }
        });
        $A.enqueueAction(action);
    },
    processPeakPDF: function(component, event, helper) {
        component.set("v.toggleSpinner",true);
        var recId = component.get("v.recordId");
        
        var act = component.get("c.fetchPdfFileFromS3");
        act.setParams({ recordId : recId});
        act.setCallback(this, function(r) {
            var state = r.getState();
            helper.navigateToApplnScreen(component, event, helper);
            if(state == 'SUCCESS'){
                var result = r.getReturnValue();
                if(result){
                	var navigationCheck = component.get('v.navigationCheck');
                    var pdfWin= window.open("/apex/viewPeakPdfPage?fileName="+result+"&recordId="+recId, "", "height=650,width=840");
                    component.set("v.toggleSpinner",false);
                }
            } else if(state == 'ERROR'){
                helper.toastMessage('Error', 'Error in retrieving filename');
                component.set("v.toggleSpinner",false);
            }
        });    
        $A.enqueueAction(act);
    },
    closeModal : function(component, event, helper){
        var modalCall = component.find("warningModalOnDiffOwnerCounty");
        $A.util.removeClass(modalCall.find('backDrop'),'slds-backdrop--open');
        $A.util.removeClass(modalCall.find('confirmMsgModal'), 'slds-fade-in-open'); 
        helper.redirectToRecord(component.get("v.recordId"));
    }    
})