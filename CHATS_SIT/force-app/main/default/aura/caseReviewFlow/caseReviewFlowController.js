({
    doInit : function(component, event, helper) {
        document.title = "Eligibility Case Review | Salesforce";
        var recordId = component.get("v.recordId");
        component.set("v.showSpinner", true);
        var action = component.get("c.checkEligibility");
        action.setParams({"recordId" : recordId,
                          "isDelete" : false
                         });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res.isSuccessful){
                    component.set("v.accessLevel", res.objectData.accessLevel);
                    component.set("v.showSpinner", false);
                    // Added 'Draft Form' logic below by Rishav for CCCAP-7603
                    component.set("v.showDraftForm", res.objectData.showDraftForm); 
                    if(res.objectData.showDraftForm){
                        component.set("v.showDraftForm_Q1", true);
                        component.set("v.lastDraftReviewId", res.objectData.lastDraftReviewId);
                    } else {
                        helper.launchInitialForm(component, event, helper);
                    }
                } else {
                    component.set("v.showSpinner", false);
                    helper.showToast('error', res.errorMessage);
                    window.history.back();
                }
            } else {
                helper.showToast('error', response.getError);
            }
        });
        $A.enqueueAction(action);
    },
    
    doYes1 : function(component, event, helper) {
        component.set('v.showQuestion2', true);
    },
    
    doYes2 : function(component, event, helper) {
        component.set('v.showReviewForm', true);
        component.set('v.showQuestion1', false);
        component.set('v.showCaseOwnerForm1', false);
        //added for CCCAP-11863 by Shashank
        component.set('v.caseReviewObj.No_Change_Indicator__c','Y'); // Change is there in Case Review since last Case Review 
    },
    
    // Added by Rishav for CCCAP-7603
    doYes3 : function(component, event, helper) {
        component.set('v.showReviewForm', true);
        component.set('v.showCaseOwnerForm1', false);
    },
    
    // Added by Rishav for CCCAP-7603
    doYes4 : function(component, event, helper) {
        component.set("v.showDraftForm", false);
        component.set('v.recordId', component.get('v.lastDraftReviewId'));
        component.set('v.screenMode', 'EDIT');
        helper.launchInitialForm(component, event, helper);
    },
    
    // Added by Rishav for CCCAP-7603
    doYes5 : function(component, event, helper) {
        component.set("v.showDraftForm", false);
        component.set("v.showSpinner", true);
        var action = component.get("c.deleteCaseReview");
        action.setParams({"recordId" : component.get("v.lastDraftReviewId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res.isSuccessful){
                    component.set("v.showSpinner", false);
                    helper.launchInitialForm(component, event, helper);
                } else {
                    component.set("v.showSpinner", false);
                    helper.showToast('error', res.errorMessage);
                }
            } else {
                helper.showToast('error', response.getError);
            }
        });
        $A.enqueueAction(action);
    },
    
    doNo1 : function(component, event, helper) {
        component.set('v.showReviewForm', true);
        component.set('v.showQuestion1', false);
        component.set('v.showCaseOwnerForm1', false);
    },
    
    doNo2 : function(component, event, helper) {
        var action = component.get("c.resubmitLastReview");
        action.setParams({"recordId" : component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res.isSuccessful){
                    component.set("v.showSpinner", false);
                    helper.showToast('success', 'Case Review re-submitted successfully');
                    helper.redirectToRecord(res.objectData.caseReviewId);
                } else {
                    component.set("v.showSpinner", false);
                    helper.showToast('error', res.errorMessage);
                }
            } else {
                helper.showToast('error', response.getError);
            }
        });
        $A.enqueueAction(action);
    },
    
    // Added by Rishav for CCCAP-7603
    doNo3 : function(component, event, helper) {
        component.set('v.showCaseOwnerForm2', true);
    },
    
    // Added by Rishav for CCCAP-7603
    doNo4 : function(component, event, helper) {
        component.set("v.showDraftForm_Q1", false);
        component.set("v.showDraftForm_Q2", true);
    },
    
    // Added by Rishav for CCCAP-7603
    doNo5 : function(component, event, helper) {
        component.set("v.showDraftForm_Q2", false);
        component.set("v.showDraftForm_Q3", true);
    },
    
    doOk : function(component, event, helper) {
        helper.redirectToRecord(component.get('v.caseReviewObj.Id'));
    },
    
    // Added by Rishav for CCCAP-7603
    doOk2 : function(component, event, helper) {
        helper.redirectToRecord(component.get('v.recordId'));
    },
    
    // Added by Rishav for CCCAP-7603
    doOk3 : function(component, event, helper) {
        window.history.back();
    },
    
    doSave : function(component, event, helper, methodName) {
        helper.upsertCaseReview(component, event, helper, 'doSave');
    },
    
    doCancel : function(component, event, helper) {
        window.history.back();
    },
    
    doSubmit : function(component, event, helper, methodName) {
        helper.upsertCaseReview(component, event, helper, 'doSubmit');
    },
    
    updateParentFee : function(component, event, helper) {
        var sampleMonth = component.get("v.caseReviewObj.Sample_Month__c");
            var sampleYear = component.get("v.caseReviewObj.Sample_Year__c");
        if(component.get("v.screenMode") != 'VIEW'){
            var isParentFeeBlank = false;
            var isSubsidyAmountBlank = false;
            var errorMessage = "";
            
            if(!$A.util.isEmpty(sampleMonth) && !$A.util.isEmpty(sampleYear)){
                component.set("v.showSpinner", true);
                var action = component.get("c.getParentFeeSubsidyAmount");
                action.setParams({
                    "recordId" : component.get("v.caseRecord.Id"),
                    "sampleMonth" : sampleMonth,
                    "sampleYear" : sampleYear,
                    "screenMode" : component.get("v.screenMode")
                });
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if(state === "SUCCESS") {
                        var res = response.getReturnValue();
                        if(res.isSuccessful){
                            component.set("v.showSpinner", false);
                            if(res.objectData.parentFee){
                                component.set("v.caseReviewObj.Parent_Fee__c", res.objectData.parentFee.amt_copay_case_assesd__c);
                            } else {
                                component.set("v.caseReviewObj.Parent_Fee__c", 0.00);
                                isParentFeeBlank = true;
                            }
                            if(res.objectData.subsidyAmount){
                                component.set("v.caseReviewObj.Subsidy_Amount_Paid__c", res.objectData.subsidyAmount);
                            } else {
                                component.set("v.caseReviewObj.Subsidy_Amount_Paid__c", 0.00);
                                isSubsidyAmountBlank = true;
                            }
                            if(isParentFeeBlank && isSubsidyAmountBlank){
                                errorMessage = 'There is no Parent Fee allocated and no Subsidy Amount paid for the selected Sample Month and Sample Year.';
                            } else if(isParentFeeBlank && !isSubsidyAmountBlank) {
                                errorMessage = 'There is no Parent Fee allocated for the selected Sample Month and Sample Year.';
                            } else if(isSubsidyAmountBlank && !isParentFeeBlank) {
                                errorMessage = 'There is no Subsidy Amount paid for the selected Sample Month and Sample Year.';
                            }
                            helper.showToast('warning', errorMessage);
                    	} else {
                            component.set("v.showSpinner", false);
                            helper.showToast('error', res.errorMessage);
                        }
                    } else {
                        helper.showToast('error', response.getError);
                    }
                });
                $A.enqueueAction(action);
            }
        }
        if(sampleMonth && sampleYear){
            helper.handleSampleMonthYear(component,event,helper); 
        }else{
            component.set('v.caseType','');
            component.set('v.caseTypeLabel','');  //CCCAP-12378
            component.set('v.showQuestions', false);
        }
    },
    
    // Added by Rishav for CCCAP-7697
    calculateCorrectSubsidyAmount : function(component, event, helper) {
        helper.calculateCorrectSubsidyAmount(component);
    },
    
    //Added by Nikita for CCCAP-9347
    roundOffPaymentAmount : function(component, event, helper) {
        var pmtAmount = component.get("v.caseReviewObj.Improper_Payment_Amount__c");
        var pmtAmountRounded = Number(pmtAmount).toFixed(2);
        component.set("v.caseReviewObj.Improper_Payment_Amount__c",pmtAmountRounded);
    }
})