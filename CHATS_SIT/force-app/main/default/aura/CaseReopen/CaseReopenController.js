({
    doInit : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.getInitData", 
                                        function(response){
                                            component.set("v.case",response.objectData.data);
                                            component.set("v.caseApplnDateInfo.DTE_APPLN_OLD__c", response.objectData.data.DTE_APPLN__c);// CCCAP-13251
                                            var tempCaseObj = JSON.parse(JSON.stringify(component.get("v.case")));
                                            component.set("v.caseCopy",tempCaseObj);
                                            component.set("v.newCaseStatus",response.objectData.newCaseStatus);
                                            component.set('v.isCountyMatch',response.objectData.isCountyMatch);
                                            component.set('v.countyName',response.objectData.countyName);
                                            if(response.objectData.data.T_SBSD_CASE10__r!=undefined && response.objectData.data.T_SBSD_CASE10__r.length>0){
                                                component.set("v.caseStatus",response.objectData.data.T_SBSD_CASE10__r[0]);
                                            }
                                            if(response.objectData.currentCaseStatusMode){
                                                component.set("v.currentCaseStatusMode",response.objectData.currentCaseStatusMode);
                                            }
                                            if(response.objectData.ipvDisqualification){
                                                component.set("v.ipvDisqualification", response.objectData.ipvDisqualification);
                                                component.set("v.ipvDisqualificationMsg", response.objectData.warningMsg);
                                            }
                                            component.set('v.currentTabNumber',1);
                                        }, {'caseId':component.get("v.recordId")}, false, null);
    },
    
    doCancel : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        helper.goToRecord(recordId,'detail');        
    },
    
    doFinish : function(component, event, helper) {
        var ipvDisqualification = component.get("v.ipvDisqualification");
        var dateToday = new Date();
        var pageMessages = [];
        var caseRec_val = component.get("v.case");
        var caseCopy_val = component.get("v.caseCopy");
        var applnDate_val = new Date(caseRec_val.DTE_APPLN__c);
        applnDate_val.setDate(applnDate_val.getDate() + 1);
        applnDate_val.setHours(0); applnDate_val.setMinutes(0); applnDate_val.setSeconds(0);applnDate_val.setMilliseconds(0);
        if(!component.get('v.isCountyMatch')){
            pageMessages.push('The case that you are trying to reopen is with '+component.get('v.countyName')+' county. This does not match your assigned county(ies).');
        }else if(component.get("v.childCareProgram") == 'LI' || component.get("v.childCareProgram") =='FT' || component.get("v.childCareProgram") =='TF'){
            /* Commenting as part of CCCAP-13251
            if(component.get("v.newCaseStatus").CDE_ELIGTY_CONTNUS__c=='N' && caseRec_val.DTE_APPLN__c == caseCopy_val.DTE_APPLN__c && component.get("v.showConfirmationModal")){
                //helper.callModal(component,'confirmationModalOnReopenWithApplnDate'); Commenting as part of CCCAP-13251
            } else if (component.get("v.newCaseStatus").CDE_ELIGTY_CONTNUS__c=='N' && applnDate_val > dateToday){
               // pageMessages.push($A.get("$Label.c.APP_DTE_MUST_BE_IN_FUTURE"));  commenting as part of CCCAP-13251
            } else if(component.get("v.newCaseStatus").CDE_ELIGTY_CONTNUS__c=='N' && caseRec_val.DTE_APPLN__c < caseCopy_val.DTE_APPLN__c ){
                //pageMessages.push($A.get("$Label.c.UpdAppDate_MustBe_Grtr_OrigAppRecvdDate")); commenting as part of CCCAP-13251
            } else {*/
                if(ipvDisqualification){
                    helper.callModal(component,'confirmationModalOnIPVDisqualification'); 
                }
                else{
                    helper.ReopenCompletion(component, event, helper);
                }
           // }
        } else {
            if(ipvDisqualification){
                helper.callModal(component,'confirmationModalOnIPVDisqualification');   
            }else{
                helper.ReopenCompletion(component, event, helper);  
            }
        }
        if(pageMessages.length > 0){
            component.set("v.pageMessages",pageMessages);
            component.set("v.messageType","error");    
        }
    },
    
    actionOnYesButton: function(component, event, helper) {
        var modalCall = component.find('confirmationModalOnReopenWithApplnDate');
        var ipvDisqualification = component.get("v.ipvDisqualification");
        modalCall.hideConfirmModal();
        if(ipvDisqualification){
            helper.callModal(component,'confirmationModalOnIPVDisqualification');
        }
        else{
            helper.ReopenCompletion(component, event, helper);
        }
    },
    actionOnIPVYesButton: function(component, event, helper) {
        var modalCall = component.find('confirmationModalOnIPVDisqualification');
        modalCall.hideConfirmModal();
        helper.ReopenCompletion(component, event, helper);
    }
})