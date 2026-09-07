({
    corspdSearch : function (component, event, helper) {
        var inputProvided = component.get("v.param1");
        var endDateProvided = component.get("v.endDate");
        var todaysDate = helper.getTodaysDate();
        var isBeginDateValid, isEndDateValid;
        isBeginDateValid = isEndDateValid = true;
        if(!$A.util.isEmpty(inputProvided.DTE_REQ__c)){
            isBeginDateValid = helper.checkValidDate(component,event,helper,inputProvided.DTE_REQ__c);
        }
        if(!$A.util.isEmpty(endDateProvided)){
            isEndDateValid = helper.checkValidDate(component,event,helper,endDateProvided);
        }
        if(isBeginDateValid && isEndDateValid){
            if((inputProvided.DTE_REQ__c != null && inputProvided.DTE_REQ__c > todaysDate) || (endDateProvided != null && endDateProvided > todaysDate)){
                helper.toastMessage('Error', 'Requested Dates cannot be in future.')
            } else if (endDateProvided != null && endDateProvided != '' && inputProvided.DTE_REQ__c != null && inputProvided.DTE_REQ__c > endDateProvided){
                helper.toastMessage('Error','End Date must be greater than or Equal to Begin Date');
            } else {
                helper.searchReasonCode(component, helper);    
            }    
        } else {
            helper.toastMessage('Error','Please enter valid date format(MM/DD/YYYY).');
        }
    },

    closeModel : function (component, event, helper) {
        component.set("v.isOpen", false);
    },

    deleteCorspd2 : function(component, event, helper){
        debugger;
        var delCorspdId = [];
        var getAllId = component.find("boxPack");
        var selRecCount = component.get("v.selectedCount");
        if(selRecCount > 0){
            for (var i = 0; i < getAllId.length; i++) {
                if (getAllId[i].get("v.value") == true) {
                    delCorspdId.push(getAllId[i].get("v.text"));
                }
            }
            component.set('v.confirmationModal', true);
        }else{
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({
                'title' : 'Error',
                'type'  : 'error',
                'message' : 'Please select atleast one Correspondence to delete'
            });
            showToast.fire();
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

    createCorspdMan : function(component, event, helper) {
        component.set("v.openManCorspd", true);
    },

    printCorspd : function(component, event, helper) {
        component.set("v.toggleSpinner",true);
        var printCorspdId = [];
        var getAllId = component.find("boxPack");
        var selRecCount = component.get("v.selectedCount");
        
        if(selRecCount > 20){
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({
                'title' : 'Error',
                'type'  : 'Error',
                'message' :  'Correspondence Print limit exceeded. Maximum of 20 Correspondences can be selected to print.'
            });
            showToast.fire();
            component.set("v.toggleSpinner",false);
            return;
        }else if((selRecCount == 1) && (getAllId.length == undefined)){
            printCorspdId.push(component.find("boxPack").get("v.text"));
            helper.printSelected(component, helper, printCorspdId);
        }else if((selRecCount > 0) && (getAllId.length > 0)){
            for (var i = 0; i < getAllId.length; i++) {
                if (getAllId[i].get("v.value") == true) {
                    printCorspdId.push(getAllId[i].get("v.text"));
                }
            }
            helper.printSelected(component, helper, printCorspdId);
        }else if (selRecCount == 0) {
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({
                'title' : 'Error',
                'type'  : 'error',
                'message' :  'Please Select At Least One Correspondence to Print'
            });
            showToast.fire();
            component.set("v.toggleSpinner",false);
        }
    },

    corspdIdLink : function (component, event, helper){
        var hrefValue = event.target.text;
        helper.viewSelectedCorspd(component, event, hrefValue,helper);
    },

    onClickYes : function(component, event, helper){
        var corspdIdsToRemove = [];
        var getAllId = component.find("boxPack");
        var selRecCount = component.get("v.selectedCount");
        if(selRecCount > 0){
            for (var i = 0; i < getAllId.length; i++) {
                if (getAllId[i].get("v.value") == true) {
                    corspdIdsToRemove.push(getAllId[i].get("v.text"));
                }
            }
            if(($A.util.isEmpty(corspdIdsToRemove)) && (getAllId.length == undefined || getAllId.length == '') && (component.get("v.searchResult").length == 1) && (selRecCount == 1)){
                corspdIdsToRemove.push(component.get("v.searchResult")[0].Id);
            }
            component.set("v.toggleSpinner",true);
            helper.deleteSelected(component, event, corspdIdsToRemove, helper);
        }
    },

    selectAll : function(component, event, helper) {
        var currentPageNumber = component.get('v.currentPageNo');
        var searchResultCounts = component.get('v.searchResultCount');
        var startCorrespondence = 20 * currentPageNumber;
        var selectedHeaderCheck = event.getSource().get("v.value");
        var listOfResults = component.get("v.encapsulatedSearchResult");
        var results=component.get('v.searchResult');
        var length = results.length;
        var corrToBeSelected;
        if(Math.abs(length - startCorrespondence) < searchResultCounts){
            corrToBeSelected = Math.abs(length - startCorrespondence);
        } else {
            corrToBeSelected = searchResultCounts
        }
        for(var i=startCorrespondence; i<startCorrespondence + corrToBeSelected; i++){
            listOfResults[i].checked = selectedHeaderCheck;
        }
        component.set('v.encapsulatedSearchResult', listOfResults);
        if(selectedHeaderCheck){
            component.set("v.selectedCount", corrToBeSelected);
        } else {
            component.set("v.selectedCount", 0);
        }
    },

    clickNext: function(component){
        var currentNumber = component.get('v.currentPageNo');
        var length = component.get('v.searchResult').length;
        var searchResultCount = component.get('v.searchResultCount');
        currentNumber++;
        if(!(currentNumber<Math.ceil(length/searchResultCount))){
            //if we're already at maximum, don't do anything
            return;
        }
        component.set('v.currentPageNo', currentNumber);
    },

    clickPrevious: function(component){
        var currentNumber = component.get('v.currentPageNo');
        if(currentNumber==0){
            //if we're already at page zero, don't do anything
            return;
        }
        component.set('v.currentPageNo', --currentNumber);
    },

    sortbyColumn: function(component, event, helper) {
        debugger;
        var dataToSort = component.get("v.encapsulatedSearchResult");
        //var dataToSort = dataToSortObj[0].payload;
        if(dataToSort != null && dataToSort != undefined){
            var idToSort = event.target.id;
            if(undefined !== idToSort && "" !==idToSort){
                helper.sortBy(component, idToSort);
            }
        }
    },

    doInit: function(component, event, helper){
        var fetchUserdataAction = component.get("c.fetchUserdata");
        fetchUserdataAction.setCallback(this, function(response){
            var lsr = response.getReturnValue();
            if(lsr.isSuccessful){
                component.set("v.userData",lsr.objectData);
                component.set("v.userProfileName",lsr.objectData.userProfileName);
            }
        });
        $A.enqueueAction(fetchUserdataAction);
        helper.setCorspdStatusOptions(component); // Added by Rishav for CCCAP-7800
    },

    navigate : function(component, event, helper) {
        var navigateEvent = $A.get("e.force:navigateToComponent");
        navigateEvent.setParams({
            componentDef: "c:viewPrintedCorspd"
        });
        navigateEvent.fire();
    }
})