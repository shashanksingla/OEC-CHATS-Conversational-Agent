({    
    validateCR107 :function(component,event,helper){
        var newparam = component.get("v.param");
        let isValid = newparam.NME_CORSPD__c != 'CR107';
        let checkList = newparam.CR107_Checklist__c || '';
        let items =  checkList.split(';');
        if(items.length ==2 && items.includes('01') && items.includes('18')){
            helper.toastMessage('Error','Please select another Missing Verification that impacts case eligibility to proceed with this correspondence.');
        }else if(items.length ==1 && items.includes('01')){
            helper.toastMessage('Error','Another missing verification selection must be made to proceed. This notice cannot be used for only Child Care information requests, as this does not impact a family’s eligibility. Please use CR212.');
        }else if(items.length ==1 && items.includes('18')){
            helper.toastMessage('Error','Please select another Missing Verification that impacts case eligibility to proceed with this correspondence.');
        }else{
            isValid = true;
        }
        return isValid;
	},
    updateItem: function(component, event, helper) {
        if(this.validateCR107(component,event,helper)){ // CCCAP-7709
        component.set("v.toggleSpinner",true);
        var isCR114Valid= false;
        var isCR207Valid= false;
        var isValidCounty = true;        
        var newParam1 = component.get("v.param");

        component.set("v.isDisbaleTrue",true); // Added by Diya for CCCAP-6345 
        // Validate County 
        if(newParam1.CDE_COUNTY__c){            
            var cAction = component.get("c.validateCounty");
            cAction.setParams({
                county: newParam1.CDE_COUNTY__c             
            });
            cAction.setCallback(this, function(r) {
                var state = r.getState();
                if (state == "SUCCESS") {
                    var response = r.getReturnValue();
                    if(response.isValid == false){
                        isValidCounty = false;
                        component.set("v.toggleSpinner",false);                        
                        var countyError = 'The county '+response.countyName+' does not match your assigned county(ies).';
                        this.toastMessage('Error', countyError);
                        component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                    }
                } else if (state == "ERROR") {
                    component.set("v.toggleSpinner",false);
                    this.toastMessage('Error', 'Error in validating county');
                    component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                }
            });
            $A.enqueueAction(cAction);           
        }
        
        // Validate Case Id
        if(newParam1.IDN_CASE__c){
            var caseAction = component.get("c.validateCase");
            caseAction.setParams({
                caseId: newParam1.IDN_CASE__c                
            });
            caseAction.setCallback(this, function(r) {
                var state = r.getState();
                if (state == "SUCCESS") {
                    var message = r.getReturnValue();
                    if(message == 'ValidCase'){
                        isCR114Valid =true;
                        isCR207Valid =true;
                        // Added 'CR110' below by Rishav for CCCAP-2213
                        if((newParam1.NME_CORSPD__c != 'CR114' && newParam1.NME_CORSPD__c != 'CR207' && newParam1.NME_CORSPD__c != 'CR110')) {
                            this.callProcessManualCorr(component, event, helper);
                        }
                    } else if (message == 'InvalidCase'){
                        component.set("v.toggleSpinner",false);
                        this.toastMessage('Error', 'Please provide the valid Case Id.');
                        component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                    } else if(message == 'InvalidCaseCounty'){
                        component.set("v.toggleSpinner",false);
                        this.toastMessage('Error', 'The case '+newParam1.IDN_CASE__c+ ' does not belong to your assigned county(ies).');
                        component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                    }
                } else if (state == "ERROR") {
                    component.set("v.toggleSpinner",false);
                    this.toastMessage('Error', 'Error in validating the Case Id');
                    component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                }
            });
            $A.enqueueAction(caseAction);           
        }
        
        // Validate Provider Id
        if(newParam1.IDN_PROVR__c){
            var isCR207ProValid= false;
            var provrAction = component.get("c.validateProvider");
            provrAction.setParams({
                providerId: newParam1.IDN_PROVR__c,               
            });
            provrAction.setCallback(this, function(r) {
                var state = r.getState();
                if (state == "SUCCESS") {
                    var message = r.getReturnValue();
                    if(message == 'ValidProvider'){
                        isCR207ProValid =true;
                        if((newParam1.NME_CORSPD__c != 'CR207') && isValidCounty) {
                            this.callProcessManualCorr(component, event, helper);
                        }
                    } else if(message == 'InvalidProvider'){
                        component.set("v.toggleSpinner",false);
                        this.toastMessage('Error', 'Please provide the valid Provider Id.');
                        component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                    } else if(message == 'InvalidProviderCounty'){
                        debugger;
                        if(newParam1.NME_CORSPD__c == 'CR702'){
                            this.callProcessManualCorr(component, event, helper);
                    }else{
                        component.set("v.toggleSpinner",false);
                        this.toastMessage('Error', 'The provider '+newParam1.IDN_PROVR__c+ ' does not belong to your assigned county(ies).');
                        component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345
                    }
                         
                    }
                } else if (state == "ERROR") {
                    component.set("v.toggleSpinner",false);
                    this.toastMessage('Error', 'Error in validating the Provider Id');
                    component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                }
            });
            $A.enqueueAction(provrAction);           
        }
        
        // Validate Child/Client Id
        if(newParam1.IDN_CLIENT__c){
            var childAction = component.get("c.validateChild");
            childAction.setParams({
                clientId: newParam1.IDN_CLIENT__c
            });
            childAction.setCallback(this, function(r) {
                var state = r.getState();
                if (state == "SUCCESS") {
                    var message = r.getReturnValue();
                    if(message == 'ValidChild') {
                        if(newParam1.NME_CORSPD__c != 'CR114' && newParam1.NME_CORSPD__c != 'CR207') {
                            this.callProcessManualCorr(component, event, helper);
                        } else if(isCR114Valid && (newParam1.NME_CORSPD__c == 'CR114')) {
                            this.callProcessManualCorr(component, event, helper);
                        } 
                    } else if (message == 'InvalidChild') {
                        // Added this if section by Rishav for CCCAP-2213
                        if(newParam1.NME_CORSPD__c == 'CR110'){
                            component.set("v.toggleSpinner",false);
                            this.toastMessage('Error', 'Please provide the valid Individual ID.');
                            component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                        } else if(newParam1.NME_CORSPD__c == 'CR207') { // Added else if by Rishav for CCCAP-4245
                            // Do nothing as 'c.validateCaseClientAssociation' check below will do the same
                        } else {
                            component.set("v.toggleSpinner",false);
                            this.toastMessage('Error', 'Please provide the valid Child Id.');
                            component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                        }
                    }
                } else if (state == "ERROR") {
                    component.set("v.toggleSpinner",false);
                    this.toastMessage('Error', 'Error in validating the Child Id');
                    component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 

                }
            });
            $A.enqueueAction(childAction); 
        }
        
        // Validate Adjustment Id
        if(newParam1.IDN_ADJMT__c){
            var adjustmentAction = component.get("c.validateAdjustment");
            adjustmentAction.setParams({
                adjustmentId: newParam1.IDN_ADJMT__c
            });
            adjustmentAction.setCallback(this, function(r) {
                var state = r.getState();
                if (state == "SUCCESS") {
                    var message = r.getReturnValue(); 
                    if(message == 'ValidAdjustment'){
                        if(isCR207Valid || isCR207ProValid) {
                            console.log('calling from adjustment');
                            var adjComProCaseAction=component.get("c.validateAdjtmtCaseProv");
                            adjComProCaseAction.setParams({
                                adjustmentId: newParam1.IDN_ADJMT__c,
                                providerId:newParam1.IDN_PROVR__c,
                                caseId:newParam1.IDN_CASE__c
                            });
                            adjComProCaseAction.setCallback(this, function(r) {
                                var state1 = r.getState();
                                if (state1 == "SUCCESS") {
                                    var message = r.getReturnValue();
                                    if(message == 'validProvAndCase'){
                                        // Start: Added below code by Rishav for CCCAP-4245
                                        // this.callProcessManualCorr(component, event, helper);
                                        var caseId = newParam1.IDN_CASE__c;
                                        var clientId = newParam1.IDN_CLIENT__c;
                                        if(newParam1.NME_CORSPD__c == 'CR207' && newParam1.IDN_CASE__c && newParam1.IDN_CLIENT__c) {
                                            var action = component.get("c.validateCaseClientAssociation");
                                            action.setParams({
                                                caseId : caseId,
                                                clientId : clientId
                                            });
                                            action.setCallback(this, function(response) {
                                                var state = response.getState();
                                                if(state == "SUCCESS") {
                                                    var isInvalid = response.getReturnValue();
                                                    if(isInvalid){
                                                        component.set("v.toggleSpinner",false);
                                                        this.toastMessage('Error', 'Client ID is not associated with the Case ID entered. Please verify and update the record ID.');
                                                        component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                                                    } else {
                                                        this.callProcessManualCorr(component, event, helper);
                                                    }
                                                } else if (state == "ERROR") {
                                                    component.set("v.toggleSpinner",false);
                                                    this.toastMessage('Error', 'Error in validating the Case and Client association');
                                                    component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                                                }
                                            });
                                            $A.enqueueAction(action);
                                        } else {
                                            this.callProcessManualCorr(component, event, helper);
                                        }
                                        // End : CCCAP-4245
                                    } else if (message == 'InvalidvalidProvAndCase'){
                                        component.set("v.toggleSpinner",false);
                                        this.toastMessage('Error', 'The Case ID/Provider ID is not associated with the Adjustment ID. Please verify the combination entered and try again.');
                                        component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                                    } else if(message == 'InvalidProvAndCaseCounty'){
                                        component.set("v.toggleSpinner",false);
                                        this.toastMessage('Error', 'The adjustment '+newParam1.IDN_ADJMT__c+ ' does not belong to your assigned county(ies).');
                                        component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                                    }
                                } else if (state1 == "ERROR") {
                                    component.set("v.toggleSpinner",false);
                                    this.toastMessage('Error', 'Error in validating the InvalidAdjustment Id');
                                    component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                                }
                            });
                            $A.enqueueAction(adjComProCaseAction);                                                         
                        }                    
                    } else if (message == 'InvalidAdjustment'){
                        component.set("v.toggleSpinner",false);
                        this.toastMessage('Error', 'The Adjustment ID must be a Recovery in Calculation Complete status.');
                        component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                    } else if (message == 'InvalidAdjustmentCounty'){
                        component.set("v.toggleSpinner",false);
                        this.toastMessage('Error', 'The adjustment '+newParam1.IDN_ADJMT__c+ ' does not belong to your assigned county(ies).');
                        component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                    }
                } else if (state == "ERROR") {
                    component.set("v.toggleSpinner",false);
                    this.toastMessage('Error', 'Error in validating the InvalidAdjustment Id');
                    component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                }
            });
            $A.enqueueAction(adjustmentAction);           
        }
    }        
    },
    
    callProcessManualCorr : function(component, event, helper) {
        var newParam1 = component.get("v.param");
        var action = component.get("c.processManualCorspd");
        // Added DQBeginDate,DQEndDate,DQHearingDate,numOfOccurrencesString,ContactPhoneNumber parameters and toString() logic below by Rishav for CCCAP-2213 & CCCAP-2769
        var numOfOccurrencesString;
        if(newParam1.Number_of_Occurrences__c){
            numOfOccurrencesString = newParam1.Number_of_Occurrences__c.toString();   
        }
        action.setParams({
            corspdName: 		newParam1.NME_CORSPD__c,
            caseId: 			newParam1.IDN_CASE__c,
            providerId: 		newParam1.IDN_PROVR__c,
            countyCode: 		newParam1.CDE_COUNTY__c,
            cr107Checklist: 	newParam1.CR107_Checklist__c,
            cr107Other: 		newParam1.CR107_OTHER_TEXT__c,
            cr702Checklist: 	newParam1.CR702_Checklist__c,
            cr702Text: 			newParam1.CR702_TEXT__c,
            dteOfDeadline:		component.get("v.manualchecklist").DTE_DEADLINE__c,
            clientId:			newParam1.IDN_CLIENT__c,
            adjustmentId:		newParam1.IDN_ADJMT__c,
            cr212checklist:		newParam1.CR212_Checklist__c,
            DQBeginDate: 		newParam1.Disqualification_Begin_Date__c,
            DQEndDate: 			newParam1.Disqualification_End_Date__c,
            DQHearingDate: 		newParam1.Disqualification_Hearing_Date__c,
            numOfOccurrences: 	numOfOccurrencesString,
            ContactPhoneNumber: newParam1.Contact_Phone_Number__c
        });
        action.setCallback(this, function(r) {
            var state = r.getState();
            if (state == "SUCCESS") {
                var corrSfid = r.getReturnValue();
                component.set("v.responseCorspd", corrSfid);
                this.callManualWebservice(component, event, helper);
            } else if (state == "ERROR") {
                component.set("v.toggleSpinner",false);
                this.toastMessage('Error', 'Error in creating the Manual Correspondence Request');
                component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
            }
        });
        $A.enqueueAction(action);
    },
    
    disabledfield: function(component, event) {
        var newparam2 = component.get("v.param");
        var action1 = component.get("c.performdisable");
        action1.setParams({
            corspdName: newparam2.NME_CORSPD__c
        });
        action1.setCallback(this, function(e) {
            console.log('return from server ' + e.getReturnValue());
            if (e.getReturnValue() == "C") {
                component.set('v.pidboolean', true);
                component.set('v.cidboolean', false);
                component.set('v.aidboolean', true);
            } else if (e.getReturnValue() == "P") {
                component.set('v.cidboolean', true);
                component.set('v.pidboolean', false);
                component.set('v.aidboolean', true);
            } else {
                component.set('v.cidboolean', false);
                component.set('v.pidboolean', false);
                component.set('v.aidboolean', false);
            }
            if(newparam2.NME_CORSPD__c == 'CR107'){ // CCCAP-7709 for defaulting DOD to 15 Days.
                const d = new Date();
                d.setDate(d.getDate() + 15);
                let manual = component.get("v.manualchecklist") || {};
                if(manual && !manual.DTE_DEADLINE__c){
                    let deadLineDate = d.toISOString();
                    component.set("v.manualchecklist.DTE_DEADLINE__c",deadLineDate);
                }
            }
        });
        $A.enqueueAction(action1);
    },
    
    callManualWebservice: function(component, event, helper) {
        var corrSfid = component.get("v.responseCorspd");
        var newParam1 = component.get("v.param");
        var generated='';
        component.set('v.generated','');
        var isSuccess=false;
        var a = component.get("c.getManualCorspdDetails");
        a.setParams({
            corrSfid: corrSfid,
            "provdrId":newParam1.IDN_PROVR__c,
            "casId":newParam1.IDN_CASE__c
        });
        a.setCallback(this, function(res) {
            var state1 = res.getState();
            if (state1 == "SUCCESS") {
                isSuccess=true;
                var corspdRtrnObject = res.getReturnValue();
                debugger;
                if((corspdRtrnObject != null) && (corspdRtrnObject != '') ) {
                    var path = JSON.stringify(corspdRtrnObject.path);
                    var fileName = JSON.stringify(corspdRtrnObject.fileName);
                    var path1 = path.slice(1, -1);
                    var fileName1 = fileName.slice(1, -1);
                    var labelUrl = $A.get("$Label.c.correspondenceTargetPdfServlet");
                    var url = labelUrl + 'pathInAws=' + path1 + '&fileName=' + fileName1;
                    //var pdfWin = window.open(url, "", "height=650,width=840");
                    component.set('v.generated','success');
                    generated='success';
                    var pdfWin= window.open("/apex/CorrespondencePage?fileName="+fileName1, "", "height=650,width=840");
                } else {
                    component.set("v.toggleSpinner",false);
                    this.toastMessage('Error', 'AEM Service Exception - Failed to retrive response from AEM Service');
                }
                component.set("v.toggleSpinner",false);
                
            } else if (state1 == "ERROR") {
                component.set("v.toggleSpinner",false);
                this.toastMessage('Error', 'Exception occured in Get Manual Correspondence Details Method');
            }
        });
        $A.enqueueAction(a);    
        var time = 1;
        window.setTimeout(
            $A.getCallback(function() {
                if(component.get('v.generated')=='success'){
                    helper.manualPrintMove(component,event,helper,corrSfid);                        
                }
            }), time * 7000);
        if(isSuccess){
            component.set("v.isOpen", false);
            component.set("v.childAttr", false);
            component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
        }
    },
    
    toastMessage: function(state, msg) {
        var showToast = $A.get("e.force:showToast");
        showToast.setParams({
            'title': state,
            'type': state.toLowerCase(),
            'message': msg
        });
        showToast.fire();
        return;
    },
    
    manualPrintMove: function(component,event,helper,corrSfid){
        var lstCorspdIds = component.get("v.responseCorspd");
        var action = component.get("c.processManualCorspdPrint");
        action.setParams({
            "corrSfid": corrSfid
        });
        action.setCallback(this, function(response) {
            var state2 = response.getState();
            var corrospRetun = response.getReturnValue();
            if (state2 == "SUCCESS") {
                if(corrospRetun.returnStatus!='Success'){
                    this.toastMessage('Warning','The record you selected to print has failed due to web service unavailability. Please try again after sometime');
                    component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
                }else{
                    this.toastMessage('Success','Success');
                }
                component.set("v.isOpen", false);
                component.set("v.childAttr", false);
            }else{
                this.toastMessage('Warning','The record you selected to print has failed due to web service unavailability. Please try again after sometime');
                component.set("v.isDisbaleTrue",false); // Added by Diya for CCCAP-6345 
            }
            
        });       
        $A.enqueueAction(action);
    },
    
    /*
     Author: Rishav Maji
     Description: validates if DQBeginDate is a past date
     Jira Id: CCCAP-2769
   	*/ 
    validateDQBeginDate : function(component, event, helper) {
        let DQBeginDateCmp = component.find("DQBeginDate");
        let dateInstance = new Date(DQBeginDateCmp.get("v.value"));
        let today = new Date();
        dateInstance.setHours(0,0,0,0);
        today.setHours(0,0,0,0);
        if(dateInstance < today)
            DQBeginDateCmp.setCustomValidity("Date entered cannot be in the past");
        else
            DQBeginDateCmp.setCustomValidity("");
        DQBeginDateCmp.reportValidity();
    },
    
    /*
     Author: Rishav Maji
     Description: updates DQEndDate field based on DQBeginDate & numOfOccurrences values
     Jira Id: CCCAP-2769
   	*/ 
    updateDQEndDate : function(component, event, helper) {
        if(component.get("v.param.Number_of_Occurrences__c") == 1){
            component.set("v.DQEndDateRequired", true);
            component.set("v.DQEndDatePlaceholder", "");
            component.set("v.param.Disqualification_End_Date__c", helper.genericDateUpdateLogic(component.get("v.param.Disqualification_Begin_Date__c"),null,12,null,true));
        } else if(component.get("v.param.Number_of_Occurrences__c") == 2) {
            component.set("v.DQEndDateRequired", true);
            component.set("v.DQEndDatePlaceholder", "");
            component.set("v.param.Disqualification_End_Date__c", helper.genericDateUpdateLogic(component.get("v.param.Disqualification_Begin_Date__c"),null,24,null,true));
        } else if(component.get("v.param.Number_of_Occurrences__c") >= 3) {
            component.set("v.DQEndDateRequired", false);
            component.set("v.DQEndDatePlaceholder", "Infinite");
            component.set("v.param.Disqualification_End_Date__c", null);
        } else {
            component.set("v.DQEndDateRequired", true);
            component.set("v.DQEndDatePlaceholder", "");
            component.set("v.param.Disqualification_End_Date__c", null);
        }
    },

    //added for CCCAP-11596
    clearAllFields : function (component){
        component.set("v.param.IDN_CASE__c", '');
        component.set("v.param.IDN_CLIENT__c", '');
        component.set("v.param.IDN_PROVR__c", '');
        component.set("v.param.CDE_COUNTY__c", '');
        component.set("v.manualchecklist.DTE_DEADLINE__c", '');
        component.set("v.param.CR107_Checklist__c", '');
        component.set("v.param.CR107_OTHER_TEXT__c", '');
        component.set("v.param.CR702_Checklist__c", '');
        component.set("v.param.CR702_TEXT__c", '');
        component.set("v.param.CR212_Checklist__c", '');
    }
})