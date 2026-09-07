({ 
    corspdSearch : function(component, event, helper) {        
        var action = component.get("c.fetchUserCounties");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                component.set("v.userCounties", res.allUserCounties);
                component.set("v.isAdminUser", res.adminUser);
            }
        });
        $A.enqueueAction(action);
        var inputProvided = component.get("v.param1");
        var endDateProvided = component.get("v.endDate");
        var datePrintedBeginDate = component.get("v.datePrintedBeginDate");
        var datePrintedEndDate = component.get("v.datePrintedEndDate");
        var todaysDate = helper.getTodaysDate();
        var isReqstdBeginDateValid,isReqstdEndDateValid,isPrintedBeginDateValid,isPrintedEndDateValid;
        isReqstdBeginDateValid = isReqstdEndDateValid = isPrintedBeginDateValid = isPrintedEndDateValid = true;
        
        if(!$A.util.isEmpty(inputProvided.dte_reqstd__c)){
            isReqstdBeginDateValid = helper.checkValidDate(component,event,helper,inputProvided.dte_reqstd__c);
        }
        if(!$A.util.isEmpty(endDateProvided)){
            isReqstdEndDateValid = helper.checkValidDate(component,event,helper,endDateProvided);
        }
        if(!$A.util.isEmpty(datePrintedBeginDate)){
            isPrintedBeginDateValid = helper.checkValidDate(component,event,helper,datePrintedBeginDate);
        }
        if(!$A.util.isEmpty(datePrintedEndDate)){
            isPrintedEndDateValid = helper.checkValidDate(component,event,helper,datePrintedEndDate);
        }
        if(isReqstdBeginDateValid && isReqstdEndDateValid && isPrintedBeginDateValid && isPrintedEndDateValid){
            if((inputProvided.dte_reqstd__c != null && inputProvided.dte_reqstd__c > todaysDate) || (endDateProvided != null && endDateProvided > todaysDate)){
                helper.toastMessage('Error', 'Requested Dates cannot be in future.')
            } else if((datePrintedBeginDate != null && datePrintedBeginDate > todaysDate) || (datePrintedEndDate != null && datePrintedEndDate > todaysDate)){
                helper.toastMessage('Error','Date Printed cannot be in future')
            } else if ((endDateProvided != null && endDateProvided != '' && inputProvided.dte_reqstd__c != null && inputProvided.dte_reqstd__c > endDateProvided) ||
                       (datePrintedEndDate != null && datePrintedBeginDate != null && datePrintedEndDate != '' && datePrintedBeginDate != '' && datePrintedBeginDate > datePrintedEndDate)) {
                helper.toastMessage('Error','End Date must be greater than or equal to Begin Date');
            } else {
                helper.searchReasonCode(component, event, helper);    
            }
        } else {
            helper.toastMessage('Error','Please enter valid date format(MM/DD/YYYY).');
        }
    },
    
    closeModel : function(component, event, helper) {
        component.set("v.isOpen", false);
    },
    
    corspdIdLink : function(component, event, helper) {
        var hrefValue = event.target.text;
        helper.viewPrintedCorspd(component, event, hrefValue);
    },
    
    clickNext: function(component){
        //advance the page number by 1
        var currentNumber = component.get('v.currentPageNo');
        var completeList = component.get('v.searchResult');
        var searchResultCount = component.get('v.searchResultCount');
        currentNumber++;
        if(!(currentNumber<Math.ceil(completeList.length/searchResultCount))){
            //if we're already at maximum, don't do anything
            //currentNumber++ used because page number starts at zero
            return;
        }
        var beginIndex = currentNumber*searchResultCount;
        component.set('v.displayedSearchResults' , completeList.slice(beginIndex, beginIndex+searchResultCount));
        component.set('v.currentPageNo', currentNumber);
    },
    
    clickPrevious: function(component){
        //decrease the page number by 1
        var currentNumber = component.get('v.currentPageNo');
        var searchResultCount = component.get('v.searchResultCount');
        if(currentNumber==0){
            //if we're already at page zero, don't do anything
            return;
        }
        var completeList = component.get('v.searchResult');
        currentNumber--;
        var beginIndex = currentNumber*searchResultCount;
        var length = completeList.length;
        component.set('v.displayedSearchResults' , completeList.slice(beginIndex, beginIndex+searchResultCount));
        component.set('v.currentPageNo', currentNumber);
    },
    
    sortbyColumn: function(component, event, helper) {
        var dataToSort = component.get("v.displayedSearchResults");
        if(dataToSort != null && dataToSort != undefined){
            var idToSort = event.target.id;
            if(undefined !== idToSort && "" !==idToSort){
                helper.sortBy(component, idToSort);
            }
        }
    },
    
    navigate : function(component, event, helper) {
        var navigateEvent = $A.get("e.force:navigateToComponent");
        navigateEvent.setParams({
            componentDef: "c:CorspdPrintQueue"
        });
        navigateEvent.fire();
    },
    
    checkboxSelect : function (component, event, helper) {
        var selectedRec = event.getSource().get("v.value");
        var getSelectedNumber=component.get('v.selectedCount');
        if (selectedRec == true) {
            getSelectedNumber++;
        } else if(selectedRec == false && getSelectedNumber != 0){
            getSelectedNumber--;
        }
        console.log(selectedRec+' should be true and '+getSelectedNumber+' should not be zero');
        component.set("v.selectedCount", getSelectedNumber);
    },
    
    deleteCorspd2 : function(component, event, helper){
        console.log('deleteCorpd2 called');
        var delCorspdId = [];
        var getAllId = component.find("boxPack");
        var selRecCount = component.get("v.selectedCount");
        if(selRecCount > 0){
            for(var i = 0; i < getAllId.length; i++) {
                if (getAllId[i].get("v.value") == true) {
                    delCorspdId.push(getAllId[i].get("v.text"));
                }
            }
            component.set('v.confirmationModal', true);
        } else {
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({
                'title' : 'Error',
                'type'  : 'error',
                'message' : 'Please select atleast one Correspondence to delete'
            });
            showToast.fire();
        }
    },
    
    selectAll : function(component, event, helper) {
        var currentPageNumber = component.get('v.currentPageNo');
        var searchResultCounts = component.get('v.searchResultCount');
        var startCorrespondence = 20 * currentPageNumber;
        var selectedHeaderCheck = event.getSource().get("v.value");
        var listOfResults = component.get("v.displayedSearchResults");
        var results = component.get('v.searchResult');
        var length = results.length;
        var corrToBeSelected;
        var numOfSelectedCorspd = 0;
        if(Math.abs(length - startCorrespondence) < searchResultCounts){
            corrToBeSelected = Math.abs(length - startCorrespondence);
        } else {
            corrToBeSelected = searchResultCounts
        }
        for(var i=startCorrespondence; i<startCorrespondence + corrToBeSelected; i++){
            if(listOfResults[i].countyMatched){
                listOfResults[i].checked = selectedHeaderCheck;
                numOfSelectedCorspd++; // Added by Rishav for CCCAP-8200
            }
        }
        component.set('v.displayedSearchResults', listOfResults);
        if(selectedHeaderCheck) {
            component.set("v.selectedCount", numOfSelectedCorspd);
        } else {
            component.set("v.selectedCount", 0);
        }
    },
    
    suppressClicked: function(component,event,helper,printCorspdId){
        console.log('suppressedClicked clicked');
        component.set("v.toggleSpinner",true);
        var printCorspdId = [];
        var getAllId = component.find("boxPack");
        console.log('getAllId: '+getAllId.length);
        var selRecCount = component.get("v.selectedCount");
        if(selRecCount > 20){
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({
                'title' : 'Error',
                'type'  : 'Error',
                'message' :  'Correspondence Suppress limit exceeded. Maximum of 20 Correspondences can be selected to Suppress.'
            });
            showToast.fire();
            component.set("v.toggleSpinner",false);
            return;
        } else if((selRecCount == 1) && (getAllId.length == undefined)) {
            printCorspdId.push(component.find("boxPack").get("v.text"));
            component.set('v.printCorspdId',printCorspdId);            
            component.set('v.supressedUnSuppressedMessage','Are you sure you want Suppress or Unsuppress the selected correspondence?');
            component.set('v.confirmationModalSupressed', true); 
            component.set("v.toggleSpinner",false);
            helper.callModal(component,'confirmationModalOnSupressed');
        } else if((selRecCount > 0) && (getAllId.length > 0)) {
            for(var i = 0; i < getAllId.length; i++) {
                if(getAllId[i].get("v.value") == true) {
                    printCorspdId.push(getAllId[i].get("v.text"));
                }
            }
            component.set('v.printCorspdId',printCorspdId); 
            component.set('v.confirmationModalSupressed', true);
            component.set('v.supressedUnSuppressedMessage','Are you sure you want Suppress or Unsuppress the selected correspondence?');
            component.set("v.toggleSpinner",false);
            helper.callModal(component,'confirmationModalOnSupressed');
        } else if(selRecCount == 0) {
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({
                'title' : 'Error',
                'type'  : 'error',
                'message' : 'Please select atleast one Correspondence to suppress'
            });
            showToast.fire();
            component.set("v.toggleSpinner",false);
        }
    },
    
    unSuppressClicked: function(component,event,helper,printCorspdId){
        console.log('unsuppressedClicked clicked');
        component.set("v.toggleSpinner",true);
        var printCorspdId = [];
        var getAllId = component.find("boxPack");
        var selRecCount = component.get("v.selectedCount");
        
        if(selRecCount > 20) {
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({
                'title' : 'Error',
                'type'  : 'Error',
                'message' :  'Correspondence UnSuppress limit exceeded. Maximum of 20 Correspondences can be selected to UnSuppress.'
            });
            showToast.fire();
            component.set("v.toggleSpinner",false);
            return;
        } else if((selRecCount == 1) && (getAllId.length == undefined)) {
            printCorspdId.push(component.find("boxPack").get("v.text"));
            component.set('v.printCorspdId',printCorspdId);
            component.set('v.supressedUnSuppressedMessage','Are you sure you want Suppress or Unsuppress the selected correspondence?');
            component.set('v.confirmationModalUnSuppressed', true); 
            component.set("v.toggleSpinner",false);
            helper.callModal(component,'confirmationModalOnUnSuppressed');
            
        } else if((selRecCount > 0) && (getAllId.length > 0)) {
            for(var i = 0; i < getAllId.length; i++) {
                if(getAllId[i].get("v.value") == true) {
                    printCorspdId.push(getAllId[i].get("v.text"));
                }
            }
            component.set('v.printCorspdId',printCorspdId);
            component.set('v.supressedUnSuppressedMessage','Are you sure you want Suppress or Unsuppress the selected correspondence?');
            component.set('v.confirmationModalUnSuppressed', true); 
            component.set("v.toggleSpinner",false);
            helper.callModal(component,'confirmationModalOnUnSuppressed');
        } else if(selRecCount == 0) {
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({
                'title' : 'Error',
                'type'  : 'error',
                'message' : 'Please select atleast one Correspondence to unsuppress'
            });
            showToast.fire();
            component.set("v.toggleSpinner",false);
        }
    },
    
    onClickYes : function(component, event, helper){
        var corspdIdsToRemove = [];
        var getAllId = component.find("boxPack");
        var selRecCount = component.get("v.selectedCount");
        if(selRecCount > 0){
            for (var i = 0; i < getAllId.length; i++) {
                if (getAllId[i].get("v.value") == true && !$A.util.isEmpty(getAllId[i].get("v.text")))//CCCAP-2718 A new condition added to avoid the bad or Null value
                {
                    corspdIdsToRemove.push(getAllId[i].get("v.text"));
                }
            }
            if(($A.util.isEmpty(corspdIdsToRemove)) && (getAllId.length == undefined || getAllId.length == '') && (component.get("v.searchResult").length == 1) && (selRecCount == 1)){
                corspdIdsToRemove.push(component.get("v.searchResult")[0].idn_corr_nam);//CCCAP-2718 As Id is not a field so it was not recognizable and idn_corr_nam is added instead of that which is identifiable.
            }
            component.set("v.toggleSpinner",true);
            helper.deleteSelected(component, event, corspdIdsToRemove, helper);
        }
    },
    
    checkboxSelect : function (component, event, helper) {
        var selectedRec = event.getSource().get("v.value");
        var getSelectedNumber=component.get('v.selectedCount');
        if (selectedRec == true) {
            getSelectedNumber++;
        } else if(selectedRec == false && getSelectedNumber != 0){
            getSelectedNumber--;
        }
        console.log(selectedRec+' should be true and '+getSelectedNumber+' should not be zero');
        component.set("v.selectedCount", getSelectedNumber);
    },
    
    confirmYes : function(component, event, helper){
        var cmp = component.find('confirmationModalOnSupressed');
        cmp.hideConfirmModal();
        var printCorspdId=component.get('v.printCorspdId');
        component.set("v.showSpinner", false);
        helper.suppressSelected(component,event, helper, printCorspdId);
    },
    
    confirmYes1 : function(component, event, helper){
        var cmp = component.find('confirmationModalOnUnSuppressed');
        cmp.hideConfirmModal();
        var printCorspdId=component.get('v.printCorspdId'); 
        component.set("v.showSpinner", false);
        helper.unSuppressSelected(component,event, helper, printCorspdId);
    }
})