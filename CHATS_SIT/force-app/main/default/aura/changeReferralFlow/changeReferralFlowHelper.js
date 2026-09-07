({
	doNextHlp : function(component, event, helper) {
		var evt = $A.get("e.force:navigateToComponent");
    evt.setParams({
        componentDef : "c:referralProcessQueueFlow",
        componentAttributes: {
            isChangeRefFlow :true,
            currentTabNumber:2,
            recordId:component.get("v.recordId"),
            showNext:true,
            oldAppProcessQueueRecId:component.get("v.recordIdOld")
        }
    });
    evt.fire();
    },
    updateAppPrcQueueHlp : function(component, event, helper) {
        helper.callServer(component,"c.getAppAndRelatedChildDataChange", 
                                        function(response){
                                            if(response.isSuccessful){
                                                var referralType =component.get("v.referralType");
                                                if(referralType=='Renewal'){
                                                    helper.showToast('warning', 'Renewal Referral has been processed. Please review the referral and case screens and take necessary action on the case.');
                                                }else{
                                                    helper.showToast('success', 'Referral has been processed successfully.');
                                                }
                                                var navEvt = $A.get("e.force:navigateToSObject");
                                                navEvt.setParams({
                                                    "recordId": component.get("v.caseIdToRedirect"),
                                                    "slideDevName": "related"
                                                });
                                                navEvt.fire();
                                            }else{
                                                helper.showToast('error', response.errorMessage);
                                            }
                                        }, {'appProcessQueueId':component.get("v.recordId")}, false, null);
        
    },
})