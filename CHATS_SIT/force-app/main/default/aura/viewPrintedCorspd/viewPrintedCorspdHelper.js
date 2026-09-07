({
    searchReasonCode : function(component, event, helper) {
        component.set("v.toggleSpinner", true);
        var input = (component.get("v.param1")!=null?component.get("v.param1"):'' );
        var dateRequestedEndRange = component.get("v.endDate");
        var datePrintedBeginDate = component.get("v.datePrintedBeginDate");
        var datePrintedEndDate = component.get("v.datePrintedEndDate");
        var requestedBy = component.get("v.userInfoId");
        var action = component.get("c.processCorspdSearch");
        var check=input.Suppressed_Indicator__c;
        action.setParams({ corspdStatus:"REL", 
                          countyName:input.idn_county__c, 
                          caseId:input.idn_case__c, 
                          providerId:input.idn_provr__c,
                          dateRequested:input.dte_reqstd__c, 
                          dateRequestedEndRange:!$A.util.isEmpty(dateRequestedEndRange)?dateRequestedEndRange:null,
                          correspondenceId:input.idn_corr_nam__c, 
                          correspondenceType: input.nam_corr__c, 
                          correspondenceRecipientType: input.cde_type_rcpt__c, 
                          requestedBy: requestedBy,
                          datePrintedBeginDate: !$A.util.isEmpty(datePrintedBeginDate)?datePrintedBeginDate:null, 
                          datePrintedEndDate: !$A.util.isEmpty(datePrintedEndDate)?datePrintedEndDate:null,
                          screen:"PrintedCorrespondence",
                          suppressIndicator: input.Suppressed_Indicator__c
                         });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state == "SUCCESS"){
                var corspdRtrnObject = response.getReturnValue();
                if(((corspdRtrnObject.payload != null) && (corspdRtrnObject.payload != '') && (corspdRtrnObject.payload != undefined)) && !$A.util.isEmpty(corspdRtrnObject.payload.listOfRecords)) {
                    var recordList = corspdRtrnObject.payload.listOfRecords;
                    var allUserCounties = component.get("v.userCounties");
                    for(var i=0; i<recordList.length; i++){
                        if(allUserCounties.includes(recordList[i].idn_county_name) || component.get("v.isAdminUser"))
                            recordList[i].countyMatched = true;
                        else 
                            recordList[i].countyMatched = false;
                    }
                    component.set("v.searchResult", recordList);
                    component.set("v.totalNumberOfRecordsFound", corspdRtrnObject.payload.totalNumberOfRecordsFound); // Added by Rishav for CCCAP-7499
                    var length = recordList.length;
                    component.set("v.totalNumberOfRecordsDisplaying", length); // Added by Rishav for CCCAP-7499
                    var searchResultCount = component.get('v.totalNumberOfRecordsFound');
                    if(length<=searchResultCount){
                        //if there are fewer or an equal number of search results than the listed number of items per page
                        component.set("v.displayedSearchResults", recordList.slice(0, length));
                        component.set("v.numberOfPages", 1);
                        //display all results and set the number of pages to 1
                    }else{
                        component.set("v.displayedSearchResults", recordList.slice(0, searchResultCount));
                        component.set("v.numberOfPages", Math.ceil(recordList.length/searchResultCount));
                    }
                    //reset current page number
                    component.set('v.currentPageNo', 0);
                    if(searchResultCount > length)
                        this.toastMessage('Warning','More records are available. Please refine your search criteria to limit the results');
                    if((corspdRtrnObject.payload.listOfRecords != null ) && (corspdRtrnObject.payload.listOfRecords != '') && (corspdRtrnObject.payload.listOfRecords != undefined)){
                        component.set("v.servletUrl", corspdRtrnObject.targetUrl);
                        component.set("v.corspdPathInAws", corspdRtrnObject.corspdPathInAws);
                    } else
                    	this.resetSearchView(component,event,helper);
                } else
                	this.resetSearchView(component,event,helper);
            } else if(state == "ERROR") {
                this.resetSearchView(component,event,helper);  
            }
            component.set("v.toggleSpinner", false);
        }); 
        $A.enqueueAction(action);
    },
    resetSearchView: function(component,event,helper){
        component.set("v.searchResult", []);
        component.set('v.displayedSearchResults',[]);
        component.set('v.numberOfPages', 0);
        component.set('v.currentPageNo', 0);
        this.toastMessage('Error','No Correspondence Exists for the given Input');
    },
    viewPrintedCorspd : function (component, event, corspdId){
        var action = component.get("c.getFileName");
        action.setParams({ corspdId : corspdId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state == "SUCCESS"){
                var corspdRtrnObject = response.getReturnValue();
                if(((corspdRtrnObject.payload != null) && (corspdRtrnObject.payload != '') && (corspdRtrnObject.payload != undefined))) {
                    component.set("v.corrId_fileName", corspdRtrnObject.payload[0].idn_corr_nam__c);
                    component.set("v.corrId_lang", corspdRtrnObject.payload[0].cde_lang_doc__c);
                    var corrId = component.get("v.corrId_fileName");
                    var servletUrl = component.get("v.servletUrl");    
                    var path = component.get("v.corspdPathInAws");
                    var fileName;
                    var corrIdLang = component.get("v.corrId_lang");
                    if(!$A.util.isEmpty(corrIdLang)){
                        var lang = corrIdLang;
                        fileName = corrId + '_' + lang +'.pdf';
                    }else{
                        fileName = corrId+'.pdf';
                    }
                    var url = servletUrl+'pathInAws='+path+'&fileName='+fileName;
                    //var pdfWin = window.open(url, "", "height=650,width=840");
                    var pdfWin= window.open("/apex/CorrespondencePage?fileName="+fileName, "", "height=650,width=840");
                    console.log(pdfWin);
                } else
                    this.toastMessage('Error','Error in Retrieving Correspondence Pdf filename');
            } else if(state == "ERROR")
                this.toastMessage('Error','Error in retrieving FileName of the Pdf.');
        });
        $A.enqueueAction(action);
    },
    
    sortBy: function(component, id) {
        var sortAsc = component.get("v.sortAsc"),
            field = id,
            sortField = id,
            records = component.get("v.displayedSearchResults"),
            dummyRecordArray = [],
            sortedRecord = [];
        // dummyRecord will possess all 'PAYLOAD' Object from all records
        for (var i = 0; i < records.length; i++) {
            dummyRecordArray[i] = records[i];//.payload;
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
        console.log('------records', records);
        component.set("v.sortAsc", sortAsc);
        component.set("v.sortField", id);
        component.set("v.displayedSearchResults", sortedRecord);
    },
    
    toastMessage : function(state,msg){
        var showToast = $A.get("e.force:showToast");
        showToast.setParams({
            'title' : state,
            'type'  : state.toLowerCase(),
            'message' : msg
        });
        showToast.fire();
    },
    
    getTodaysDate: function(){
        var today = new Date();
        var dd = String(today.getDate()).padStart(2, '0');
        var mm = String(today.getMonth() + 1).padStart(2, '0');
        var yyyy = today.getFullYear();
        return yyyy + '-' + mm + '-' + dd;
    },
    
    checkValidDate: function(component,event,helper,dateValue){
        var valid = true;
        if(!$A.util.isEmpty(dateValue)){
            if(dateValue.length != 10){
                valid = false; 
            }
        }
        return valid;
    },
    
    deleteSelected: function(component, event, delCorspdId, helper) {
        var listSearchResults = component.get("v.searchResult");
        var deleteAction = component.get("c.corspdSuppressOrDeleteAction");
        deleteAction.setParams({
            "lstCorspdId": delCorspdId,
            "operation":"DELETE",
            "listSearchResults": listSearchResults
        });
        deleteAction.setCallback(this, function(response) {
            var state = response.getState();
            var corspdRtrnObject = response.getReturnValue();
            if (state == "SUCCESS" && !$A.util.isEmpty(corspdRtrnObject)) {       
                if(corspdRtrnObject.returnStatus == 'Success'){
                    this.toastMessage('Success','Selected Correspondences are deleted.');
                    component.set("v.confirmationModal", false);
                    component.set("v.selectAllCheckbox", false);
                    component.set("v.selectedCount", 0);
                    component.set("v.param1", '');
                    helper.searchReasonCode(component,event,helper);
                }else {
                    this.toastMessage('Error',JSON.stringify(corspdRtrnObject.errorMessage[0].errorMsg));
                }
            } else if (state == "ERROR") {
                this.toastMessage('Error','Error in calling server side action.');
            }
            component.set("v.toggleSpinner", false);
        });
        $A.enqueueAction(deleteAction);
    },
    
    setDisplayedResults: function(component, listOfResults){
        var searchResultCount = component.get('v.searchResultCount');
        var length = listOfResults.length;
        var retVal = [];
        for(var i = 0; i < length; i += 1) {
            retVal[i] = new Object({
                'checked': false,
                'payload': listOfResults[i]
            });
        }
        component.set('v.numberOfPages', Math.ceil(length / searchResultCount));
        component.set('v.currentPageNo', 0);
        return retVal;
    },
    
    suppressSelected : function(component,event,helper,printCorspdId){
        var stopSpinner = true;
        var time = 1; //in second
        var suppressAction = component.get("c.corspdSuppressOrDeleteAction");
        suppressAction.setParams({
            "lstCorspdId": printCorspdId,
            "operation":"SUPPRESS"
        });
        suppressAction.setCallback(this,function(response){
            var corspdRtrnObject = response.getReturnValue();
            var state = response.getState();
            if(state=='SUCCESS'){
                if(corspdRtrnObject.returnStatus=='Success'){
                    if(corspdRtrnObject.payload.errorMessage!=null && corspdRtrnObject.payload.errorMessage!=''){
                        this.toastMessage('Error','One or more of the correspondences selected are not in Suppressed or Unsuppressed status. Please ensure all correspondence selected are in the same Suppressed or Unsuppressed status');
                        helper.searchReasonCode(component,event,helper);
                    }else{
                        component.set("v.selectAllCheckbox", false);
                        component.set("v.selectedCount", 0);
                        this.toastMessage('Success','Selected Correspondences are Suppressed');
                        helper.searchReasonCode(component,event,helper);
                    }
                }else if(corspdRtrnObject.errorMessage!=null){
                    this.toastMessage('Error','Error in calling server side action');
                }
            }else if(state=='ERROR'){
                this.toastMessage('Error','Error in calling server side action.');
                stopSpinner = false;
            }
            component.set("v.toggleSpinner", false);
        });
        $A.enqueueAction(suppressAction);
    },
    
    unSuppressSelected : function(component,event,helper,printCorspdId){
        var stopSpinner = true;
        var time = 1; //in second
        var suppressAction = component.get("c.corspdSuppressOrDeleteAction");
        suppressAction.setParams({
            "lstCorspdId": printCorspdId,
            "operation":"UNSUPPRESS"
        });
        suppressAction.setCallback(this,function(response){
            var corspdRtrnObject = response.getReturnValue();
            var state = response.getState();
            if(state=='SUCCESS'){             
                if(corspdRtrnObject.returnStatus=='Success'){
                    if(corspdRtrnObject.payload.errorMessage!=null && corspdRtrnObject.payload.errorMessage!=''){
                        this.toastMessage('Error','One or more of the correspondences selected are not in Suppressed or Unsuppressed status. Please ensure all correspondence selected are in the same Suppressed or Unsuppressed status');
                        helper.searchReasonCode(component,event,helper);
                    }else{
                        component.set("v.selectAllCheckbox", false);
                        component.set("v.selectedCount", 0);
                        this.toastMessage('Success','Selected Correspondences are Unsuppressed');
                        helper.searchReasonCode(component,event,helper);
                    }
                }else if(corspdRtrnObject.errorMessage!=null){
                    this.toastMessage('Error','Error in calling server side action');
                }
            }else if(state=='ERROR'){
                this.toastMessage('Error','Error in calling server side action.');
                stopSpinner = false;
            }
            component.set("v.toggleSpinner", false);
        });
        $A.enqueueAction(suppressAction);
    },
    
    callModal : function(cmp, modalName) {
        var modalCall = cmp.find(modalName);
        modalCall.openModal();
    }
})