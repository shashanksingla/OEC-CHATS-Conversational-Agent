({
	doInit: function(component, event, helper) {
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
                    var pdfWin= window.open("/apex/viewReferralPdfPage?fileName="+result+"&recordId="+recId, "", "height=650,width=840");
                    component.set("v.toggleSpinner",false);
                }
            } else if(state == 'ERROR'){
                helper.toastMessage('Error', 'Error in retrieving filename');
                component.set("v.toggleSpinner",false);
            }
        });    
        $A.enqueueAction(act);
    }   
})