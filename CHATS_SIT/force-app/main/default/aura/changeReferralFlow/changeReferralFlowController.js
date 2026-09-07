({
    doInit : function(component, event, helper){
        helper.callServerAndHandleError(component,"c.getAppAndRelatedChildData", 
                                        function(response){
                                            debugger;
                                            if(!$A.util.isEmpty(response.objectData) ){
                                                debugger;
                                                component.set("v.caseIdToRedirect",response.objectData.caseId);
                                                component.set("v.isNewIndivReceived",response.objectData.isNewIndivReceived);
                                                component.set("v.appCaseId",response.objectData.appCaseId);
                                                component.set("v.recordIdOld",response.objectData.recordIdOld);
                                                component.set("v.referralType",response.objectData.referralType);
                                                component.set("v.referralId",response.objectData.referralId);
                                                component.set("v.appProcessQueueRec",response.objectData.appProcessQueue);
                                                component.set("v.referralReason",((response.objectData.appProcessQueue[0] || {}).IDN_APPLN__r || {}).CBMS_REF_REASON__c);
                                                if(!$A.util.isEmpty(response.objectData.oldCounty) ){
                                                    component.set("v.oldCounty",response.objectData.oldCounty);
                                                    component.set("v.newCounty",response.objectData.newCounty); 
                                                }
                                                if(!$A.util.isEmpty(response.objectData.caseRefInfo) ){
                                                    component.set("v.noChange",true);
                                                    component.set("v.caseRefList",response.objectData.caseRefInfo);
                                                }
                                                if(!$A.util.isEmpty(response.objectData.childCareRefList) ){
                                                    component.set("v.noChange",true);
                                                    component.set("v.childCareRefList",response.objectData.childCareRefList);
                                                }
                                                if(!$A.util.isEmpty(response.objectData.incomeRefList) ){
                                                    component.set("v.noChange",true);
                                                    component.set("v.incomeRefList",response.objectData.incomeRefList);
                                                }
                                                // Added by Rishav for CCCAP-7696
                                                if(!$A.util.isEmpty(response.objectData.activeAuthList)){
                                                    component.set("v.activeAuthList", response.objectData.activeAuthList);
                                                }
                                                component.set("v.isChildCareEditable",response.objectData.isChildCareEditable);
                                                component.set("v.isCaseInfoEditable",response.objectData.isCaseInfoEditable);

                                                if(!$A.util.isEmpty(response.objectData.existingRefUnPrc) ){
                                                    component.set("v.existingRefUnPrc",true);
                                                    component.set("v.isNewIndivReceived",false);
                                                    component.set("v.isChildCareEditable",false);
                                                    component.set("v.isCaseInfoEditable",false);
                                                    var toastEvent1 = $A.get("e.force:showToast");
                                                    var errorMsg ="There is a referral application previously received for the Referral ID "+component.get("v.referralId")+"  but not yet processed. Please process the previous referral first. ";
                                                    toastEvent1.setParams({
                                                        "title": "Error!",
                                                        "message": errorMsg,
                                                        "type" : "error"
                                                    });
                                                    toastEvent1.fire();
                                                    
                                                }else{
                                                    component.set("v.existingRefUnPrc",false);  
                                                }
                                            }
                                        }, {'appProcessQueueId':component.get("v.recordId")}, false, null);
    },
    doFinish :function(component, event, helper){
        var incomeRefList = component.get("v.incomeRefList");
        var caseRefList = component.get("v.caseRefList");
        var showErrorMsg = false;
        if(!$A.util.isEmpty(incomeRefList) || !$A.util.isEmpty(incomeRefList)){
            if(!$A.util.isEmpty(incomeRefList) && !component.get("v.netIncomeAccOrRej")){
                var toastEvent1 = $A.get("e.force:showToast");
                toastEvent1.setParams({
                    "title": "Error!",
                    "message": "You must approve/deny the changes from Comparison Module to proceed further.",
                    "type" : "error"
                });
                toastEvent1.fire();
            }else if(!$A.util.isEmpty(caseRefList) && !component.get("v.countyAccOrRej")){
                var toastEvent1 = $A.get("e.force:showToast");
                toastEvent1.setParams({
                    "title": "Error!",
                    "message": "You must approve/deny the changes from Comparison Module to proceed further.",
                    "type" : "error"
                });
                toastEvent1.fire();
            }else{
                if(component.get("v.countyChange")){
                    var toastEvent1 = $A.get("e.force:showToast");
                    toastEvent1.setParams({
                        "title": "Waring!",
                        "message": "Please take appropriate county transfer action on the case.",
                        "type" : "warning"
                    });
                    toastEvent1.fire();
                }
                
                helper.updateAppPrcQueueHlp(component, event, helper); 
            }
        }else{
            if(component.get("v.countyChange")){
                    var toastEvent1 = $A.get("e.force:showToast");
                    toastEvent1.setParams({
                        "title": "Waring!",
                        "message": "Please take appropriate county transfer action on the case.",
                        "type" : "warning"
                    });
                    toastEvent1.fire();
                }
                
                helper.updateAppPrcQueueHlp(component, event, helper);
        }
        
        /*  var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.caseIdToRedirect"),
            "slideDevName": "related"
        });
        navEvt.fire();*/
        
    },
    onCancel :function(component, event, helper){
        
        debugger;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.recordId"),
            "slideDevName": "related"
        });
        navEvt.fire();
   
    },
    doNext : function(component, event, helper){
        helper.doNextHlp(component, event, helper);
    },
})