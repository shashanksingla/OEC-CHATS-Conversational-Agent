({
    launchInitialForm : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var action = component.get("c.getInitData");
        helper.setSampleYear(component);
        action.setParams({
            "recordId" : recordId,
            "screenMode" : component.get("v.screenMode")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res.isSuccessful){
                    component.set('v.caseRecord', res.objectData.caseRecord);
                    component.set('v.screenMode', res.objectData.screenMode);
                    component.set('v.allCauseOptions', res.objectData.allCauseOptions);
                    component.set('v.allErrorOptions', res.objectData.allErrorOptions);
                    component.set('v.caseReviewObj.Reviewer_Name__c', res.objectData.reviewerName);
                    component.set('v.caseReviewObj.Reviewer_Title__c', res.objectData.reviewerTitle);
                    
                    if(res.objectData.caseType == 'LI'){
                        component.set("v.caseReviewObj.Eligibility_Period_From__c", res.objectData.caseRecord.DTE_APPLN__c);
                        component.set("v.caseReviewObj.Eligibility_Period_To__c", res.objectData.caseRecord.DTE_REDET_CASE__c);
                    }
                    if(res.objectData.screenMode == 'NEW'){
                        component.set('v.showCaseOwnerForm1', res.objectData.showCaseOwnerForm); // Added by Rishav for CCCAP-7603
                        component.set('v.showQuestion1', res.objectData.showInitialForm);
                        component.set('v.showReviewForm', !res.objectData.showInitialForm && !res.objectData.showCaseOwnerForm);
                        component.set("v.caseReviewObj.Sample_Year__c", null);
                        component.set('v.caseReviewObj.Case__c', recordId);
                        var reviewDate = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
                        component.set('v.reviewDate', reviewDate);
                    }else if(res.objectData.screenMode == 'EDIT'){
                        component.set('v.caseType', res.objectData.caseType);
                        component.set('v.showReviewForm', true);
                        component.set('v.caseReviewObj', res.objectData.caseReviewObj);
                        var reviewDate = $A.localizationService.formatDate(res.objectData.caseReviewObj.CreatedDate, "YYYY-MM-DD");
                        component.set('v.reviewDate', reviewDate);
                        component.set('v.errorCount', res.objectData.errorCount);
                    }else if(res.objectData.screenMode == 'VIEW'){
                        component.set('v.caseType', res.objectData.caseType);
                        component.set('v.showReviewForm', false);
                        component.set('v.showQuestion1', false);
                        component.set('v.caseReviewObj', res.objectData.caseReviewObj);
                    }
                } else {
                    helper.showToast('error', res.errorMessage);
                }
            } else {
                helper.showToast('error', response.getError);
            }
        });
        $A.enqueueAction(action);
    },
    
    // Sample Year field value and assignment
    setSampleYear : function(component) {
        var today = new Date();
        var currentYear = today.getFullYear();
        var currentYearOptions = component.get("v.sampleYearOptions");
        var sampleYearOptions = [];
        var option = {
            "label": "--None--",
            "value": null
        };
        sampleYearOptions.push(option);
        for(var i=currentYearOptions[0]; i<=currentYear; i++){
            var option = {
                "label": i.toString(),
                "value": i.toString()
            };
            sampleYearOptions.push(option);
        }
        component.set("v.sampleYearOptions", sampleYearOptions);
    },
    
    setReviewStatus : function(component) {
        if(component.get("v.errorCount") > 0){
            component.set("v.caseReviewObj.Review_Status__c", "3");
        } else if(component.get("v.errorCount") < 0) {
            component.set("v.caseReviewObj.Review_Status__c", "1");
        } else {
            component.set("v.caseReviewObj.Review_Status__c", "2");
        }
    },
    
    upsertCaseReview : function(component, event, helper, methodName) {
        var isValid = true;
        // Added by Rishav for CCCAP-7603
        if(methodName == 'doSubmit' || (methodName == 'doSave' && component.get("v.caseReviewObj.Review_Status__c")!='1')){ // Skip required field validation while Saving
            var allQuestionRowCmp = component.find("questionRow");
            isValid = helper.validateCurrentPage(component, event, helper);
            allQuestionRowCmp.forEach(function(questionRowCmp, index) {
                if(!questionRowCmp.checkRowValidity('')){
                    isValid = false;
                }
            });
        }
        if(component.get("v.caseType") != 'LI'){
            isValid = helper.validateEligibilityDates(component, event, helper, isValid);
        }
        if(isValid){ 
            if((component.get('v.screenMode')=='NEW') || (component.get("v.caseReviewObj.Review_Status__c")=='1')){
            	helper.updateProgramType(component);
            }
            if(methodName == 'doSave'){
                if(component.get("v.caseReviewObj.IsSubmitted__c")){
                    helper.setReviewStatus(component);
                }
            } else {
                helper.setReviewStatus(component); 
            }
            var caseReviewObj = component.get('v.caseReviewObj');
            var responseWrapperList = component.get('v.responseWrapperList');
            console.log('caseReviewObj-->'+JSON.stringify(caseReviewObj));
            if(component.get('v.caseType') !='LI' && component.get('v.caseType') !='TF'){
                responseWrapperList = [];
            }
            console.log('responseWrapperList-->'+JSON.stringify(responseWrapperList));
            var action = component.get("c.saveCaseReview");
            action.setParams({"caseReviewObj" : caseReviewObj, 
                              "responseWrapperList" : responseWrapperList,
                              "methodName" : methodName,
                              "screenMode" : component.get('v.screenMode')});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if(state === "SUCCESS") {
                    var res = response.getReturnValue();
                    if(res.isSuccessful){                        
                        if(methodName == 'doSave'){
                            helper.showToast('success', 'Case Review record saved successfully');
                            helper.redirectToRecord(res.objectData.caseReviewObj.Id);
                        }
                        if(methodName == 'doSubmit'){
                        	component.set('v.caseReviewObj', res.objectData.caseReviewObj);
                            component.set('v.showTaskReminder', true);
                        }
                    } else {
                        helper.showToast('error', res.errorMessage);
                    }
                } else {
                    helper.showToast('error', response.getError);
                }
            });
            $A.enqueueAction(action);
        } else {
            helper.showToast('error', $A.get('$Label.c.CaseReview_Error_PageError'));
        }
    },
    
    validateEligibilityDates : function(component, event, helper, isValidTillNow) {
        var isValid = isValidTillNow;
        var currentDate = this.getDateInUTC(new Date());
        var fromDate = this.getDateInUTC(component.get('v.caseReviewObj.Eligibility_Period_From__c'));
        var toDate = this.getDateInUTC(component.get('v.caseReviewObj.Eligibility_Period_To__c'));
        var inputComponents = component.find('input-field');
        if(inputComponents){
            if(inputComponents.length > 0){
                component.find('input-field').reduce(function(validSoFar, cmp) {
                    if(cmp.get('v.Id') == 'eligDateFrom'){
                        if(fromDate > currentDate){
                            isValid = false;
                            cmp.set('v.errorMessage', $A.get('$Label.c.CaseReview_Error_FutureDate'));
                            cmp.showError();
                        }
                    }
                    if(cmp.get('v.Id') == 'eligDateTo'){
                        var sampleMonth = component.get('v.caseReviewObj.Sample_Month__c');
                        var sampleYear = component.get('v.caseReviewObj.Sample_Year__c');
                        if(sampleMonth && sampleYear){
                            var sampleDate = new Date(sampleYear, sampleMonth-1, 1);
                            if(toDate < sampleDate){
                                isValid = false;
                                cmp.set('v.errorMessage', $A.get('$Label.c.CaseReview_Error_SampleMonth'));
                                cmp.showError();
                            }
                        }
                        if(fromDate > toDate){
                            isValid = false;
                            cmp.set('v.errorMessage', $A.get('$Label.c.CaseReview_Error_ToDateFromDate'));
                            cmp.showError();
                        }
                    }
                }, true);
            }
        }
        return isValid;
    },
    
    getDateInUTC : function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    
    // Added by Rishav for CCCAP-7697
    calculateCorrectSubsidyAmount : function(component) {
        var isPmtImproper = component.get("v.caseReviewObj.Improper_Payment__c");
        var subsidyAmt = component.get("v.caseReviewObj.Subsidy_Amount_Paid__c");
        if(isPmtImproper == "Y" || isPmtImproper == "Yes"){
            var pmtType = component.get("v.caseReviewObj.Improper_Payment_Type__c");
            var pmtAmount = parseFloat(component.get("v.caseReviewObj.Improper_Payment_Amount__c"));
            var subAmount = parseFloat(component.get("v.caseReviewObj.Subsidy_Amount_Paid__c"));
            if(!isNaN(pmtAmount) && !isNaN(subAmount)){
                if(pmtType == 'Overpayment'){
                    component.set("v.correctSubsidyAmount", subAmount - pmtAmount);
                }
                if(pmtType == 'Underpayment'){
                    component.set("v.correctSubsidyAmount", subAmount + pmtAmount);
                }
            } else {
                component.set("v.correctSubsidyAmount", subsidyAmt);
            }
        } else {
            component.set("v.caseReviewObj.Improper_Payment_Amount__c", 0.00);
            component.set("v.correctSubsidyAmount", subsidyAmt);
            component.set("v.caseReviewObj.Improper_Payment_Type__c", null);
        }
    },
    
    //Added by Nikita for CCCAP-9146
    updateProgramType : function(component){        
    	component.set("v.caseReviewObj.Program_Type__c", component.get("v.caseType"));
        console.log('updateProgramType');
	},
    
    //CCCAP-12156
    handleSampleMonthYear: function(component, event, helper) {
        let lastProgram = component.get('v.caseType');
        component.set('v.showQuestions', false);
        
        var action = component.get("c.handleSampleMonthUpdates");
        var params = {
            "recordId": component.get('v.recordId'),
            "sampleMonth": component.get("v.caseReviewObj.Sample_Month__c"),
            "sampleYear": component.get("v.caseReviewObj.Sample_Year__c"),
            "screenMode": component.get("v.screenMode"),
            "caseId": component.get('v.recordId')
        };
        
        if (component.get("v.screenMode") != "NEW") {
            params.caseId = component.get("v.caseReviewObj.Case__c");
        }
                
        action.setParams(params);
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                if (res.isSuccessful) {
                    if (res.objectData.caseType == 'LI') {
                        component.set("v.caseReviewObj.Eligibility_Period_From__c", component.get('v.caseRecord.DTE_APPLN__c'));
                        component.set("v.caseReviewObj.Eligibility_Period_To__c", component.get('v.caseRecord.DTE_REDET_CASE__c'));
                    }
                    component.set('v.caseType', res.objectData.caseType);
                    component.set('v.caseTypeLabel', res.objectData.caseTypeLabel); //CCCAP-12378
                    if (lastProgram != res.objectData.caseType || component.get('v.firstProgramFetch') == false) {
	                    component.set('v.responseWrapperList', JSON.parse(JSON.stringify(res.objectData.responseWrapperList)));                        
                    }
                    component.set('v.showQuestions', true);
                } else {
                    if (res.objectData && res.objectData.programNotExpected) {
                        component.set('v.caseType', '');
                        component.set('v.caseTypeLabel',''); //CCCAP-12378
                        helper.showToast('error', res.errorMessage);
                        component.set('v.responseWrapperList', []);
                    }
                }
                component.set("v.showSpinner", false);
                component.set('v.firstProgramFetch', true);
            } else if (state === "ERROR") {
                var errors = response.getError();
                helper.showToast('error', 'An error occurred while processing the request.');
                component.set("v.showSpinner", false);
            }
        });
        
        $A.enqueueAction(action);
    }
        //end CCCAP-12156

})