({
    searchReasonCode: function(component, helper) {
        component.set("v.toggleSpinner", true);
        component.set("v.selectAllCheckbox", false);
        component.set("v.selectedCount", 0);
        var input = component.get("v.param1");
        var endDateRange = component.get("v.endDate");
        var requestedBy = component.get("v.userInfoId");
        var action = component.get("c.processCorspdSearch");
        action.setParams({
            corspdStatus: input.CDE_CORSPD_STATUS__c, 
            countyName: input.CDE_COUNTY__c,
            caseId: input.IDN_CASE__c,
            providerId: input.IDN_PROVR__C,
            dateRequested: input.DTE_REQ__c,
            dateRequestedEndRange: !$A.util.isEmpty(endDateRange)?endDateRange:null,
            correspondenceId: input.Name,
            correspondenceType: input.NME_CORSPD__c,
            correspondenceRecipientType: input.CDE_TYPE_RCPT__c,
            requestedBy: requestedBy,
            datePrintedBeginDate:null,
            datePrintedEndDate:null,
            screen: "CorrespondenceGeneration"
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var corspdRtrnObject = response.getReturnValue();
            if(state == "SUCCESS" && !$A.util.isEmpty(corspdRtrnObject) && !$A.util.isEmpty(corspdRtrnObject.payload) && !$A.util.isEmpty(corspdRtrnObject.payload.length)) {
                component.set("v.searchResult", corspdRtrnObject.payload);
                component.set('v.encapsulatedSearchResult', helper.setDisplayedResults(component, corspdRtrnObject.payload));
                component.set("v.totalNumberOfRecordsFound", corspdRtrnObject.corspdSearchListCount); // Added by Rishav for CCCAP-7499
                component.set("v.totalNumberOfRecordsDisplaying", corspdRtrnObject.payload.length); // Added by Rishav for CCCAP-7499
                var searchResultCount = component.get('v.searchResultCount'); // Added by Rishav for CCCAP-7499
                if(corspdRtrnObject && corspdRtrnObject.payload) {
                    if(component.get('v.totalNumberOfRecordsFound') > searchResultCount) {
                        helper.toastMessage('Warning','More records are available. Please refine your search criteria to limit the results');
                    }
                    component.set("v.searchResultList", true);
                } else {
                    component.set("v.searchResult", []);
                    component.set('v.numberOfPages', 0);
                    component.set('v.currentPageNo', 0);
                    component.set('v.encapsulatedSearchResult', []);
                    helper.toastMessage('Error','No Correspondence Exists for the given Input.');
                }
            } else if(state == "SUCCESS" && corspdRtrnObject.returnStatus == 'Failure' && !$A.util.isEmpty(corspdRtrnObject.errorMessage) && corspdRtrnObject.errorMessage.length > 0){
                var errorList = corspdRtrnObject.errorMessage
                for(var i = 0; i < errorList.length ; i++){
                    helper.toastMessage('Error',errorList[i].errorMsg);
                }
            } else {
                component.set("v.searchResult", []);
                component.set('v.numberOfPages', 0);
                component.set('v.currentPageNo', 0);
                component.set('v.encapsulatedSearchResult', []);
                helper.toastMessage('Error','No Correspondence Exists for the given Input.');
            }
            component.set("v.toggleSpinner", false);
        });
        $A.enqueueAction(action);
    },
    
    setDisplayedResults: function(component, listOfResults){
        var searchResultCount = component.get('v.searchResultCount');
        var length = listOfResults.length;
        var retVal = [];
        for (var i = 0; i < length; i += 1) {
            retVal[i] = new Object({
                'checked': false,
                'payload': listOfResults[i]
            });
        }
        component.set('v.numberOfPages', Math.ceil(length / searchResultCount));
        component.set('v.currentPageNo', 0);
        return retVal;
    },
    
    deleteSelected: function(component, event, delCorspdId, helper) {
        var listSearchResults = component.get("v.searchResult");
        var deleteAction = component.get("c.processCorspdDelete");
        deleteAction.setParams({
            "lstCorspdId": delCorspdId,
            "listSearchResults": listSearchResults
        });
        deleteAction.setCallback(this, function(response) {
            var state = response.getState();
            var corspdRtrnObject = response.getReturnValue();
            if (state == "SUCCESS" && !$A.util.isEmpty(corspdRtrnObject)) {
                if(corspdRtrnObject.returnStatus == 'Success'){
                    if (!$A.util.isEmpty(corspdRtrnObject.CountOfGeneratedRecordsInDelete) && corspdRtrnObject.CountOfGeneratedRecordsInDelete > 0)
                        helper.toastMessage('Error','One or more correspondence selected are in generated status. Please ensure correspondence are not in generated status in order to delete.');
                    else
                        helper.toastMessage('Success','Selected Correspondences are deleted.');
                    component.set("v.confirmationModal", false);
                    component.set("v.selectAllCheckbox", false);
                    component.set("v.selectedCount", 0);
                    component.set("v.searchResult", corspdRtrnObject.payload);
                    component.set('v.encapsulatedSearchResult', helper.setDisplayedResults(component, corspdRtrnObject.payload));
                } else {
                    helper.toastMessage('Error',JSON.stringify(corspdRtrnObject.errorMessage[0].errorMsg));
                }
            } else if (state == "ERROR") {
                helper.toastMessage('Error','Error in calling server side action.');
            }
            component.set("v.toggleSpinner", false);
        });
        $A.enqueueAction(deleteAction);
    },
    
    printSelected: function(component, helper, printCorspdId) {
        var stopSpinner = true;
        var time = 1; //in second
        var printAction = component.get("c.processCorspdPrint");
        printAction.setParams({
            "lstCorspdId": printCorspdId
        });
        printAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var corspdRtrnObject = response.getReturnValue();
                if (corspdRtrnObject.returnStatus == 'Success') {
                    if (corspdRtrnObject.CountOfRequestedRecordsInPrint != null && corspdRtrnObject.CountOfRequestedRecordsInPrint != undefined && corspdRtrnObject.CountOfRequestedRecordsInPrint > 0) {
                        helper.toastMessage('Error','One or more correspondence selected is not in generated status. Please ensure correspondence selected are in generated status in order to print');
                        component.set("v.selectedCount", 0);
                        //Add the logic to re-load with stored results
                        window.setTimeout(
                            $A.getCallback(function() {
                                helper.searchReasonCode(component, helper);
                            }), time * 1000);
                        //stopSpinner = false;
                    } else {
                        if ((corspdRtrnObject.payload.aem != null) && (corspdRtrnObject.payload.aem != '') && (corspdRtrnObject.payload.aem != undefined)) {
                            var path = JSON.stringify(corspdRtrnObject.payload.aem.path);
                            var fileName = JSON.stringify(corspdRtrnObject.payload.aem.assembledFilename);
                            var path1 = path.slice(1, -1);
                            var fileName1 = fileName.slice(1, -1);
                            if ((corspdRtrnObject.targetUrl != null) && (corspdRtrnObject.targetUrl != '') && (corspdRtrnObject.targetUrl != undefined)) {
                                var labelUrl = corspdRtrnObject.targetUrl;
                                var url = labelUrl + 'pathInAws=' + path1 + '&fileName=' + fileName1;
                                //var pdfWin = window.open(url, "", "height=650,width=840");
                                var pdfWin= window.open("/apex/CorrespondencePage?fileName="+fileName1, "", "height=650,width=840");
                                //Add the logic to re-load with stored results display
                                window.setTimeout(
                                    $A.getCallback(function() {
                                        helper.searchReasonCode(component, helper);
                                    }), time * 5000);
                            }
                        }
                        component.set("v.selectedCount", 0);
                    }
                } else {
                    if(typeof corspdRtrnObject.errorMessage[0].errorMsg=='string'){
                        helper.toastMessage('Error',corspdRtrnObject.errorMessage[0].errorMsg);
                    } else {
                        helper.toastMessage('Error',JSON.stringify(corspdRtrnObject.errorMessage[0].errorMsg));
                    }
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    component.set("v.selectedCount", 0);
                    //Add the logic to re-load with stored results
                    window.setTimeout(
                        $A.getCallback(function() {
                            helper.searchReasonCode(component, helper);
                        }), time * 5000);
                    stopSpinner = false;
                }
            } else if (state == "ERROR") {
                helper.toastMessage('Error','Error in calling server side action.');
                stopSpinner = false;
            }
            component.set("v.toggleSpinner", stopSpinner);
        });
        $A.enqueueAction(printAction);
    },
    
    viewSelectedCorspd: function(component, event, corspdId, helper) {
        var self = this;
        var time = 1; //in second
        component.set("v.retryAttempts",component.get("v.retryAttempts")+1);
        console.log('corspdId ' + corspdId);
        component.set("v.toggleSpinner", true);
        var viewCorspd = component.get("c.processCorspdQueueToView");
        viewCorspd.setParams({
            "corspdId": corspdId
        })
        viewCorspd.setCallback(this, function(response) {
            var state = response.getState();
            if(state == "SUCCESS") {
                var corspdRtrnObject = response.getReturnValue();
                if (corspdRtrnObject.returnStatus == 'Success') {
                    component.set("v.retryAttempts",0);
                    if (corspdRtrnObject.CorrespondenceAlreadyGenerated == true) {
                        var time = 1;
                        window.setTimeout(
                            $A.getCallback(function() {
                                var alreadygenUrl = corspdRtrnObject.targetUrl + 'pathInAws=correspondence/request' + '&fileName=' + corspdRtrnObject.CorrespondenceFileName;
                                //var alreadyGenpdf = window.open(alreadygenUrl, "", "height=650,width=840");
                                var stopSpinner = true;
                                var printDateAction = component.get("c.addPrintedDateToCorspdDate");
                                printDateAction.setParams({
                                    "lstCorspdId": corspdId,
                                    "alreadygenUrl":alreadygenUrl,
                                    "fileName":corspdRtrnObject.CorrespondenceFileName                            
                                });
                                printDateAction.setCallback(this,function(response){
                                    var corspdRtrn = response.getReturnValue();
                                    var state1 = response.getState();
                                    if(state1=='SUCCESS'){
                                        if(corspdRtrn.returnStatus=='Success'){                                        
                                            if(corspdRtrn.payload.is200){
                                                var pdfWin= window.open("/apex/CorrespondencePage?fileName="+corspdRtrnObject.CorrespondenceFileName, "", "height=650,width=840");
                                                
                                                window.setTimeout(
                                                    $A.getCallback(function() {
                                                        helper.searchReasonCode(component, helper);
                                                    }), time * 3000);
                                            } else{
                                                helper.toastMessage('Error',corspdRtrn.payload.errorMessage);                                            
                                            }
                                        }else if(corspdRtrn.errorMessage!=null){
                                            helper.toastMessage('Error','Error in calling server side action');
                                        }
                                    }else if(state1=='ERROR'){
                                        helper.toastMessage('Error','Error in calling server side action.');
                                        stopSpinner = false;
                                    }
                                    component.set("v.toggleSpinner", false);
                                });$A.enqueueAction(printDateAction);
                                
                            }),time * 5000);
                    } else {
                        if ((corspdRtrnObject.payload.aEMResponse != null) && (corspdRtrnObject.payload.aEMResponse != '') && (corspdRtrnObject.payload.aEMResponse != undefined)) {
                            var path = JSON.stringify(corspdRtrnObject.payload.aEMResponse.path);
                            var fileName = JSON.stringify(corspdRtrnObject.payload.aEMResponse.fileName);
                            var path1 = path.slice(1, -1);
                            var fileName1 = fileName.slice(1, -1);
                            if ((corspdRtrnObject.targetUrl != null) && (corspdRtrnObject.targetUrl != '') && (corspdRtrnObject.targetUrl != undefined)) {
                                var labelUrl = corspdRtrnObject.targetUrl;
                                var url = labelUrl + 'pathInAws=' + path1 + '&fileName=' + fileName1;
                                //var pdfWin = window.open(url, "", "height=650,width=840");
                                var pdfWin= window.open("/apex/CorrespondencePage?fileName="+fileName1, "", "height=650,width=840");
                                var time = 1;
                                window.setTimeout(
                                    $A.getCallback(function() {
                                        helper.searchReasonCode(component, helper);
                                    }), time * 3000
                                );
                            }
                        } else {
                            helper.toastMessage('Error','AEMResponse returned is : ' + corspdRtrnObject.payload.aEMResponse);
                        }
                    }
                    component.set("v.toggleSpinner", false);
                } else {
                    if(corspdRtrnObject.errorMessage[0].errorMsg=='RETRY' && component.get("v.retryAttempts")<4){
                        window.setTimeout(
                            $A.getCallback(function() {
                                console.log('Attempt no:'+component.get("v.retryAttempts"));
                                self.viewSelectedCorspd(component, event, corspdId, helper);
                            }), time * 5000
                        );
                    }else if(corspdRtrnObject.errorMessage[0].errorMsg=='RETRY' && component.get("v.retryAttempts") >= 4){
                        this.toastMessage('Error','Error in rendering letter in AEM. The number of attempts made to AEM: '+component.get("v.retryAttempts")+ '. Please Click on the Correspondence link again.');
                        var dismissActionPanel = $A.get("e.force:closeQuickAction");
                        dismissActionPanel.fire();
                        component.set("v.retryAttempts",0);
                        component.set("v.toggleSpinner", false);
                    }else{
                        this.toastMessage('Error','Error: ' + corspdRtrnObject.errorMessage[0].errorMsg);
                        var dismissActionPanel = $A.get("e.force:closeQuickAction");
                        dismissActionPanel.fire();
                        component.set("v.toggleSpinner", false);
                    }
                }
            } else if (state == "ERROR") {
                helper.toastMessage('Error','Error in calling server side action.');
                component.set("v.toggleSpinner", false);
            }
        });
        $A.enqueueAction(viewCorspd);
    },
    
    toastMessage: function(state, msg) {
        var showToast = $A.get("e.force:showToast");
        showToast.setParams({
            'title': state,
            'type': state.toLowerCase(),
            'message': msg
        });
        showToast.fire();
    },
    
    sortBy: function(component, id) {
        var sortAsc = component.get("v.sortAsc"),
            field = id,
            sortField = id,
            records = component.get("v.encapsulatedSearchResult"),
            dummyRecordArray = [],
            sortedRecord = [];
        // dummyRecord will possess all 'PAYLOAD' Object from all records
        for (var i = 0; i < records.length; i++) {
            dummyRecordArray[i] = records[i].payload;
            // Another additional attribute 'parentIndex' is added to keep track of actual index of the object
            dummyRecordArray[i].parentIndex = i;
        }
        sortAsc = sortField != field || !sortAsc;
        // dummyRecord Array is Sorted
        dummyRecordArray.sort(function(a, b) {
            var t1 = a[field] == b[field],
                t2 = (!a[field] && b[field]) || (a[field] < b[field]);
            return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
        });
        for (var i = 0; i < records.length; i++) {
            sortedRecord.push(records[dummyRecordArray[i].parentIndex]);
        }
        component.set("v.sortAsc", sortAsc);
        component.set("v.sortField", id);
        component.set("v.encapsulatedSearchResult", sortedRecord);
    },
    
    getTodaysDate: function(){
        var today = new Date();
        var dd = String(today.getDate()).padStart(2, '0');
        var mm = String(today.getMonth() + 1).padStart(2, '0');
        var yyyy = today.getFullYear();
        return yyyy + '-' + mm + '-' + dd;
    },
    
    checkValidDate: function(component, event, helper, dateValue){
        var valid = true;
        if(!$A.util.isEmpty(dateValue)){
            if(dateValue.length != 10){
                valid = false; 
            }
        }
        return valid;
    },
    
    // Added by Rishav for CCCAP-7800
    setCorspdStatusOptions: function(component){
        var currentStatusOptions = component.get("v.statusOptions");
        var statusOptions = [];
        var option = {
            "label": "--None--",
            "value": null
        };
        statusOptions.push(option);
        currentStatusOptions.forEach(function(status, index) {
            var option = {
                "label": status.toString(),
                "value": status.toString()
            };
            statusOptions.push(option);
        });
        component.set("v.statusOptions", statusOptions);
    }
})