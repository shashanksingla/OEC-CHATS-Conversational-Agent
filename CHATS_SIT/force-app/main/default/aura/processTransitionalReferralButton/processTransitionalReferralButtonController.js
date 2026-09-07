({

    doInit : function(component, event, helper){
        helper.callServerAndHandleError(component,"c.getAppAndRelatedLowIncomeData", 
                                        function(response){
                                            debugger;
                                            if(!$A.util.isEmpty(response.objectData) ){
                                                debugger;
                                                component.set("v.caseIdToRedirect",response.objectData.processTransitionalRefe);
                                                component.set("v.appCaseId",response.objectData.appCaseId);
                                                component.set("v.closureReason",response.objectData.closureReason);
                                                component.set("v.referralType",response.objectData.referralType);
                                                if(response.objectData.noDataMessage != null){
                                                    component.set("v.noDataMessage",response.objectData.noDataMessage);
                                                }
                                                if(!$A.util.isEmpty(response.objectData.employmentLIRefInfo) ){
                                                    component.set("v.employmentLIRefInfo",response.objectData.employmentLIRefInfo);
                                                }
                                                if(!$A.util.isEmpty(response.objectData.selfEmploymentLIRefInfo) ){
                                                    component.set("v.selfEmploymentLIRefInfo",response.objectData.selfEmploymentLIRefInfo);
                                                }
                                                if(!$A.util.isEmpty(response.objectData.emplIncomeLIInfo) ){
                                                    component.set("v.emplIncomeLIInfo",response.objectData.emplIncomeLIInfo);
                                                }
                                                 if(!$A.util.isEmpty(response.objectData.emplPaystubLIInfo) ){
                                                    component.set("v.emplPaystubLIInfo",response.objectData.emplPaystubLIInfo);
                                                }
                                                if(!$A.util.isEmpty(response.objectData.activityLIRefInfo) ){
                                                    component.set("v.activityLIRefInfo",response.objectData.activityLIRefInfo);
                                                }
                                                if(!$A.util.isEmpty(response.objectData.incomeTypesLIRefInfo) ){
                                                    component.set("v.incomeTypesLIRefInfo",response.objectData.incomeTypesLIRefInfo);
                                                }
                                            }
                                        }, {'appProcessQueueId':component.get("v.recordId")}, false, null);
        
    },
    
    doFinish : function (component, event, helper){
        if(component.get("v.referralType") == 'Transition'){
            $A.util.toggleClass(component.find("backdropTransitionalReferral"),"slds-backdrop");
            $A.util.toggleClass(component.find("backdropTransitionalReferral"),"slds-backdrop_open");
            $A.util.toggleClass(component.find("transitionalReferral"),"slds-fade-in-open");
        }else if(component.get("v.referralType") == 'Closure') {
            $A.util.toggleClass(component.find("backdropClosureReferral"),"slds-backdrop");
            $A.util.toggleClass(component.find("backdropClosureReferral"),"slds-backdrop_open");
            $A.util.toggleClass(component.find("closureReferral"),"slds-fade-in-open");
        }
    },
    
    handleClose: function(component, event, helper) {
        var referralType = component.get("v.referralType");
        if (referralType === 'Transition') {
            $A.util.removeClass(component.find("backdropTransitionalReferral"), "slds-backdrop");
            $A.util.removeClass(component.find("backdropTransitionalReferral"), "slds-backdrop_open");
            $A.util.removeClass(component.find("transitionalReferral"), "slds-fade-in-open");
        } else if (referralType === 'Closure') {
            $A.util.removeClass(component.find("backdropClosureReferral"), "slds-backdrop");
            $A.util.removeClass(component.find("backdropClosureReferral"), "slds-backdrop_open");
            $A.util.removeClass(component.find("closureReferral"), "slds-fade-in-open");
        }
    },
    
    doCancel : function(component, event, helper) {
        helper.redirectToRecord(component.get("v.recordId"));
    },
    
    hideTransitionalReferralWarning : function(component, event, helper) {
        $A.util.removeClass(component.find("backdropTransitionalReferral"),"slds-backdrop");
        $A.util.removeClass(component.find("backdropTransitionalReferral"),"slds-backdrop_open");
        $A.util.removeClass(component.find("transitionalReferral"),"slds-fade-in-open");
        
         helper.callServerAndHandleError(component,"c.processTransitionOnFinish", 
                                        function(response){
                                            debugger;
                                            if(!$A.util.isEmpty(response.objectData) ){
                                                debugger;
                                                component.set("v.caseIdToRedirect",response.objectData.caseId);
                                                
                                                var navEvt = $A.get("e.force:navigateToSObject");
                                                navEvt.setParams({
                                                    "recordId": component.get("v.caseIdToRedirect"),
                                                    "slideDevName": "related"
                                                });
                                                navEvt.fire();
                                                helper.showToast('success', 'Referral has been processed successfully.');
                                                
                                            }
                                        }, {'appProcessQueueId':component.get("v.recordId")}, false, null);

    },
    
    hideClosureReferralWarning : function(component, event, helper) {
        $A.util.removeClass(component.find("backdropClosureReferral"),"slds-backdrop");
        $A.util.removeClass(component.find("backdropClosureReferral"),"slds-backdrop_open");
        $A.util.removeClass(component.find("closureReferral"),"slds-fade-in-open");
        
         helper.callServerAndHandleError(component,"c.processTransitionOnFinish", 
                                        function(response){
                                            debugger;
                                            if(!$A.util.isEmpty(response.objectData) ){
                                                debugger;
                                                component.set("v.caseIdToRedirect",response.objectData.caseId);
                                                
                                                var navEvt = $A.get("e.force:navigateToSObject");
                                                navEvt.setParams({
                                                    "recordId": component.get("v.caseIdToRedirect"),
                                                    "slideDevName": "related"
                                                });
                                                helper.showToast('success', 'Referral has been processed successfully.');
                                                navEvt.fire();
                                                
                                                
                                            }
                                        }, {'appProcessQueueId':component.get("v.recordId")}, false, null);

    }
})